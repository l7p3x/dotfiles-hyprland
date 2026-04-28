#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Installing dotfiles..."

rsync -av --exclude='install.sh' --exclude='.gitignore' --exclude='.git' "$SCRIPT_DIR/" "$HOME/"

REPO_URL="https://github.com/googIyEYES/YAMIS.git"
TMP_DIR=$(mktemp -d)
ICON_DEST="$HOME/.local/share/icons"

git clone --depth 1 "$REPO_URL" "$TMP_DIR/YAMIS"

mkdir -p "$ICON_DEST"
tar -xzf "$TMP_DIR/YAMIS/monochrome-icon-theme.tar.gz" -C "$ICON_DEST"

rm -rf "$TMP_DIR"

echo "Installation complete."
echo "Credits: YAMIS icons by https://github.com/googIyEYES/YAMIS"
