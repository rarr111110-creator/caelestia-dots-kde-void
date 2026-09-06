#!/usr/bin/env bash
# 06-services.sh  Enable background services and reload KWin.
#
# systemd distros (Arch/Fedora/Debian) get systemd user units.
# Void Linux (runit) gets XDG autostart entries instead — runit has no user
# service manager of its own, and autostart is the native KDE mechanism.

set -euo pipefail

echo
echo ""
echo "  Step 6/11  Services & KWin"
echo ""

has_systemd() {
    command -v systemctl >/dev/null 2>&1 && [[ -d /run/systemd/system ]]
}

if has_systemd; then
    if systemctl --user is-enabled --quiet qs-kwin-bridge.service 2>/dev/null || \
       systemctl --user is-active --quiet qs-kwin-bridge.service 2>/dev/null; then
        echo "  Disabling legacy qs-kwin-bridge service..."
        systemctl --user disable --now qs-kwin-bridge.service 2>/dev/null || true
    fi
fi

echo "  Clearing legacy KWin workspace shortcuts to avoid QML conflicts..."
for i in $(seq 1 10); do
    kwriteconfig6 --file kglobalshortcutsrc --group "kwin" --key "Switch to Desktop $i" "none,none,Switch to Desktop $i"
    kwriteconfig6 --file kglobalshortcutsrc --group "kwin" --key "Window to Desktop $i" "none,none,Move Window to Desktop $i"
done

echo "  Disabling legacy quickshell-kde-bridge KWin script..."
kwriteconfig6 --file kwinrc --group "Plugins" --key "quickshell-kde-bridgeEnabled" "false"

echo "  Setting default KWin virtual desktops to 5 (only if not already configured)..."
EXISTING_DESKTOPS="$(kreadconfig6 --file kwinrc --group "Desktops" --key "Number" 2>/dev/null || true)"
if [ -z "$EXISTING_DESKTOPS" ]; then
    kwriteconfig6 --file kwinrc --group "Desktops" --key "Number" "5"
    kwriteconfig6 --file kwinrc --group "Desktops" --key "Rows" "1"
    for i in $(seq 1 5); do
        kwriteconfig6 --file kwinrc --group "Desktops" --key "Name_$i" "Desktop $i"
    done
else
    echo "  Existing virtual desktop configuration found - leaving it untouched."
fi

#  ydotoold (on-screen keyboard key injection)
# ydotoold needs access to /dev/uinput. Add a udev rule to allow the 'input'
# group to access it, then add the user to that group.
echo "  Applying system-level configurations (requires root)..."
sudo bash -s -- "$USER" << 'EOF'
TARGET_USER="$1"

has_systemd() {
    command -v systemctl >/dev/null 2>&1 && [[ -d /run/systemd/system ]]
}

if has_systemd; then
    if systemctl is-enabled --quiet keyd.service 2>/dev/null || \
       systemctl is-active --quiet keyd.service 2>/dev/null; then
        echo "  Disabling legacy keyd service..."
        systemctl disable --now keyd.service 2>/dev/null || true
    fi
elif [[ -d /run/runit/service || -d /var/service ]]; then
    # runit (Void): disabling a service means removing the symlink from the
    # service directory (/var/service, or /run/runit/service on newer setups).
    for _svdir in /var/service /run/runit/service; do
        if [[ -L "$_svdir/keyd" ]]; then
            echo "  Disabling legacy keyd runit service..."
            rm -f "$_svdir/keyd" || true
        fi
    done
fi

echo "  Setting up ydotoold (OSK key injection daemon)..."

if [[ ! -f /etc/udev/rules.d/80-uinput.rules ]]; then
    echo 'KERNEL=="uinput", GROUP="input", MODE="0660"' > /etc/udev/rules.d/80-uinput.rules
    udevadm control --reload-rules 2>/dev/null || true
    udevadm trigger 2>/dev/null || true
    echo "  [OK]  udev rule for uinput created."
fi

if ! groups "$TARGET_USER" | grep -q '\binput\b'; then
    usermod -aG input "$TARGET_USER"
    echo "  [OK]  Added $TARGET_USER to 'input' group (takes effect on next login)."
else
    echo "  [OK]  $TARGET_USER already in 'input' group."
fi

if [[ -e /dev/uinput ]]; then
    UINPUT_PERMS=$(stat -c "%a" /dev/uinput 2>/dev/null)
    UINPUT_GROUP=$(stat -c "%G" /dev/uinput 2>/dev/null)
    if [[ "$UINPUT_PERMS" != *"660" ]] || [[ "$UINPUT_GROUP" != "input" ]]; then
        chmod 660 /dev/uinput 2>/dev/null || true
        chgrp input /dev/uinput 2>/dev/null || true
    fi
fi

# Load the uinput module on boot (the udev rule only helps if the module is up).
if [[ ! -e /dev/uinput ]]; then
    modprobe uinput 2>/dev/null || true
fi
if ! grep -qs '^uinput$' /etc/modules-load.d/uinput.conf 2>/dev/null; then
    mkdir -p /etc/modules-load.d
    echo 'uinput' > /etc/modules-load.d/uinput.conf
fi
EOF

if ! command -v ydotoold >/dev/null 2>&1; then
    echo "  [WARN] ydotoold is not installed - skipping daemon setup."
    echo "         On Void it is built from source by sdata/void-dist/installDP_void.sh."
fi

# Deploy ydotoold-wrapper script to ~/.local/bin
mkdir -p "$HOME/.local/bin"
cat > "$HOME/.local/bin/ydotoold-wrapper" << 'WRAPPER'
#!/bin/bash
# ydotoold-wrapper  starts ydotoold with uinput access (user is in 'input' group)
SOCKET="${YDOTOOL_SOCKET:-/run/user/$(id -u)/.ydotool_socket}"
if [ -S "$SOCKET" ] && pidof ydotoold > /dev/null 2>&1; then
    exit 0
fi
# Resolve the binary at runtime: package installs land in /usr/bin, source
# builds (e.g. Void, where ydotool is not packaged) land in /usr/local/bin.
YDOTOOLD_BIN="$(command -v ydotoold 2>/dev/null || echo /usr/bin/ydotoold)"
exec "$YDOTOOLD_BIN" \
    --socket-path="$SOCKET" \
    --socket-perm=0660
WRAPPER
chmod +x "$HOME/.local/bin/ydotoold-wrapper"
echo "  [OK]  ydotoold-wrapper deployed to ~/.local/bin."

if command -v ydotoold >/dev/null 2>&1; then
    if has_systemd; then
        # systemd distros: user unit
        mkdir -p "$HOME/.config/systemd/user"
        cat > "$HOME/.config/systemd/user/ydotoold.service" << 'UNIT'
[Unit]
Description=ydotoold key injection daemon
After=graphical-session.target
PartOf=graphical-session.target

[Service]
Type=simple
ExecStart=%h/.local/bin/ydotoold-wrapper
Restart=on-failure
Environment=YDOTOOL_SOCKET=/run/user/%U/.ydotool_socket

[Install]
WantedBy=graphical-session.target
UNIT
        systemctl --user daemon-reload
        systemctl --user enable ydotoold.service 2>/dev/null || true
        systemctl --user start ydotoold.service 2>/dev/null || \
            echo "  [INFO] ydotoold will start on next login."
        echo "  [OK]  ydotoold service configured (systemd)."
    else
        # runit (Void) and other non-systemd distros: XDG autostart entry.
        mkdir -p "$HOME/.config/autostart"
        cat > "$HOME/.config/autostart/ydotoold.desktop" << EOF
[Desktop Entry]
Type=Application
Name=ydotoold key injection daemon
Comment=Starts ydotoold for on-screen keyboard key injection
Exec=$HOME/.local/bin/ydotoold-wrapper
Terminal=false
Hidden=false
X-GNOME-Autostart-enabled=true
EOF
        echo "  [OK]  ydotoold daemon configured (autostart entry)."
        # Start it now for the current session, if possible.
        nohup "$HOME/.local/bin/ydotoold-wrapper" >/dev/null 2>&1 & disown || true
    fi
fi

echo "[OK]  Services configured."
