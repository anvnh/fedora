setup_fonts() {
    _install_nerd_font
}

_install_nerd_font() {
    local font_name="JetBrainsMono Nerd Font"
    local font_dir="$HOME/.local/share/fonts"
    local marker="$font_dir/JetBrainsMonoNerdFont-Regular.ttf"

    if [[ -f "$marker" ]]; then
        print_skip "$font_name"
        return
    fi

    print_info "Installing $font_name..."

    local tmp_zip
    tmp_zip=$(mktemp --suffix=.zip)
    curl -fLo "$tmp_zip" \
        "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip"

    mkdir -p "$font_dir"
    unzip -oq "$tmp_zip" -d "$font_dir"
    rm -f "$tmp_zip"

    fc-cache -f "$font_dir" >/dev/null
    print_success "$font_name installed"
}