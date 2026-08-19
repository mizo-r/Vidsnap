/// A download task — the central entity of the app.
///
/// Stored locally in Hive via `DownloadTaskAdapter`. No `@HiveType` annotations
/// are used to avoid requiring build_runner on CI.
class DownloadTask {
  DownloadTask({
    required this.id,
    required this.sourceId,
    required this.originalUrl,
    required this.videoTitle,
    required this.customFileName,
    required this.formatId,
    required this.quality,
    required this.extension,
    required this.status,
    required this.progressPercent,
    required this.downloadedBytes,
    this.totalBytes,
    this.filePath,
    required this.createdAt,
    required this.retryCount,
    this.downloadUrl,
    this.thumbnailUrl,
    this.errorMessage,
  });

  final String id;
  final String sourceId;
  final String originalUrl;
  final String videoTitle;
  String customFileName;
  final String formatId;
  final String quality;
  final String extension;
  DownloadStatus status;
  int progressPercent;
  int downloadedBytes;
  int? totalBytes;
  String? filePath;
  final DateTime createdAt;
  int retryCount;
  String? downloadUrl;
  String? thumbnailUrl;
  String? errorMessage;

  bool get isCompleted => status == DownloadStatus.completed;
  bool get isFailed => status == DownloadStatus.failed;
  bool get isActive => status == DownloadStatus.queued || status == DownloadStatus.downloading;
  bool get canPause => status == DownloadStatus.downloading;
  bool get canResume => status == DownloadStatus.paused;
  bool get canRetry => status == DownloadStatus.failed;

  DownloadTask copyWith({
    DownloadStatus? status,
    int? progressPercent,
    int? downloadedBytes,
    int? totalBytes,
    String? filePath,
    int? retryCount,
    String? errorMessage,
  }) =>
      DownloadTask(
        id: id,
        sourceId: sourceId,
        originalUrl: originalUrl,
        videoTitle: videoTitle,
        customFileName: customFileName,
        formatId: formatId,
        quality: quality,
        extension: extension,
        status: status ?? this.status,
        progressPercent: progressPercent ?? this.progressPercent,
        downloadedBytes: downloadedBytes ?? this.downloadedBytes,
        totalBytes: totalBytes ?? this.totalBytes,
        filePath: filePath ?? this.filePath,
        createdAt: createdAt,
        retryCount: retryCount ?? this.retryCount,
        downloadUrl: downloadUrl,
        thumbnailUrl: thumbnailUrl,
        errorMessage: errorMessage ?? this.errorMessage,
      );
}

enum DownloadStatus { queued, downloading, paused, completed, failed }
