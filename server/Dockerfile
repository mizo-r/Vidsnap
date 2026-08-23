# Multi-stage build: keeps the final image small while still compiling TypeScript.
FROM node:20-alpine AS builder

# Install yt-dlp + ffmpeg (needed at runtime, but installing here too for a
# single-layer image — the runtime stage copies node_modules from this stage).
RUN apk add --no-cache python3 py3-pip ffmpeg \
    && pip install --no-cache-dir --break-system-packages yt-dlp \
    && yt-dlp --version

WORKDIR /app

# Install ALL dependencies (including devDependencies for `tsc`).
# The devDependencies are only needed during build, not at runtime.
COPY package.json package-lock.json* ./
RUN npm install

# Compile TypeScript → JavaScript
COPY tsconfig.json ./
COPY src ./src
RUN npm run build

# Remove devDependencies so the runtime image only keeps what's needed.
RUN npm prune --omit=dev

# ---------------------------------------------------------------------------
# Runtime stage — same base image, but only the compiled JS + production deps.
# ---------------------------------------------------------------------------
FROM node:20-alpine AS runtime

# Re-install the runtime system deps (yt-dlp + ffmpeg) in the slim runtime image.
# `wget` is needed by the Docker HEALTHCHECK below.
RUN apk add --no-cache python3 py3-pip ffmpeg wget \
    && pip install --no-cache-dir --break-system-packages yt-dlp \
    && yt-dlp --version

WORKDIR /app

# Copy compiled JS + production node_modules from the builder stage.
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/package.json ./package.json

# Render sets the PORT env var automatically. Do NOT hardcode PORT here —
# doing so would clash with Render's own port assignment and cause the
# "x-render-routing: no-server" 404 response.
# The app reads `process.env.PORT || 3000` at runtime (in src/index.ts).
ENV NODE_ENV=production

# EXPOSE is informational only; Render ignores it and uses its own port.
# We keep it for local `docker run` compatibility.
EXPOSE 3000

# HEALTHCHECK uses $PORT so it works both locally (PORT=3000 default) and
# on Render (PORT set automatically by the platform).
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s \
  CMD wget -qO- http://localhost:${PORT:-3000}/health || exit 1

CMD ["node", "dist/index.js"]
