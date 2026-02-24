#!/usr/bin/env bash
# ============================================================
# build-in-docker.sh - Build the project using Docker
#
# This script builds the Electron app inside a Docker container,
# ensuring a consistent build environment regardless of the host.
#
# Usage:
#   ./scripts/docker/build-in-docker.sh              # Build Linux targets
#   ./scripts/docker/build-in-docker.sh --no-cache    # Rebuild without cache
# ============================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
DIST_DIR="$PROJECT_ROOT/dist"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_info()  { echo -e "${GREEN}[DOCKER-BUILD]${NC} $*"; }
log_warn()  { echo -e "${YELLOW}[DOCKER-BUILD]${NC} $*"; }
log_error() { echo -e "${RED}[DOCKER-BUILD]${NC} $*" >&2; }

# Parse arguments
DOCKER_BUILD_ARGS=""
for arg in "$@"; do
  case "$arg" in
    --no-cache)  DOCKER_BUILD_ARGS="--no-cache" ;;
    --help|-h)
      echo "Usage: $0 [--no-cache]"
      echo ""
      echo "Builds the Electron app inside Docker for Linux."
      echo ""
      echo "Options:"
      echo "  --no-cache  Force rebuild of Docker image layers"
      echo "  --help      Show this help"
      exit 0
      ;;
  esac
done

cd "$PROJECT_ROOT"

# Ensure dist directory exists
mkdir -p "$DIST_DIR"

log_info "Building Docker image..."
docker build \
  $DOCKER_BUILD_ARGS \
  -f scripts/docker/Dockerfile \
  -t adplus-builder \
  . 2>&1

log_info "Extracting build artifacts..."
# Run the builder and copy output to local dist/
CONTAINER_ID=$(docker create adplus-builder)
docker cp "$CONTAINER_ID:/output/." "$DIST_DIR/" 2>/dev/null || true
docker rm "$CONTAINER_ID" > /dev/null

log_info "============================================================"
log_info "Docker build complete! Output:"
log_info "============================================================"

if [ -d "$DIST_DIR" ]; then
  find "$DIST_DIR" -maxdepth 1 -type f | while read -r file; do
    size=$(du -sh "$file" | cut -f1)
    log_info "  $size  $(basename "$file")"
  done
else
  log_warn "No output files found."
fi
