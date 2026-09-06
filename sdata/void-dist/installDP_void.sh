#!/usr/bin/env bash
# installDP_void.sh - Void Linux (XBPS/runit) package installation for Caelestia KDE Port

set -uo pipefail

log()  { echo -e "\033[0;36m[INFO]\033[0m $*"; }
err()  { echo -e "\033[0;31m[ERR]\033[0m  $*"; }

log "Installing Void Linux packages..."

INSTALL_FISH="${INSTALL_FISH:-true}"
INSTALL_PAPIRUS="${INSTALL_PAPIRUS:-true}"
INSTALL_DARKLY="${INSTALL_DARKLY:-true}"

if ! command -v xbps-install >/dev/null 2>&1; then
    err "xbps-install not found. This script only runs on Void Linux."
    exit 1
fi

# Core dependencies split by group — controlled via PACKAGE_GROUP env var
PACKAGE_GROUP="${PACKAGE_GROUP:-all}"

# Package names verified against void-packages (srcpkgs listing).
CORE_PACKAGES=(
    base-devel cmake ninja ccache rsync xz unzip
    wl-clipboard cliphist wl-clip-persist inotify-tools wireplumber trash-cli jq yq
    aubio-devel lm_sensors libsensors-devel
    pipewire pipewire-devel glibc
    qt6-base-devel qt6-base-private-devel qt6-declarative-devel qt6-wayland qt6-wayland-devel
    qt6-svg-devel qt6-shadertools-devel qt6-tools qt6-multimedia
    kpipewire-devel kf6-kglobalaccel-devel kf6-kwindowsystem-devel kf6-networkmanager-qt-devel
    kf6-kguiaddons-devel kf6-kconfig-devel libX11-devel
    extra-cmake-modules kf6-kcoreaddons-devel kwin-devel
    kglobalacceld kde-cli-tools
    libsecret-devel libqalculate-devel qalculate Vulkan-Headers
    ffmpeg ffmpeg-devel
    python3 python3-pip python3-devel
)

SHELL_PACKAGES=(
    quickshell foot eza fastfetch starship btop bash
)

THEME_PACKAGES=(
    noto-fonts-ttf noto-fonts-cjk noto-fonts-emoji
)

UTILITY_PACKAGES=(
    fuzzel swappy ddcutil NetworkManager ImageMagick tesseract-ocr tesseract-ocr-eng
    spectacle gpu-screen-recorder slurp grim xdg-utils sassc bat ripgrep lazygit xdg-user-dirs uv
)

# Packages with no Void repo binary — handled by manual source build / download
# in the fallback section below:
#   app2unit (not packaged), libcava (Void ships upstream cava, not LukashonakV),
#   adw-gtk3 (not packaged), darkly (not packaged), caelestia-cli (not packaged),
#   ydotool (not packaged)

# Build final package list based on selected group
PACKAGES=()
case "$PACKAGE_GROUP" in
    core)   PACKAGES=("${CORE_PACKAGES[@]}") ;;
    shell)  PACKAGES=("${SHELL_PACKAGES[@]}") ;;
    themes) PACKAGES=("${THEME_PACKAGES[@]}") ;;
    utils)  PACKAGES=("${UTILITY_PACKAGES[@]}") ;;
    all|*)  PACKAGES=("${CORE_PACKAGES[@]}" "${SHELL_PACKAGES[@]}" "${THEME_PACKAGES[@]}" "${UTILITY_PACKAGES[@]}") ;;
esac

if [[ "$PACKAGE_GROUP" == "all" || "$PACKAGE_GROUP" == "shell" ]]; then
    if [[ "$INSTALL_FISH" == "true" ]]; then
        PACKAGES+=(fish-shell)
    else
        log "Skipping Fish installation by user choice."
    fi
fi

if [[ "$PACKAGE_GROUP" == "all" || "$PACKAGE_GROUP" == "themes" ]]; then
    if [[ "$INSTALL_PAPIRUS" == "true" ]]; then
        PACKAGES+=(papirus-icon-theme)
    else
        log "Skipping Papirus icon theme installation by user choice."
    fi
fi

log "Syncing XBPS repository data..."
sudo xbps-install -S || log "xbps sync reported issues; continuing anyway."

log "Installing packages via xbps (group: $PACKAGE_GROUP)..."

FAILED_PKGS=()

# Batch install; xbps resolves everything atomically, so a single bad package
# name aborts the whole batch — on failure retry one-by-one and log the bad ones.
if ! sudo xbps-install -y "${PACKAGES[@]}"; then
    log "Batch install had failures. Retrying individually..."
    for pkg in "${PACKAGES[@]}"; do
        if xbps-query -p pkgver "$pkg" >/dev/null 2>&1; then
            continue
        fi
        if ! sudo xbps-install -y "$pkg"; then
            err "xbps failed to install $pkg"
            FAILED_PKGS+=("$pkg")
        fi
    done
fi

# ---------------------------------------------------------------------------
# Source-build / download fallbacks for packages missing from Void repos
# ---------------------------------------------------------------------------

# Compile a project from its upstream git repo using whatever build system it
# ships (meson > cmake > autotools > plain makefile).
build_from_source() {
    local pkg="$1" repo="$2" tmpdir
    shift 2
    local extra_cmake_args=("$@")
    tmpdir="$(mktemp -d)"
    if ! git clone --depth 1 "$repo" "$tmpdir"; then
        err "Failed to clone source for $pkg from $repo."
        rm -rf "$tmpdir"
        return 1
    fi
    (
        cd "$tmpdir" || exit 1
        if [ -f "meson.build" ]; then
            meson setup build && meson compile -C build && sudo meson install -C build
        elif [ -f "CMakeLists.txt" ]; then
            cmake -B build "${extra_cmake_args[@]}" && cmake --build build && sudo cmake --install build
        elif [ -x "autogen.sh" ] || [ -f "configure.ac" ] || [ -f "configure" ]; then
            if [ -x "autogen.sh" ]; then ./autogen.sh; fi
            ./configure && make && sudo make install
        elif [ -f "Makefile" ] || [ -f "makefile" ] || [ -f "GNUmakefile" ]; then
            make && sudo make install
        else
            err "No recognized build system for $pkg; skipping source build."
            exit 1
        fi
    ) || {
        err "Manual build for $pkg failed."
        rm -rf "$tmpdir"
        return 1
    }
    rm -rf "$tmpdir"
    return 0
}

# app2unit — launcher helper (plain shell script installed by make)
if [[ "$PACKAGE_GROUP" == "all" || "$PACKAGE_GROUP" == "core" ]]; then
    if ! command -v app2unit >/dev/null 2>&1; then
        log "app2unit is not packaged on Void; building from source..."
        tmpdir="$(mktemp -d)"
        if git clone --depth 1 https://github.com/Vladimir-csp/app2unit "$tmpdir"; then
            ( cd "$tmpdir" && sudo make install ) || { err "Manual build for app2unit failed."; FAILED_PKGS+=("app2unit"); }
        else
            err "Failed to clone app2unit."
            FAILED_PKGS+=("app2unit")
        fi
        rm -rf "$tmpdir"
    fi

    # libcava (custom fork used for the audio visualizer; Void's `cava`
    # package is the upstream terminal visualizer, not this fork)
    if ! pkg-config --exists libcava 2>/dev/null && [ ! -e /usr/lib/libcava.so ] && [ ! -e /usr/lib64/libcava.so ] && [ ! -e /usr/local/lib/libcava.so ]; then
        log "libcava is not packaged on Void; building LukashonakV/cava from source..."
        sudo xbps-install -y fftw-devel alsa-lib-devel pulseaudio-devel iniparser-devel meson cmake gcc || true
        if ! build_from_source "libcava" "https://github.com/LukashonakV/cava"; then
            FAILED_PKGS+=("libcava")
        fi
    fi

    # ydotool (uinput key injection used by the on-screen keyboard path)
    if ! command -v ydotoold >/dev/null 2>&1; then
        log "ydotool is not packaged on Void; building from source..."
        sudo xbps-install -y cmake make base-devel || true
        if ! build_from_source "ydotool" "https://github.com/ReimuNotMoe/ydotool" -DBUILD_DOCS=OFF -DSYSTEMD_USER_SERVICE=OFF -DSYSTEMD_SYSTEM_SERVICE=OFF; then
            log "ydotool build failed. On-screen keyboard key injection will be unavailable."
            FAILED_PKGS+=("ydotool")
        fi
    fi
fi

# ---------------------------------------------------------------------------
# Fonts + adw-gtk3 + Darkly (theme group)
# ---------------------------------------------------------------------------
if [[ "$PACKAGE_GROUP" == "all" || "$PACKAGE_GROUP" == "themes" ]]; then

log "Downloading and installing required custom fonts (parallel)..."
mkdir -p "${XDG_DATA_HOME:-$HOME/.local/share}/fonts"

curl -sL "https://github.com/google/material-design-icons/raw/master/variablefont/MaterialSymbolsRounded%5BFILL%2CGRAD%2Copsz%2Cwght%5D.ttf" -o "${XDG_DATA_HOME:-$HOME/.local/share}/fonts/MaterialSymbolsRounded.ttf" &
_pid_ms=$!

curl -sL "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.0.2/CascadiaCode.zip" -o "/tmp/CascadiaCode.zip" &
_pid_cc=$!

curl -sL "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.0.2/JetBrainsMono.zip" -o "/tmp/JetBrainsMono.zip" &
_pid_jb=$!

curl -sL "https://github.com/google/fonts/raw/main/ofl/rubik/Rubik-VariableFont_wght.ttf" -o "${XDG_DATA_HOME:-$HOME/.local/share}/fonts/Rubik-VariableFont_wght.ttf" &
_pid_ru=$!

wait $_pid_ms $_pid_cc $_pid_jb $_pid_ru

sudo xbps-install -y unzip >/dev/null 2>&1 || true
unzip -qo "/tmp/CascadiaCode.zip" -d "${XDG_DATA_HOME:-$HOME/.local/share}/fonts" 2>/dev/null && rm -f "/tmp/CascadiaCode.zip" || { err "Failed to extract CascadiaCode font."; echo "CascadiaCode font" >> "${XDG_CACHE_HOME:-$HOME/.cache}/caelestia-kde/failed_packages.txt"; }
unzip -qo "/tmp/JetBrainsMono.zip" -d "${XDG_DATA_HOME:-$HOME/.local/share}/fonts" 2>/dev/null && rm -f "/tmp/JetBrainsMono.zip" || { err "Failed to extract JetBrains Mono Nerd Font."; echo "JetBrains Mono Nerd Font" >> "${XDG_CACHE_HOME:-$HOME/.cache}/caelestia-kde/failed_packages.txt"; }
# Material Symbols and Rubik are single .ttf files, no extraction needed
[[ -f "${XDG_DATA_HOME:-$HOME/.local/share}/fonts/MaterialSymbolsRounded.ttf" ]] || { err "Failed to download Material Symbols font."; echo "Material Symbols font" >> "${XDG_CACHE_HOME:-$HOME/.cache}/caelestia-kde/failed_packages.txt"; }
[[ -f "${XDG_DATA_HOME:-$HOME/.local/share}/fonts/Rubik-VariableFont_wght.ttf" ]] || { err "Failed to download Rubik font."; echo "Rubik font" >> "${XDG_CACHE_HOME:-$HOME/.cache}/caelestia-kde/failed_packages.txt"; }

fc-cache -f || true

# adw-gtk3 is not packaged on Void — install from the upstream release tarball.
if [[ ! -d "${XDG_DATA_HOME:-$HOME/.local/share}/themes/adw-gtk3" ]] && [[ ! -d "$HOME/.themes/adw-gtk3" ]]; then
    log "adw-gtk3 is not packaged on Void; installing from upstream release..."
    tmpdir="$(mktemp -d)"
    if curl -sL "https://github.com/lassekongo83/adw-gtk3/releases/download/v5.3/adw-gtk3v5.3.tar.xz" | tar -xJ -C "$tmpdir"; then
        mkdir -p "${XDG_DATA_HOME:-$HOME/.local/share}/themes"
        cp -r "$tmpdir/adw-gtk3" "$tmpdir/adw-gtk3-dark" "${XDG_DATA_HOME:-$HOME/.local/share}/themes/" || { err "Failed to install adw-gtk3"; FAILED_PKGS+=("adw-gtk3"); }
    else
        err "Failed to download adw-gtk3 theme."
        FAILED_PKGS+=("adw-gtk3")
    fi
    rm -rf "$tmpdir"
fi

log "Building and Installing Darkly KDE Theme..."
if [[ "$INSTALL_DARKLY" == "true" ]]; then
    if ! command -v darkly >/dev/null 2>&1; then
        tmpdir="$(mktemp -d)"
        sudo xbps-install -y cmake ninja extra-cmake-modules gettext \
            qt6-base-devel qt6-declarative-devel \
            kf6-kconfig-devel kf6-kconfigwidgets-devel kf6-kcoreaddons-devel \
            kf6-kguiaddons-devel kf6-ki18n-devel kf6-kiconthemes-devel \
            kf6-kio-devel kf6-kwidgetsaddons-devel kf6-kwindowsystem-devel \
            kf6-kcolorscheme-devel kf6-kcmutils-devel kf6-kirigami-devel \
            kf6-kdecoration-devel || true
        if git clone --depth 1 https://github.com/Bali10050/Darkly "$tmpdir"; then
            (
                cd "$tmpdir" || exit 1
                cmake -B build -DCMAKE_BUILD_TYPE=Release -DBUILD_QT5=OFF && cmake --build build -j"$(nproc)" && cd build && sudo cmake --install .
            ) || err "Failed to build Darkly theme from source."
        fi
        rm -rf "$tmpdir"
    fi
else
    log "Skipping Darkly package installation by user choice."
fi

fi  # end of PACKAGE_GROUP themes/all block

# ---------------------------------------------------------------------------
# Shell extras (fish handled above); caelestia-cli wrapper
# ---------------------------------------------------------------------------
if [[ "$PACKAGE_GROUP" == "all" || "$PACKAGE_GROUP" == "shell" ]]; then

log "Installing Caelestia CLI wrapper..."
if ! command -v caelestia >/dev/null 2>&1; then
    sudo xbps-install -y python3-pip python3-virtualenv || true
    tmpdir="$(mktemp -d)"
    (
        cd "$tmpdir" || exit 1
        curl -sL "https://github.com/caelestia-dots/cli/releases/download/v1.0.8/caelestia-1.0.8.tar.gz" -o caelestia.tar.gz
        tar -xzf caelestia.tar.gz
        cd caelestia-1.0.8 || exit 1
        # uv is installed from the Void repos (UTILITY_PACKAGES); it builds the
        # wheel in an isolated environment so no system python3-hatchling etc.
        # are required. pip with build isolation is the fallback.
        if command -v uv >/dev/null 2>&1; then
            uv tool install . || exit 1
        else
            pip3 install --user . || sudo pip3 install . || exit 1
        fi

        # Install fish completions if fish is present
        mkdir -p ~/.config/fish/completions/
        cp ./completions/caelestia.fish ~/.config/fish/completions/ 2>/dev/null || true
    ) || err "Failed to install caelestia-cli."
    rm -rf "$tmpdir"
fi

fi  # end of PACKAGE_GROUP shell/all block

if [ ${#FAILED_PKGS[@]} -ne 0 ]; then
    mkdir -p "${XDG_CACHE_HOME:-$HOME/.cache}/caelestia-kde"
    err "The following packages could not be installed:"
    for pkg in "${FAILED_PKGS[@]}"; do
        err "  - $pkg"
        echo "$pkg" >> "${XDG_CACHE_HOME:-$HOME/.cache}/caelestia-kde/failed_packages.txt"
    done
fi

if command -v xdg-user-dirs-update >/dev/null 2>&1; then
    xdg-user-dirs-update || true
fi

if command -v sassc >/dev/null 2>&1 && ! command -v sass >/dev/null 2>&1; then
    sudo ln -sf /usr/bin/sassc /usr/local/bin/sass || true
fi

log "Void package installation complete."
