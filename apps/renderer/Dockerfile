# Video kỷ niệm renderer (D-068). Build context: apps/renderer after `pnpm build` (build/).
# Remotion needs Chrome Headless Shell and its system libraries; ffmpeg ships with @remotion/renderer.
FROM node:22-bookworm-slim
RUN apt-get update && apt-get install -y --no-install-recommends \
      libnss3 libdbus-1-3 libatk1.0-0 libgbm-dev libasound2 libxrandr2 libxkbcommon-dev \
      libxfixes3 libxcomposite1 libxdamage1 libatk-bridge2.0-0 libpango-1.0-0 libcairo2 libcups2 \
      fonts-noto-color-emoji ca-certificates \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY build/package.json ./
RUN npm install --omit=dev --no-audit --no-fund --loglevel=error \
    && node -e "import('@remotion/renderer').then((m) => m.ensureBrowser())"
COPY build/ ./
ENV NODE_ENV=production
CMD ["node", "server.js"]
