/**
 * Whitelisted source identifiers.
 *
 * The app and server share this list — any URL whose host doesn't match a
 * whitelisted source is rejected before any network call.
 *
 * To extend support, add a new entry with a host pattern. yt-dlp supports
 * 1000+ sites, but we deliberately keep the list small to surface a clean
 * UX ("unsupported source" instead of a confusing extraction failure).
 */

export interface SourceDef {
  id: string;
  label: string;
  /** Hosts (lowercase) that map to this source. Subdomains allowed. */
  hosts: string[];
}

export const SOURCES: SourceDef[] = [
  {
    id: 'youtube',
    label: 'YouTube',
    hosts: [
      'youtube.com',
      'www.youtube.com',
      'm.youtube.com',
      'youtu.be',
      'youtube-nocookie.com',
    ],
  },
  {
    id: 'tiktok',
    label: 'TikTok',
    hosts: ['tiktok.com', 'www.tiktok.com', 'vm.tiktok.com', 'vt.tiktok.com'],
  },
  {
    id: 'instagram',
    label: 'Instagram',
    hosts: ['instagram.com', 'www.instagram.com'],
  },
  {
    id: 'facebook',
    label: 'Facebook',
    hosts: ['facebook.com', 'www.facebook.com', 'm.facebook.com', 'fb.watch', 'fb.com'],
  },
  {
    id: 'twitter',
    label: 'X (Twitter)',
    hosts: ['twitter.com', 'www.twitter.com', 'x.com', 'www.x.com', 't.co'],
  },
];

export const SOURCE_IDS: string[] = SOURCES.map((s) => s.id);

export function findSourceByUrl(rawUrl: string): SourceDef | null {
  let host: string;
  try {
    host = new URL(rawUrl).hostname.toLowerCase();
  } catch {
    return null;
  }
  return SOURCES.find((s) => s.hosts.includes(host)) ?? null;
}

export function isSourceAllowed(rawUrl: string): boolean {
  return findSourceByUrl(rawUrl) !== null;
}
