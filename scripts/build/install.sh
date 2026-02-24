#!/usr/bin/env bash
# ============================================================
# install.sh - Install dependencies for Ability Draft Plus
#
# Handles npm install, native module rebuild, and tfjs fixes.
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

# Install npm dependencies
log_info "Installing npm dependencies..."
npm install --no-optional 2>&1 || {
  log_warn "npm install with --no-optional failed, trying standard install..."
  npm install 2>&1
}

# Rebuild native modules for Electron
log_info "Rebuilding native modules for Electron..."
npx electron-rebuild -f 2>&1 || {
  log_warn "electron-rebuild failed. Native modules may not work correctly."
  log_warn "Ensure build tools are installed (python3, make, g++)."
}

# Apply TensorFlow.js fix
log_info "Applying TensorFlow.js build fix..."
node "$SCRIPT_DIR/fix-tfjs-node-build.js" 2>&1 || {
  log_warn "TensorFlow.js fix failed. ML features may not work."
}

log_info "============================================================"
log_info "Installation complete!"
log_info "============================================================"
log_info ""
log_info "Next steps:"
log_info "  npm start         # Run the app"
log_info "  npm run dev       # Run with hot reload"
log_info "  npm run dev:debug # Run with debug + hot reload"
