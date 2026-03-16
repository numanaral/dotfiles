#!/usr/bin/env bash
# Bootstrap script -- clones the dotfiles repo and runs setup.
#
# Usage (one-liner from a fresh server):
#   bash <(curl -fsSL https://raw.githubusercontent.com/numanaral/dotfiles/main/install.sh)
#   bash <(curl -fsSL https://raw.githubusercontent.com/numanaral/dotfiles/main/install.sh) --all
#   bash <(curl -fsSL https://raw.githubusercontent.com/numanaral/dotfiles/main/install.sh) --system --shell

set -euo pipefail

REPO="https://github.com/numanaral/dotfiles.git"
INSTALL_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"

echo ""
echo "╔══════════════════════════════════════════╗"
echo "║       dotfiles bootstrap installer       ║"
echo "╚══════════════════════════════════════════╝"
echo ""

if [ -d "$INSTALL_DIR" ]; then
  echo "[INFO] $INSTALL_DIR already exists. Pulling latest..."
  cd "$INSTALL_DIR"
  git pull --ff-only 2>/dev/null || echo "[WARN] Could not pull (not a git repo or no remote). Using existing files."
else
  echo "[INFO] Cloning $REPO -> $INSTALL_DIR"
  if command -v git &>/dev/null; then
    git clone "$REPO" "$INSTALL_DIR"
  else
    echo "[INFO] git not found, installing..."
    apt-get update -y && apt-get install -y git
    git clone "$REPO" "$INSTALL_DIR"
  fi
fi

cd "$INSTALL_DIR"
chmod +x setup.sh scripts/*.sh scripts/lib/utils.sh

echo ""
echo "[INFO] Running setup.sh $*"
echo ""

exec bash ./setup.sh "$@"
