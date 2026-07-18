#!/bin/bash
# gnome.sh: GNOME configurations

if [ "$(gsettings get org.gnome.desktop.input-sources xkb-options)" = "['ctrl:nocaps']" ]; then
    print_installed "Caps Lock to Ctrl remapping"
else
    print_info "Remapping Caps Lock to Ctrl..."
    gsettings set org.gnome.desktop.input-sources xkb-options "['ctrl:nocaps']"

    if [ "$(gsettings get org.gnome.desktop.input-sources xkb-options)" = "['ctrl:nocaps']" ]; then
        print_success "Caps Lock mapped to Ctrl."
    else
        echo -e "${RED}[ERROR] Failed to map Caps Lock. State verification failed.${NC}"
        exit 1
    fi
fi

if [ "$(gsettings get org.gnome.desktop.interface color-scheme)" = "'prefer-dark'" ]; then
    print_installed "GNOME Dark Mode"
else
    print_info "Setting GNOME theme to Dark Mode..."
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
    print_success "GNOME Dark Mode enabled."
fi

gsettings set org.gnome.desktop.interface gtk-enable-primary-paste true
