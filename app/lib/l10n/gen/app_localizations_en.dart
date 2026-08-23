// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'VidSnap';

  @override
  String get navHome => 'Home';

  @override
  String get navDownloads => 'Downloads';

  @override
  String get navHistory => 'History';

  @override
  String get navSettings => 'Settings';

  @override
  String get navWhatsApp => 'Statuses';

  @override
  String get homePasteLink => 'Paste link';

  @override
  String get homePasteHint => 'Paste a video URL here';

  @override
  String get homeExtracting => 'Extracting video info…';

  @override
  String get homeExtractError =>
      'Could not extract video. Check the URL or your server.';

  @override
  String get homeUnsupportedSource => 'This source is not supported yet.';

  @override
  String get homeRecentDownloads => 'Recent downloads';

  @override
  String get homeNoDownloads => 'No downloads yet. Paste a link to start.';

  @override
  String get homeWelcomeTitle => 'Download any video, fast';

  @override
  String get homeWelcomeSubtitle =>
      'Paste a link, pick a quality, and you\'re done.';

  @override
  String get homeClipboardDetected => 'Link detected in clipboard';

  @override
  String get homeOpenClipboard => 'Open';

  @override
  String get homeQuickActions => 'Quick actions';

  @override
  String get homeQuickActionWhatsApp => 'WhatsApp Statuses';

  @override
  String get homeQuickActionDownloads => 'Active downloads';

  @override
  String get homeQuickActionHistory => 'History';

  @override
  String get downloaderTitle => 'Download options';

  @override
  String get downloaderFileName => 'File name';

  @override
  String get downloaderQuality => 'Quality';

  @override
  String get downloaderRecommended => 'Recommended';

  @override
  String get downloaderFileSize => 'Size';

  @override
  String get downloaderDownload => 'Download';

  @override
  String get downloaderCancel => 'Cancel';

  @override
  String get downloaderLoading => 'Loading formats…';

  @override
  String get downloaderNoFormats => 'No downloadable formats found.';

  @override
  String get downloaderVideoTab => 'Video';

  @override
  String get downloaderAudioTab => 'Audio';

  @override
  String get downloaderSaveFolder => 'Save to';

  @override
  String get downloaderEstimatedSize => 'Estimated size';

  @override
  String get downloaderAudioSection => 'Audio only';

  @override
  String get downloaderVideoSection => 'Video';

  @override
  String get downloaderMergeRequired => 'Merge';

  @override
  String get downloadsActive => 'Active';

  @override
  String get downloadsCompleted => 'Completed';

  @override
  String get downloadsFailed => 'Failed';

  @override
  String get downloadsEmpty => 'Nothing here yet.';

  @override
  String get downloadsPause => 'Pause';

  @override
  String get downloadsResume => 'Resume';

  @override
  String get downloadsRetry => 'Retry';

  @override
  String get downloadsCancel => 'Cancel';

  @override
  String get downloadsDelete => 'Delete';

  @override
  String get downloadsOpen => 'Open';

  @override
  String get downloadsShare => 'Share';

  @override
  String get downloadsMerging => 'Merging video + audio…';

  @override
  String get downloadsClearCompleted => 'Clear completed';

  @override
  String get historyTitle => 'History';

  @override
  String get historyEmpty => 'No history yet.';

  @override
  String get historyClearAll => 'Clear all history';

  @override
  String get historyClearConfirm =>
      'Clear all history? This won\'t delete the files.';

  @override
  String get historyDeleteFile => 'Delete file';

  @override
  String get historyDeleteFileConfirm => 'Delete the file from your device?';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsGeneral => 'General';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageSystem => 'System default';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeSystem => 'System';

  @override
  String get settingsSaveFolder => 'Default save folder';

  @override
  String get settingsSaveFolderReset => 'Reset to default path';

  @override
  String get settingsDownloads => 'Downloads';

  @override
  String get settingsMaxConcurrent => 'Max concurrent downloads';

  @override
  String get settingsClipboardMonitoring => 'Clipboard monitoring';

  @override
  String get settingsClipboardMonitoringDesc =>
      'Detect supported links in your clipboard';

  @override
  String get settingsNotifications => 'Notifications';

  @override
  String get settingsNotificationsDesc => 'Show download progress & completion';

  @override
  String get settingsServer => 'Extraction server';

  @override
  String get settingsServerUrl => 'Server URL';

  @override
  String get settingsServerUrlHint => 'https://your-server.example.com';

  @override
  String get settingsServerTest => 'Test connection';

  @override
  String get settingsServerTesting => 'Testing…';

  @override
  String get settingsServerOk => 'Server is reachable.';

  @override
  String get settingsServerFail => 'Could not reach the server.';

  @override
  String get settingsAbout => 'About';

  @override
  String get settingsVersion => 'Version';

  @override
  String get settingsClearData => 'Clear all app data';

  @override
  String get settingsClearDataConfirm =>
      'Clear all local data? Downloads will not be deleted.';

  @override
  String get settingsStorage => 'Storage';

  @override
  String get settingsClearCache => 'Clear cache';

  @override
  String get settingsClearCacheConfirm =>
      'Delete all temporary merge files and partial downloads?';

  @override
  String get settingsCacheSize => 'Current cache size';

  @override
  String settingsCacheCleared(String size) {
    return 'Cache cleared — $size freed';
  }

  @override
  String get whatsappTitle => 'WhatsApp Statuses';

  @override
  String get whatsappTabImages => 'Images';

  @override
  String get whatsappTabVideos => 'Videos';

  @override
  String get whatsappTabSaved => 'Saved';

  @override
  String get whatsappBusinessToggle => 'WhatsApp Business';

  @override
  String get whatsappNoStatuses =>
      'No statuses found.\nOpen WhatsApp and view some statuses first.';

  @override
  String get whatsappPermissionNeeded => 'Storage permission required';

  @override
  String get whatsappPermissionDesc =>
      'VidSnap needs access to all files to read WhatsApp statuses. Tap below to grant.';

  @override
  String get whatsappGrantPermission => 'Grant permission';

  @override
  String get whatsappOpenSettings => 'Open settings';

  @override
  String get whatsappRefresh => 'Refresh';

  @override
  String get whatsappSave => 'Save';

  @override
  String get whatsappSavedToast => 'Saved to gallery';

  @override
  String get whatsappSaveFailed => 'Failed to save status';

  @override
  String get whatsappViewOriginal => 'View original';

  @override
  String get whatsappStatusRefreshed => 'Statuses refreshed';

  @override
  String get whatsappReShare => 'Re-share';

  @override
  String get notificationsDownloading => 'Downloading';

  @override
  String get notificationsDownloadComplete => 'Download complete';

  @override
  String get notificationsDownloadFailed => 'Download failed';

  @override
  String get notificationsOpen => 'Open';

  @override
  String get notificationsShare => 'Share';

  @override
  String get notificationsRetry => 'Retry';

  @override
  String get notificationsClipboardTitle => 'Link detected';

  @override
  String get notificationsClipboardBody => 'Tap to open in VidSnap';

  @override
  String get commonSave => 'Save';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonConfirm => 'Confirm';

  @override
  String get commonClose => 'Close';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonOpen => 'Open';

  @override
  String get commonShare => 'Share';

  @override
  String get commonError => 'Something went wrong';

  @override
  String get commonLoading => 'Loading…';

  @override
  String get commonEmpty => 'Nothing to show';

  @override
  String get commonNoInternet => 'No internet connection';

  @override
  String get commonPermissionDenied => 'Permission denied';

  @override
  String get commonBytes => 'B';

  @override
  String get commonKiloBytes => 'KB';

  @override
  String get commonMegaBytes => 'MB';

  @override
  String get commonGigaBytes => 'GB';
}
