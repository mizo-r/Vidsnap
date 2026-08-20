/// User-configurable settings — single record stored in Hive.
class AppSettings {
  AppSettings({
    this.language = 'en',
    this.themeMode = 'dark',
    this.defaultSaveFolder = 'Vidsnap/download',
    this.clipboardMonitoringEnabled = true,
    this.maxConcurrentDownloads = 2,
    this.notificationsEnabled = true,
    this.serverUrl = 'https://vidsnap-server.example.com',
  });

  String language;
  String themeMode;
  String defaultSaveFolder;
  bool clipboardMonitoringEnabled;
  int maxConcurrentDownloads;
  bool notificationsEnabled;
  String serverUrl;

  AppSettings copyWith({
    String? language,
    String? themeMode,
    String? defaultSaveFolder,
    bool? clipboardMonitoringEnabled,
    int? maxConcurrentDownloads,
    bool? notificationsEnabled,
    String? serverUrl,
  }) =>
      AppSettings(
        language: language ?? this.language,
        themeMode: themeMode ?? this.themeMode,
        defaultSaveFolder: defaultSaveFolder ?? this.defaultSaveFolder,
        clipboardMonitoringEnabled: clipboardMonitoringEnabled ?? this.clipboardMonitoringEnabled,
        maxConcurrentDownloads: maxConcurrentDownloads ?? this.maxConcurrentDownloads,
        notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
        serverUrl: serverUrl ?? this.serverUrl,
      );
}
