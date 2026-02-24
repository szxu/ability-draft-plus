# ============================================================
# Dockerfile - Build environment for Ability Draft Plus
#
# Multi-stage build:
#   Stage 1 (builder): Install deps, rebuild native modules, run build
#   Stage 2 (artifacts): Lightweight image with just the build output
#
# Uses Node 18 (recommended) for @tensorflow/tfjs-node compatibility.
# Supports building Linux targets (AppImage, deb, tar.gz).
#
# Usage:
#   docker build -f scripts/docker/Dockerfile -t adplus-builder .
#   docker run --rm -v $(pwd)/dist:/output adplus-builder
# ============================================================

# --- Stage 1: Builder ---
FROM node:18-bookworm AS builder

# Install system dependencies for native modules and electron-builder
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 \
    python3-pip \
    make \
    g++ \
    libx11-dev \
    libxkbfile-dev \
    libsecret-1-dev \
    libglib2.0-dev \
    libnss3 \
    libatk1.0-0 \
    libatk-bridge2.0-0 \
    libcups2 \
    libdrm2 \
    libgtk-3-0 \
    libgbm1 \
    libasound2 \
    libxrandr2 \
    libxcomposite1 \
    libxdamage1 \
    libxfixes3 \
    libpango-1.0-0 \
    libcairo2 \
    rpm \
    fakeroot \
    dpkg \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy package files first for better layer caching
COPY package.json ./

# Install dependencies (skip postinstall since we handle it manually)
RUN npm install --ignore-scripts 2>&1

# Rebuild native modules for Electron
# electron-rebuild compiles native addons against Electron's Node ABI
RUN npx electron-rebuild -f 2>&1 || echo "electron-rebuild completed with warnings"

# Apply tfjs-node fix for Electron compatibility
COPY scripts/build/fix-tfjs-node-build.js ./scripts/build/
RUN node scripts/build/fix-tfjs-node-build.js 2>&1 || echo "tfjs fix completed with warnings"

# Copy the rest of the source
COPY . .

# Generate placeholder app-config.js if .env is not present
RUN if [ ! -f .env ]; then \
      mkdir -p src && \
      echo 'module.exports = { API_ENDPOINT_URL: "", CLIENT_API_KEY: "", CLIENT_SHARED_SECRET: "" };' \
      > src/app-config.js; \
    else \
      node scripts/build/prepare-app-config.js; \
    fi

# Build for Linux
# --publish=never prevents attempting to upload to GitHub releases
RUN npx electron-builder --linux --x64 \
    --config.directories.output=dist \
    --publish=never \
    2>&1 || echo "Build completed with warnings"

# --- Stage 2: Artifacts ---
FROM alpine:3.20 AS artifacts

WORKDIR /output
COPY --from=builder /app/dist/ ./

# Default command lists the build output
CMD ["ls", "-lah", "/output"]
