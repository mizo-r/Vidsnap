import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:ffmpeg_kit_flutter_new_min/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_min/ffmpeg_kit_config.dart';
import 'package:ffmpeg_kit_flutter_new_min/return_code.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:vidsnap/core/services/extraction_service.dart';
import 'package:vidsnap/data/models/download_task.dart';
import 'package:vidsnap/data/models/history_item.dart';
import 'package:vidsnap/data/repositories/download_repository.dart';
import 'package:vidsnap/data/repositories/history_repository.dart';
import 'package:vidsnap/data/repositories/settings_repository.dart';

/// Manages the download queue and persists progress to Hive.
///
/// Supports two modes:
///   1. Direct download — single URL, no merge.
///   2. Merge download — video + audio downloaded in parallel, then merged
///      via FFmpeg into a single MP4.
class DownloadService {
  DownloadService({
    required this.dio,
    required this.downloadRepo,
    required this.historyRepo,
    required this.settingsRepo,
    required this.extractionService,
  });

  final Dio dio;
  final DownloadRepository downloadRepo;
  final HistoryRepository historyRepo;
  final SettingsRepository settingsRepo;
  final ExtractionService extractionService;

  final Map<String, CancelToken> _cancelTokens = {};
  final Map<String, StreamSubscription<List<int>>> _subscriptions = {};
  final _progressController = StreamController<DownloadTask>.broadcast();
  final _uuid = const Uuid();

  Stream<DownloadTask> get progressStream => _progressController.stream;

  /// Enqueues a new download and starts it if a slot is free.
  Future<DownloadTask> enqueue({
    required String sourceId,
    required String originalUrl,
    required String videoTitle,
    required String customFileName,
    required String formatId,
    required String quality,
    required String extension,
    required String downloadUrl,
    String? thumbnailUrl,
    int? totalBytes,
    bool requiresMerge = false,
    String? videoUrl,
    String? audioUrl,
    int? videoTotalBytes,
    int? audioTotalBytes,
  }) async {
    final id = _uuid.v4();
    final task = DownloadTask(
      id: id,
      sourceId: sourceId,
      originalUrl: originalUrl,
      videoTitle: videoTitle,
      customFileName: customFileName,
      formatId: formatId,
      quality: quality,
      extension: extension,
      status: DownloadStatus.queued,
      progressPercent: 0,
      downloadedBytes: 0,
      totalBytes: totalBytes,
      createdAt: DateTime.now(),
      retryCount: 0,
      downloadUrl: downloadUrl,
      videoUrl: videoUrl,
      audioUrl: audioUrl,
      requiresMerge: requiresMerge,
      thumbnailUrl: thumbnailUrl,
      videoTotalBytes: videoTotalBytes,
      audioTotalBytes: audioTotalBytes,
    );
    await downloadRepo.add(task);
    _tryStartNext();
    return task;
  }

  Future<void> pause(String id) async {
    final task = downloadRepo.getById(id);
    if (task == null || !task.isActive) return;
    if (task.mergePhase) return; // can't pause during merge
    _cancelTokens[id]?.cancel('paused');
    _cancelTokens.remove(id);
    _subscriptions[id]?.cancel();
    _subscriptions.remove(id);
    task.status = DownloadStatus.paused;
    await downloadRepo.update(task);
    _progressController.add(task);
    _tryStartNext();
  }

  Future<void> resume(String id) async {
    final task = downloadRepo.getById(id);
    if (task == null || task.status != DownloadStatus.paused) return;
    task.status = DownloadStatus.queued;
    await downloadRepo.update(task);
    _tryStartNext();
  }

  Future<void> retry(String id) async {
    final task = downloadRepo.getById(id);
    if (task == null) return;
    task
      ..status = DownloadStatus.queued
      ..progressPercent = 0
      ..downloadedBytes = 0
      ..videoDownloadedBytes = 0
      ..audioDownloadedBytes = 0
      ..errorMessage = null
      ..mergePhase = false
      ..retryCount = task.retryCount + 1;
    await downloadRepo.update(task);
    _tryStartNext();
  }

  Future<void> cancel(String id) async {
    _cancelTokens[id]?.cancel('cancelled');
    _cancelTokens.remove(id);
    _subscriptions[id]?.cancel();
    _subscriptions.remove(id);
    // Clean up any temp files
    await _cleanupTempFiles(id);
    await downloadRepo.delete(id);
    _tryStartNext();
  }

  void _tryStartNext() {
    final maxConcurrent = settingsRepo.current.maxConcurrentDownloads;
    final active = downloadRepo.active.where((t) => t.status == DownloadStatus.downloading).length;
    final slotsLeft = maxConcurrent - active;
    if (slotsLeft <= 0) return;
    final queued = downloadRepo.all
        .where((t) => t.status == DownloadStatus.queued)
        .take(slotsLeft)
        .toList();
    for (final task in queued) {
      _startDownload(task);
    }
  }

  Future<void> _startDownload(DownloadTask task) async {
    if (task.requiresMerge) {
      if (task.videoUrl == null || task.audioUrl == null) {
        task
          ..status = DownloadStatus.failed
          ..errorMessage = 'Missing video or audio URL for merge';
        await downloadRepo.update(task);
        return;
      }
      await _startMergeDownload(task);
    } else {
      if (task.downloadUrl == null) {
        task
          ..status = DownloadStatus.failed
          ..errorMessage = 'Missing download URL';
        await downloadRepo.update(task);
        return;
      }
      await _startDirectDownload(task);
    }
  }

  // ===========================================================================
  // Direct download (no merge)
  // ===========================================================================

  Future<void> _startDirectDownload(DownloadTask task) async {
    task.status = DownloadStatus.downloading;
    await downloadRepo.update(task);
    _progressController.add(task);

    final cancelToken = CancelToken();
    _cancelTokens[task.id] = cancelToken;

    final dir = await _resolveSaveDir();
    final safeName = _sanitizeFileName(task.customFileName);
    final filePath = p.join(dir.path, '$safeName.${task.extension}');
    final file = File(filePath);

    int downloaded = task.downloadedBytes;
    final headers = <String, dynamic>{};
    if (downloaded > 0) {
      headers[HttpHeaders.rangeHeader] = 'bytes=$downloaded-';
    }

    IOSink sink = file.openWrite(mode: FileMode.writeOnlyAppend);

    try {
      final response = await dio.get<ResponseBody>(
        task.downloadUrl!,
        options: Options(
          responseType: ResponseType.stream,
          receiveTimeout: const Duration(minutes: 30),
          sendTimeout: const Duration(seconds: 15),
          followRedirects: true,
          maxRedirects: 5,
          headers: headers,
        ),
        cancelToken: cancelToken,
      );

      final supportsResume = response.statusCode == 206;
      if (!supportsResume) {
        downloaded = 0;
        await sink.flush();
        await sink.close();
        sink = file.openWrite(mode: FileMode.writeOnly);
      }

      final total = task.totalBytes ??
          (response.headers.value('content-length') != null
              ? int.tryParse(response.headers.value('content-length')!) ?? 0
              : 0);

      final completer = Completer<void>();
      late StreamSubscription<List<int>> sub;
      sub = response.data!.stream.listen(
        (chunk) {
          sink.add(chunk);
          downloaded += chunk.length;
          task
            ..status = DownloadStatus.downloading
            ..downloadedBytes = downloaded
            ..totalBytes = total > 0 ? total : null
            ..progressPercent = total > 0 ? ((downloaded / total) * 100).clamp(0, 100).round() : 0;
          _progressController.add(task);
        },
        onError: (e) {
          if (!completer.isCompleted) completer.completeError(e);
        },
        onDone: () {
          if (!completer.isCompleted) completer.complete();
        },
        cancelOnError: true,
      );
      _subscriptions[task.id] = sub;

      await completer.future;
      await sink.flush();
      await sink.close();

      task
        ..status = DownloadStatus.completed
        ..progressPercent = 100
        ..downloadedBytes = downloaded
        ..filePath = filePath;
      await downloadRepo.update(task);
      _progressController.add(task);

      await historyRepo.add(HistoryItem(
        id: task.id,
        fileName: task.customFileName,
        sourceId: task.sourceId,
        quality: task.quality,
        downloadedAt: DateTime.now(),
        filePath: filePath,
        fileSizeBytes: downloaded,
        thumbnailUrl: task.thumbnailUrl,
      ));
    } catch (e) {
      try {
        await sink.flush();
        await sink.close();
      } catch (_) {}
      if (e is DioException && CancelToken.isCancel(e)) {
        // Paused or cancelled — no need to mark as failed.
      } else {
        await _handleDownloadError(task, e);
      }
    } finally {
      _cancelTokens.remove(task.id);
      _subscriptions.remove(task.id);
      _tryStartNext();
    }
  }

  // ===========================================================================
  // Merge download (video + audio in parallel, then FFmpeg)
  // ===========================================================================

  Future<void> _startMergeDownload(DownloadTask task) async {
    task.status = DownloadStatus.downloading;
    await downloadRepo.update(task);
    _progressController.add(task);

    final tempDir = await _resolveTempDir();
    final videoPath = p.join(tempDir.path, '${task.id}_video.mp4');
    final audioPath = p.join(tempDir.path, '${task.id}_audio.m4a');

    try {
      // Download both in parallel
      final results = await Future.wait([
        _downloadStream(
          task: task,
          url: task.videoUrl!,
          filePath: videoPath,
          onProgress: (downloaded, total) async {
            task.videoDownloadedBytes = downloaded;
            if (total > 0) task.videoTotalBytes = total;
            _updateMergeProgress(task);
            await downloadRepo.update(task);
          },
        ),
        _downloadStream(
          task: task,
          url: task.audioUrl!,
          filePath: audioPath,
          onProgress: (downloaded, total) async {
            task.audioDownloadedBytes = downloaded;
            if (total > 0) task.audioTotalBytes = total;
            _updateMergeProgress(task);
            await downloadRepo.update(task);
          },
        ),
      ]);

      // If either failed, throw
      for (final success in results) {
        if (!success) throw Exception('Parallel download failed');
      }

      // Merge phase
      task.mergePhase = true;
      _progressController.add(task);
      await downloadRepo.update(task);

      final dir = await _resolveSaveDir();
      final safeName = _sanitizeFileName(task.customFileName);
      final outputPath = p.join(dir.path, '$safeName.mp4');

      // FFmpeg: -i video -i audio -c copy output.mp4
      // -c copy avoids re-encoding (fast, no quality loss)
      final cmd = '-i "$videoPath" -i "$audioPath" -c copy -y "$outputPath"';
      final session = await FFmpegKit.execute(cmd);
      final returnCode = await session.getReturnCode();

      if (!ReturnCode.isSuccess(returnCode)) {
        throw Exception('FFmpeg merge failed (code ${returnCode?.getValue()})');
      }

      // Verify output exists
      final outputFile = File(outputPath);
      if (!await outputFile.exists()) {
        throw Exception('FFmpeg output file not found');
      }
      final outputSize = await outputFile.length();

      // Clean up temp files
      await _safeDelete(videoPath);
      await _safeDelete(audioPath);

      // Mark complete
      task
        ..status = DownloadStatus.completed
        ..progressPercent = 100
        ..downloadedBytes = outputSize
        ..totalBytes = outputSize
        ..filePath = outputPath
        ..mergePhase = false;
      await downloadRepo.update(task);
      _progressController.add(task);

      await historyRepo.add(HistoryItem(
        id: task.id,
        fileName: task.customFileName,
        sourceId: task.sourceId,
        quality: task.quality,
        downloadedAt: DateTime.now(),
        filePath: outputPath,
        fileSizeBytes: outputSize,
        thumbnailUrl: task.thumbnailUrl,
      ));
    } catch (e) {
      // Clean up temp files on any failure
      await _safeDelete(videoPath);
      await _safeDelete(audioPath);
      task.mergePhase = false;
      await _handleDownloadError(task, e);
    } finally {
      _cancelTokens.remove(task.id);
      _cancelTokens.remove('${task.id}_video');
      _cancelTokens.remove('${task.id}_audio');
      _subscriptions.remove(task.id);
      _subscriptions.remove('${task.id}_video');
      _subscriptions.remove('${task.id}_audio');
      _tryStartNext();
    }
  }

  void _updateMergeProgress(DownloadTask task) {
    final v = task.videoDownloadedBytes;
    final a = task.audioDownloadedBytes;
    final vTotal = task.videoTotalBytes ?? 0;
    final aTotal = task.audioTotalBytes ?? 0;
    final totalDone = v + a;
    final totalAll = (vTotal > 0 ? vTotal : 0) + (aTotal > 0 ? aTotal : 0);
    task.downloadedBytes = totalDone;
    if (totalAll > 0) {
      task.progressPercent = ((totalDone / totalAll) * 100).clamp(0, 100).round();
    }
    _progressController.add(task);
  }

  Future<bool> _downloadStream({
    required DownloadTask task,
    required String url,
    required String filePath,
    required Future<void> Function(int downloaded, int total) onProgress,
  }) async {
    final cancelToken = CancelToken();
    final key = '${task.id}_${p.basenameWithoutExtension(filePath)}';
    _cancelTokens[key] = cancelToken;

    final file = File(filePath);
    final sink = file.openWrite(mode: FileMode.writeOnly);

    try {
      final response = await dio.get<ResponseBody>(
        url,
        options: Options(
          responseType: ResponseType.stream,
          receiveTimeout: const Duration(minutes: 30),
          sendTimeout: const Duration(seconds: 15),
          followRedirects: true,
          maxRedirects: 5,
        ),
        cancelToken: cancelToken,
      );

      final total = int.tryParse(response.headers.value('content-length') ?? '') ?? 0;
      int downloaded = 0;

      final completer = Completer<bool>();
      late StreamSubscription<List<int>> sub;
      sub = response.data!.stream.listen(
        (chunk) {
          sink.add(chunk);
          downloaded += chunk.length;
          onProgress(downloaded, total);
        },
        onError: (e) {
          if (!completer.isCompleted) completer.completeError(e);
        },
        onDone: () {
          if (!completer.isCompleted) completer.complete(true);
        },
        cancelOnError: true,
      );
      _subscriptions[key] = sub;

      await completer.future;
      await sink.flush();
      await sink.close();
      return true;
    } catch (e) {
      try {
        await sink.flush();
        await sink.close();
      } catch (_) {}
      // Delete partial file
      await _safeDelete(filePath);
      return false;
    }
  }

  // ===========================================================================
  // Error handling & URL refresh
  // ===========================================================================

  Future<void> _handleDownloadError(DownloadTask task, dynamic e) async {
    if (e is DioException && CancelToken.isCancel(e)) {
      // Paused or cancelled — no need to mark as failed.
      return;
    }

    // Detect expired URL (403/410 from CDN).
    final isExpiredUrl = e is DioException &&
        (e.response?.statusCode == 403 ||
            e.response?.statusCode == 410 ||
            e.message?.contains('Forbidden') == true);

    if (isExpiredUrl && task.retryCount < 2) {
      try {
        final fresh = await extractionService.extract(
          serverUrl: settingsRepo.current.serverUrl,
          videoUrl: task.originalUrl,
        );

        if (task.requiresMerge) {
          // Find matching video format
          final vMatch = fresh.formats.firstWhere(
            (f) => f.formatId == task.formatId,
            orElse: () => fresh.formats.firstWhere(
              (f) => f.label == task.quality,
              orElse: () => fresh.formats.firstWhere((f) => f.recommended,
                  orElse: () => fresh.formats.first),
            ),
          );
          // Find best audio
          final aMatch = fresh.audioFormats.isNotEmpty ? fresh.audioFormats.first : null;
          if (vMatch.videoUrl != null && aMatch != null) {
            task
              ..videoUrl = vMatch.videoUrl
              ..audioUrl = aMatch.downloadUrl
              ..retryCount = task.retryCount + 1
              ..status = DownloadStatus.queued
              ..errorMessage = null
              ..videoDownloadedBytes = 0
              ..audioDownloadedBytes = 0;
            await downloadRepo.update(task);
            _progressController.add(task);
            _tryStartNext();
            return;
          }
        } else {
          final match = fresh.formats.firstWhere(
            (f) => f.formatId == task.formatId,
            orElse: () => fresh.formats.firstWhere(
              (f) => f.label == task.quality,
              orElse: () => fresh.formats.first,
            ),
          );
          task
            ..downloadUrl = match.downloadUrl
            ..retryCount = task.retryCount + 1
            ..status = DownloadStatus.queued
            ..errorMessage = null
            ..downloadedBytes = 0
            ..progressPercent = 0;
          await downloadRepo.update(task);
          _progressController.add(task);
          _tryStartNext();
          return;
        }
      } catch (_) {
        // fall through to mark as failed
      }
    }

    task
      ..status = DownloadStatus.failed
      ..errorMessage = e.toString();
    await downloadRepo.update(task);
    _progressController.add(task);
  }

  // ===========================================================================
  // Path & file helpers
  // ===========================================================================

  Future<Directory> _resolveSaveDir() async {
    final folder = settingsRepo.current.defaultSaveFolder;
    if (Platform.isAndroid) {
      final isAbsolute = folder.startsWith('/');
      final dirPath = isAbsolute ? folder : '/storage/emulated/0/$folder';
      final dir = Directory(dirPath);
      if (!dir.existsSync()) dir.createSync(recursive: true);
      return dir;
    }
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(appDir.path, folder));
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return dir;
  }

  Future<Directory> _resolveTempDir() async {
    final cache = await getTemporaryDirectory();
    final dir = Directory(p.join(cache.path, 'vidsnap_merge'));
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return dir;
  }

  String _sanitizeFileName(String name) {
    return name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').trim();
  }

  Future<void> _safeDelete(String path) async {
    try {
      final f = File(path);
      if (await f.exists()) await f.delete();
    } catch (_) {}
  }

  Future<void> _cleanupTempFiles(String taskId) async {
    try {
      final tempDir = await _resolveTempDir();
      final entities = tempDir.listSync();
      for (final e in entities) {
        if (e is File && p.basename(e.path).contains(taskId)) {
          await e.delete();
        }
      }
    } catch (_) {}
  }

  /// Clears all temporary merge files and partial downloads.
  /// Returns the number of bytes freed.
  Future<int> clearAllTempFiles() async {
    int freed = 0;
    try {
      final tempDir = await _resolveTempDir();
      final entities = tempDir.listSync();
      for (final e in entities) {
        if (e is File) {
          freed += await e.length();
          await e.delete();
        }
      }
    } catch (_) {}

    // Also clear partial files in save dir (.part extension)
    try {
      final saveDir = await _resolveSaveDir();
      final entities = saveDir.listSync();
      for (final e in entities) {
        if (e is File && (e.path.endsWith('.part') || e.path.endsWith('.tmp'))) {
          freed += await e.length();
          await e.delete();
        }
      }
    } catch (_) {}

    return freed;
  }

  /// Returns the current size of temporary files (in bytes).
  Future<int> tempFilesSize() async {
    int total = 0;
    try {
      final tempDir = await _resolveTempDir();
      for (final e in tempDir.listSync()) {
        if (e is File) total += await e.length();
      }
    } catch (_) {}
    try {
      final saveDir = await _resolveSaveDir();
      for (final e in saveDir.listSync()) {
        if (e is File && (e.path.endsWith('.part') || e.path.endsWith('.tmp'))) {
          total += await e.length();
        }
      }
    } catch (_) {}
    return total;
  }

  void dispose() {
    for (final token in _cancelTokens.values) {
      token.cancel('disposed');
    }
    for (final sub in _subscriptions.values) {
      sub.cancel();
    }
    _progressController.close();
  }
}

final downloadServiceProvider = Provider<DownloadService>((ref) {
  final dio = Dio();
  // Disable FFmpegKit statistics logging (keeps logcat clean).
  FFmpegKitConfig.disableLogs();
  final service = DownloadService(
    dio: dio,
    downloadRepo: ref.watch(downloadRepositoryProvider),
    historyRepo: ref.watch(historyRepositoryProvider),
    settingsRepo: ref.watch(settingsRepositoryProvider),
    extractionService: ref.watch(extractionServiceProvider),
  );
  ref.onDispose(service.dispose);
  return service;
});
