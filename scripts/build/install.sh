#!/usr/bin/env bash
# ============================================================
# install.sh - Install dependencies for Ability Draft Plus
#
# Handles npm install, native module rebuild, and tfjs fixes.
# Uses --ignore-scripts to avoid postinstall failures with native
# modules, then rebuilds them individually.
#
# Usage:
#   ./scripts/build/install.sh          # Full install
#   ./scripts/build/install.sh --clean  # Clean install (removes node_modules)
# ============================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info()  { echo -e "${GREEN}[INSTALL]${NC} $*"; }
log_warn()  { echo -e "${YELLOW}[INSTALL]${NC} $*"; }
log_error() { echo -e "${RED}[INSTALL]${NC} $*" >&2; }

CLEAN_INSTALL=false
for arg in "$@"; do
  case "$arg" in
    --clean) CLEAN_INSTALL=true ;;
    --help|-h)
      echo "Usage: $0 [--clean]"
      echo ""
      echo "Options:"
      echo "  --clean  Remove node_modules and package-lock.json before installing"
      echo "  --help   Show this help"
      exit 0
      ;;
  esac
done

cd "$PROJECT_ROOT"

# System info
log_info "System info:"
log_info "  Node.js: $(node --version)"
log_info "  npm:     $(npm --version)"
log_info "  OS:      $(uname -s) $(uname -m)"
log_info "  Python:  $(python3 --version 2>/dev/null || echo 'not found')"

# Clean if requested
if [ "$CLEAN_INSTALL" = true ]; then
  log_info "Cleaning existing installation..."
  rm -rf "$PROJECT_ROOT/node_modules" "$PROJECT_ROOT/package-lock.json"
  log_info "Cleaned."
fi

# Step 1: Install npm dependencies (skip postinstall to avoid native module failures)
log_info "Installing npm dependencies (--ignore-scripts)..."
npm install --ignore-scripts 2>&1
log_info "Base dependencies installed."

# Step 2: Rebuild native modules individually
# better-sqlite3: build against current Node.js
log_info "Rebuilding better-sqlite3..."
if [ -d "$PROJECT_ROOT/node_modules/better-sqlite3" ]; then
  (cd "$PROJECT_ROOT/node_modules/better-sqlite3" && \
   npx --yes node-gyp rebuild --release 2>&1) && \
    log_info "  better-sqlite3 rebuilt successfully." || \
    log_warn "  better-sqlite3 rebuild failed. Database features may not work."
fi

# sharp: install prebuilt binary for current platform
log_info "Rebuilding sharp..."
if [ -d "$PROJECT_ROOT/node_modules/sharp" ]; then
  PLATFORM=$(uname -s | tr '[:upper:]' '[:lower:]')
  ARCH=$(uname -m)
  case "$ARCH" in
    x86_64) ARCH="x64" ;;
    aarch64|arm64) ARCH="arm64" ;;
  esac
  npm install "--platform=$PLATFORM" "--arch=$ARCH" sharp --ignore-scripts 2>&1 && \
    log_info "  sharp installed with prebuilt binary ($PLATFORM-$ARCH)." || \
    log_warn "  sharp install failed. Image processing may not work."
fi

# @tensorflow/tfjs-node: requires Node 18 and Electron headers
log_info "Checking @tensorflow/tfjs-node..."
if [ -d "$PROJECT_ROOT/node_modules/@tensorflow/tfjs-node" ]; then
  NODE_MAJOR=$(node -v | sed 's/v\([0-9]*\).*/\1/')
  if [ "$NODE_MAJOR" -le 20 ]; then
    log_info "  Node $NODE_MAJOR detected, attempting tfjs-node rebuild..."
    npm rebuild @tensorflow/tfjs-node --build-addon-from-source 2>&1 && \
      log_info "  tfjs-node rebuilt successfully." || \
      log_warn "  tfjs-node rebuild failed. Use Docker with Node 18 for ML features."
  else
    log_warn "  Node $NODE_MAJOR detected. @tensorflow/tfjs-node requires Node <=20."
    log_warn "  Use Docker (scripts/docker/) with Node 18 for full ML support."
    # Create placeholder so packaging doesn't fail
    mkdir -p "$PROJECT_ROOT/node_modules/@tensorflow/tfjs-node/lib/napi-v8"
    touch "$PROJECT_ROOT/node_modules/@tensorflow/tfjs-node/lib/napi-v8/tfjs_binding.node"
  fi
fi

# Step 3: Apply TensorFlow.js fix
log_info "Applying TensorFlow.js build fix..."
node "$SCRIPT_DIR/fix-tfjs-node-build.js" 2>&1 || {
  log_warn "TensorFlow.js fix had warnings (non-fatal)."
}

log_info "============================================================"
log_info "Installation complete!"
log_info "============================================================"
log_info ""
log_info "Next steps:"
log_info "  npm start                                    # Run the app"
log_info "  npm run dev                                  # Run with hot reload"
log_info "  ./scripts/build/build.sh --linux             # Build Linux packages"
log_info "  ./scripts/docker/build-in-docker.sh          # Build via Docker"
