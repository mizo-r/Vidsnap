import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vidsnap/data/models/app_settings.dart';
import 'package:vidsnap/data/repositories/storage_service.dart';

/// Single-record settings repository. The settings are stored under
/// the key `app` in the settings box.
class SettingsRepository {
  SettingsRepository(this._box);

  final Box<AppSettings> _box;

  static const String _key = 'app';

  AppSettings get current {
    final s = _box.get(_key);
    if (s == null) {
      final defaults = AppSettings();
      _box.put(_key, defaults);
      return defaults;
    }
    return s;
  }

  Future<void> update(AppSettings Function(AppSettings) mutator) async {
    final updated = mutator(current);
    await _box.put(_key, updated);
  }

  Future<void> replace(AppSettings settings) => _box.put(_key, settings);

  Future<void> reset() async {
    await _box.put(_key, AppSettings());
  }

  Stream<BoxEvent> watch() => _box.watch();
}

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  final box = ref.watch(settingsBoxProvider);
  return SettingsRepository(box);
});
