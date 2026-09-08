#!/usr/bin/env bash
# 02-all-packages.sh - Consolidated package installation (all groups in one run)
# Dispatches to the distro-specific sdata/<dist>-dist script; replaces separate
# core/shell/themes/utils installs to avoid redundant repository syncs.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib/log.sh"
BUNDLE_DIR="${BUNDLE_DIR:?BUNDLE_DIR not set}"
export PACKAGE_GROUP="all"
if [[ "${BASE_DISTRO:-}" == "arch" ]]; then
    bash "$BUNDLE_DIR/sdata/arch-dist/installDP.sh"
elif [[ "${BASE_DISTRO:-}" == "fedora" ]]; then
    bash "$BUNDLE_DIR/sdata/fedora-dist/installDP_fedora.sh"
elif [[ "${BASE_DISTRO:-}" == "debian" ]]; then
    bash "$BUNDLE_DIR/sdata/debian-dist/installDP_debian.sh"
elif [[ "${BASE_DISTRO:-}" == "void" ]]; then
    bash "$BUNDLE_DIR/sdata/void-dist/installDP_void.sh"
else
<<<<<<< HEAD
    echo "[ERR] BASE_DISTRO must be 'arch', 'fedora', 'debian', or 'void' (got '${BASE_DISTRO:-unset}')" >&2
    exit 1
=======
    die "BASE_DISTRO must be 'arch', 'fedora', or 'debian' (got '${BASE_DISTRO:-unset}')"
>>>>>>> upstream/main
fi
