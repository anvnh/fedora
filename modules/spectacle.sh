#!/usr/bin/env bash

configure_spectacle() {
    local config_dir
    config_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

    local source_file="$config_dir/configs/spectacle/spectaclerc"
    local target_file="$HOME/.config/spectaclerc"

    if [[ ! -f "$source_file" ]]; then
        echo "[ERROR] Spectacle configuration not found."
        return 1
    fi

    if [[ -f "$target_file" ]] && cmp -s "$source_file" "$target_file"; then
        echo "[SKIP] Spectacle already configured."
        return
    fi

    mkdir -p "$(dirname "$target_file")"
    install -m 600 "$source_file" "$target_file"

    echo "[SUCCESS] Spectacle configured."
}
