# VidSnap Extraction Server

Lightweight Node.js + Express service that wraps `yt-dlp` to convert a video page URL into direct download links.

## Endpoints

### `GET /health`
Returns `{ "status": "ok", "version": "1.0.0" }`.

### `POST /extract`
**Request:**
```json
{ "url": "https://www.youtube.com/watch?v=..." }
```

**Response (200):**
```json
{
  "sourceId": "youtube",
  "sourceLabel": "YouTube",
  "originalUrl": "https://...",
  "title": "How to Learn Flutter Fast",
  "thumbnail": "https://i.ytimg.com/...",
  "durationSeconds": 612,
  "uploader": "Channel Name",
  "formats": [
    {
      "formatId": "22",
      "label": "720p MP4",
      "kind": "muxed",
      "extension": "mp4",
      "fileSizeBytes": 52428800,
      "downloadUrl": "https://...",
      "recommended": true
    },
    {
      "formatId": "251",
      "label": "Audio WEBM 160kbps",
      "kind": "audio",
      "extension": "webm",
      "fileSizeBytes": 8388608,
      "downloadUrl": "https://..."
    }
  ]
}
```

**Errors:**
- `400` — invalid request body
- `403` — source not whitelisted
- `502` — yt-dlp failed (upstream error)
- `504` — yt-dlp timed out

## Run locally

```bash
# 1. Install yt-dlp on your machine
pip install yt-dlp

# 2. Install deps
npm install

# 3. Run dev mode
npm run dev
```

## Run via Docker

```bash
cp .env.example .env
docker compose up -d
```

The Docker image bundles `yt-dlp` and `ffmpeg`, so no system install is needed.

## Deploy

Any container host works (Render, Railway, Fly.io, a VPS). Set the env vars from `.env.example` and expose port 3000. After deploy, set the resulting URL in the VidSnap app under Settings → Server URL.
