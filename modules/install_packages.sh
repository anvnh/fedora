#!/usr/bin/env bash

_INSTALL_PACKAGES_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

_configure_dnf() {
    local main_config
    main_config=$(dnf --dump-main-config) || return 1

    local -a expected_opts=(
        "max_parallel_downloads = 10"
        "fastestmirror = 1"
        "defaultyes = 1"
        "ip_resolve = ipv4"
    )

    local needs_update=false
    local opt
    for opt in "${expected_opts[@]}"; do
        if ! grep -qxF "$opt" <<< "$main_config"; then
            needs_update=true
            break
        fi
    done

    if [[ "$needs_update" == false ]]; then
        print_skip "DNF configuration"
        return 0
    fi

    print_info "Maximize DNF download speed and force IPv4 routing..."
    sudo dnf config-manager setopt \
        max_parallel_downloads=10 \
        fastestmirror=True \
        defaultyes=True \
        ip_resolve=4 || return 1
    print_success "DNF configuration updated"
}

_enable_third_party_repos() {
    if fedora-third-party query | grep -q 'enabled'; then
        print_skip "Third-party repositories"
        return 0
    fi

    print_info "Enabling third-party repositories..."
    sudo fedora-third-party enable
    print_success "Third-party repositories enabled."
}

_trim_whitespace() {
    local value="$1"
    value="${value#"${value%%[![:space:]]*}"}"
    value="${value%"${value##*[![:space:]]}"}"
    printf '%s' "$value"
}

_install_dnf_packages() {
    local list_file="$_INSTALL_PACKAGES_DIR/packages/dnf.txt"
    local -a packages=()
    local line

    if [[ ! -f "$list_file" ]]; then
        print_error "DNF package list not found: $list_file"
        return 1
    fi

    while IFS= read -r line || [[ -n "$line" ]]; do
        line=$(_trim_whitespace "${line%%#*}")
        [[ -z "$line" ]] && continue
        packages+=("$line")
    done <"$list_file"

    if ((${#packages[@]} == 0)); then
        print_skip "Essentials Packages (empty list)"
        return 0
    fi

    install_dnf "Essentials Packages" "${packages[@]}"
}

_install_flatpak_apps() {
    local list_file="$_INSTALL_PACKAGES_DIR/packages/flatpak.txt"
    local line app_id app_name

    if [[ ! -f "$list_file" ]]; then
        print_error "Flatpak package list not found: $list_file"
        return 1
    fi

    while IFS= read -r line || [[ -n "$line" ]]; do
        line=$(_trim_whitespace "${line%%#*}")
        [[ -z "$line" ]] && continue

        if [[ "$line" != *"|"* ]]; then
            print_error "Invalid Flatpak entry (expected '<app_id> | <display_name>'): $line"
            return 1
        fi

        app_id=$(_trim_whitespace "${line%%|*}")
        app_name=$(_trim_whitespace "${line#*|}")
        if [[ -z "$app_id" || -z "$app_name" ]]; then
            print_error "Invalid Flatpak entry (missing app ID or display name): $line"
            return 1
        fi

        install_flatpak "$app_name" "$app_id"
    done <"$list_file"
}

setup_install_packages() {
    _configure_dnf
    _enable_third_party_repos

    # print_info "Update system packages..."
    # sudo dnf update -y

    _install_dnf_packages
    _install_flatpak_apps
}
