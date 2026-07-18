#!/bin/bash
set -euo pipefail

# Get the directory of the current script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ================ lib ================ #
source "$SCRIPT_DIR/lib/common.sh"
source "$SCRIPT_DIR/lib/install.sh"

# Run modules
source "$SCRIPT_DIR/modules/dnf.sh"
source "$SCRIPT_DIR/modules/git.sh"
source "$SCRIPT_DIR/modules/gnome.sh"
source "$SCRIPT_DIR/modules/ghostty.sh"

setup_dnf
setup_git
setup_gnome
setup_ghostty

print_success "All setup modules completed successfully."
