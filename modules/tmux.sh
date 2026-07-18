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

setup_tmux() {
    install_dnf "tmux" tmux
    _configure_tmux
}