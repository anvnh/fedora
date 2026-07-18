#!/bin/bash
set -euo pipefail

# Get the directory of the current script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ================ lib ================ #
source "$SCRIPT_DIR/lib/common.sh"
source "$SCRIPT_DIR/lib/install.sh"

# Run modules
for file in "$SCRIPT_DIR/modules/"*.sh; do
    [[ -f "$file" ]] && source "$file"
done

setup_dnf
setup_git
setup_gnome
setup_ghostty
setup_tmux

print_success "All setup modules completed successfully."
