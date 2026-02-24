#!/usr/bin/env bash
# ============================================================
# build.sh - Build distributable packages for Ability Draft Plus
#
# Supports Linux (AppImage, deb, tar.gz) and Windows (portable, NSIS)
# cross-compilation via electron-builder.
#
# Usage:
#   ./scripts/build/build.sh                    # Build for current platform
#   ./scripts/build/build.sh --linux            # Build Linux targets
#   ./scripts/build/build.sh --win              # Build Windows targets (needs Wine)
#   ./scripts/build/build.sh --all              # Build all platforms
#   ./scripts/build/build.sh --clean            # Clean then build
#   ./scripts/build/build.sh --skip-rebuild     # Skip native module rebuild
# ============================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
DIST_DIR="$PROJECT_ROOT/dist"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info()  { echo -e "${GREEN}[BUILD]${NC} $*"; }
log_warn()  { echo -e "${YELLOW}[BUILD]${NC} $*"; }
log_error() { echo -e "${RED}[BUILD]${NC} $*" >&2; }

# Parse arguments
BUILD_TARGET=""
CLEAN_FIRST=false
SKIP_REBUILD=false
EXTRA_ARGS=""

for arg in "$@"; do
  case "$arg" in
    --linux)  BUILD_TARGET="linux" ;;
    --win)    BUILD_TARGET="win" ;;
    --all)    BUILD_TARGET="all" ;;
    --clean)  CLEAN_FIRST=true ;;
    --skip-rebuild)  SKIP_REBUILD=true ;;
    --help|-h)
      echo "Usage: $0 [--linux|--win|--all] [--clean] [--skip-rebuild]"
      echo ""
      echo "Options:"
      echo "  --linux         Build Linux targets (AppImage, deb, tar.gz)"
      echo "  --win           Build Windows targets (portable, NSIS installer)"
      echo "  --all           Build for all platforms"
      echo "  --clean         Clean dist/ before building"
      echo "  --skip-rebuild  Skip native module rebuild (for CI/envs without Electron headers)"
      echo "  --help          Show this help"
      exit 0
      ;;
    *)
      log_error "Unknown argument: $arg"
      exit 1
      ;;
  esac
done

cd "$PROJECT_ROOT"

# Clean if requested
if [ "$CLEAN_FIRST" = true ]; then
  log_info "Cleaning previous build artifacts..."
  rm -rf "$DIST_DIR"
  log_info "Clean complete."
fi

# Verify node_modules
if [ ! -d "$PROJECT_ROOT/node_modules" ]; then
  log_error "node_modules not found. Run 'npm install' or './scripts/build/install.sh' first."
  exit 1
fi

# Generate app-config.js for production
log_info "Preparing production configuration..."
if [ -f "$PROJECT_ROOT/.env" ]; then
  node "$SCRIPT_DIR/prepare-app-config.js"
else
  log_warn "No .env file found. Creating placeholder app-config.js..."
  mkdir -p "$PROJECT_ROOT/src"
  cat > "$PROJECT_ROOT/src/app-config.js" << 'APPCONFIG'
// Auto-generated placeholder - no .env file was present at build time
module.exports = {
  API_ENDPOINT_URL: "",
  CLIENT_API_KEY: "",
  CLIENT_SHARED_SECRET: ""
};
APPCONFIG
  log_warn "App-config.js created with empty values. API features will not work."
fi

# Handle skip-rebuild flag
if [ "$SKIP_REBUILD" = true ]; then
  EXTRA_ARGS="-c.npmRebuild=false"
  log_warn "Skipping native module rebuild (--skip-rebuild)."
  log_warn "Native modules must be pre-built or this build may not work at runtime."
fi

# Run the build
log_info "Starting electron-builder..."

case "$BUILD_TARGET" in
  linux)
    log_info "Building for Linux..."
    npx electron-builder --linux --x64 --publish=never $EXTRA_ARGS
    ;;
  win)
    log_info "Building for Windows (cross-compile)..."
    npx electron-builder --win --x64 --publish=never $EXTRA_ARGS
    ;;
  all)
    log_info "Building for all platforms..."
    npx electron-builder --linux --win --x64 --publish=never $EXTRA_ARGS
    ;;
  *)
    log_info "Building for current platform..."
    npx electron-builder --publish=never $EXTRA_ARGS
    ;;
esac

# Report results
log_info "============================================================"
log_info "Build complete! Output files:"
log_info "============================================================"

if [ -d "$DIST_DIR" ]; then
  find "$DIST_DIR" -maxdepth 1 -type f \( -name "*.exe" -o -name "*.AppImage" -o -name "*.deb" -o -name "*.tar.gz" -o -name "*.snap" \) | while read -r file; do
    size=$(du -sh "$file" | cut -f1)
    log_info "  $size  $(basename "$file")"
  done
else
  log_warn "No dist/ directory found. Build may have failed."
fi
