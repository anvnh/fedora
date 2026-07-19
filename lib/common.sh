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

request_reboot_and_resume() {
    local script_path="$1"
    
    print_warning "System requires a reboot to continue."
    print_info "Setting up auto-resume mechanism..."
    
    local autostart_dir="$HOME/.config/autostart"
    mkdir -p "$autostart_dir"
    
    local desktop_file="$autostart_dir/resume-setup-fedora.desktop"
    
    cat <<EOF > "$desktop_file"
[Desktop Entry]
Type=Application
Name=Resume Fedora Setup
Exec=ptyxis -- bash -c '"$1"; exec bash' _ "$script_path"
Hidden=false
X-GNOME-Autostart-enabled=true
EOF

    print_warning "Rebooting in 5 seconds... Press Ctrl+C to abort."
    sleep 5
    sudo reboot
}
