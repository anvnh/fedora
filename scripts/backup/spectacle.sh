#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

backup_config() {
    local source_file="$1"
    local target_file="$2"
    local name="$3"

    if [[ ! -f "$source_file" ]]; then
        echo "[WARN] $name configuration not found."
        return 0
    fi

    if [[ -f "$target_file" ]] && cmp -s "$source_file" "$target_file"; then
        echo "[SKIP] $name configuration is already up to date."
        return 0
    fi

    mkdir -p "$(dirname "$target_file")"
    cp -- "$source_file" "$target_file"

    echo "[SUCCESS] $name configuration backed up."
}

backup_config \
    "$HOME/.config/spectaclerc" \
    "$ROOT_DIR/configs/spectacle/spectaclerc" \
    "Spectacle"
