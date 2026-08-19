# VidSnap

A privacy-first mobile video downloader with WhatsApp status saver, built with Flutter. Companion Express server uses yt-dlp for link extraction.

> **Disclaimer:** VidSnap is intended for downloading content the user has the legal right to download. Respect each platform's Terms of Service and copyright laws. The authors are not responsible for misuse.

## Features

- Paste / share / clipboard link detection (YouTube, TikTok, Instagram, Facebook, X/Twitter)
- Bottom-sheet quality picker with file size hints
- Background downloads with pause / resume / retry
- WhatsApp + WhatsApp Business status saver (images & videos) — Snaptube-like UX
- Local-only storage (Hive) — no accounts, no cloud sync
- Dark / Light theme, English / Arabic with full RTL
- Foreground service + smart notifications
- Configurable server URL (Settings)

## Repository layout

```
Vidsnap/
├── app/        Flutter mobile app
├── server/     Node.js + Express + yt-dlp extraction service
├── tools/      Icon generation scripts and assets
└── .github/    CI workflows (APK build)
```

## Quick start

### 1. Run the extraction server

```bash
cd server
cp .env.example .env
npm install
npm run dev
# Server listens on http://localhost:3000
```

Production (Docker):

```bash
cd server
docker compose up -d
```

### 2. Build the Flutter app

```bash
cd app
flutter pub get
flutter run
```

### 3. Build APK via GitHub Actions

Push a tag `v*` to GitHub — the workflow at `.github/workflows/build-apk.yml` will build a signed APK and attach it to a Release.

You can also trigger the workflow manually from the Actions tab → "Build APK" → Run workflow.

## Configuration

- **Server URL**: Set in the app under Settings → Server URL. Default is `https://vidsnap-server.example.com` (placeholder). Change it to point to your deployment.
- **Signing**: For a stable release key, set these GitHub Secrets:
  - `KEYSTORE_BASE64` — base64-encoded `.jks` file
  - `KEYSTORE_PASSWORD`
  - `KEY_ALIAS`
  - `KEY_PASSWORD`
  
  If the secrets are missing, the workflow auto-generates a self-signed keystore for that run.

## License

MIT
