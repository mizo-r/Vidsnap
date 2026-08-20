import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:vidsnap/data/models/app_settings.dart';
import 'package:vidsnap/data/repositories/storage_service.dart';

/// Single-record settings repository. The settings are stored under
/// the key `app` in the settings box.
///
/// On first launch (no record yet), the language is auto-detected from the
/// device locale via [PlatformDispatcher]. Subsequent launches honor the
/// user's saved choice.
class SettingsRepository {
  SettingsRepository(this._box);

  final Box<AppSettings> _box;

  static const String _key = 'app';

  AppSettings get current {
    final s = _box.get(_key);
    if (s == null) {
      // First launch — auto-detect language from device locale.
      final defaults = AppSettings(
        language: _detectDeviceLanguage(),
      );
      _box.put(_key, defaults);
      return defaults;
    }
    return s;
  }

  /// Returns 'ar' if the device locale is Arabic, else 'en'.
  String _detectDeviceLanguage() {
    try {
      final locale = PlatformDispatcher.instance.locale;
      final code = locale.languageCode.toLowerCase();
      if (code == 'ar') return 'ar';
    } catch (_) {}
    return 'en';
  }

  Future<void> update(AppSettings Function(AppSettings) mutator) async {
    final updated = mutator(current);
    await _box.put(_key, updated);
  }

  Future<void> replace(AppSettings settings) => _box.put(_key, settings);

  Future<void> reset() async {
    await _box.put(_key, AppSettings(
      language: _detectDeviceLanguage(),
    ));
  }

  Stream<BoxEvent> watch() => _box.watch();
}

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  final box = ref.watch(settingsBoxProvider);
  return SettingsRepository(box);
});
