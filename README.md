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
- **Language**: Defaults to "System default" (follows the device locale). Users can override in Settings → Language to force Arabic or English.
- **Signing** (required for releases): Set these four GitHub Secrets. Without them, the workflow will **fail loudly** (it no longer auto-generates a throwaway keystore, because that breaks app updates on user devices).

  | Secret name | What to put | How to get it |
  |-------------|-------------|---------------|
  | `KEYSTORE_BASE64` | Your `.jks` keystore file, base64-encoded | `base64 -w0 vidsnap.jks` on Linux/macOS, or `certutil -encode vidsnap.jks vidsnap.b64` then copy contents on Windows |
  | `KEYSTORE_PASSWORD` | The keystore's store password | Whatever you set when generating the keystore |
  | `KEY_ALIAS` | The alias of the signing key inside the keystore | Whatever you passed to `keytool -genkey ... -alias <name>` |
  | `KEY_PASSWORD` | The password for that specific key | Whatever you set as `-keypass` |

  **How to generate a keystore locally (do this ONCE, keep the file safe):**

  ```bash
  keytool -genkey -v \
    -keystore vidsnap.jks \
    -keyalg RSA -keysize 2048 -validity 10000 \
    -alias vidsnap \
    -dname "CN=VidSnap, OU=Mobile, O=VidSnap, L=Default, S=Default, C=US" \
    -storepass <YOUR_STORE_PASSWORD> \
    -keypass <YOUR_KEY_PASSWORD>
  ```

  Then encode and add to GitHub Secrets (repo → Settings → Secrets and variables → Actions → New repository secret):

  ```bash
  base64 -w0 vidsnap.jks   # copy entire output as KEYSTORE_BASE64
  ```

  ⚠️ **Keep `vidsnap.jks` in a safe offline location.** If you lose it, you cannot update the app for users who already installed it — Android will reject the new APK as a different app.

  **Add the secrets at:** https://github.com/mizofly/Vidsnap/settings/secrets/actions

## License

MIT
