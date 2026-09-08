#!/usr/bin/env bash
# 07-kde-apps.sh  Install KDE-specific applications:
#   - kvantum + kvantum-qt5 (Qt style engine for Material You look)
#   - kde-material-you-colors (AUR widget/daemon for wallpaper-adaptive colors)
#
# Idempotent: checks before installing.

set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib/log.sh"

echo
echo ""
info "Installing KDE theme applications"
echo ""

install_if_missing() {
    local pkg="$1"
    if [[ "$BASE_DISTRO" == "arch" ]]; then
        if pacman -Qi "$pkg" >/dev/null 2>&1; then
            skip "$pkg already installed."
            return 0
        fi
        info "Installing $pkg..."
        yay -S --needed ${CONFIRM_ARG:-} "$pkg" 2>/dev/null || \
        sudo pacman -S --needed ${CONFIRM_ARG:-} "$pkg" 2>/dev/null || {
            warn "Could not install $pkg, skipping."
            return 1
        }
        ok "$pkg installed."
    elif [[ "$BASE_DISTRO" == "fedora" ]]; then
        if dnf list --installed "$pkg" >/dev/null 2>&1; then
            skip "$pkg already installed."
            return 0
        fi
        info "Installing $pkg..."
        sudo dnf install -y "$pkg" 2>/dev/null || {
            warn "Could not install $pkg, skipping."
            return 1
        }
        ok "$pkg installed."
    elif [[ "$BASE_DISTRO" == "debian" ]]; then
        if dpkg -s "$pkg" >/dev/null 2>&1; then
            skip "$pkg already installed."
            return 0
        fi
        info "Installing $pkg..."
        sudo apt-get install -y "$pkg" 2>/dev/null || {
            warn "Could not install $pkg, skipping."
            return 1
        }
<<<<<<< HEAD
        echo "  [OK]  $pkg installed."
    elif [[ "$BASE_DISTRO" == "void" ]]; then
        if xbps-query -p pkgver "$pkg" >/dev/null 2>&1; then
            echo "  [SKIP] $pkg already installed."
            return 0
        fi
        echo "  Installing $pkg..."
        sudo xbps-install -y "$pkg" 2>/dev/null || {
            echo -e "  \033[0;31m[FAIL] Could not install $pkg  skipping.\033[0m"
            return 1
        }
        echo "  [OK]  $pkg installed."
=======
        ok "$pkg installed."
>>>>>>> upstream/main
    fi
}

#  Kvantum 
if [[ "${INSTALL_KVANTUM:-true}" == "true" ]]; then
    if [[ "$BASE_DISTRO" == "debian" ]]; then
        install_if_missing qt6-style-kvantum || install_if_missing kvantum
        install_if_missing qt5-style-kvantum || true
    elif [[ "$BASE_DISTRO" == "void" ]]; then
        # Void's kvantum package ships the Qt6 style plugin (there is no
        # separate kvantum-qt5 package anymore).
        install_if_missing kvantum
    else
        install_if_missing kvantum
        install_if_missing kvantum-qt5 || true   # optional qt5 support
    fi
else
    skip "Skipping Kvantum installation by user choice."
fi

#  uv (required for kde-material-you-colors on fedora) 
if ! command -v uv >/dev/null 2>&1; then
    info "Installing uv..."
 #   if [[ "$BASE_DISTRO" == "arch" ]]; then
    install_if_missing uv || curl -LsSf https://astral.sh/uv/install.sh | sh  # ci:allow-curl-pipe
    #else
     #   curl -LsSf https://astral.sh/uv/install.sh | sh
    #fi
    # Add uv to path for current session if installed via script
    export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"
fi

#  kde-material-you-colors 
if [[ "${APPLY_MATERIAL_YOU:-true}" == "true" ]]; then
    if [[ "$BASE_DISTRO" == "arch" ]]; then
        install_if_missing kde-material-you-colors
    elif [[ "$BASE_DISTRO" == "fedora" ]]; then
        if ! command -v kde-material-you-colors >/dev/null 2>&1; then
            info "Installing kde-material-you-colors via uv..."
            sudo dnf install -y dbus-devel dbus-glib-devel python3-devel
            uv tool install kde-material-you-colors >/dev/null 2>&1 || {
                warn "Could not install kde-material-you-colors, skipping."
            }
        else
            skip "kde-material-you-colors already installed."
        fi
    elif [[ "$BASE_DISTRO" == "debian" ]]; then
        if ! command -v kde-material-you-colors >/dev/null 2>&1; then
            info "Installing kde-material-you-colors via uv..."
            sudo apt-get install -y libdbus-1-dev libdbus-glib-1-dev python3-dev
            uv tool install kde-material-you-colors >/dev/null 2>&1 || {
                warn "Could not install kde-material-you-colors, skipping."
            }
        else
            skip "kde-material-you-colors already installed."
        fi
    elif [[ "$BASE_DISTRO" == "void" ]]; then
        if ! command -v kde-material-you-colors >/dev/null 2>&1; then
            echo "  Installing kde-material-you-colors via uv..."
            sudo xbps-install -y dbus-devel dbus-glib-devel python3-devel
            uv tool install kde-material-you-colors >/dev/null 2>&1 || {
                echo -e "  \033[0;31m[FAIL] Could not install kde-material-you-colors  skipping.\033[0m"
            }
        else
            echo "  [SKIP] kde-material-you-colors already installed."
        fi
    fi
else
<<<<<<< HEAD
    echo "  [SKIP] Skipping kde-material-you-colors installation. Uninstalling if present..."

    # Stop/disable the service if it exists (systemd distros only)
    if command -v systemctl >/dev/null 2>&1 && [[ -d /run/systemd/system ]]; then
        systemctl --user stop kde-material-you-colors.service 2>/dev/null || true
        systemctl --user disable kde-material-you-colors.service 2>/dev/null || true
    fi
    # Non-systemd autostart entry (Void/runit and similar)
    rm -f "$HOME/.config/autostart/kde-material-you-colors.desktop" 2>/dev/null || true

=======
    info "Skipping kde-material-you-colors installation; uninstalling if present..."
    
    # Stop the service if running
    systemctl --user stop kde-material-you-colors.service 2>/dev/null || true
    systemctl --user disable kde-material-you-colors.service 2>/dev/null || true
    
>>>>>>> upstream/main
    # Uninstall the package
    if [[ "$BASE_DISTRO" == "arch" ]]; then
        sudo pacman -Rs --noconfirm kde-material-you-colors 2>/dev/null || true
    elif [[ "$BASE_DISTRO" == "fedora" || "$BASE_DISTRO" == "debian" || "$BASE_DISTRO" == "void" ]]; then
        uv tool uninstall kde-material-you-colors 2>/dev/null || true
    fi
fi

#  darkly (plasma theme)
# (installed by the installDP.sh scripts as a prebuilt package, COPR, or AUR)

# Update plasma configuration for default look/feel if needed
    kwriteconfig6 --file plasmarc --group "Theme" --key "name" "darkly" 2>/dev/null || true

echo "[OK]  KDE extra apps step complete."
