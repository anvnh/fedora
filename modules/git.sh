configure_git_credentials() {
    local current_name current_email
    current_name=$(git config --global user.name || true)
    current_email=$(git config --global user.email || true)

    if [[ -n "$current_name" && -n "$current_email" ]]; then
        print_installed "Git identity ($current_name <$current_email>)"
        return
    fi

    print_info "Configuring Git..."

    local git_name git_email

    read -rp "Git username: " git_name
    read -rp "Git email: " git_email

    git config --global user.name "$git_name"
    git config --global user.email "$git_email"

    print_success "Git configured"
}