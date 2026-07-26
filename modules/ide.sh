#!/usr/bin/env bash

_install_vscode() {
    if flatpak info "com.visualstudio.code" >/dev/null 2>&1; then
        print_info "Removing Flatpak Visual Studio Code..."
        flatpak uninstall -y com.visualstudio.code
        print_success "Flatpak Visual Studio Code removed."
    fi

    if command -v code >/dev/null 2>&1 || rpm -q code >/dev/null 2>&1; then
        print_skip "Visual Studio Code"
        return
    fi

    print_info "Installing Visual Studio Code..."

    if [[ ! -f /etc/yum.repos.d/vscode.repo ]]; then
        sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
        cat <<'EOF' | sudo tee /etc/yum.repos.d/vscode.repo >/dev/null
[vscode]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
EOF
    fi

    if command -v dnf5 >/dev/null 2>&1; then
        sudo dnf5 install -y code
    else
        sudo dnf install -y code
    fi

    print_success "Visual Studio Code installed."
}

setup_ide() {
    _install_vscode
}
