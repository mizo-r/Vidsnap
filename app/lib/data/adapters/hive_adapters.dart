import 'package:hive/hive.dart';
import 'package:vidsnap/data/models/app_settings.dart';
import 'package:vidsnap/data/models/download_task.dart';
import 'package:vidsnap/data/models/history_item.dart';

/// Manually-registered Hive type adapters (no build_runner required).
///
/// NOTE: Versioning — if the model changes, bump the field count and append
/// new fields at the end. Old boxes will return null for missing fields,
/// which the model's defaults handle gracefully.
class DownloadTaskAdapter extends TypeAdapter<DownloadTask> {
  @override
  final int typeId = 1;

  @override
  DownloadTask read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DownloadTask(
      id: fields[0] as String,
      sourceId: fields[1] as String,
      originalUrl: fields[2] as String,
      videoTitle: fields[3] as String,
      customFileName: fields[4] as String,
      formatId: fields[5] as String,
      quality: fields[6] as String,
      extension: fields[7] as String,
      status: DownloadStatus.values[fields[8] as int],
      progressPercent: fields[9] as int,
      downloadedBytes: fields[10] as int,
      totalBytes: fields[11] as int?,
      filePath: fields[12] as String?,
      createdAt: fields[13] as DateTime,
      retryCount: fields[14] as int,
      downloadUrl: fields[15] as String?,
      videoUrl: fields[16] as String?,
      audioUrl: fields[17] as String?,
      requiresMerge: (fields[18] as bool?) ?? false,
      thumbnailUrl: fields[19] as String?,
      errorMessage: fields[20] as String?,
      mergePhase: (fields[21] as bool?) ?? false,
      videoDownloadedBytes: (fields[22] as int?) ?? 0,
      audioDownloadedBytes: (fields[23] as int?) ?? 0,
      videoTotalBytes: fields[24] as int?,
      audioTotalBytes: fields[25] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, DownloadTask obj) {
    writer
      ..writeByte(26)
      ..writeByte(0)..write(obj.id)
      ..writeByte(1)..write(obj.sourceId)
      ..writeByte(2)..write(obj.originalUrl)
      ..writeByte(3)..write(obj.videoTitle)
      ..writeByte(4)..write(obj.customFileName)
      ..writeByte(5)..write(obj.formatId)
      ..writeByte(6)..write(obj.quality)
      ..writeByte(7)..write(obj.extension)
      ..writeByte(8)..write(obj.status.index)
      ..writeByte(9)..write(obj.progressPercent)
      ..writeByte(10)..write(obj.downloadedBytes)
      ..writeByte(11)..write(obj.totalBytes)
      ..writeByte(12)..write(obj.filePath)
      ..writeByte(13)..write(obj.createdAt)
      ..writeByte(14)..write(obj.retryCount)
      ..writeByte(15)..write(obj.downloadUrl)
      ..writeByte(16)..write(obj.videoUrl)
      ..writeByte(17)..write(obj.audioUrl)
      ..writeByte(18)..write(obj.requiresMerge)
      ..writeByte(19)..write(obj.thumbnailUrl)
      ..writeByte(20)..write(obj.errorMessage)
      ..writeByte(21)..write(obj.mergePhase)
      ..writeByte(22)..write(obj.videoDownloadedBytes)
      ..writeByte(23)..write(obj.audioDownloadedBytes)
      ..writeByte(24)..write(obj.videoTotalBytes)
      ..writeByte(25)..write(obj.audioTotalBytes);
  }
}

class HistoryItemAdapter extends TypeAdapter<HistoryItem> {
  @override
  final int typeId = 3;

  @override
  HistoryItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HistoryItem(
      id: fields[0] as String,
      fileName: fields[1] as String,
      sourceId: fields[2] as String,
      quality: fields[3] as String,
      downloadedAt: fields[4] as DateTime,
      filePath: fields[5] as String,
      fileSizeBytes: fields[6] as int,
      thumbnailUrl: fields[7] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, HistoryItem obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)..write(obj.id)
      ..writeByte(1)..write(obj.fileName)
      ..writeByte(2)..write(obj.sourceId)
      ..writeByte(3)..write(obj.quality)
      ..writeByte(4)..write(obj.downloadedAt)
      ..writeByte(5)..write(obj.filePath)
      ..writeByte(6)..write(obj.fileSizeBytes)
      ..writeByte(7)..write(obj.thumbnailUrl);
  }
}

class AppSettingsAdapter extends TypeAdapter<AppSettings> {
  @override
  final int typeId = 4;

  @override
  AppSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    // Backward compatibility: pre-1.1.0 versions saved 'ar' or 'en'
    // directly. New versions save 'system' as the default.
    // Existing users keep their explicit choice — that's the desired behavior
    // (if they previously picked a language, we honor it).
    final savedLanguage = fields[0] as String? ?? 'system';
    return AppSettings(
      language: savedLanguage,
      themeMode: fields[1] as String? ?? 'dark',
      defaultSaveFolder: fields[2] as String? ?? 'Vidsnap/download',
      clipboardMonitoringEnabled: fields[3] as bool? ?? true,
      maxConcurrentDownloads: fields[4] as int? ?? 2,
      notificationsEnabled: fields[5] as bool? ?? true,
      serverUrl: fields[6] as String? ?? 'https://vidsnap-server.example.com',
    );
  }

  @override
  void write(BinaryWriter writer, AppSettings obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)..write(obj.language)
      ..writeByte(1)..write(obj.themeMode)
      ..writeByte(2)..write(obj.defaultSaveFolder)
      ..writeByte(3)..write(obj.clipboardMonitoringEnabled)
      ..writeByte(4)..write(obj.maxConcurrentDownloads)
      ..writeByte(5)..write(obj.notificationsEnabled)
      ..writeByte(6)..write(obj.serverUrl);
  }
}
