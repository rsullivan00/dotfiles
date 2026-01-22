#!/usr/bin/env bash
# Install and configure WezTerm
#
# Usage:
#   ./scripts/install_wezterm.sh           # Install wezterm + config
#   ./scripts/install_wezterm.sh --remove  # Remove config symlink
#   ./scripts/install_wezterm.sh --skip-install  # Only set up config

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
WEZTERM_SOURCE="$REPO_ROOT/config/wezterm/wezterm.lua"
WEZTERM_TARGET="$HOME/.wezterm.lua"

info() { echo -e "\033[0;36m[WezTerm]\033[0m $1"; }
ok() { echo -e "\033[0;32m[WezTerm]\033[0m $1"; }
warn() { echo -e "\033[0;33m[WezTerm]\033[0m $1"; }
err() { echo -e "\033[0;31m[WezTerm]\033[0m $1"; }

backup_and_remove() {
  local path="$1"
  if [ -e "$path" ] || [ -L "$path" ]; then
    if [ -L "$path" ]; then
      rm "$path"
      info "Removed existing symlink: $path"
    else
      local backup="${path}.$(date +%Y%m%d-%H%M%S).bak"
      mv "$path" "$backup"
      ok "Backed up existing config to: $backup"
    fi
  fi
}

# Parse arguments
REMOVE=false
SKIP_INSTALL=false
for arg in "$@"; do
  case $arg in
    --remove) REMOVE=true ;;
    --skip-install) SKIP_INSTALL=true ;;
  esac
done

if [ "$REMOVE" = true ]; then
  info "Removing WezTerm configuration..."
  if [ -L "$WEZTERM_TARGET" ]; then
    rm "$WEZTERM_TARGET"
    ok "Removed wezterm config symlink"
  elif [ -e "$WEZTERM_TARGET" ]; then
    warn "WezTerm config is not a symlink, not removing"
  else
    warn "No wezterm config found"
  fi
  exit 0
fi

# Install WezTerm
if [ "$SKIP_INSTALL" = false ]; then
  if [ -x "$(command -v apt)" ]; then
    info "Installing WezTerm via apt..."
    # WezTerm provides a repo for Debian/Ubuntu
    curl -fsSL https://apt.fury.io/wez/gpg.key | sudo gpg --yes --dearmor -o /usr/share/keyrings/wezterm-fury.gpg
    echo 'deb [signed-by=/usr/share/keyrings/wezterm-fury.gpg] https://apt.fury.io/wez/ * *' | sudo tee /etc/apt/sources.list.d/wezterm.list
    sudo apt update
    sudo apt install -y wezterm
  elif [ -x "$(command -v brew)" ]; then
    info "Installing WezTerm via Homebrew..."
    brew install --cask wezterm
  elif [ -x "$(command -v pacman)" ]; then
    info "Installing WezTerm via pacman..."
    sudo pacman -S --noconfirm wezterm
  else
    warn "No supported package manager found. Please install WezTerm manually from https://wezfurlong.org/wezterm/"
  fi
fi

# Verify source config exists
if [ ! -f "$WEZTERM_SOURCE" ]; then
  err "WezTerm config not found: $WEZTERM_SOURCE"
  exit 2
fi

# Set up WezTerm config
info "Setting up WezTerm config..."
backup_and_remove "$WEZTERM_TARGET"
ln -s "$WEZTERM_SOURCE" "$WEZTERM_TARGET"
ok "Created link: $WEZTERM_TARGET -> $WEZTERM_SOURCE"

echo ""
ok "WezTerm setup complete!"
echo ""
