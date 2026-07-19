#!/bin/bash

setup_install_packages() {
    local PACKAGES=(
        wl-clipboard
        libgda
        libgda-sqlite
        gsound
        nvim
    )

    local dnf_conf="/etc/dnf/dnf.conf"
    local dnf_opts=(
        "max_parallel_downloads=10"
        "fastestmirror=True"
        "defaultyes=True"
        "ip_resolve=4"
    )
    
    local needs_update=false
    for opt in "${dnf_opts[@]}"; do
        if ! grep -qxF "$opt" "$dnf_conf"; then
            needs_update=true
            break
        fi
    done

    if [[ "$needs_update" == false ]]; then
        print_skip "DNF configuration"
    else
        print_info "Maximize DNF download speed and force IPv4 routing..."
        for opt in "${dnf_opts[@]}"; do
            grep -qxF "$opt" "$dnf_conf" || echo "$opt" | sudo tee -a "$dnf_conf" >/dev/null
        done
        print_success "DNF configuration updated"
        
        request_reboot_and_resume "$SCRIPT_DIR/setup.sh"
    fi

    if fedora-third-party query | grep -q 'enabled'; then
        print_skip "Third-party repositories"
    else
        print_info "Enabling third-party repositories..."
        sudo fedora-third-party enable
        print_success "Third-party repositories enabled."
    fi

    print_info "Update system packages..."
    # skipped to avoid long install times"
    # sudo dnf update -y

    install_dnf "Essentials Packages" "${PACKAGES[@]}"

    install_flatpak "Extension Manager" "com.mattjakeman.ExtensionManager"
    install_flatpak "Super Productivity" "com.super_productivity.SuperProductivity"
    install_flatpak "Actual Budget" "com.actualbudget.actual"
}
