#!/bin/bash
# dnf.sh: DNF configuration

print_info "Maximize DNF download speed and force IPv4 routing..."
grep -qxF 'max_parallel_downloads=10' /etc/dnf/dnf.conf || echo 'max_parallel_downloads=10' | sudo tee -a /etc/dnf/dnf.conf
grep -qxF 'fastestmirror=True' /etc/dnf/dnf.conf || echo 'fastestmirror=True' | sudo tee -a /etc/dnf/dnf.conf
grep -qxF 'defaultyes=True' /etc/dnf/dnf.conf || echo 'defaultyes=True' | sudo tee -a /etc/dnf/dnf.conf
grep -qxF 'ip_resolve=4' /etc/dnf/dnf.conf || echo 'ip_resolve=4' | sudo tee -a /etc/dnf/dnf.conf
print_success "DNF configuration updated"

print_info "Update system packages..."
# sudo dnf update -y

print_info "Installing utility packages..."
sudo dnf install wl-clipboard libgda libgda-sqlite gsound -y
print_success "Utility packages installed"

if flatpak info com.mattjakeman.ExtensionManager >/dev/null 2>&1; then
    print_installed "Extension Manager"
else
    print_info "Install extension manager..."
    flatpak install -y flathub com.mattjakeman.ExtensionManager
    print_success "Extension manager installed"
fi

PACKAGE_SUPERPRODUCTIVITY="com.super_productivity.SuperProductivity"
if flatpak info  $PACKAGE_SUPERPRODUCTIVITY >/dev/null 2>&1; then
    print_installed "Super Productivity"
else
    print_info "Installing Super Productivity..."
    flatpak install -y flathub $PACKAGE_SUPERPRODUCTIVITY
    print_success "Super Productivity installed"
fi
