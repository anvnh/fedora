#!/usr/bin/env bash

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

    qdbus6 org.kde.keyboard /Layouts reconfigure >/dev/null 2>&1 || true
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

    qdbus6 org.kde.KWin /KWin reconfigure >/dev/null 2>&1 || true
    qdbus6 org.kde.kglobalaccel /kglobalaccel org.kde.KGlobalAccel.reloadConfig >/dev/null 2>&1 || true

    print_success "Window shortcuts configured."
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

    qdbus6 org.kde.KWin /KWin reconfigure >/dev/null 2>&1 || true
    print_success "Cursor theme configured to $theme_name."
}

setup_configure_desktop() {
    if ! command -v kwriteconfig6 >/dev/null 2>&1; then
        print_error "kwriteconfig6 not found. Please ensure KDE Plasma 6 is installed."
        return 1
    fi

    _configure_caps_lock
    _configure_window_shortcuts
    _configure_cursor
}
