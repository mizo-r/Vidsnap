import { spawn } from 'child_process';
import path from 'path';
import { findSourceByUrl } from './sources';
import type { ExtractResponse, FormatOption } from './validation';

const YTDLP_PATH = process.env.YTDLP_PATH || 'yt-dlp';
const YTDLP_TIMEOUT_MS = Number(process.env.YTDLP_TIMEOUT_MS || 30_000);
const COOKIES_FILE = process.env.COOKIES_FILE || '';

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

function humanizeQuality(format: any): { label: string; kind: 'video' | 'audio' | 'muxed' } {
  const ext = (format.ext || '').toLowerCase();
  const height = format.height;
  const vcodec = format.vcodec && format.vcodec !== 'none';
  const acodec = format.acodec && format.acodec !== 'none';

  if (vcodec && acodec) {
    return {
      label: height ? `${height}p ${ext.toUpperCase()}` : `Video ${ext.toUpperCase()}`,
      kind: 'muxed',
    };
  }
  if (vcodec) {
    return {
      label: height ? `${height}p ${ext.toUpperCase()} (video only)` : `Video only ${ext.toUpperCase()}`,
      kind: 'video',
    };
  }
  if (acodec) {
    const abr = format.abr ? ` ${Math.round(format.abr)}kbps` : '';
    return {
      label: `Audio ${ext.toUpperCase()}${abr}`,
      kind: 'audio',
    };
  }
  return { label: ext.toUpperCase(), kind: 'video' };
}

function pickBestFormats(info: any): FormatOption[] {
  // Prefer pre-merged formats when available; otherwise build combinations.
  const out: FormatOption[] = [];
  const seen = new Set<string>();

  const pushFormat = (f: any, recommended = false) => {
    if (!f) return;
    if (!f.url) return;
    const id = f.format_id || f.format;
    if (!id || seen.has(id)) return;
    const { label, kind } = humanizeQuality(f);
    out.push({
      formatId: id,
      label,
      kind,
      extension: (f.ext || 'mp4').toLowerCase(),
      fileSizeBytes: f.filesize || f.filesize_approx || null,
      downloadUrl: f.url,
      recommended,
    });
    seen.add(id);
  };

  // 1) Single-file muxed formats (best first)
  const formats: any[] = info.formats || [];
  const muxed = formats
    .filter((f) => f.vcodec && f.vcodec !== 'none' && f.acodec && f.acodec !== 'none' && f.url)
    .sort((a, b) => (b.height || 0) - (a.height || 0));

  // Recommend best muxed <= 1080p for compatibility
  const bestMuxed = muxed.find((f) => (f.height || 0) <= 1080) || muxed[0];
  if (bestMuxed) pushFormat(bestMuxed, true);
  for (const f of muxed) pushFormat(f);

  // 2) Audio-only options (mp3 / m4a)
  const audio = formats
    .filter((f) => (!f.vcodec || f.vcodec === 'none') && f.acodec && f.acodec !== 'none' && f.url)
    .sort((a, b) => (b.abr || 0) - (a.abr || 0));
  for (const f of audio.slice(0, 3)) pushFormat(f);

  // 3) High-resolution video-only formats (for users who want max quality)
  const videoOnly = formats
    .filter((f) => f.vcodec && f.vcodec !== 'none' && (!f.acodec || f.acodec === 'none') && f.url)
    .sort((a, b) => (b.height || 0) - (a.height || 0));
  for (const f of videoOnly.slice(0, 4)) pushFormat(f);

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

  const formats = pickBestFormats(info);

  return {
    sourceId: source.id,
    sourceLabel: source.label,
    originalUrl: rawUrl,
    title: info.title || info.fulltitle || 'Untitled',
    thumbnail: info.thumbnail || null,
    durationSeconds: typeof info.duration === 'number' ? info.duration : null,
    uploader: info.uploader || info.channel || null,
    formats,
  };
}
