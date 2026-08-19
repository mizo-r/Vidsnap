/// WhatsApp status item (image or video) discovered on the device.
class WhatsAppStatus {
  WhatsAppStatus({
    required this.id,
    required this.filePath,
    required this.kind,
    required this.sizeBytes,
    required this.modifiedAt,
  });

  final String id;
  final String filePath;
  final WhatsAppStatusKind kind;
  final int sizeBytes;
  final DateTime modifiedAt;

  String get fileName => filePath.split('/').last;

  bool get isVideo => kind == WhatsAppStatusKind.video;
}

enum WhatsAppStatusKind { image, video }
