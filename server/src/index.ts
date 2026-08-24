import cors from 'cors';
import express from 'express';
import helmet from 'helmet';
import rateLimit from 'express-rate-limit';
import { TtlCache } from './cache';
import { extract, ExtractionError } from './extractor';
import { ExtractRequestSchema, type ExtractResponse } from './validation';
import { isSourceAllowed } from './sources';

const PORT = Number(process.env.PORT || 3000);
const ALLOWED_ORIGINS = process.env.ALLOWED_ORIGINS || '*';
const RATE_LIMIT_WINDOW_MS = Number(process.env.RATE_LIMIT_WINDOW_MS || 15 * 60 * 1000);
const RATE_LIMIT_MAX = Number(process.env.RATE_LIMIT_MAX || 100);
const CACHE_TTL_SECONDS = Number(process.env.CACHE_TTL_SECONDS || 300);

const app = express();

// Render (and most cloud providers) use a reverse proxy that sets the
// X-Forwarded-For header. Without 'trust proxy', express-rate-limit
// throws a ValidationError and crashes the request (502 to the client).
// Setting it to 1 trusts the first proxy hop (Render's load balancer).
app.set('trust proxy', 1);

app.use(helmet());
app.use(express.json({ limit: '32kb' }));

const corsOptions =
  ALLOWED_ORIGINS === '*'
    ? undefined
    : {
        origin: ALLOWED_ORIGINS.split(',').map((s) => s.trim()),
        credentials: false,
      };
app.use(cors(corsOptions));

app.use(
  rateLimit({
    windowMs: RATE_LIMIT_WINDOW_MS,
    max: RATE_LIMIT_MAX,
    standardHeaders: true,
    legacyHeaders: false,
    message: { error: 'Too many requests, please retry later.' },
  }),
);

const cache = new TtlCache<ExtractResponse>(CACHE_TTL_SECONDS);
// Sweep every 5 minutes
setInterval(() => cache.sweep(), 5 * 60 * 1000).unref();

app.get('/health', (_req, res) => {
  res.json({ status: 'ok', version: '1.0.0' });
});

app.post('/extract', async (req, res) => {
  const parsed = ExtractRequestSchema.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({ error: 'Invalid request', details: parsed.error.flatten() });
    return;
  }

  const { url } = parsed.data;

  if (!isSourceAllowed(url)) {
    res.status(403).json({ error: 'Source not supported' });
    return;
  }

  const cached = cache.get(url);
  if (cached) {
    res.json(cached);
    return;
  }

  try {
    const result = await extract(url);
    cache.set(url, result);
    res.json(result);
  } catch (e: any) {
    if (e instanceof ExtractionError) {
      const status =
        e.kind === 'unsupported' ? 403 : e.kind === 'invalid' ? 400 : e.kind === 'timeout' ? 504 : 502;
      res.status(status).json({ error: e.message });
      return;
    }
    res.status(500).json({ error: 'Internal server error' });
  }
});

app.use((_req, res) => {
  res.status(404).json({ error: 'Not found' });
});

app.listen(PORT, () => {
  console.log(`[VidSnap] extraction server listening on :${PORT}`);
});

export default app;
