import 'package:flutter/material.dart';
import 'package:vidsnap/l10n/gen/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vidsnap/core/constants/colors.dart';
import 'package:vidsnap/core/services/clipboard_monitor_service.dart';
import 'package:vidsnap/core/services/notification_service.dart';
import 'package:vidsnap/data/models/app_settings.dart';
import 'package:vidsnap/data/repositories/settings_repository.dart';
import 'package:vidsnap/router.dart';

/// Riverpod provider that exposes the current settings as a stream so the
/// UI updates instantly when settings change.
final settingsStreamProvider = StreamProvider<AppSettings>((ref) {
  final repo = ref.watch(settingsRepositoryProvider);
  return repo.watch().map((_) => repo.current);
});

final currentSettingsProvider = Provider<AppSettings>((ref) {
  final asyncValue = ref.watch(settingsStreamProvider);
  return asyncValue.when(
    data: (s) => s,
    loading: () => ref.read(settingsRepositoryProvider).current,
    error: (_, __) => ref.read(settingsRepositoryProvider).current,
  );
});

class VidSnapApp extends ConsumerStatefulWidget {
  const VidSnapApp({super.key});

  @override
  ConsumerState<VidSnapApp> createState() => _VidSnapAppState();
}

class _VidSnapAppState extends ConsumerState<VidSnapApp> {
  late final ClipboardMonitorService _clipboard;

  @override
  void initState() {
    super.initState();
    _clipboard = ref.read(clipboardMonitorProvider);
    _clipboard.detectedUrls.listen((url) {
      ref.read(notificationServiceProvider).showClipboardDetected(url: url);
    });
    // Defer starting the clipboard monitor until after the first frame
    // so we have access to the latest settings.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settings = ref.read(currentSettingsProvider);
      if (settings.clipboardMonitoringEnabled) {
        _clipboard.start();
      }
    });
  }

  @override
  void dispose() {
    _clipboard.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(currentSettingsProvider);
    final themeMode = _parseThemeMode(settings.themeMode);
    final locale = Locale(settings.language);

    return MaterialApp.router(
      title: 'VidSnap',
      debugShowCheckedModeBanner: false,
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: themeMode,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: buildRouter(),
      builder: (context, child) {
        // Update clipboard monitor when settings change.
        final s = ref.watch(currentSettingsProvider);
        if (s.clipboardMonitoringEnabled) {
          _clipboard.start();
        } else {
          _clipboard.stop();
        }
        return child!;
      },
    );
  }

  ThemeMode _parseThemeMode(String mode) {
    switch (mode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }
}
