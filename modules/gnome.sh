#!/bin/bash
_install_dash_to_dock() {
    if rpm -q gnome-shell-extension-dash-to-dock >/dev/null 2>&1; then
        print_skip "Dash to Dock extension"
        gnome-extensions enable dash-to-dock@micxgx.gmail.com >/dev/null 2>&1 || true
        return 0
    else
        print_info "Installing Dash to Dock extension..."
        sudo dnf5 install -y gnome-shell-extension-dash-to-dock || exit 1
        
        print_warning "Dash to Dock installed. GNOME requires a reboot to register the extension."
        print_warning "Please reboot your system and run this script again to enable and configure it."
        return 1
    fi
}

_configure_dash_to_dock() {
    # Check if the schema is available before attempting to configure
    if ! gsettings list-keys org.gnome.shell.extensions.dash-to-dock >/dev/null 2>&1; then
        print_error "Dash to Dock schema not found. Configuration skipped. You may need to restart GNOME first."
        return
    fi

    local needs_update=false
    
    [[ "$(gsettings get org.gnome.shell.extensions.dash-to-dock dock-position 2>/dev/null)" != "'BOTTOM'" ]] && needs_update=true
    [[ "$(gsettings get org.gnome.shell.extensions.dash-to-dock dock-fixed 2>/dev/null)" != "true" ]] && needs_update=true
    [[ "$(gsettings get org.gnome.shell.extensions.dash-to-dock click-action 2>/dev/null)" != "'minimize'" ]] && needs_update=true
    [[ "$(gsettings get org.gnome.shell.extensions.dash-to-dock extend-height 2>/dev/null)" != "false" ]] && needs_update=true
    [[ "$(gsettings get org.gnome.shell.extensions.dash-to-dock apply-custom-theme 2>/dev/null)" != "true" ]] && needs_update=true
    [[ "$(gsettings get org.gnome.shell.extensions.dash-to-dock dash-max-icon-size 2>/dev/null)" != "32" ]] && needs_update=true

    if [[ "$needs_update" == false ]]; then
        print_skip "Dash to Dock configuration"
        return
    fi

    print_info "Configuring Dash to Dock..."
    
    gsettings set org.gnome.shell.extensions.dash-to-dock dock-position 'BOTTOM' || print_error "Failed to set dock-position to BOTTOM"
    gsettings set org.gnome.shell.extensions.dash-to-dock dock-fixed true || print_error "Failed to set dock-fixed to true"
    gsettings set org.gnome.shell.extensions.dash-to-dock click-action 'minimize' || print_error "Failed to set click-action to minimize"
    gsettings set org.gnome.shell.extensions.dash-to-dock extend-height false || print_error "Failed to set extend-height to false"
    gsettings set org.gnome.shell.extensions.dash-to-dock apply-custom-theme true || print_error "Failed to set apply-custom-theme to true"
    gsettings set org.gnome.shell.extensions.dash-to-dock dash-max-icon-size 32 || print_error "Failed to set dash-max-icon-size to 32"
    
    print_success "Dash to Dock configured."
}

setup_gnome() {
    if [ "$(gsettings get org.gnome.desktop.input-sources xkb-options)" = "['ctrl:nocaps']" ]; then
        print_skip "Caps Lock to Ctrl remapping"
    else
        print_info "Remapping Caps Lock to Ctrl..."
        gsettings set org.gnome.desktop.input-sources xkb-options "['ctrl:nocaps']"

        if [ "$(gsettings get org.gnome.desktop.input-sources xkb-options)" = "['ctrl:nocaps']" ]; then
            print_success "Caps Lock mapped to Ctrl."
        else
            echo -e "${RED}[ERROR] Failed to map Caps Lock. State verification failed.${NC}"
            exit 1
        fi
    fi

    if [ "$(gsettings get org.gnome.desktop.interface color-scheme)" = "'prefer-dark'" ]; then
        print_skip "GNOME Dark Mode"
    else
        print_info "Setting GNOME theme to Dark Mode..."
        gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
        print_success "GNOME Dark Mode enabled."
    fi

    gsettings set org.gnome.desktop.interface gtk-enable-primary-paste true

    if [ "$(gsettings get org.gnome.shell.keybindings show-screenshot-ui)" = "['<Shift><Super>s']" ]; then
        print_skip "GNOME Screenshot shortcut"
    else
        print_info "Setting GNOME Screenshot shortcut to Super+Shift+S..."
        gsettings set org.gnome.shell.keybindings show-screenshot-ui "['<Shift><Super>s']"
        print_success "GNOME Screenshot shortcut configured."
    fi

    if [ "$(gsettings get org.gnome.desktop.wm.keybindings toggle-maximized)" = "['<Alt>Return']" ]; then
        print_skip "GNOME Maximize shortcut"
    else
        print_info "Setting GNOME Maximize shortcut to Alt+Enter..."
        gsettings set org.gnome.desktop.wm.keybindings toggle-maximized "['<Alt>Return']"
        print_success "GNOME Maximize shortcut configured."
    fi

    if _install_dash_to_dock; then
        _configure_dash_to_dock
    else
        print_info "Skipping Dash to Dock configuration until system is rebooted."
    fi
}
