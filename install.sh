#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(dirname "$(realpath "$0")")"
SELF="$(basename "$0")"

REPO_URL="https://www.github.com/googIyEYES/YAMIS.git"
TMP_DIR="$(mktemp -d)"
DEST="$HOME/.local/share/icons"

# mover arquivos com segurança
for f in "$SCRIPT_DIR"/*; do
    [ -f "$f" ] || continue

    case "$(basename "$f")" in
        "$SELF"|.gitignore)
            continue
            ;;
    esac

    mv "$f" "$HOME/"
done

# clonar repo (shallow)
git clone --depth 1 "$REPO_URL" "$TMP_DIR/YAMIS"

# garantir destino
mkdir -p "$DEST"

# extrair
tar -xzf "$TMP_DIR/YAMIS/monochrome-icon-theme.tar.gz" -C "$DEST"

# limpeza
rm -rf "$TMP_DIR"

+++ install.sh (修改后)
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
