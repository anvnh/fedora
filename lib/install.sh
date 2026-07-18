#!bin/bash

install_flatpak() {
    local app_name="$1"
    local app_id="$2"

    if flatpak info "$app_id" >/dev/null 2>&1; then
        print_installed "$app_name"
        return
    fi

    print_info "Installing $app_name..."
    flatpak install -y flathub "$app_id"
    print_success "$app_name installed"
}