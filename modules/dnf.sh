#!/bin/bash

setup_dnf() {
    local PACKAGES=(
        wl-clipboard
        libgda
        libgda-sqlite
        gsound
        nvim
    )

    print_info "Maximize DNF download speed and force IPv4 routing..."
    grep -qxF 'max_parallel_downloads=10' /etc/dnf/dnf.conf || echo 'max_parallel_downloads=10' | sudo tee -a /etc/dnf/dnf.conf
    grep -qxF 'fastestmirror=True' /etc/dnf/dnf.conf || echo 'fastestmirror=True' | sudo tee -a /etc/dnf/dnf.conf
    grep -qxF 'defaultyes=True' /etc/dnf/dnf.conf || echo 'defaultyes=True' | sudo tee -a /etc/dnf/dnf.conf
    grep -qxF 'ip_resolve=4' /etc/dnf/dnf.conf || echo 'ip_resolve=4' | sudo tee -a /etc/dnf/dnf.conf
    print_success "DNF configuration updated"

    print_info "Update system packages..."
    # sudo dnf update -y

    install_dnf "Essentials Packages" "${PACKAGES[@]}"

    install_flatpak "Extension Manager" "com.mattjakeman.ExtensionManager"
    install_flatpak "Super Productivity" "com.super_productivity.SuperProductivity"
}
