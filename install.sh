#!/usr/bin/env bash

set -e

SCRIPT_PATH="$0"
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"
TARGET_DIR="$HOME/.config"

echo "Script directory: $SCRIPT_DIR"
echo "Destination: $TARGET_DIR"

# Create destination if it doesn't exist
mkdir -p "$TARGET_DIR"

# Enable dotglob to include hidden files, nullglob to avoid errors if empty
shopt -s dotglob nullglob

cd "$SCRIPT_DIR"

EXCLUSIONS=(
    "install.sh"
    ".git"
    ".gitignore"
    "README.md"
)

for item in *; do
    if [[ "$item" == * ]]; then  # Match all
        exclude=false
        for excl in "${EXCLUSIONS[@]}"; do
            if [[ "$item" == "$excl" ]]; then
                exclude=true
                break
            fi
        done
        if [[ "$exclude" == false ]]; then
            echo "Moving $item to $TARGET_DIR/"
            mv "$item" "$TARGET_DIR/"
        else
            echo "Skipping: $item"
        fi
    fi
done

echo "Installation complete!"
echo "Execute Run 'chmod +x $SCRIPT_PATH' if necessary to make it executable."
