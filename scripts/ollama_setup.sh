#!/bin/bash

# Strict mode, as required of everything under scripts/.
#
# pipefail is the one that changes behaviour here: the Ollama installer is
# fetched with `curl | sh`, and without it a failed download pipes nothing into
# a shell that exits 0 quite happily. The script would then carry on to enable a
# service for a package that was never installed, and die there instead, with an
# error pointing at the wrong step.
set -euo pipefail

# Harmonious HSL colors for elegant premium styling output
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

section() {
    local title="$1"
    echo -e "\n${BLUE}===================================================${NC}"
    echo -e "${BLUE} ${title}${NC}"
    echo -e "${BLUE}===================================================${NC}"
}

section "Ollama AI Setup for Caelestia"

# 1. Install Ollama
section "Step 1/4 - Install Ollama"
curl -fsSL https://ollama.com/install.sh | sh  # ci:allow-curl-pipe

# 2. Enable and start the Ollama daemon
section "Step 2/4 - Enable and Start Ollama Daemon"

# The upstream ollama installer only knows how to register a systemd unit, so
# on runit systems (Void Linux) we create the service ourselves following the
# Void conventions: service directory under /etc/sv, enabled via a symlink in
# /var/service.
if command -v systemctl >/dev/null 2>&1 && [ -d /run/systemd/system ]; then
    sudo systemctl enable --now ollama
    echo -e "${GREEN}Ollama daemon is now running in the background (systemd).${NC}"
elif command -v sv >/dev/null 2>&1 && [ -d /etc/sv ]; then
    echo -e "${YELLOW}systemd not found; setting up a runit service for ollama...${NC}"

    OLLAMA_BIN="$(command -v ollama || true)"
    if [ -z "$OLLAMA_BIN" ] && [ -x /usr/local/bin/ollama ]; then
        OLLAMA_BIN="/usr/local/bin/ollama"
    fi
    if [ -z "$OLLAMA_BIN" ]; then
        echo -e "${RED}ollama binary not found; the upstream install must have failed.${NC}"
        exit 1
    fi

    # Dedicated system user (matches what the upstream systemd unit does).
    if ! id ollama >/dev/null 2>&1; then
        sudo useradd -r -s /usr/sbin/nologin -U -m -d /usr/share/ollama ollama 2>/dev/null || true
    fi

    # GPU access groups when present (mirrors the upstream installer intent).
    for grp in render video; do
        if getent group "$grp" >/dev/null 2>&1; then
            sudo usermod -aG "$grp" ollama 2>/dev/null || true
        fi
    done

    sudo mkdir -p /etc/sv/ollama
    # HOME is set explicitly: chpst switches uid/gid but keeps the caller's
    # environment, and ollama stores its models under $HOME/.ollama — running
    # as root's HOME would dump multi-GB models somewhere unexpected.
    sudo tee /etc/sv/ollama/run > /dev/null << EOF
#!/bin/sh
exec 2>&1
export HOME=/usr/share/ollama
exec chpst -u ollama:ollama "$OLLAMA_BIN" serve
EOF
    sudo chmod +x /etc/sv/ollama/run

    # Enable: symlink into the live service directory and start it.
    # ln -sfn refuses to overwrite a pre-existing *directory*, so remove any
    # stale entry first (covers partial previous installs).
    if [ -d /var/service ]; then
        if [ -L /var/service/ollama ] || [ -d /var/service/ollama ]; then
            sudo rm -rf /var/service/ollama
        fi
        sudo ln -s /etc/sv/ollama /var/service/ollama
    fi
    sudo sv start ollama 2>/dev/null || true
    echo -e "${GREEN}Ollama runit service enabled and started (/etc/sv/ollama).${NC}"
else
    echo -e "${YELLOW}No systemd or runit found; start ollama manually with: ollama serve${NC}"
fi

# 3. Prompt user to download models
section "Step 3/4 - Model Selection"
echo -e "Caelestia's AI Assistant requires at least one model. Here are some popular options:"
echo -e "  1) llama3  (Meta's highly capable model, ~4.7GB)"
echo -e "  2) phi3    (Microsoft's lightweight and fast model, ~2.3GB)"
echo -e "  3) gemma   (Google's lightweight model, ~5.2GB)"
echo -e "  4) mistral (Solid all-rounder model, ~4.1GB)"
echo -e "  5) All of the above"
echo -e "  6) Skip for now"

read -p "Select models to download [1-6]: " MODEL_CHOICE

pull_model() {
    echo -e "${BLUE}Pulling $1...${NC}"
    ollama pull "$1"
}

case $MODEL_CHOICE in
    1) pull_model "llama3" ;;
    2) pull_model "phi3" ;;
    3) pull_model "gemma" ;;
    4) pull_model "mistral" ;;
    5) 
        pull_model "llama3"
        pull_model "phi3"
        pull_model "gemma"
        pull_model "mistral"
        ;;
    6) echo -e "${YELLOW}Skipping model download. You can download models later using 'ollama pull <model>'.${NC}" ;;
    *) echo -e "${RED}Invalid selection. Skipping model download.${NC}" ;;
esac

# 4. Final configuration and setup
section "Step 4/4 - Finalize Setup"
echo -e "Setting up autostart for Ollama with Caelestia Shell."
# Note: The service (systemd unit on Arch/Fedora/Debian, runit service on
# Void) is enabled system-wide and starts automatically on boot.

echo -e "\n${GREEN}===================================================${NC}"
echo -e "${GREEN}          Ollama Setup Completed Successfully!      ${NC}"
echo -e "${GREEN}===================================================${NC}"
echo -e "Caelestia's AI assistant is now ready to use."
echo -e "Open the sidebar in the shell and start chatting!"
echo -e "${GREEN}===================================================${NC}"
