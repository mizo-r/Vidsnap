/// App-wide constants.
class AppConstants {
  AppConstants._();

  static const String appName = 'VidSnap';
  static const String appVersion = '1.0.0';

  /// Hive box names
  static const String boxDownloads = 'download_tasks';
  static const String boxHistory = 'history';
  static const String boxSettings = 'settings';

  /// Notification channel
  static const String notifChannelId = 'vidsnap_downloads';
  static const String notifChannelName = 'Downloads';
  static const String notifChannelDesc = 'Download progress & completion notifications.';

  /// Clipboard monitor interval
  static const Duration clipboardPollInterval = Duration(seconds: 3);

  /// Default settings
  static const String defaultLanguage = 'en';
  static const String defaultTheme = 'dark';
  static const int defaultMaxConcurrentDownloads = 2;
  static const bool defaultClipboardMonitoring = true;
  static const bool defaultNotificationsEnabled = true;
  /// Default save folder (relative to external storage root on Android).
  /// Saves to: /storage/emulated/0/Vidsnap/download
  static const String defaultSaveFolder = 'Vidsnap/download';

  /// WhatsApp status directories (multiple fallbacks for different Android versions)
  static const List<String> whatsappStatusDirs = [
    '/storage/emulated/0/Android/media/com.whatsapp/WhatsApp/Media/.Statuses',
    '/storage/emulated/0/WhatsApp/Media/.Statuses',
    '/storage/emulated/0/Android/data/com.whatsapp/files/Media/.Statuses',
  ];

  static const List<String> whatsappBusinessStatusDirs = [
    '/storage/emulated/0/Android/media/com.whatsapp.w4b/WhatsApp Business/Media/.Statuses',
    '/storage/emulated/0/WhatsApp Business/Media/.Statuses',
    '/storage/emulated/0/Android/data/com.whatsapp.w4b/files/Media/.Statuses',
  ];
}
