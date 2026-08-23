import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ar')
  ];

  /// Application name
  ///
  /// In en, this message translates to:
  /// **'VidSnap'**
  String get appTitle;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navDownloads.
  ///
  /// In en, this message translates to:
  /// **'Downloads'**
  String get navDownloads;

  /// No description provided for @navHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get navHistory;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @navWhatsApp.
  ///
  /// In en, this message translates to:
  /// **'Statuses'**
  String get navWhatsApp;

  /// No description provided for @homePasteLink.
  ///
  /// In en, this message translates to:
  /// **'Paste link'**
  String get homePasteLink;

  /// No description provided for @homePasteHint.
  ///
  /// In en, this message translates to:
  /// **'Paste a video URL here'**
  String get homePasteHint;

  /// No description provided for @homeExtracting.
  ///
  /// In en, this message translates to:
  /// **'Extracting video info…'**
  String get homeExtracting;

  /// No description provided for @homeExtractError.
  ///
  /// In en, this message translates to:
  /// **'Could not extract video. Check the URL or your server.'**
  String get homeExtractError;

  /// No description provided for @homeUnsupportedSource.
  ///
  /// In en, this message translates to:
  /// **'This source is not supported yet.'**
  String get homeUnsupportedSource;

  /// No description provided for @homeRecentDownloads.
  ///
  /// In en, this message translates to:
  /// **'Recent downloads'**
  String get homeRecentDownloads;

  /// No description provided for @homeNoDownloads.
  ///
  /// In en, this message translates to:
  /// **'No downloads yet. Paste a link to start.'**
  String get homeNoDownloads;

  /// No description provided for @homeWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Download any video, fast'**
  String get homeWelcomeTitle;

  /// No description provided for @homeWelcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Paste a link, pick a quality, and you\'re done.'**
  String get homeWelcomeSubtitle;

  /// No description provided for @homeClipboardDetected.
  ///
  /// In en, this message translates to:
  /// **'Link detected in clipboard'**
  String get homeClipboardDetected;

  /// No description provided for @homeOpenClipboard.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get homeOpenClipboard;

  /// No description provided for @homeQuickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick actions'**
  String get homeQuickActions;

  /// No description provided for @homeQuickActionWhatsApp.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp Statuses'**
  String get homeQuickActionWhatsApp;

  /// No description provided for @homeQuickActionDownloads.
  ///
  /// In en, this message translates to:
  /// **'Active downloads'**
  String get homeQuickActionDownloads;

  /// No description provided for @homeQuickActionHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get homeQuickActionHistory;

  /// No description provided for @downloaderTitle.
  ///
  /// In en, this message translates to:
  /// **'Download options'**
  String get downloaderTitle;

  /// No description provided for @downloaderFileName.
  ///
  /// In en, this message translates to:
  /// **'File name'**
  String get downloaderFileName;

  /// No description provided for @downloaderQuality.
  ///
  /// In en, this message translates to:
  /// **'Quality'**
  String get downloaderQuality;

  /// No description provided for @downloaderRecommended.
  ///
  /// In en, this message translates to:
  /// **'Recommended'**
  String get downloaderRecommended;

  /// No description provided for @downloaderFileSize.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get downloaderFileSize;

  /// No description provided for @downloaderDownload.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get downloaderDownload;

  /// No description provided for @downloaderCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get downloaderCancel;

  /// No description provided for @downloaderLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading formats…'**
  String get downloaderLoading;

  /// No description provided for @downloaderNoFormats.
  ///
  /// In en, this message translates to:
  /// **'No downloadable formats found.'**
  String get downloaderNoFormats;

  /// No description provided for @downloaderVideoTab.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get downloaderVideoTab;

  /// No description provided for @downloaderAudioTab.
  ///
  /// In en, this message translates to:
  /// **'Audio'**
  String get downloaderAudioTab;

  /// No description provided for @downloaderSaveFolder.
  ///
  /// In en, this message translates to:
  /// **'Save to'**
  String get downloaderSaveFolder;

  /// No description provided for @downloaderEstimatedSize.
  ///
  /// In en, this message translates to:
  /// **'Estimated size'**
  String get downloaderEstimatedSize;

  /// No description provided for @downloaderAudioSection.
  ///
  /// In en, this message translates to:
  /// **'Audio only'**
  String get downloaderAudioSection;

  /// No description provided for @downloaderVideoSection.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get downloaderVideoSection;

  /// No description provided for @downloaderMergeRequired.
  ///
  /// In en, this message translates to:
  /// **'Merge'**
  String get downloaderMergeRequired;

  /// No description provided for @downloadsActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get downloadsActive;

  /// No description provided for @downloadsCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get downloadsCompleted;

  /// No description provided for @downloadsFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get downloadsFailed;

  /// No description provided for @downloadsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet.'**
  String get downloadsEmpty;

  /// No description provided for @downloadsPause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get downloadsPause;

  /// No description provided for @downloadsResume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get downloadsResume;

  /// No description provided for @downloadsRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get downloadsRetry;

  /// No description provided for @downloadsCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get downloadsCancel;

  /// No description provided for @downloadsDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get downloadsDelete;

  /// No description provided for @downloadsOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get downloadsOpen;

  /// No description provided for @downloadsShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get downloadsShare;

  /// No description provided for @downloadsMerging.
  ///
  /// In en, this message translates to:
  /// **'Merging video + audio…'**
  String get downloadsMerging;

  /// No description provided for @downloadsClearCompleted.
  ///
  /// In en, this message translates to:
  /// **'Clear completed'**
  String get downloadsClearCompleted;

  /// No description provided for @historyTitle.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get historyTitle;

  /// No description provided for @historyEmpty.
  ///
  /// In en, this message translates to:
  /// **'No history yet.'**
  String get historyEmpty;

  /// No description provided for @historyClearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear all history'**
  String get historyClearAll;

  /// No description provided for @historyClearConfirm.
  ///
  /// In en, this message translates to:
  /// **'Clear all history? This won\'t delete the files.'**
  String get historyClearConfirm;

  /// No description provided for @historyDeleteFile.
  ///
  /// In en, this message translates to:
  /// **'Delete file'**
  String get historyDeleteFile;

  /// No description provided for @historyDeleteFileConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete the file from your device?'**
  String get historyDeleteFileConfirm;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsGeneral.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get settingsGeneral;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsLanguageSystem.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get settingsLanguageSystem;

  /// No description provided for @settingsTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsTheme;

  /// No description provided for @settingsThemeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsThemeDark;

  /// No description provided for @settingsThemeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsThemeLight;

  /// No description provided for @settingsThemeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settingsThemeSystem;

  /// No description provided for @settingsSaveFolder.
  ///
  /// In en, this message translates to:
  /// **'Default save folder'**
  String get settingsSaveFolder;

  /// No description provided for @settingsSaveFolderReset.
  ///
  /// In en, this message translates to:
  /// **'Reset to default path'**
  String get settingsSaveFolderReset;

  /// No description provided for @settingsDownloads.
  ///
  /// In en, this message translates to:
  /// **'Downloads'**
  String get settingsDownloads;

  /// No description provided for @settingsMaxConcurrent.
  ///
  /// In en, this message translates to:
  /// **'Max concurrent downloads'**
  String get settingsMaxConcurrent;

  /// No description provided for @settingsClipboardMonitoring.
  ///
  /// In en, this message translates to:
  /// **'Clipboard monitoring'**
  String get settingsClipboardMonitoring;

  /// No description provided for @settingsClipboardMonitoringDesc.
  ///
  /// In en, this message translates to:
  /// **'Detect supported links in your clipboard'**
  String get settingsClipboardMonitoringDesc;

  /// No description provided for @settingsNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settingsNotifications;

  /// No description provided for @settingsNotificationsDesc.
  ///
  /// In en, this message translates to:
  /// **'Show download progress & completion'**
  String get settingsNotificationsDesc;

  /// No description provided for @settingsServer.
  ///
  /// In en, this message translates to:
  /// **'Extraction server'**
  String get settingsServer;

  /// No description provided for @settingsServerUrl.
  ///
  /// In en, this message translates to:
  /// **'Server URL'**
  String get settingsServerUrl;

  /// No description provided for @settingsServerUrlHint.
  ///
  /// In en, this message translates to:
  /// **'https://your-server.example.com'**
  String get settingsServerUrlHint;

  /// No description provided for @settingsServerTest.
  ///
  /// In en, this message translates to:
  /// **'Test connection'**
  String get settingsServerTest;

  /// No description provided for @settingsServerTesting.
  ///
  /// In en, this message translates to:
  /// **'Testing…'**
  String get settingsServerTesting;

  /// No description provided for @settingsServerOk.
  ///
  /// In en, this message translates to:
  /// **'Server is reachable.'**
  String get settingsServerOk;

  /// No description provided for @settingsServerFail.
  ///
  /// In en, this message translates to:
  /// **'Could not reach the server.'**
  String get settingsServerFail;

  /// No description provided for @settingsAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAbout;

  /// No description provided for @settingsVersion.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get settingsVersion;

  /// No description provided for @settingsClearData.
  ///
  /// In en, this message translates to:
  /// **'Clear all app data'**
  String get settingsClearData;

  /// No description provided for @settingsClearDataConfirm.
  ///
  /// In en, this message translates to:
  /// **'Clear all local data? Downloads will not be deleted.'**
  String get settingsClearDataConfirm;

  /// No description provided for @settingsStorage.
  ///
  /// In en, this message translates to:
  /// **'Storage'**
  String get settingsStorage;

  /// No description provided for @settingsClearCache.
  ///
  /// In en, this message translates to:
  /// **'Clear cache'**
  String get settingsClearCache;

  /// No description provided for @settingsClearCacheConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete all temporary merge files and partial downloads?'**
  String get settingsClearCacheConfirm;

  /// No description provided for @settingsCacheSize.
  ///
  /// In en, this message translates to:
  /// **'Current cache size'**
  String get settingsCacheSize;

  /// No description provided for @settingsCacheCleared.
  ///
  /// In en, this message translates to:
  /// **'Cache cleared — {size} freed'**
  String settingsCacheCleared(String size);

  /// No description provided for @whatsappTitle.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp Statuses'**
  String get whatsappTitle;

  /// No description provided for @whatsappTabImages.
  ///
  /// In en, this message translates to:
  /// **'Images'**
  String get whatsappTabImages;

  /// No description provided for @whatsappTabVideos.
  ///
  /// In en, this message translates to:
  /// **'Videos'**
  String get whatsappTabVideos;

  /// No description provided for @whatsappTabSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get whatsappTabSaved;

  /// No description provided for @whatsappBusinessToggle.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp Business'**
  String get whatsappBusinessToggle;

  /// No description provided for @whatsappNoStatuses.
  ///
  /// In en, this message translates to:
  /// **'No statuses found.\nOpen WhatsApp and view some statuses first.'**
  String get whatsappNoStatuses;

  /// No description provided for @whatsappPermissionNeeded.
  ///
  /// In en, this message translates to:
  /// **'Storage permission required'**
  String get whatsappPermissionNeeded;

  /// No description provided for @whatsappPermissionDesc.
  ///
  /// In en, this message translates to:
  /// **'VidSnap needs access to all files to read WhatsApp statuses. Tap below to grant.'**
  String get whatsappPermissionDesc;

  /// No description provided for @whatsappGrantPermission.
  ///
  /// In en, this message translates to:
  /// **'Grant permission'**
  String get whatsappGrantPermission;

  /// No description provided for @whatsappOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get whatsappOpenSettings;

  /// No description provided for @whatsappRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get whatsappRefresh;

  /// No description provided for @whatsappSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get whatsappSave;

  /// No description provided for @whatsappSavedToast.
  ///
  /// In en, this message translates to:
  /// **'Saved to gallery'**
  String get whatsappSavedToast;

  /// No description provided for @whatsappSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to save status'**
  String get whatsappSaveFailed;

  /// No description provided for @whatsappViewOriginal.
  ///
  /// In en, this message translates to:
  /// **'View original'**
  String get whatsappViewOriginal;

  /// No description provided for @whatsappStatusRefreshed.
  ///
  /// In en, this message translates to:
  /// **'Statuses refreshed'**
  String get whatsappStatusRefreshed;

  /// No description provided for @whatsappReShare.
  ///
  /// In en, this message translates to:
  /// **'Re-share'**
  String get whatsappReShare;

  /// No description provided for @notificationsDownloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading'**
  String get notificationsDownloading;

  /// No description provided for @notificationsDownloadComplete.
  ///
  /// In en, this message translates to:
  /// **'Download complete'**
  String get notificationsDownloadComplete;

  /// No description provided for @notificationsDownloadFailed.
  ///
  /// In en, this message translates to:
  /// **'Download failed'**
  String get notificationsDownloadFailed;

  /// No description provided for @notificationsOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get notificationsOpen;

  /// No description provided for @notificationsShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get notificationsShare;

  /// No description provided for @notificationsRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get notificationsRetry;

  /// No description provided for @notificationsClipboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Link detected'**
  String get notificationsClipboardTitle;

  /// No description provided for @notificationsClipboardBody.
  ///
  /// In en, this message translates to:
  /// **'Tap to open in VidSnap'**
  String get notificationsClipboardBody;

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// No description provided for @commonConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get commonConfirm;

  /// No description provided for @commonClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// No description provided for @commonRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get commonRetry;

  /// No description provided for @commonOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get commonOpen;

  /// No description provided for @commonShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get commonShare;

  /// No description provided for @commonError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get commonError;

  /// No description provided for @commonLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get commonLoading;

  /// No description provided for @commonEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing to show'**
  String get commonEmpty;

  /// No description provided for @commonNoInternet.
  ///
  /// In en, this message translates to:
  /// **'No internet connection'**
  String get commonNoInternet;

  /// No description provided for @commonPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Permission denied'**
  String get commonPermissionDenied;

  /// No description provided for @commonBytes.
  ///
  /// In en, this message translates to:
  /// **'B'**
  String get commonBytes;

  /// No description provided for @commonKiloBytes.
  ///
  /// In en, this message translates to:
  /// **'KB'**
  String get commonKiloBytes;

  /// No description provided for @commonMegaBytes.
  ///
  /// In en, this message translates to:
  /// **'MB'**
  String get commonMegaBytes;

  /// No description provided for @commonGigaBytes.
  ///
  /// In en, this message translates to:
  /// **'GB'**
  String get commonGigaBytes;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
