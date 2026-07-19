#!/bin/bash
setup_gnome() {
    if [ "$(gsettings get org.gnome.desktop.input-sources xkb-options)" = "['ctrl:nocaps']" ]; then
        print_skip "Caps Lock to Ctrl remapping"
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
        print_skip "GNOME Dark Mode"
    else
        print_info "Setting GNOME theme to Dark Mode..."
        gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
        print_success "GNOME Dark Mode enabled."
    fi

    gsettings set org.gnome.desktop.interface gtk-enable-primary-paste true

    if [ "$(gsettings get org.gnome.shell.keybindings show-screenshot-ui)" = "['<Shift><Super>s']" ]; then
        print_skip "GNOME Screenshot shortcut"
    else
        print_info "Setting GNOME Screenshot shortcut to Super+Shift+S..."
        gsettings set org.gnome.shell.keybindings show-screenshot-ui "['<Shift><Super>s']"
        print_success "GNOME Screenshot shortcut configured."
    fi

    if [ "$(gsettings get org.gnome.desktop.wm.keybindings toggle-maximized)" = "['<Alt>Return']" ]; then
        print_skip "GNOME Maximize shortcut"
    else
        print_info "Setting GNOME Maximize shortcut to Alt+Enter..."
        gsettings set org.gnome.desktop.wm.keybindings toggle-maximized "['<Alt>Return']"
        print_success "GNOME Maximize shortcut configured."
    fi
}
