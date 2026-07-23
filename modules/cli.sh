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

_set_default_shell_zsh() {
    local zsh_path
    zsh_path=$(command -v zsh)

    if [[ "$SHELL" == "$zsh_path" ]]; then
        print_skip "Default shell (zsh)"
        return
    fi

    print_info "Setting zsh as default shell..."
    chsh -s "$zsh_path" "$USER"
    print_success "Default shell set to zsh"
    request_reboot_and_resume "$SCRIPT_DIR/setup.sh"
}

_install_powerlevel10k() {
    local p10k_dir="$HOME/.powerlevel10k"

    if [[ -d "$p10k_dir" ]]; then
        print_skip "Powerlevel10k theme"
        return
    fi

    print_info "Installing Powerlevel10k theme..."
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$p10k_dir"
    print_success "Powerlevel10k theme installed."
}

_install_zsh() {
    install_dnf "zsh" zsh
    link_config "zsh" "$SCRIPT_DIR/configs/.zshrc" "$HOME/.zshrc"
    _set_default_shell_zsh
    _install_powerlevel10k
}

setup_cli() {
    _install_ghostty
    
    install_dnf "tmux" tmux
    link_config "tmux" "$SCRIPT_DIR/configs/.tmux.conf" "$HOME/.config/tmux/tmux.conf"

    _install_zsh
}
