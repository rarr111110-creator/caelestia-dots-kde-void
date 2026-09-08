#!/usr/bin/env bash
# 02a-submodules.sh - Initialize git submodules

set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib/log.sh"

# Initialize submodules
if [[ -f "$BUNDLE_DIR/.gitmodules" ]]; then
    info "Initializing submodules..."
    git submodule sync --recursive >/dev/null 2>&1 || true
    git submodule update --init --recursive --depth 1 --jobs "$(nproc 2>/dev/null || echo 1)" >/dev/null 2>&1 || warn "Failed to initialize all submodules."
fi