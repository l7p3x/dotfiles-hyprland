#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Installing dotfiles..."

rsync -av --exclude='install.sh' --exclude='.gitignore' --exclude='.git' "$SCRIPT_DIR/" "$HOME/"

ICON_URL="https://ocs-dl.fra1.cdn.digitaloceanspaces.com/data/files/1752923957/yet-another-monochrome-icon-set.tar.gz?response-content-disposition=attachment%3B%2520yet-another-monochrome-icon-set.tar.gz&X-Amz-Content-Sha256=UNSIGNED-PAYLOAD&X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=RWJAQUNCHT7V2NCLZ2AL%2F20260428%2Fus-east-1%2Fs3%2Faws4_request&X-Amz-Date=20260428T144949Z&X-Amz-SignedHeaders=host&X-Amz-Expires=3600&X-Amz-Signature=540754c78c5b4b5dfcfb8133f3f22c0ceb7582069b5a468c4535348c2812d4e4"
TMP_DIR=$(mktemp -d)
ICON_DEST="$HOME/.local/share/icons"
ICON_FILE="$TMP_DIR/yamis-icons.tar.gz"

mkdir -p "$ICON_DEST"

echo "Downloading YAMIS icons..."
curl -L "$ICON_URL" -o "$ICON_FILE"

echo "Extracting icons..."
tar -xzf "$ICON_FILE" -C "$ICON_DEST"

rm -rf "$TMP_DIR"

echo "Installation complete."
echo "Credits: Yet Another Monochrome Icon Set - https://store.kde.org/p/2303161"
