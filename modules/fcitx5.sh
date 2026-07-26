#!/bin/bash

_configure_fcitx5_autostart() {
    local autostart_dir="$HOME/.config/autostart"
    local desktop_dst="$autostart_dir/org.fcitx.Fcitx5.desktop"

    if [[ -f "$desktop_dst" ]] && grep -q "X-GNOME-Autostart-enabled=true" "$desktop_dst" 2>/dev/null; then
        print_skip "Fcitx5 autostart desktop entry"
        return 0
    else
        print_info "Configuring Fcitx5 autostart desktop entry..."
        mkdir -p "$autostart_dir"
        cat <<EOF > "$desktop_dst"
[Desktop Entry]
Name=Fcitx 5
GenericName=Input Method
Comment=Start Input Method
Exec=fcitx5 -d
Icon=org.fcitx.Fcitx5
Terminal=false
Type=Application
X-GNOME-Autostart-enabled=true
EOF
        print_success "Fcitx5 autostart desktop entry created."
        return 1
    fi
}

_configure_fcitx5_profile() {
    local target_dir="$HOME/.config/fcitx5"
    mkdir -p "$target_dir"

    local profile_src="$SCRIPT_DIR/configs/fcitx5/profile"
    local profile_dst="$target_dir/profile"
    local config_src="$SCRIPT_DIR/configs/fcitx5/config"
    local config_dst="$target_dir/config"

    if cmp -s "$profile_src" "$profile_dst" 2>/dev/null && cmp -s "$config_src" "$config_dst" 2>/dev/null; then
        print_skip "Fcitx5 profile and hotkeys"
        return 0
    fi

    # Stop running fcitx5 process to prevent in-memory config from overwriting files on exit
    if pgrep -x fcitx5 >/dev/null 2>&1; then
        print_info "Stopping running Fcitx5 to apply configuration..."
        pkill -x fcitx5 || true
        sleep 1
    fi

    print_info "Configuring Fcitx5 profile and hotkeys..."
    cp -f "$profile_src" "$profile_dst"
    cp -f "$config_src" "$config_dst"
    print_success "Fcitx5 profile and hotkeys configured."
    return 1
}

setup_fcitx5() {
    local updated=false

    if ! _configure_fcitx5_profile; then
        updated=true
    fi

    local env_src="$SCRIPT_DIR/configs/environment.d/fcitx5.conf"
    local env_dst="$HOME/.config/environment.d/fcitx5.conf"
    if ! [[ -L "$env_dst" && "$(readlink -f "$env_dst")" == "$(readlink -f "$env_src")" ]]; then
        updated=true
    fi
    link_config "Fcitx5 environment variables" "$env_src" "$env_dst"

    local xinput_src="$SCRIPT_DIR/configs/imsettings/xinputrc"
    local xinput_dst="$HOME/.config/imsettings/xinputrc"
    if ! [[ -L "$xinput_dst" && "$(readlink -f "$xinput_dst")" == "$(readlink -f "$xinput_src")" ]]; then
        updated=true
    fi
    link_config "Fcitx5 imsettings" "$xinput_src" "$xinput_dst"

    if ! _configure_fcitx5_autostart; then
        updated=true
    fi

    if [[ "$updated" == true || "${XMODIFIERS:-}" != "@im=fcitx" ]]; then
        request_reboot_and_resume "$SCRIPT_DIR/setup.sh"
    fi
}

