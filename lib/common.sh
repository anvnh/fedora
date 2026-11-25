#!/bin/bash

RED="\033[1;91m"
GREEN="\033[1;92m"
YELLOW="\033[1;93m"
BLUE="\033[1;94m"
MAGENTA="\033[1;95m"
CYAN="\033[1;96m"
WHITE="\033[1;97m"
NC="\033[0m"

print_success() {
    echo -e "${GREEN}[SUCCESS] $1${NC}"
}

print_info() {
    echo -e "${YELLOW}[INFO] $1${NC}"
}

print_warning() {
    echo -e "${MAGENTA}[WARNING] $1${NC}"
}

print_error() {
    echo -e "${RED}[ERROR] $1${NC}"
}

print_skip() {
    local color="${2:-$CYAN}"
    echo -e "${color}[SKIP]${NC} $1"
}

check_environment() {
    if ((EUID == 0)); then
        print_error "Run this script as a regular user, not root."
        return 1
    fi

    if [[ ! -r /etc/os-release ]]; then
        print_error "Unable to identify the operating system."
        return 1
    fi

    local os_id
    os_id=$(
        source /etc/os-release
        printf '%s' "${ID:-unknown}"
    )

    if [[ "$os_id" != "fedora" ]]; then
        print_error "This project only supports Fedora Linux."
        return 1
    fi

    if [[ ":${XDG_CURRENT_DESKTOP:-}:" != *":KDE:"* ]]; then
        print_error "This project requires a KDE Plasma session."
        return 1
    fi

    local required_commands=(sudo dnf rpm busctl)
    local cmd

    for cmd in "${required_commands[@]}"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            print_error "Required command not found: $cmd"
            return 1
        fi
    done

    if ! busctl --user status org.kde.KWin >/dev/null 2>&1; then
        print_error "KWin is not available in the current session."
        return 1
    fi

    if ! sudo -v; then
        print_error "Unable to obtain sudo privileges."
        return 1
    fi

    print_success "Environment checks passed."
}

request_reboot_and_resume() {
    local script_path="$1"

    print_warning "System requires a reboot to continue."
    print_info "Setting up auto-resume mechanism..."

    local autostart_dir="$HOME/.config/autostart"
    mkdir -p "$autostart_dir"

    local desktop_file="$autostart_dir/resume-setup-fedora.desktop"

    local term_cmd
    if command -v ghostty >/dev/null 2>&1; then
        term_cmd="ghostty -e"
    elif command -v konsole >/dev/null 2>&1; then
        term_cmd="konsole -e"
    elif command -v ptyxis >/dev/null 2>&1; then
        term_cmd="ptyxis --"
    else
        term_cmd="xterm -e"
    fi

    cat <<EOF >"$desktop_file"
[Desktop Entry]
Type=Application
Name=Resume Fedora Setup
Exec=$term_cmd bash -c '"$1"; exec "\$SHELL"' _ "$script_path"
Hidden=false
EOF

    print_warning "Rebooting in 5 seconds... Press Ctrl+C to abort."
    sleep 5
    sudo systemctl reboot -i
}
