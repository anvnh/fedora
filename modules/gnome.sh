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

    if [ "$(gsettings get org.gnome.shell.extensions.dash-to-dock dock-position)" = "'BOTTOM'" ]; then
        print_skip "Dash to Dock position"
    else
        print_info "Setting Dash to Dock position to BOTTOM..."
        gsettings set org.gnome.shell.extensions.dash-to-dock dock-position 'BOTTOM'
        print_success "Dash to Dock position configured."
    fi

    if [ "$(gsettings get org.gnome.shell.extensions.dash-to-dock dock-fixed)" = "true" ]; then
        print_skip "Dash to Dock fixed mode"
    else
        print_info "Setting Dash to Dock to fixed mode (no auto-hide)..."
        gsettings set org.gnome.shell.extensions.dash-to-dock dock-fixed true
        print_success "Dash to Dock fixed mode configured."
    fi

    if [ "$(gsettings get org.gnome.shell.extensions.dash-to-dock click-action)" = "'minimize'" ]; then
        print_skip "Dash to Dock click-action"
    else
        print_info "Setting Dash to Dock click action to minimize..."
        gsettings set org.gnome.shell.extensions.dash-to-dock click-action 'minimize'
        print_success "Dash to Dock click-action configured."
    fi

    if [ "$(gsettings get org.gnome.shell.extensions.dash-to-dock extend-height)" = "false" ]; then
        print_skip "Dash to Dock shrink"
    else
        print_info "Shrinking Dash to Dock (disabling extend-height)..."
        gsettings set org.gnome.shell.extensions.dash-to-dock extend-height false
        print_success "Dash to Dock shrink configured."
    fi

    if [ "$(gsettings get org.gnome.shell.extensions.dash-to-dock apply-custom-theme)" = "true" ]; then
        print_skip "Dash to Dock built-in theme"
    else
        print_info "Enabling Dash to Dock built-in theme..."
        gsettings set org.gnome.shell.extensions.dash-to-dock apply-custom-theme true
        print_success "Dash to Dock built-in theme enabled."
    fi

    if [ "$(gsettings get org.gnome.shell.extensions.dash-to-dock dash-max-icon-size)" = "32" ]; then
        print_skip "Dash to Dock icon size"
    else
        print_info "Setting Dash to Dock icon size limit to 32..."
        gsettings set org.gnome.shell.extensions.dash-to-dock dash-max-icon-size 32
        print_success "Dash to Dock icon size limit configured."
    fi
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
