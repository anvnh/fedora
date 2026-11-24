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

_configure_window_shortcuts() {
    local current_close current_maximize current_show_desktop
    current_close=$(kreadconfig6 --file kglobalshortcutsrc --group kwin --key "Window Close" 2>/dev/null || true)
    current_maximize=$(kreadconfig6 --file kglobalshortcutsrc --group kwin --key "Window Maximize" 2>/dev/null || true)
    current_show_desktop=$(kreadconfig6 --file kglobalshortcutsrc --group kwin --key "Show Desktop" 2>/dev/null || true)

    local needs_update=false
    [[ "$current_close" != *"Meta+Q"* ]] && needs_update=true
    [[ "$current_maximize" != *"Alt+Return"* ]] && needs_update=true
    [[ "$current_show_desktop" != "none"* ]] && needs_update=true

    if [[ "$needs_update" == false ]]; then
        print_skip "Window shortcuts (Super+Q close, Alt+Return maximize, unbind Super+D)"
        return 0
    fi

    print_info "Configuring KDE window shortcuts (Super+Q close, Alt+Return maximize, unbind Super+D)..."
    kwriteconfig6 --file kglobalshortcutsrc --group kwin --key "Window Close" "Meta+Q,Alt+F4,Close Window"
    kwriteconfig6 --file kglobalshortcutsrc --group kwin --key "Window Maximize" "Alt+Return,Meta+PgUp,Maximize Window"
    kwriteconfig6 --file kglobalshortcutsrc --group kwin --key "Show Desktop" "none,none,Peek at Desktop"

    local meta_d=268435524
    _remove_kde_shortcut_key kwin "Show Desktop" "$meta_d" || true

    _qdbus org.kde.KWin /KWin reconfigure >/dev/null 2>&1 || true
    _qdbus org.kde.kglobalaccel /kglobalaccel org.kde.KGlobalAccel.reloadConfig >/dev/null 2>&1 || true

    print_success "Window shortcuts configured."
}

_add_kde_shortcut_key() {
    local component="$1" action="$2" key="$3"
    local -a action_id=(4 "$component" "$action" "" "")
    local current
    local -a sequences
    # Each D-Bus key sequence contains four Qt key codes, padded with zeroes.
    local sequence=" 4 $key 0 0 0 "

    current=$(_kglobalaccel shortcutKeys as "${action_id[@]}") || return 1
    if [[ " $current " == *"$sequence"* ]]; then
        return 0
    fi

    read -r -a sequences <<< "$current"
    _kglobalaccel setForeignShortcutKeys 'asa(ai)' "${action_id[@]}" \
        "$((sequences[1] + 1))" "${sequences[@]:2}" 4 "$key" 0 0 0 || return 1

    current=$(_kglobalaccel shortcutKeys as "${action_id[@]}") || return 1
    if [[ " $current " != *"$sequence"* ]]; then
        print_error "KDE could not assign the shortcut for $action."
        return 1
    fi
}

_configure_virtual_desktop_shortcuts() {
    local qt_alt=0x08000000 qt_ctrl=0x04000000 qt_shift=0x02000000
    local qt_h=0x48 qt_l=0x4c
    local move_modifiers=$((qt_alt | qt_ctrl | qt_shift))

    print_info "Configuring virtual desktop shortcuts (Alt+H/L switch, Ctrl+Alt+Shift+H/L move window)..."
    _add_kde_shortcut_key kwin "Switch to Next Desktop" "$((qt_alt | qt_l))" || return 1
    _add_kde_shortcut_key kwin "Switch to Previous Desktop" "$((qt_alt | qt_h))" || return 1
    _add_kde_shortcut_key kwin "Window One Desktop to the Right" "$((move_modifiers | qt_l))" || return 1
    _add_kde_shortcut_key kwin "Window One Desktop to the Left" "$((move_modifiers | qt_h))" || return 1
    print_success "Virtual desktop shortcuts configured."
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
    _configure_virtual_desktop_shortcuts
    _configure_cursor
}
