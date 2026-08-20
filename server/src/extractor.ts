import { spawn } from 'child_process';
import { findSourceByUrl } from './sources';
import type { ExtractResponse, FormatOption, AudioFormat } from './validation';

const YTDLP_PATH = process.env.YTDLP_PATH || 'yt-dlp';
const YTDLP_TIMEOUT_MS = Number(process.env.YTDLP_TIMEOUT_MS || 30_000);
const COOKIES_FILE = process.env.COOKIES_FILE || '';

/// Qualities the app exposes in its UI — every other height is hidden.
const TARGET_HEIGHTS = [360, 480, 720, 1080];

export class ExtractionError extends Error {
  constructor(
    message: string,
    public readonly kind: 'unsupported' | 'upstream' | 'timeout' | 'invalid' = 'upstream',
  ) {
    super(message);
    this.name = 'ExtractionError';
  }
}

/** Promisified yt-dlp invocation with -J (dump JSON). */
function runYtDlp(url: string): Promise<any> {
  return new Promise((resolve, reject) => {
    const args = [
      '-J',
      '--no-warnings',
      '--no-playlist',
      '--no-check-certificate',
      '--skip-download',
      url,
    ];
    if (COOKIES_FILE) {
      args.unshift('--cookies', COOKIES_FILE);
    }

    const proc = spawn(YTDLP_PATH, args, {
      cwd: process.cwd(),
      env: process.env,
      stdio: ['ignore', 'pipe', 'pipe'],
    });

    let stdout = '';
    let stderr = '';
    const timer = setTimeout(() => {
      proc.kill('SIGKILL');
      reject(new ExtractionError('yt-dlp timed out', 'timeout'));
    }, YTDLP_TIMEOUT_MS);

    proc.stdout.on('data', (chunk) => {
      stdout += chunk.toString();
    });
    proc.stderr.on('data', (chunk) => {
      stderr += chunk.toString();
    });

    proc.on('error', (err) => {
      clearTimeout(timer);
      reject(
        new ExtractionError(
          `Failed to launch yt-dlp. Is the binary installed and on PATH? (${err.message})`,
          'upstream',
        ),
      );
    });

    proc.on('close', (code) => {
      clearTimeout(timer);
      if (code !== 0) {
        const msg = stderr.trim().split('\n').pop() || `yt-dlp exited with code ${code}`;
        reject(new ExtractionError(msg, 'upstream'));
        return;
      }
      try {
        resolve(JSON.parse(stdout));
      } catch (e: any) {
        reject(new ExtractionError(`Failed to parse yt-dlp output: ${e.message}`, 'upstream'));
      }
    });
  });
}

interface RankedFormat {
  f: any;
  score: number;
}

/**
 * Pick the best format for a given target height.
 * Preference order (highest score first):
 *   1. Muxed (video+audio) at exact height
 *   2. Muxed at nearest lower height
 *   3. Video-only at exact height (requires merge with audio)
 *   4. Video-only at nearest lower height (requires merge)
 */
function pickBestForHeight(formats: any[], targetHeight: number): {
  muxed?: any;
  videoOnly?: any;
  requiresMerge: boolean;
} {
  const muxedAtHeight = formats.find(
    (f) => isMuxed(f) && f.height === targetHeight,
  );
  if (muxedAtHeight) {
    return { muxed: muxedAtHeight, requiresMerge: false };
  }

  // Find nearest-lower muxed
  const lowerMuxed = formats
    .filter((f) => isMuxed(f) && f.height && f.height < targetHeight)
    .sort((a, b) => b.height - a.height)[0];
  if (lowerMuxed) {
    return { muxed: lowerMuxed, requiresMerge: false };
  }

  // No muxed available — use video-only at this height (or nearest lower)
  const videoAtHeight = pickBestVideoOnlyAtHeight(formats, targetHeight);
  if (videoAtHeight) {
    return { videoOnly: videoAtHeight, requiresMerge: true };
  }

  // Find nearest-lower video-only
  const lowerVideoHeights = formats
    .filter((f) => isVideoOnly(f) && f.height && f.height < targetHeight)
    .map((f) => f.height)
    .sort((a, b) => b - a);
  if (lowerVideoHeights.length > 0) {
    const nearestHeight = lowerVideoHeights[0];
    const lowerVideo = pickBestVideoOnlyAtHeight(formats, nearestHeight);
    if (lowerVideo) {
      return { videoOnly: lowerVideo, requiresMerge: true };
    }
  }

  return { requiresMerge: false };
}

function isMuxed(f: any): boolean {
  return (
    f &&
    f.vcodec &&
    f.vcodec !== 'none' &&
    f.acodec &&
    f.acodec !== 'none' &&
    !!f.url &&
    /// Only accept direct HTTPS downloads — HLS manifests (.m3u8) require a
    /// special downloader and would yield a tiny text file instead of video.
    f.protocol === 'https'
  );
}

function isVideoOnly(f: any): boolean {
  return (
    f &&
    f.vcodec &&
    f.vcodec !== 'none' &&
    (!f.acodec || f.acodec === 'none') &&
    !!f.url &&
    f.protocol === 'https'
  );
}

function isAudioOnly(f: any): boolean {
  return (
    f &&
    (!f.vcodec || f.vcodec === 'none') &&
    f.acodec &&
    f.acodec !== 'none' &&
    !!f.url &&
    f.protocol === 'https'
  );
}

/// Pick the best audio-only format (prefer m4a for compatibility, then highest abr).
function pickBestAudio(formats: any[]): any | null {
  const audio = formats.filter(isAudioOnly);
  if (audio.length === 0) return null;
  // Prefer m4a (mp4 audio) — best compatibility with Android MediaStore + FFmpeg merge
  const m4a = audio
    .filter((f) => (f.ext || '').toLowerCase() === 'm4a')
    .sort((a, b) => (b.abr || 0) - (a.abr || 0))[0];
  if (m4a) return m4a;
  return audio.sort((a, b) => (b.abr || 0) - (a.abr || 0))[0];
}

/// Pick the best video-only format for a given height.
/// Preference: avc1/mp4 (best compatibility with FFmpeg + Android) → vp9/webm → av1/mp4
function pickBestVideoOnlyAtHeight(formats: any[], height: number): any | null {
  const candidates = formats.filter((f) => isVideoOnly(f) && f.height === height);
  if (candidates.length === 0) return null;
  // avc1 first
  const avc1 = candidates.find((f) => (f.vcodec || '').startsWith('avc1'));
  if (avc1) return avc1;
  // vp9 next
  const vp9 = candidates.find((f) => (f.vcodec || '').startsWith('vp9'));
  if (vp9) return vp9;
  // av1 last (slow to decode on older devices)
  return candidates[0];
}

function humanizeAudio(f: any): string {
  const ext = (f.ext || '').toLowerCase();
  const abr = f.abr ? ` ${Math.round(f.abr)}kbps` : '';
  return `Audio ${ext.toUpperCase()}${abr}`;
}

function humanizeVideo(f: any, requiresMerge: boolean): string {
  const ext = (f.ext || '').toLowerCase();
  const height = f.height;
  const base = height ? `${height}p ${ext.toUpperCase()}` : `Video ${ext.toUpperCase()}`;
  return requiresMerge ? `${base}` : `${base}`;
}

/**
 * Build the list of FormatOptions for the four target heights.
 * Each entry is either:
 *   - muxed direct download (requiresMerge=false, has downloadUrl)
 *   - requires merge (requiresMerge=true, has videoUrl + audioUrl)
 */
function buildVideoFormats(formats: any[], bestAudio: any | null): FormatOption[] {
  const out: FormatOption[] = [];

  for (const targetHeight of TARGET_HEIGHTS) {
    const pick = pickBestForHeight(formats, targetHeight);

    if (pick.muxed) {
      const f = pick.muxed;
      out.push({
        formatId: f.format_id || String(f.height),
        label: humanizeVideo(f, false),
        kind: 'muxed',
        extension: (f.ext || 'mp4').toLowerCase(),
        fileSizeBytes: f.filesize || f.filesize_approx || null,
        downloadUrl: f.url,
        requiresMerge: false,
        recommended: targetHeight === 720,
      });
    } else if (pick.videoOnly && bestAudio) {
      const v = pick.videoOnly;
      const videoSize = v.filesize || v.filesize_approx || null;
      const audioSize = bestAudio.filesize || bestAudio.filesize_approx || null;
      const totalSize =
        videoSize && audioSize ? videoSize + audioSize : videoSize || audioSize || null;

      out.push({
        formatId: v.format_id || String(v.height),
        label: humanizeVideo(v, true),
        kind: 'video',
        extension: 'mp4', // final extension after merge
        fileSizeBytes: totalSize,
        downloadUrl: v.url, // primary (video)
        videoUrl: v.url,
        audioUrl: bestAudio.url,
        requiresMerge: true,
        recommended: targetHeight === 720,
      });
    }
    // If neither muxed nor videoOnly is available at this height, skip it.
  }

  return out;
}

function buildAudioFormats(formats: any[]): AudioFormat[] {
  const audio = formats.filter(isAudioOnly);
  const seen = new Set<string>();
  const out: AudioFormat[] = [];

  // Prefer m4a first (best compatibility with Android MediaStore)
  const m4a = audio
    .filter((f) => (f.ext || '').toLowerCase() === 'm4a')
    .sort((a, b) => (b.abr || 0) - (a.abr || 0));
  for (const f of m4a.slice(0, 2)) {
    const id = f.format_id;
    if (id && !seen.has(id)) {
      out.push({
        formatId: id,
        label: humanizeAudio(f),
        extension: (f.ext || 'm4a').toLowerCase(),
        fileSizeBytes: f.filesize || f.filesize_approx || null,
        downloadUrl: f.url,
        abr: f.abr ? Math.round(f.abr) : null,
      });
      seen.add(id);
    }
  }

  // Then add the best webm/opus as alternative
  const others = audio
    .filter((f) => (f.ext || '').toLowerCase() !== 'm4a')
    .sort((a, b) => (b.abr || 0) - (a.abr || 0));
  for (const f of others.slice(0, 1)) {
    const id = f.format_id;
    if (id && !seen.has(id)) {
      out.push({
        formatId: id,
        label: humanizeAudio(f),
        extension: (f.ext || 'webm').toLowerCase(),
        fileSizeBytes: f.filesize || f.filesize_approx || null,
        downloadUrl: f.url,
        abr: f.abr ? Math.round(f.abr) : null,
      });
      seen.add(id);
    }
  }

  return out;
}

export async function extract(rawUrl: string): Promise<ExtractResponse> {
  const source = findSourceByUrl(rawUrl);
  if (!source) {
    throw new ExtractionError(`Source not supported`, 'unsupported');
  }

  let info: any;
  try {
    info = await runYtDlp(rawUrl);
  } catch (e: any) {
    if (e instanceof ExtractionError) throw e;
    throw new ExtractionError(e.message || 'Unknown extraction error', 'upstream');
  }

  const allFormats: any[] = info.formats || [];
  const bestAudio = pickBestAudio(allFormats);
  const videoFormats = buildVideoFormats(allFormats, bestAudio);
  const audioFormats = buildAudioFormats(allFormats);

  return {
    sourceId: source.id,
    sourceLabel: source.label,
    originalUrl: rawUrl,
    title: info.title || info.fulltitle || 'Untitled',
    thumbnail: info.thumbnail || null,
    durationSeconds: typeof info.duration === 'number' ? info.duration : null,
    uploader: info.uploader || info.channel || null,
    formats: videoFormats,
    audioFormats,
  };
}
