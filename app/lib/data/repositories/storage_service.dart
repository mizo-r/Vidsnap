import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:vidsnap/core/constants/app_constants.dart';
import 'package:vidsnap/data/adapters/hive_adapters.dart';
import 'package:vidsnap/data/models/app_settings.dart';
import 'package:vidsnap/data/models/download_task.dart';
import 'package:vidsnap/data/models/history_item.dart';

/// Initializes Hive, registers adapters, and opens all required boxes.
/// Call once at app startup (in `main()`).
Future<void> initStorage() async {
  await Hive.initFlutter();

  // Register adapters (idempotent — Hive throws if a typeId is already registered)
  if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(DownloadTaskAdapter());
  if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(HistoryItemAdapter());
  if (!Hive.isAdapterRegistered(4)) Hive.registerAdapter(AppSettingsAdapter());

  await Hive.openBox<DownloadTask>(AppConstants.boxDownloads);
  await Hive.openBox<HistoryItem>(AppConstants.boxHistory);
  await Hive.openBox<AppSettings>(AppConstants.boxSettings);
}

/// Convenience providers for the three boxes.
final downloadsBoxProvider = Provider<Box<DownloadTask>>((ref) {
  final box = Hive.box<DownloadTask>(AppConstants.boxDownloads);
  ref.onDispose(() {});
  return box;
});

final historyBoxProvider = Provider<Box<HistoryItem>>((ref) {
  return Hive.box<HistoryItem>(AppConstants.boxHistory);
});

final settingsBoxProvider = Provider<Box<AppSettings>>((ref) {
  return Hive.box<AppSettings>(AppConstants.boxSettings);
});
