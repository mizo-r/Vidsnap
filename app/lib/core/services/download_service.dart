import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
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
      thumbnailUrl: thumbnailUrl,
    );
    await downloadRepo.add(task);
    _tryStartNext();
    return task;
  }

  Future<void> pause(String id) async {
    final task = downloadRepo.getById(id);
    if (task == null || !task.isActive) return;
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
      ..errorMessage = null
      ..retryCount = task.retryCount + 1;
    await downloadRepo.update(task);
    _tryStartNext();
  }

  Future<void> cancel(String id) async {
    _cancelTokens[id]?.cancel('cancelled');
    _cancelTokens.remove(id);
    _subscriptions[id]?.cancel();
    _subscriptions.remove(id);
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
    if (task.downloadUrl == null) {
      task
        ..status = DownloadStatus.failed
        ..errorMessage = 'Missing download URL';
      await downloadRepo.update(task);
      return;
    }

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

      // If server doesn't honor Range, restart from 0.
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
        (chunk) async {
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

      // Add to history
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
        // Detect expired URL (403 Forbidden from CDN usually means the
        // signed download URL has expired). Try to refresh it once.
        final isExpiredUrl = e is DioException &&
            (e.response?.statusCode == 403 ||
                e.response?.statusCode == 410 ||
                e.message?.contains('Forbidden') == true);

        if (isExpiredUrl && task.retryCount < 2) {
          // Re-extract a fresh download URL from the server, then restart.
          try {
            final fresh = await extractionService.extract(
              serverUrl: settingsRepo.current.serverUrl,
              videoUrl: task.originalUrl,
            );
            // Find a matching format (same formatId).
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
              ..errorMessage = null;
            await downloadRepo.update(task);
            _progressController.add(task);
            _tryStartNext();
            return;
          } catch (_) {
            // Re-extraction failed — fall through to mark as failed below.
          }
        }
        task
          ..status = DownloadStatus.failed
          ..errorMessage = e.toString();
        await downloadRepo.update(task);
        _progressController.add(task);
      }
    } finally {
      _cancelTokens.remove(task.id);
      _subscriptions.remove(task.id);
      _tryStartNext();
    }
  }

  Future<Directory> _resolveSaveDir() async {
    final folder = settingsRepo.current.defaultSaveFolder;
    if (Platform.isAndroid) {
      final external = await getExternalStorageDirectory();
      if (external != null) {
        // On Android 11+ with Scoped Storage, apps can only write to their own
        // package-specific external dir. Files saved here appear under
        // /Android/data/<package>/files/<folder> — visible to file managers.
        final dir = Directory(p.join(external.path, folder));
        if (!dir.existsSync()) dir.createSync(recursive: true);
        return dir;
      }
    }
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(appDir.path, folder));
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return dir;
  }

  String _sanitizeFileName(String name) {
    return name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').trim();
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
