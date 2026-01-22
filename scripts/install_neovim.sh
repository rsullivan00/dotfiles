#!/usr/bin/env bash
# Install and configure Neovim with LazyVim
#
# Usage:
#   ./scripts/install_neovim.sh           # Install neovim + config
#   ./scripts/install_neovim.sh --remove  # Remove config symlink
#   ./scripts/install_neovim.sh --skip-install  # Only set up config

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
NVIM_SOURCE="$REPO_ROOT/config/nvim-lazyvim"
NVIM_TARGET="${XDG_CONFIG_HOME:-$HOME/.config}/nvim"

info() { echo -e "\033[0;36m[Neovim]\033[0m $1"; }
ok() { echo -e "\033[0;32m[Neovim]\033[0m $1"; }
warn() { echo -e "\033[0;33m[Neovim]\033[0m $1"; }
err() { echo -e "\033[0;31m[Neovim]\033[0m $1"; }

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
  info "Removing Neovim configuration..."
  if [ -L "$NVIM_TARGET" ]; then
    rm "$NVIM_TARGET"
    ok "Removed nvim config symlink"
  elif [ -e "$NVIM_TARGET" ]; then
    warn "Nvim config is not a symlink, not removing"
  else
    warn "No nvim config found"
  fi
  exit 0
fi

# Install neovim and dependencies
if [ "$SKIP_INSTALL" = false ]; then
  if [ -x "$(command -v apt)" ]; then
    info "Installing Neovim and dependencies via apt..."
    sudo apt update
    sudo apt install -y neovim ripgrep fd-find
  elif [ -x "$(command -v brew)" ]; then
    info "Installing Neovim and dependencies via Homebrew..."
    brew install neovim ripgrep fd
  elif [ -x "$(command -v pacman)" ]; then
    info "Installing Neovim and dependencies via pacman..."
    sudo pacman -S --noconfirm neovim ripgrep fd
  else
    warn "No supported package manager found. Please install neovim, ripgrep, and fd manually."
  fi
fi

# Verify source config exists
if [ ! -d "$NVIM_SOURCE" ]; then
  err "Neovim config not found: $NVIM_SOURCE"
  exit 2
fi

# Create config directory if needed
mkdir -p "$(dirname "$NVIM_TARGET")"

# Set up Neovim config
info "Setting up Neovim config..."
backup_and_remove "$NVIM_TARGET"
ln -s "$NVIM_SOURCE" "$NVIM_TARGET"
ok "Created link: $NVIM_TARGET -> $NVIM_SOURCE"

echo ""
ok "Neovim setup complete!"
echo ""
info "Run 'nvim' - LazyVim will auto-install on first launch"
echo ""
