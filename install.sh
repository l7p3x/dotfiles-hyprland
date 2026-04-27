#!/usr/bin/env bash

SCRIPT_DIR="$(dirname "$(realpath "$0")")"

for f in "$SCRIPT_DIR"/*; do
    case "$(basename "$f")" in
        .gitignore)
            continue
            ;;
    esac
    mv "$f" ~/
done

git clone https://www.github.com/googIyEYES/YAMIS.git && cd YAMIS
tar -xzvf monochrome-icon-theme.tar.gz -C "~/.local/share/icons/"
sudo rm -r Yet-Another-Monochrome-Icon-Theme
