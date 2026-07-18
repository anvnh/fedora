#!/bin/bash
set -euo pipefail

# Get the directory of the current script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source utility functions
source "$SCRIPT_DIR/modules/utils.sh"

# Run modules
source "$SCRIPT_DIR/modules/dnf.sh"
source "$SCRIPT_DIR/modules/gnome.sh"
source "$SCRIPT_DIR/modules/ghostty.sh"

print_success "All setup modules completed successfully."
