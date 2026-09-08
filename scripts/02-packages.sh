#!/usr/bin/env bash
# 02-packages.sh - Ensure Python tooling for konsave backups
# (Package groups are installed by the individual 02-*-packages.sh scripts)

set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib/log.sh"
source "$(dirname "${BASH_SOURCE[0]}")/lib/privileges.sh"

BUNDLE_DIR="${BUNDLE_DIR:?BUNDLE_DIR not set}"

echo

info "Ensuring Python tooling for konsave backups"
if ! command -v python3 >/dev/null 2>&1 || ! python3 -m pip --version >/dev/null 2>&1; then
    package_distro="${BASE_DISTRO:-}"
    if [[ -z "$package_distro" ]]; then
        if command -v pacman >/dev/null 2>&1; then
            package_distro="arch"
        elif command -v dnf >/dev/null 2>&1; then
            package_distro="fedora"
        elif command -v apt-get >/dev/null 2>&1; then
            package_distro="debian"
        elif command -v xbps-install >/dev/null 2>&1; then
            package_distro="void"
        fi
    fi

    if [[ "$package_distro" == "arch" ]]; then
        caelestia_sudo pacman -S --needed --noconfirm python python-pip
    elif [[ "$package_distro" == "fedora" ]]; then
        caelestia_sudo dnf install -y python3 python3-pip
    elif [[ "$package_distro" == "debian" ]]; then
<<<<<<< HEAD
        sudo apt-get update && sudo apt-get install -y python3 python3-pip python3-venv
    elif [[ "$package_distro" == "void" ]]; then
        sudo xbps-install -y python3 python3-pip python3-virtualenv
=======
        caelestia_sudo apt-get update && caelestia_sudo apt-get install -y python3 python3-pip python3-venv
>>>>>>> upstream/main
    else
        warn "Could not determine the distro for Python tooling installation."
    fi
fi

echo
ok "Package installation complete."
