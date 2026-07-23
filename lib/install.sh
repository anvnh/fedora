#!/bin/bash

install_flatpak() {
    local app_name="$1"
    local app_id="$2"

    if flatpak info "$app_id" >/dev/null 2>&1; then
        print_skip "$app_name"
        return
    fi

    print_info "Installing $app_name..."
    flatpak install -y flathub "$app_id"
    print_success "$app_name installed"
}

install_dnf() {
    local group_name="$1"
    shift

    if rpm -q "$@" >/dev/null 2>&1; then
        print_skip "$group_name"
        return
    fi

    print_info "Installing $group_name..."
    sudo dnf5 install -y "$@"
    print_success "$group_name installed"
}

link_config() {
    local label="$1"
    local src="$2"
    local dst="$3"

    if [[ -L "$dst" && "$(readlink -f "$dst")" == "$(readlink -f "$src")" ]]; then
        print_skip "$label configuration is up to date"
        return
    fi

    print_info "Linking $label configuration..."
    mkdir -p "$(dirname "$dst")"
    ln -sf "$src" "$dst"
    print_success "$label configuration linked"
}