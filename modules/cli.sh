#!/bin/bash

_install_ghostty() {
    if command -v ghostty >/dev/null 2>&1; then
        print_skip "Ghostty"
    else
        print_info "Installing Ghostty from COPR..."

        sudo dnf copr enable -y scottames/ghostty
        sudo dnf install -y ghostty

        print_success "Ghostty installed."
    fi

    KEYBINDING_PATH="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/ghostty/"
    CURRENT_BINDINGS=$(gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings)

    if [[ "$CURRENT_BINDINGS" == *"$KEYBINDING_PATH"* ]] && \
       [ "$(gsettings get org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:"$KEYBINDING_PATH" binding)" == "'<Super>Return'" ]; then
        print_skip "Ghostty keyboard shortcut"
    else
        print_info "Configuring Ghostty keyboard shortcut..."
        
        if [[ "$CURRENT_BINDINGS" != *"$KEYBINDING_PATH"* ]]; then
            if [[ "$CURRENT_BINDINGS" == *"@"* ]] || [[ "$CURRENT_BINDINGS" == "[]" ]]; then
                NEW_BINDINGS="['$KEYBINDING_PATH']"
            else
                NEW_BINDINGS="${CURRENT_BINDINGS%]*}, '$KEYBINDING_PATH']"
            fi
            gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "$NEW_BINDINGS"
        fi

        gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:"$KEYBINDING_PATH" name 'Ghostty'
        gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:"$KEYBINDING_PATH" command 'ghostty'
        gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:"$KEYBINDING_PATH" binding '<Super>Return'

        print_success "Ghostty keyboard shortcut configured."
    fi
}

_configure_tmux() {
    local src="configs/.tmux.conf"
    local dst="$HOME/.config/tmux/tmux.conf"

    if cmp -s "$src" "$dst" 2>/dev/null; then
        print_skip "tmux configuration is up to date"
        return
    fi

    print_info "Installing tmux configuration..."

    mkdir -p "$(dirname "$dst")"
    cp "$src" "$dst"

    print_success "tmux configuration installed"
}

setup_cli() {
    _install_ghostty
    
    install_dnf "tmux" tmux
    _configure_tmux
}
