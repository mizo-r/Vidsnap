import { z } from 'zod';

export const ExtractRequestSchema = z.object({
  url: z
    .string()
    .url('Invalid URL format')
    .max(2048, 'URL too long'),
});

export type ExtractRequest = z.infer<typeof ExtractRequestSchema>;

export interface FormatOption {
  formatId: string;
  /** Display label, e.g. "1080p MP4" or "128kbps MP3" */
  label: string;
  /** "video" | "audio" | "muxed" */
  kind: 'video' | 'audio' | 'muxed';
  extension: string;
  /** Approximate file size in bytes (estimated when not provided). */
  fileSizeBytes: number | null;
  /** Direct download URL. */
  downloadUrl: string;
  /** True when this is the recommended default. */
  recommended?: boolean;
}

export interface ExtractResponse {
  sourceId: string;
  sourceLabel: string;
  originalUrl: string;
  title: string;
  thumbnail: string | null;
  durationSeconds: number | null;
  uploader: string | null;
  formats: FormatOption[];
}
