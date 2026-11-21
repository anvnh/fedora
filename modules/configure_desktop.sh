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

setup_configure_desktop() {
    if ! command -v kwriteconfig6 >/dev/null 2>&1; then
        print_error "kwriteconfig6 not found. Please ensure KDE Plasma 6 is installed."
        return 1
    fi

    _configure_caps_lock
    _configure_window_shortcuts
}
