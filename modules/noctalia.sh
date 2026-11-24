#!/usr/bin/env bash

# Resolve project root directory
_NOCTALIA_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

# Ensure common helpers are available
if [[ -f "$_NOCTALIA_DIR/lib/common.sh" ]] && ! command -v print_info &>/dev/null; then
    # shellcheck source=/dev/null
    source "$_NOCTALIA_DIR/lib/common.sh"
fi

if ! declare -F _kglobalaccel >/dev/null; then
    _kglobalaccel() {
        busctl --user call org.kde.kglobalaccel /kglobalaccel org.kde.KGlobalAccel "$@"
    }
fi

if ! declare -F _remove_kde_shortcut_key >/dev/null; then
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
fi

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

_configure_noctalia_config() {
    local source="$_NOCTALIA_DIR/configs/noctalia/config.toml"
    if [[ ! -f "$source" && -f "$_NOCTALIA_DIR/configs/noctalia/noctalia-config.toml" ]]; then
        source="$_NOCTALIA_DIR/configs/noctalia/noctalia-config.toml"
    fi

    local target="${XDG_CONFIG_HOME:-$HOME/.config}/noctalia/config.toml"

    if [[ ! -f "$source" ]]; then
        print_error "Noctalia configuration not found: $source"
        return 1
    fi

    mkdir -p "$(dirname "$target")" || return 1

    if [[ -f "$target" ]] && cmp -s "$source" "$target"; then
        print_skip "Noctalia configuration is already up to date"
        return 0
    fi

    if cp "$source" "$target"; then
        print_success "Noctalia configuration imported."
    else
        print_error "Failed to import Noctalia configuration."
        return 1
    fi
}

_configure_noctalia_autostart() {
    local autostart_dir="${XDG_CONFIG_HOME:-$HOME/.config}/autostart"
    local autostart_file="$autostart_dir/dev.noctalia.Noctalia.desktop"

    local expected_content
    expected_content=$(cat << 'EOF'
[Desktop Entry]
Type=Application
Name=Noctalia
Exec=noctalia --daemon
OnlyShowIn=KDE;
EOF
)

    if [[ -f "$autostart_file" ]] && [[ "$(< "$autostart_file")" == "$expected_content" ]]; then
        print_skip "Noctalia autostart"
        return 0
    fi

    mkdir -p "$autostart_dir" || return 1
    if echo "$expected_content" > "$autostart_file"; then
        print_success "Noctalia autostart configured."
    else
        print_error "Failed to configure Noctalia autostart."
        return 1
    fi
}

_configure_noctalia_shortcuts() {
    local shortcuts_dir="${XDG_DATA_HOME:-$HOME/.local/share}/kglobalaccel"
    local alt_space=134217760 meta_v=268435542

    print_info "Configuring Noctalia keyboard shortcuts (Alt+Space: launcher, Super+V: clipboard)..."
    mkdir -p "$shortcuts_dir"

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

    print_success "Noctalia shortcuts configured."
}

_start_noctalia_daemon() {
    if ! noctalia msg status >/dev/null 2>&1; then
        print_info "Starting Noctalia daemon..."
        noctalia --daemon
        print_success "Noctalia daemon started."
    else
        print_skip "Noctalia daemon is already running"
    fi
}

setup_noctalia() {
    if ! command -v noctalia >/dev/null 2>&1; then
        print_skip "Noctalia (noctalia not found)"
        return 0
    fi

    _configure_noctalia_config
    _configure_noctalia_autostart
    _configure_noctalia_shortcuts
    _start_noctalia_daemon
}

# Alias for compatibility if called as configure_noctalia
configure_noctalia() {
    setup_noctalia
}
