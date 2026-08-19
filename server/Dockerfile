FROM node:20-alpine

# Install yt-dlp + ffmpeg (ffmpeg required by yt-dlp for some merges)
RUN apk add --no-cache python3 py3-pip ffmpeg \
    && pip install --no-cache-dir --break-system-packages yt-dlp \
    && yt-dlp --version

WORKDIR /app

COPY package.json package-lock.json* ./
RUN npm install --omit=dev || npm install --omit=dev --no-package-lock

COPY tsconfig.json ./
COPY src ./src
RUN npm run build

ENV NODE_ENV=production
ENV PORT=3000
EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s \
  CMD wget -qO- http://localhost:3000/health || exit 1

CMD ["node", "dist/index.js"]
