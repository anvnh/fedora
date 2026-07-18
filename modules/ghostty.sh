#!/bin/bash

print_info "Installing Ghostty from COPR..."

sudo dnf copr enable -y scottames/ghostty
sudo dnf install -y ghostty

print_success "Ghostty installed."
