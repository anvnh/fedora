#!/usr/bin/env bash

_qdbus() {
    if command -v qdbus-qt6 >/dev/null 2>&1; then
        qdbus-qt6 "$@"
    elif command -v qdbus6 >/dev/null 2>&1; then
        qdbus6 "$@"
    elif command -v qdbus >/dev/null 2>&1; then
        qdbus "$@"
    fi
}

_configure_caps_lock() {
    local current_options
    current_options=$(kreadconfig6 --file kxkbrc --group Layout --key Options 2>/dev/null || true)

    if [[ "$current_options" == "ctrl:nocaps" ]]; then
        print_skip "Caps Lock as Ctrl"
        return 0
    fi

    print_info "Configuring Caps Lock as Ctrl..."
    kwriteconfig6 --file kxkbrc --group Layout --key Options "ctrl:nocaps"
    kwriteconfig6 --file kxkbrc --group Layout --key ResetOldOptions "true"

    _qdbus org.kde.keyboard /Layouts reconfigure >/dev/null 2>&1 || true
    print_success "Caps Lock mapped to Ctrl."
}

_configure_window_shortcuts() {
    local current_close current_maximize
    current_close=$(kreadconfig6 --file kglobalshortcutsrc --group kwin --key "Window Close" 2>/dev/null || true)
    current_maximize=$(kreadconfig6 --file kglobalshortcutsrc --group kwin --key "Window Maximize" 2>/dev/null || true)

    local needs_update=false
    [[ "$current_close" != *"Meta+Q"* ]] && needs_update=true
    [[ "$current_maximize" != *"Alt+Return"* ]] && needs_update=true

    if [[ "$needs_update" == false ]]; then
        print_skip "Window shortcuts (Super+Q to close, Alt+Return to maximize)"
        return 0
    fi

    print_info "Configuring KDE window shortcuts..."
    kwriteconfig6 --file kglobalshortcutsrc --group kwin --key "Window Close" "Meta+Q,Alt+F4,Close Window"
    kwriteconfig6 --file kglobalshortcutsrc --group kwin --key "Window Maximize" "Alt+Return,Meta+PgUp,Maximize Window"

    _qdbus org.kde.KWin /KWin reconfigure >/dev/null 2>&1 || true
    _qdbus org.kde.kglobalaccel /kglobalaccel org.kde.KGlobalAccel.reloadConfig >/dev/null 2>&1 || true

    print_success "Window shortcuts configured."
}

_kglobalaccel() {
    busctl --user call org.kde.kglobalaccel /kglobalaccel org.kde.KGlobalAccel "$@"
}

_remove_kde_shortcut_key() {
    local component="$1" action="$2" key="$3"
    local -a action_id=(4 "$component" "$action" "" "")
    local current count=0 index
    local -a sequences kept=()

    current=$(_kglobalaccel shortcutKeys as "${action_id[@]}") || return 1
    read -r -a sequences <<< "$current"

    # Each D-Bus key sequence contains four Qt key codes, padded with zeroes.
    for ((index = 2; index < ${#sequences[@]}; index += 5)); do
        if [[ "${sequences[*]:index:5}" == "4 $key 0 0 0" ]]; then
            continue
        fi
        kept+=("${sequences[@]:index:5}")
        count=$((count + 1))
    done

    if [[ "$count" != "${sequences[1]}" ]]; then
        _kglobalaccel setForeignShortcutKeys 'asa(ai)' "${action_id[@]}" "$count" "${kept[@]}"
    fi
}

_register_noctalia_shortcut() {
    local panel="$1" name="$2" key="$3" assigned
    local -a action_id=(4 "noctalia-$panel.desktop" _launch "$name" "$name")

    _kglobalaccel doRegister as "${action_id[@]}" || return 1
    # SetPresent (2) activates the shortcut. NoAutoloading (4) applies the new key.
    assigned=$(_kglobalaccel setShortcutKeys 'asa(ai)u' "${action_id[@]}" 1 4 "$key" 0 0 0 6) || return 1
    if [[ "$assigned" != "a(ai) 1 4 $key 0 0 0" ]]; then
        print_error "KDE could not assign the shortcut for $name."
        return 1
    fi
}

_configure_noctalia_shortcuts() {
    if ! command -v noctalia >/dev/null 2>&1; then
        print_skip "Noctalia shortcuts (noctalia not found)"
        return 0
    fi

    local shortcuts_dir="${XDG_DATA_HOME:-$HOME/.local/share}/kglobalaccel"
    local autostart_dir="${XDG_CONFIG_HOME:-$HOME/.config}/autostart"
    local alt_space=134217760 meta_v=268435542

    print_info "Configuring Noctalia keyboard shortcuts (Alt+Space: launcher, Super+V: clipboard)..."
    mkdir -p "$shortcuts_dir" "$autostart_dir"

    # KGlobalAccel can register entries from this directory immediately on a fresh profile.
    cat << 'EOF' > "$shortcuts_dir/noctalia-launcher.desktop"
[Desktop Entry]
Categories=Utility;
Comment=Toggle Noctalia application launcher
Exec=noctalia msg panel-toggle launcher
Icon=noctalia
Name=Noctalia Launcher
NoDisplay=true
StartupNotify=false
Type=Application
X-KDE-GlobalAccel-CommandShortcut=true
EOF

    cat << 'EOF' > "$shortcuts_dir/noctalia-clipboard.desktop"
[Desktop Entry]
Categories=Utility;
Comment=Toggle Noctalia clipboard history
Exec=noctalia msg panel-toggle clipboard
Icon=noctalia
Name=Noctalia Clipboard
NoDisplay=true
StartupNotify=false
Type=Application
X-KDE-GlobalAccel-CommandShortcut=true
EOF

    _remove_kde_shortcut_key org.kde.krunner.desktop _launch "$alt_space"
    _remove_kde_shortcut_key plasmashell show-on-mouse-pos "$meta_v"
    _register_noctalia_shortcut launcher "Noctalia Launcher" "$alt_space"
    _register_noctalia_shortcut clipboard "Noctalia Clipboard" "$meta_v"

    local autostart_file="$autostart_dir/dev.noctalia.Noctalia.desktop"
    if [[ ! -e "$autostart_file" ]]; then
        cat << 'EOF' > "$autostart_file"
[Desktop Entry]
Type=Application
Name=Noctalia
Exec=noctalia --daemon
OnlyShowIn=KDE;
EOF
    fi

    if ! noctalia msg status >/dev/null 2>&1; then
        noctalia --daemon
    fi

    print_success "Noctalia shortcuts configured."
}

_configure_cursor() {
    local theme_name="catppuccin-mocha-dark-cursors"
    local icons_dir="$HOME/.local/share/icons"
    local theme_dir="$icons_dir/$theme_name"

    if [[ ! -d "$theme_dir" ]]; then
        print_info "Installing $theme_name cursor theme..."
        local tmp_zip
        tmp_zip=$(mktemp --suffix=.zip)
        curl -fLo "$tmp_zip" \
            "https://github.com/catppuccin/cursors/releases/download/v2.0.0/catppuccin-mocha-dark-cursors.zip"

        mkdir -p "$icons_dir"
        unzip -oq "$tmp_zip" -d "$icons_dir"
        rm -f "$tmp_zip"
        print_success "$theme_name installed."
    fi

    local current_theme
    current_theme=$(kreadconfig6 --file kcminputrc --group Mouse --key cursorTheme 2>/dev/null || true)

    if [[ "$current_theme" == "$theme_name" && -f "$HOME/.icons/default/index.theme" ]]; then
        print_skip "Cursor theme ($theme_name)"
        return 0
    fi

    print_info "Configuring cursor theme to $theme_name..."
    kwriteconfig6 --file kcminputrc --group Mouse --key cursorTheme "$theme_name"

    mkdir -p "$HOME/.icons/default"
    cat <<EOF > "$HOME/.icons/default/index.theme"
[Icon Theme]
Name=Default
Comment=Default Cursor Theme
Inherits=$theme_name
EOF

    _qdbus org.kde.KWin /KWin reconfigure >/dev/null 2>&1 || true
    print_success "Cursor theme configured to $theme_name."
}

setup_configure_desktop() {
    if ! command -v kwriteconfig6 >/dev/null 2>&1; then
        print_error "kwriteconfig6 not found. Please ensure KDE Plasma 6 is installed."
        return 1
    fi

    _configure_caps_lock
    _configure_window_shortcuts
    _configure_noctalia_shortcuts
    _configure_cursor
}
