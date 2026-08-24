import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vidsnap/data/models/app_settings.dart';
import 'package:vidsnap/data/repositories/settings_repository.dart';

/// Centralized settings state manager.
///
/// This notifier is the SINGLE source of truth for app settings.
/// It reads the current value from Hive on startup, listens to box
/// changes, and exposes `update()` which:
///   1. Persists to Hive
///   2. Immediately updates `state` so all watching widgets rebuild
///      with the new value.
final settingsProvider =
    NotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);

/// A signal that fires when the app should restart (e.g. language change).
/// The root widget listens to this and re-triggers the splash → home flow.
final restartSignalProvider = StreamProvider<void>((ref) {
  // The actual stream is created lazily and held by SettingsNotifier.
  // This provider just exposes it so the root widget can listen.
  return ref.read(settingsProvider.notifier).restartStream;
});

class SettingsNotifier extends Notifier<AppSettings> {
  late final SettingsRepository _repo;
  StreamSubscription? _sub;
  final _restartController = StreamController<void>.broadcast();

  @override
  AppSettings build() {
    _repo = ref.read(settingsRepositoryProvider);

    _sub = _repo.watch().listen((_) {
      state = _repo.current;
    });

    ref.onDispose(() {
      _sub?.cancel();
    });

    return _repo.current;
  }

  /// Stream that fires when the app should restart (language change).
  Stream<void> get restartStream => _restartController.stream;

  /// Updates settings: persists to Hive AND updates state synchronously.
  Future<void> update(AppSettings Function(AppSettings) mutator) async {
    await _repo.update(mutator);
    state = _repo.current;
  }

  /// Updates the language AND triggers an app restart.
  ///
  /// Language is the only setting that requires a full restart because
  /// changing RTL/LTR direction needs every widget to rebuild from
  /// scratch. Other settings (theme, notifications, etc.) update live.
  Future<void> changeLanguage(String language) async {
    await update((s) => s.copyWith(language: language));
    // Signal the root widget to restart the app flow.
    _restartController.add(null);
  }

  /// Resets settings to defaults.
  Future<void> reset() async {
    await _repo.reset();
    state = _repo.current;
  }

  String get serverUrl => state.serverUrl;
  String get language => state.language;
  String get themeMode => state.themeMode;
  bool get clipboardMonitoringEnabled => state.clipboardMonitoringEnabled;
  bool get notificationsEnabled => state.notificationsEnabled;
  int get maxConcurrentDownloads => state.maxConcurrentDownloads;
  String get defaultSaveFolder => state.defaultSaveFolder;
}
