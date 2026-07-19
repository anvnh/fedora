#!/bin/bash
set -euo pipefail

# Get the directory of the current script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ================ lib ================ #
source "$SCRIPT_DIR/lib/common.sh"
source "$SCRIPT_DIR/lib/install.sh"

# Auto-resume cleanup
AUTOSTART_FILE="$HOME/.config/autostart/resume-setup-fedora.desktop"
if [[ -f "$AUTOSTART_FILE" ]]; then
    print_info "Resuming setup after reboot..."
    rm -f "$AUTOSTART_FILE"
fi

# Run modules
for file in "$SCRIPT_DIR/modules/"*.sh; do
    [[ -f "$file" ]] && source "$file"
done

setup_install_packages
setup_git
setup_configure_desktop
setup_ghostty
setup_tmux

print_success "All setup modules completed successfully."
