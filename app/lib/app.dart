import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vidsnap/core/constants/colors.dart';
import 'package:vidsnap/core/providers/settings_provider.dart';
import 'package:vidsnap/core/services/clipboard_monitor_service.dart';
import 'package:vidsnap/core/services/notification_service.dart';
import 'package:vidsnap/core/utils/language_resolver.dart';
import 'package:vidsnap/l10n/gen/app_localizations.dart';
import 'package:vidsnap/router.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settings = ref.read(settingsProvider);
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
    final settings = ref.watch(settingsProvider);
    final themeMode = _parseThemeMode(settings.themeMode);
    final effectiveLanguage = resolveEffectiveLanguage(settings.language);
    final locale = Locale(effectiveLanguage);

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
      routerConfig: buildRouter(showSplash: true),
      builder: (context, child) {
        final s = ref.watch(settingsProvider);
        if (s.clipboardMonitoringEnabled) {
          _clipboard.start();
        } else {
          _clipboard.stop();
        }
        final lang = resolveEffectiveLanguage(s.language);
        return Directionality(
          textDirection: lang == 'ar' ? TextDirection.rtl : TextDirection.ltr,
          child: child ?? const SizedBox.shrink(),
        );
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
