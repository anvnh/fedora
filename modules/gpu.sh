#!/usr/bin/env bash

# Resolve project root directory and source common helpers if available
_MODULE_PATH="$(readlink -f "${BASH_SOURCE[0]}")"
_PROJECT_ROOT="$(cd "$(dirname "$_MODULE_PATH")/.." && pwd)"

if [[ -f "$_PROJECT_ROOT/lib/common.sh" ]] && ! command -v print_info &>/dev/null; then
    # shellcheck source=/dev/null
    source "$_PROJECT_ROOT/lib/common.sh"
fi

if ! command -v print_info &>/dev/null; then
    print_info() { echo -e "\033[1;93m[INFO]\033[0m $1"; }
    print_warning() { echo -e "\033[1;95m[WARNING]\033[0m $1"; }
    print_success() { echo -e "\033[1;92m[SUCCESS]\033[0m $1"; }
    print_error() { echo -e "\033[1;91m[ERROR]\033[0m $1"; }
    print_skip() { echo -e "\033[1;96m[SKIP]\033[0m $1"; }
fi

install_gpu_drivers() {
    if ! command -v lspci &>/dev/null; then
        print_info "Installing pciutils..."
        sudo dnf install -y pciutils
    fi

    local has_amd=false
    local has_intel=false
    local has_nvidia=false
    local device_class vendor_id

    while read -r _ device_class vendor_id _; do
        [[ "$device_class" =~ ^03[[:xdigit:]]{2}:$ ]] || continue

        case "${vendor_id%%:*}" in
            1002) has_amd=true ;;
            8086) has_intel=true ;;
            10de) has_nvidia=true ;;
        esac
    done < <(lspci -Dn)

    local packages=(
        # 64-bit and 32-bit graphics stack (needed for Steam RPM, Wine, 32-bit games)
        mesa-dri-drivers
        mesa-dri-drivers.i686
        mesa-vulkan-drivers
        mesa-vulkan-drivers.i686
        vulkan-tools
        glx-utils
    )

    if [[ "$has_amd" == true ]]; then
        print_info "AMD GPU detected."
        packages+=(amd-gpu-firmware)
    fi

    if [[ "$has_intel" == true ]]; then
        print_info "Intel GPU detected."
        packages+=(intel-gpu-firmware)
    fi

    if [[ "$has_nvidia" == true ]]; then
        print_warning "NVIDIA GPU detected."
        print_warning "Proprietary NVIDIA drivers require separate setup."
    fi

    if [[ "$has_amd" == false && "$has_intel" == false ]]; then
        print_warning "No supported AMD or Intel GPU detected."
        return 0
    fi

    local missing=()
    local package

    for package in "${packages[@]}"; do
        if rpm -q "$package" &>/dev/null; then
            print_skip "$package is already installed."
        else
            missing+=("$package")
        fi
    done

    if (( ${#missing[@]} == 0 )); then
        print_success "All required GPU packages (64-bit & 32-bit) are installed."
        return 0
    fi

    sudo dnf install -y "${missing[@]}"

    print_success "GPU packages installed successfully."
}

setup_gpu() {
    install_gpu_drivers "$@"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    set -euo pipefail
    if [[ "$EUID" -eq 0 ]]; then
        print_error "Run this script as a regular user."
        exit 1
    fi
    install_gpu_drivers "$@"
fi
