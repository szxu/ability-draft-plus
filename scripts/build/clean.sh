#!/usr/bin/env bash
# ============================================================
# clean.sh - Clean build artifacts and caches
#
# Usage:
#   ./scripts/build/clean.sh         # Clean dist/ only
#   ./scripts/build/clean.sh --all   # Clean dist/, node_modules, and caches
# ============================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[CLEAN]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[CLEAN]${NC} $*"; }

CLEAN_ALL=false
for arg in "$@"; do
  case "$arg" in
    --all) CLEAN_ALL=true ;;
    --help|-h)
      echo "Usage: $0 [--all]"
      echo ""
      echo "Options:"
      echo "  --all   Also remove node_modules and package-lock.json"
      echo "  --help  Show this help"
      exit 0
      ;;
  esac
done

cd "$PROJECT_ROOT"

# Always clean dist
if [ -d "$PROJECT_ROOT/dist" ]; then
  log_info "Removing dist/..."
  rm -rf "$PROJECT_ROOT/dist"
fi

# Clean generated app-config
if [ -f "$PROJECT_ROOT/src/app-config.js" ]; then
  log_info "Removing generated src/app-config.js..."
  rm -f "$PROJECT_ROOT/src/app-config.js"
fi

# Clean scripts output
if [ -d "$PROJECT_ROOT/scripts/output" ]; then
  log_info "Removing scripts/output/..."
  rm -rf "$PROJECT_ROOT/scripts/output"
fi

# Clean failed samples
if [ -d "$PROJECT_ROOT/failed-samples" ]; then
  log_info "Removing failed-samples/..."
  rm -rf "$PROJECT_ROOT/failed-samples"
fi

# Full clean
if [ "$CLEAN_ALL" = true ]; then
  if [ -d "$PROJECT_ROOT/node_modules" ]; then
    log_info "Removing node_modules/..."
    rm -rf "$PROJECT_ROOT/node_modules"
  fi
  if [ -f "$PROJECT_ROOT/package-lock.json" ]; then
    log_info "Removing package-lock.json..."
    rm -f "$PROJECT_ROOT/package-lock.json"
  fi
fi

log_info "Clean complete."
