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
///      with the new value — no StreamProvider indirection, no async
///      gap, no stale data.
///
/// Previously, the app used StreamProvider → Provider chain which was
/// fragile: widgets would sometimes show stale data after navigation
/// because the stream didn't re-emit on re-subscription. This notifier
/// solves that by keeping `state` always in sync with Hive.
final settingsProvider =
    NotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);

class SettingsNotifier extends Notifier<AppSettings> {
  late final SettingsRepository _repo;
  StreamSubscription? _sub;

  @override
  AppSettings build() {
    _repo = ref.read(settingsRepositoryProvider);

    // Listen to box changes so external modifications (e.g. reset())
    // are reflected immediately.
    _sub = _repo.watch().listen((_) {
      state = _repo.current;
    });

    ref.onDispose(() {
      _sub?.cancel();
    });

    // Return the current (or default) settings immediately.
    return _repo.current;
  }

  /// Updates settings: persists to Hive AND updates state synchronously.
  Future<void> update(AppSettings Function(AppSettings) mutator) async {
    await _repo.update(mutator);
    // Critical: update state immediately so widgets rebuild with the
    // new value. Without this, the UI would wait for the stream event
    // which can race with widget disposal during navigation.
    state = _repo.current;
  }

  /// Resets settings to defaults.
  Future<void> reset() async {
    await _repo.reset();
    state = _repo.current;
  }

  /// Convenience getters
  String get serverUrl => state.serverUrl;
  String get language => state.language;
  String get themeMode => state.themeMode;
  bool get clipboardMonitoringEnabled => state.clipboardMonitoringEnabled;
  bool get notificationsEnabled => state.notificationsEnabled;
  int get maxConcurrentDownloads => state.maxConcurrentDownloads;
  String get defaultSaveFolder => state.defaultSaveFolder;
}
