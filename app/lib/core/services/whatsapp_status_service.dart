import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:vidsnap/core/constants/app_constants.dart';
import 'package:vidsnap/data/models/whatsapp_status.dart';

/// Scans the device for WhatsApp / WhatsApp Business status files and saves
/// them to the user's gallery via MediaStore.
///
/// On Android 11+, the `.Statuses` directory is outside Scoped Storage, so
/// the app must hold `MANAGE_EXTERNAL_STORAGE` permission. We request it
/// via `manageExternalStorage` permission (Side-loaded APKs only — Play
/// Store apps would need a special exemption).
class WhatsAppStatusService {
  WhatsAppStatusService();

  /// Returns true if the app can read the WhatsApp statuses directory.
  Future<bool> hasPermission() async {
    if (Platform.isAndroid) {
      // For Android 11+ (API 30+), use MANAGE_EXTERNAL_STORAGE
      // For older versions, READ_EXTERNAL_STORAGE is enough.
      if (await Permission.manageExternalStorage.isGranted) return true;
      if (await Permission.storage.isGranted) return true;
      return false;
    }
    return false;
  }

  /// Requests the appropriate storage permission.
  /// Returns true if permission was granted.
  Future<bool> requestPermission() async {
    if (!Platform.isAndroid) return false;

    // Try manageExternalStorage first (needed for Android 11+)
    if (await Permission.manageExternalStorage.request().isGranted) {
      return true;
    }
    // Fall back to storage (works on Android 10 and below)
    if (await Permission.storage.request().isGranted) {
      return true;
    }
    return false;
  }

  /// Opens the system settings page so the user can grant the permission manually.
  Future<void> openAppSettingsPage() async {
    await openAppSettings();
  }

  /// Lists statuses (images + videos) for either WhatsApp or WhatsApp Business.
  Future<List<WhatsAppStatus>> listStatuses({required bool business}) async {
    final dirs = business
        ? AppConstants.whatsappBusinessStatusDirs
        : AppConstants.whatsappStatusDirs;

    final statuses = <WhatsAppStatus>[];
    for (final path in dirs) {
      final dir = Directory(path);
      if (!dir.existsSync()) continue;
      try {
        await for (final entity in dir.list(followLinks: false)) {
          if (entity is! File) continue;
          final ext = p.extension(entity.path).toLowerCase();
          final kind = _kindFromExtension(ext);
          if (kind == null) continue;
          final stat = await entity.stat();
          statuses.add(WhatsAppStatus(
            id: entity.path,
            filePath: entity.path,
            kind: kind,
            sizeBytes: stat.size,
            modifiedAt: stat.modified,
          ));
        }
      } catch (_) {
        // Permission denied for this path — try the next
      }
    }
    // Newest first
    statuses.sort((a, b) => b.modifiedAt.compareTo(a.modifiedAt));
    return statuses;
  }

  WhatsAppStatusKind? _kindFromExtension(String ext) {
    switch (ext) {
      case '.jpg':
      case '.jpeg':
      case '.png':
      case '.webp':
        return WhatsAppStatusKind.image;
      case '.mp4':
      case '.mkv':
      case '.3gp':
      case '.mov':
        return WhatsAppStatusKind.video;
      default:
        return null;
    }
  }

  /// Saves a status to the user's gallery via MediaStore.
  /// Returns the asset path on success.
  Future<String?> saveToGallery(WhatsAppStatus status) async {
    try {
      final file = File(status.filePath);

      if (status.isVideo) {
        // Use saveVideo for videos — requires a File, not bytes.
        final result = await PhotoManager.editor.saveVideo(
          file,
          title: 'vidsnap_${DateTime.now().millisecondsSinceEpoch}',
        );
        return result?.id;
      }

      // Use saveImage for images — requires bytes.
      final bytes = await file.readAsBytes();
      final result = await PhotoManager.editor.saveImage(
        bytes,
        filename: 'vidsnap_${DateTime.now().millisecondsSinceEpoch}_${status.fileName}',
        title: 'vidsnap_${DateTime.now().millisecondsSinceEpoch}',
      );
      return result?.id;
    } catch (_) {
      return null;
    }
  }
}

final whatsappStatusServiceProvider = Provider<WhatsAppStatusService>((ref) {
  return WhatsAppStatusService();
});
