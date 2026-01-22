#!/usr/bin/env bash
# Mount Windows devbox filesystem via SSHFS for local editing
#
# Usage:
#   ./scripts/mount_devbox.sh                    # Mount devbox
#   ./scripts/mount_devbox.sh --unmount          # Unmount devbox
#   DEVBOX_HOST=mybox ./scripts/mount_devbox.sh  # Custom hostname
#
# Prerequisites (WSL):
#   sudo apt install sshfs

set -e

# Configuration - override with environment variables
DEVBOX_HOST="${DEVBOX_HOST:-YOUR_DEVBOX_HOSTNAME}"
DEVBOX_USER="${DEVBOX_USER:-$USER}"
DEVBOX_REMOTE_PATH="${DEVBOX_REMOTE_PATH:-/C:/Users/$DEVBOX_USER}"
MOUNT_POINT="${MOUNT_POINT:-$HOME/devbox}"

info() { echo -e "\033[0;36m[Devbox]\033[0m $1"; }
ok() { echo -e "\033[0;32m[Devbox]\033[0m $1"; }
err() { echo -e "\033[0;31m[Devbox]\033[0m $1"; }

if [ "$1" = "--unmount" ] || [ "$1" = "-u" ]; then
  info "Unmounting devbox..."
  if mountpoint -q "$MOUNT_POINT" 2>/dev/null; then
    fusermount -u "$MOUNT_POINT"
    ok "Unmounted $MOUNT_POINT"
  else
    info "Not mounted"
  fi
  exit 0
fi

# Check if sshfs is installed
if ! command -v sshfs &>/dev/null; then
  err "sshfs not found. Install with: sudo apt install sshfs"
  exit 1
fi

# Check if already mounted
if mountpoint -q "$MOUNT_POINT" 2>/dev/null; then
  info "Already mounted at $MOUNT_POINT"
  exit 0
fi

# Create mount point if needed
mkdir -p "$MOUNT_POINT"

info "Mounting $DEVBOX_USER@$DEVBOX_HOST:$DEVBOX_REMOTE_PATH to $MOUNT_POINT..."

sshfs "$DEVBOX_USER@$DEVBOX_HOST:$DEVBOX_REMOTE_PATH" "$MOUNT_POINT" \
  -o reconnect \
  -o ServerAliveInterval=15 \
  -o ServerAliveCountMax=3 \
  -o follow_symlinks

ok "Mounted! Edit files at: $MOUNT_POINT"
echo ""
info "To unmount: $0 --unmount"
echo ""
