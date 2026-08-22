import 'dart:ui' show PlatformDispatcher;

/// Resolves the user's language preference into a concrete locale code.
///
/// Returns 'ar' or 'en'. Used by `app.dart` to pick the active Locale and
/// text direction. The resolution rules are:
///
///   1. If `settings.language == 'system'`, inspect the device locale.
///      - Arabic device → 'ar'
///      - Anything else → 'en' (the app's fallback)
///   2. If the user explicitly picked 'ar' or 'en', use that value as-is,
///      ignoring the device locale.
String resolveEffectiveLanguage(String settingsLanguage) {
  if (settingsLanguage == 'ar' || settingsLanguage == 'en') {
    return settingsLanguage;
  }
  // 'system' (or any unknown value) → follow device locale.
  return _deviceLanguage();
}

String _deviceLanguage() {
  try {
    final locale = PlatformDispatcher.instance.locale;
    final code = locale.languageCode.toLowerCase();
    if (code == 'ar') return 'ar';
  } catch (_) {}
  // Fallback for unsupported / undetermined device locales.
  return 'en';
}
