import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:vidsnap/data/models/app_settings.dart';
import 'package:vidsnap/data/repositories/storage_service.dart';

/// Single-record settings repository. The settings are stored under
/// the key `app` in the settings box.
///
/// On first launch, [AppSettings.language] defaults to 'system', which
/// means "follow the device locale". The actual locale resolution happens
/// in `app.dart` via [resolveEffectiveLocale].
///
/// On subsequent launches, the user's explicit choice is honored:
///   - 'system' → follow device locale
///   - 'ar' / 'en' → use that locale regardless of device
class SettingsRepository {
  SettingsRepository(this._box);

  final Box<AppSettings> _box;

  static const String _key = 'app';

  AppSettings get current {
    final s = _box.get(_key);
    if (s == null) {
      // First launch — default to 'system' (follow device locale).
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
