/// A history record — created when a download completes.
class HistoryItem {
  HistoryItem({
    required this.id,
    required this.fileName,
    required this.sourceId,
    required this.quality,
    required this.downloadedAt,
    required this.filePath,
    required this.fileSizeBytes,
    this.thumbnailUrl,
  });

  final String id;
  final String fileName;
  final String sourceId;
  final String quality;
  final DateTime downloadedAt;
  final String filePath;
  final int fileSizeBytes;
  final String? thumbnailUrl;
}
