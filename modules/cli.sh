#!/usr/bin/env bash

_configure_ghostty_shortcut() {
    if ! command -v kwriteconfig6 >/dev/null 2>&1; then
        print_skip "Ghostty keyboard shortcut (kwriteconfig6 not found)"
        return 0
    fi

    local desktop_app="com.mitchellh.ghostty.desktop"
    if [[ ! -f "/usr/share/applications/$desktop_app" ]] && [[ -f "/usr/share/applications/ghostty.desktop" ]]; then
        desktop_app="ghostty.desktop"
    fi

    local current_shortcut
    current_shortcut=$(kreadconfig6 --file kglobalshortcutsrc --group "$desktop_app" --key _launch 2>/dev/null || true)

    if [[ "$current_shortcut" == *"Meta+Return"* ]]; then
        print_skip "Ghostty keyboard shortcut"
        return 0
    fi

    print_info "Configuring Ghostty keyboard shortcut..."
    kwriteconfig6 --file kglobalshortcutsrc --group "$desktop_app" --key _launch "Meta+Return,none,Ghostty"
    qdbus6 org.kde.kglobalaccel /kglobalaccel org.kde.KGlobalAccel.reloadConfig >/dev/null 2>&1 || true

    print_success "Ghostty keyboard shortcut configured."
}

_install_ghostty() {
    if command -v ghostty >/dev/null 2>&1; then
        print_skip "Ghostty"
    else
        print_info "Installing Ghostty from COPR..."

        sudo dnf copr enable -y scottames/ghostty
        sudo dnf install -y ghostty

        print_success "Ghostty installed."
    fi

    _configure_ghostty_shortcut
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
    link_config "WakaTime" "$SCRIPT_DIR/configs/.wakatime.cfg" "$HOME/.wakatime.cfg"

    _install_zsh
}
