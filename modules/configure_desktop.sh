#!/bin/bash

_configure_copyq_autostart() {
    local autostart_dir="$HOME/.config/autostart"
    local desktop_dst="$autostart_dir/copyq.desktop"

    if [[ -f "$desktop_dst" ]] && grep -q "X-GNOME-Autostart-enabled=true" "$desktop_dst" 2>/dev/null; then
        print_skip "CopyQ autostart desktop entry"
        return 0
    fi

    print_info "Configuring CopyQ autostart desktop entry..."
    mkdir -p "$autostart_dir"
    cat <<EOF > "$desktop_dst"
[Desktop Entry]
Name=CopyQ
GenericName=Clipboard Manager
Comment=Start CopyQ clipboard manager
Exec=copyq
Icon=copyq
Terminal=false
Type=Application
X-GNOME-Autostart-enabled=true
EOF
    print_success "CopyQ autostart desktop entry created."
}

_configure_copyq_shortcut() {
    local keybinding_path="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/copyq/"
    local current_bindings
    current_bindings=$(gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings)

    # Unbind GNOME's default Super+V (notification list) so CopyQ can use it
    if [[ "$(gsettings get org.gnome.shell.keybindings toggle-message-tray 2>/dev/null)" == *"<Super>v"* ]]; then
        gsettings set org.gnome.shell.keybindings toggle-message-tray "[]" || print_error "Failed to unbind Super+V from notification list"
    fi

    if [[ "$current_bindings" == *"$keybinding_path"* ]] && \
       [[ "$(gsettings get org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:"$keybinding_path" name)" == "'CopyQ Toggle'" ]] && \
       [[ "$(gsettings get org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:"$keybinding_path" command)" == "'copyq toggle'" ]] && \
       [[ "$(gsettings get org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:"$keybinding_path" binding)" == "'<Super>v'" ]]; then
        print_skip "CopyQ keyboard shortcut"
        return
    fi

    print_info "Configuring CopyQ keyboard shortcut..."

    if [[ "$current_bindings" != *"$keybinding_path"* ]]; then
        if [[ "$current_bindings" == *"@"* ]] || [[ "$current_bindings" == "[]" ]]; then
            new_bindings="['$keybinding_path']"
        else
            new_bindings="${current_bindings%]*}, '$keybinding_path']"
        fi
        gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "$new_bindings"
    fi

    gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:"$keybinding_path" name 'CopyQ Toggle'
    gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:"$keybinding_path" command 'copyq toggle'
    gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:"$keybinding_path" binding '<Super>v'

    print_success "CopyQ keyboard shortcut configured."
}

_install_dash_to_dock() {
    if rpm -q gnome-shell-extension-dash-to-dock >/dev/null 2>&1; then
        print_skip "Dash to Dock extension"
        gnome-extensions enable dash-to-dock@micxgx.gmail.com >/dev/null 2>&1 || true
        return 0
    else
        print_info "Installing Dash to Dock extension..."
        sudo dnf install -y gnome-shell-extension-dash-to-dock || exit 1
        
        print_warning "Dash to Dock installed. GNOME requires a reboot to register the extension."
        # print_warning "Please reboot your system and run this script again to enable and configure it."
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
    [[ "$(gsettings get org.gnome.shell.extensions.dash-to-dock dock-fixed 2>/dev/null)" != "false" ]] && needs_update=true
    [[ "$(gsettings get org.gnome.shell.extensions.dash-to-dock intellihide 2>/dev/null)" != "true" ]] && needs_update=true
    [[ "$(gsettings get org.gnome.shell.extensions.dash-to-dock click-action 2>/dev/null)" != "'minimize'" ]] && needs_update=true
    [[ "$(gsettings get org.gnome.shell.extensions.dash-to-dock extend-height 2>/dev/null)" != "false" ]] && needs_update=true
    [[ "$(gsettings get org.gnome.shell.extensions.dash-to-dock apply-custom-theme 2>/dev/null)" != "true" ]] && needs_update=true
    [[ "$(gsettings get org.gnome.shell.extensions.dash-to-dock dash-max-icon-size 2>/dev/null)" != "32" ]] && needs_update=true
    [[ "$(gsettings get org.gnome.shell.extensions.dash-to-dock hot-keys 2>/dev/null)" != "false" ]] && needs_update=true
    [[ "$(gsettings get org.gnome.shell.extensions.dash-to-dock shortcut 2>/dev/null)" != "@as []" ]] && needs_update=true

    if [[ "$needs_update" == false ]]; then
        print_skip "Dash to Dock configuration"
        return
    fi

    print_info "Configuring Dash to Dock..."
    
    gsettings set org.gnome.shell.extensions.dash-to-dock dock-position 'BOTTOM' || print_error "Failed to set dock-position to BOTTOM"
    gsettings set org.gnome.shell.extensions.dash-to-dock dock-fixed false || print_error "Failed to set dock-fixed to false"
    gsettings set org.gnome.shell.extensions.dash-to-dock intellihide true || print_error "Failed to enable intelligent auto-hide"
    gsettings set org.gnome.shell.extensions.dash-to-dock click-action 'minimize' || print_error "Failed to set click-action to minimize"
    gsettings set org.gnome.shell.extensions.dash-to-dock extend-height false || print_error "Failed to set extend-height to false"
    gsettings set org.gnome.shell.extensions.dash-to-dock apply-custom-theme true || print_error "Failed to set apply-custom-theme to true"
    gsettings set org.gnome.shell.extensions.dash-to-dock dash-max-icon-size 32 || print_error "Failed to set dash-max-icon-size to 32"
    gsettings set org.gnome.shell.extensions.dash-to-dock hot-keys false || print_error "Failed to disable hot-keys"
    gsettings set org.gnome.shell.extensions.dash-to-dock shortcut '[]' || print_error "Failed to disable Dash to Dock shortcut"
    
    print_success "Dash to Dock configured."
}

setup_configure_desktop() {
    local needs_update=false

    [[ "$(gsettings get org.gnome.desktop.input-sources xkb-options 2>/dev/null)" != "['ctrl:nocaps']" ]] && needs_update=true
    [[ "$(gsettings get org.gnome.desktop.interface color-scheme 2>/dev/null)" != "'prefer-dark'" ]] && needs_update=true
    [[ "$(gsettings get org.gnome.desktop.interface gtk-enable-primary-paste 2>/dev/null)" != "true" ]] && needs_update=true
    [[ "$(gsettings get org.gnome.desktop.wm.preferences button-layout 2>/dev/null)" != "'appmenu:minimize,maximize,close'" ]] && needs_update=true
    [[ "$(gsettings get org.gnome.shell.keybindings show-screenshot-ui 2>/dev/null)" != "['<Shift><Super>s']" ]] && needs_update=true
    [[ "$(gsettings get org.gnome.desktop.wm.keybindings switch-applications 2>/dev/null)" != "@as []" ]] && needs_update=true
    [[ "$(gsettings get org.gnome.desktop.wm.keybindings switch-applications-backward 2>/dev/null)" != "@as []" ]] && needs_update=true
    [[ "$(gsettings get org.gnome.desktop.wm.keybindings switch-windows 2>/dev/null)" != "['<Alt>Tab']" ]] && needs_update=true
    [[ "$(gsettings get org.gnome.desktop.wm.keybindings switch-windows-backward 2>/dev/null)" != "['<Shift><Alt>Tab']" ]] && needs_update=true
    [[ "$(gsettings get org.gnome.desktop.wm.keybindings toggle-maximized 2>/dev/null)" != "['<Alt>Return']" ]] && needs_update=true
    [[ "$(gsettings get org.gnome.desktop.wm.keybindings close 2>/dev/null)" != "['<Super>q']" ]] && needs_update=true

    if [[ "$needs_update" == false ]]; then
        print_skip "GNOME desktop preferences"
    else
        print_info "Configuring GNOME desktop preferences..."

        gsettings set org.gnome.desktop.input-sources xkb-options "['ctrl:nocaps']" || print_error "Failed to map Caps Lock to Ctrl"
        gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' || print_error "Failed to set Dark Mode"
        gsettings set org.gnome.desktop.interface gtk-enable-primary-paste true || print_error "Failed to enable primary paste"
        gsettings set org.gnome.desktop.wm.preferences button-layout 'appmenu:minimize,maximize,close' || print_error "Failed to enable window buttons"
        gsettings set org.gnome.shell.keybindings show-screenshot-ui "['<Shift><Super>s']" || print_error "Failed to configure screenshot shortcut"
        gsettings set org.gnome.desktop.wm.keybindings switch-applications "[]" || print_error "Failed to disable app-based Alt+Tab"
        gsettings set org.gnome.desktop.wm.keybindings switch-applications-backward "[]" || print_error "Failed to disable reverse app-based Alt+Tab"
        gsettings set org.gnome.desktop.wm.keybindings switch-windows "['<Alt>Tab']" || print_error "Failed to configure window-based Alt+Tab"
        gsettings set org.gnome.desktop.wm.keybindings switch-windows-backward "['<Shift><Alt>Tab']" || print_error "Failed to configure reverse window-based Alt+Tab"
        gsettings set org.gnome.desktop.wm.keybindings toggle-maximized "['<Alt>Return']" || print_error "Failed to configure maximize shortcut"
        gsettings set org.gnome.desktop.wm.keybindings close "['<Super>q']" || print_error "Failed to configure close window shortcut"

        print_success "GNOME desktop preferences configured."
    fi

    _configure_copyq_shortcut
    _configure_copyq_autostart

    if _install_dash_to_dock; then
        _configure_dash_to_dock
    else
        print_info "Skipping Dash to Dock configuration until system is rebooted."
    fi

    if rpm -q gnome-shell-extension-kimpanel >/dev/null 2>&1; then
        gnome-extensions enable kimpanel@krajniak.info >/dev/null 2>&1 || true
        print_success "Kimpanel GNOME Shell extension enabled."
    fi
}
