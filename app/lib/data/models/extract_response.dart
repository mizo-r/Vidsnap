/// Response model from the extraction server's `POST /extract`.
class ExtractResponse {
  const ExtractResponse({
    required this.sourceId,
    required this.sourceLabel,
    required this.originalUrl,
    required this.title,
    required this.thumbnail,
    required this.durationSeconds,
    required this.uploader,
    required this.formats,
  });

  final String sourceId;
  final String sourceLabel;
  final String originalUrl;
  final String title;
  final String? thumbnail;
  final int? durationSeconds;
  final String? uploader;
  final List<FormatOption> formats;

  factory ExtractResponse.fromJson(Map<String, dynamic> json) => ExtractResponse(
        sourceId: json['sourceId'] as String,
        sourceLabel: json['sourceLabel'] as String,
        originalUrl: json['originalUrl'] as String,
        title: json['title'] as String,
        thumbnail: json['thumbnail'] as String?,
        durationSeconds: json['durationSeconds'] as int?,
        uploader: json['uploader'] as String?,
        formats: (json['formats'] as List)
            .map((e) => FormatOption.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class FormatOption {
  const FormatOption({
    required this.formatId,
    required this.label,
    required this.kind,
    required this.extension,
    required this.fileSizeBytes,
    required this.downloadUrl,
    this.recommended = false,
  });

  final String formatId;
  final String label;
  final FormatKind kind;
  final String extension;
  final int? fileSizeBytes;
  final String downloadUrl;
  final bool recommended;

  factory FormatOption.fromJson(Map<String, dynamic> json) => FormatOption(
        formatId: json['formatId'] as String,
        label: json['label'] as String,
        kind: parseKind(json['kind'] as String),
        extension: json['extension'] as String,
        fileSizeBytes: json['fileSizeBytes'] as int?,
        downloadUrl: json['downloadUrl'] as String,
        recommended: (json['recommended'] as bool?) ?? false,
      );
}

enum FormatKind { video, audio, muxed }

FormatKind parseKind(String s) {
  switch (s) {
    case 'video':
      return FormatKind.video;
    case 'audio':
      return FormatKind.audio;
    case 'muxed':
      return FormatKind.muxed;
    default:
      return FormatKind.video;
  }
}
