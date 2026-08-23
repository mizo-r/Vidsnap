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
RUN apk add --no-cache python3 py3-pip ffmpeg wget \
    && pip install --no-cache-dir --break-system-packages yt-dlp \
    && yt-dlp --version

WORKDIR /app

# Copy compiled JS + production node_modules from the builder stage.
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/package.json ./package.json

ENV NODE_ENV=production
ENV PORT=3000
EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s \
  CMD wget -qO- http://localhost:3000/health || exit 1

CMD ["node", "dist/index.js"]
