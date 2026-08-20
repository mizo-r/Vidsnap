# VidSnap — Flutter App

Privacy-first video downloader with WhatsApp status saver.

## Run locally

```bash
flutter pub get
flutter gen-l10n
flutter run
```

## Build APK

```bash
flutter build apk --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

## Project structure

```
lib/
├── main.dart                    App entry point
├── app.dart                     MaterialApp + theme + locale wiring
├── router.dart                  GoRouter with bottom-nav shell
├── core/
│   ├── constants/               Colors, sources, app constants
│   ├── services/                ExtractionService, DownloadService,
│   │                            NotificationService, WhatsAppStatusService, ...
│   └── utils/                   FormatUtils (bytes, duration, dates)
├── data/
│   ├── adapters/                Hive type adapters (manually registered)
│   ├── models/                  Plain Dart models (DownloadTask, AppSettings, ...)
│   └── repositories/            Hive-backed repos (DownloadRepo, HistoryRepo, SettingsRepo)
├── features/
│   ├── home/                    Home screen (paste link, quick actions)
│   ├── downloader/              Modal bottom sheet (quality picker)
│   ├── downloads/               Active / Completed / Failed tabs
│   ├── history/                 History list with share/delete
│   ├── settings/                Settings screen (language, theme, server URL, ...)
│   └── whatsapp/                WhatsApp status saver (grid + preview + save)
└── l10n/
    ├── app_en.arb               English strings
    ├── app_ar.arb               Arabic strings
    └── gen/                     (generated) AppLocalizations class
```

## Configuration

- **Server URL**: Set in Settings → Extraction server → Server URL. Default placeholder is `https://vidsnap-server.example.com`.
- **Package ID**: `app.vidsnap.mobile`
- **Min SDK**: 23 (Android 6.0)
- **Target SDK**: 34 (Android 14)

## Permissions

| Permission | Why |
|------------|-----|
| `INTERNET` | Call extraction server + download files |
| `POST_NOTIFICATIONS` | Show download progress & completion (Android 13+) |
| `FOREGROUND_SERVICE` + `FOREGROUND_SERVICE_DATA_SYNC` | Keep downloads running in background |
| `MANAGE_EXTERNAL_STORAGE` | Read WhatsApp `.Statuses` directory (Android 11+) |
| `READ_EXTERNAL_STORAGE` (max SDK 29) | Read WhatsApp statuses on Android 10 and below |
