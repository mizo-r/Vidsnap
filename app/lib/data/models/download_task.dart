/// A download task — the central entity of the app.
///
/// Supports two modes:
///   1. Direct download: `downloadUrl` is set, file is downloaded as-is.
///   2. Merge download: `videoUrl` + `audioUrl` are set, both are downloaded
///      in parallel, then merged via FFmpeg into a single output file.
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
    this.videoUrl,
    this.audioUrl,
    this.requiresMerge = false,
    this.thumbnailUrl,
    this.errorMessage,
    this.mergePhase = false,
    this.videoDownloadedBytes = 0,
    this.audioDownloadedBytes = 0,
    this.videoTotalBytes,
    this.audioTotalBytes,
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

  /// Direct download URL (used when requiresMerge = false).
  String? downloadUrl;

  /// Video-only URL (used when requiresMerge = true).
  String? videoUrl;

  /// Audio-only URL (used when requiresMerge = true).
  String? audioUrl;

  /// True if the client must download video + audio separately and merge.
  final bool requiresMerge;

  String? thumbnailUrl;
  String? errorMessage;

  /// True while FFmpeg is merging the two streams.
  bool mergePhase;

  // Parallel download tracking
  int videoDownloadedBytes;
  int audioDownloadedBytes;
  int? videoTotalBytes;
  int? audioTotalBytes;

  bool get isCompleted => status == DownloadStatus.completed;
  bool get isFailed => status == DownloadStatus.failed;
  bool get isActive => status == DownloadStatus.queued || status == DownloadStatus.downloading;
  bool get canPause => status == DownloadStatus.downloading && !mergePhase;
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
    bool? mergePhase,
    int? videoDownloadedBytes,
    int? audioDownloadedBytes,
    int? videoTotalBytes,
    int? audioTotalBytes,
    String? downloadUrl,
    String? videoUrl,
    String? audioUrl,
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
        downloadUrl: downloadUrl ?? this.downloadUrl,
        videoUrl: videoUrl ?? this.videoUrl,
        audioUrl: audioUrl ?? this.audioUrl,
        requiresMerge: requiresMerge,
        thumbnailUrl: thumbnailUrl,
        errorMessage: errorMessage ?? this.errorMessage,
        mergePhase: mergePhase ?? this.mergePhase,
        videoDownloadedBytes: videoDownloadedBytes ?? this.videoDownloadedBytes,
        audioDownloadedBytes: audioDownloadedBytes ?? this.audioDownloadedBytes,
        videoTotalBytes: videoTotalBytes ?? this.videoTotalBytes,
        audioTotalBytes: audioTotalBytes ?? this.audioTotalBytes,
      );
}

enum DownloadStatus { queued, downloading, paused, completed, failed }
