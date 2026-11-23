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

_detect_internal_batteries() {
    local bats=()
    for ps in /sys/class/power_supply/*; do
        [[ -d "$ps" ]] || continue

        local type scope present
        type=$(cat "$ps/type" 2>/dev/null || true)
        scope=$(cat "$ps/scope" 2>/dev/null || true)
        present=$(cat "$ps/present" 2>/dev/null || echo "1")

        # Exclude non-batteries and external peripherals (e.g. mouse/keyboard with scope=Device)
        if [[ "$type" == "Battery" && "$scope" != "Device" && "$present" == "1" ]]; then
            bats+=("$ps")
        fi
    done
    echo "${bats[@]}"
}

setup_battery() {
    local target_threshold="${1:-60}"
    local batteries
    read -r -a batteries <<< "$(_detect_internal_batteries)"

    if [[ ${#batteries[@]} -eq 0 || -z "${batteries[0]:-}" ]]; then
        print_skip "Battery charge threshold (no internal battery detected)"
        return 0
    fi

    local supported_bats=()
    for bat in "${batteries[@]}"; do
        if [[ -f "$bat/charge_control_end_threshold" ]]; then
            supported_bats+=("$bat")
        fi
    done

    if [[ ${#supported_bats[@]} -eq 0 ]]; then
        print_warning "Battery detected, but charge_control_end_threshold is not supported by kernel/hardware."
        return 0
    fi

    local service_file="/etc/systemd/system/battery-charge-threshold.service"
    local udev_file="/etc/udev/rules.d/60-battery-charge-threshold.rules"
    local needs_update=false

    # Check current runtime values
    for bat in "${supported_bats[@]}"; do
        local cur_val
        cur_val=$(cat "$bat/charge_control_end_threshold" 2>/dev/null || echo "")
        if [[ "$cur_val" != "$target_threshold" ]]; then
            needs_update=true
            break
        fi
    done

    # Check persistence files
    if [[ ! -f "$service_file" ]] || [[ ! -f "$udev_file" ]]; then
        needs_update=true
    elif ! grep -q "ATTR{charge_control_end_threshold}=\"$target_threshold\"" "$udev_file" 2>/dev/null; then
        needs_update=true
    elif ! systemctl is-enabled battery-charge-threshold.service &>/dev/null; then
        needs_update=true
    fi

    if [[ "$needs_update" == false ]]; then
        print_skip "Battery charge threshold (already set to ${target_threshold}%)"
        return 0
    fi

    print_info "Configuring battery charge limit to ${target_threshold}%..."

    # 1. Apply to runtime immediately
    for bat in "${supported_bats[@]}"; do
        echo "$target_threshold" | sudo tee "$bat/charge_control_end_threshold" >/dev/null
    done

    # 2. Setup udev rule (for hotplug, AC adapter events, wake from suspend)
    cat <<EOF | sudo tee "$udev_file" >/dev/null
ACTION=="add|change", SUBSYSTEM=="power_supply", ATTR{type}=="Battery", ATTR{charge_control_end_threshold}="$target_threshold"
EOF
    sudo udevadm control --reload-rules 2>/dev/null || true

    # 3. Setup systemd service (for boot and resume)
    cat <<EOF | sudo tee "$service_file" >/dev/null
[Unit]
Description=Set Battery Charge Threshold to ${target_threshold}%
After=multi-user.target suspend.target hibernate.target hybrid-sleep.target
DefaultDependencies=no
After=sysinit.target local-fs.target systemd-modules-load.service

[Service]
Type=oneshot
ExecStart=/bin/sh -c 'for f in /sys/class/power_supply/*/charge_control_end_threshold; do [ -f "\$f" ] && echo $target_threshold > "\$f"; done'
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target suspend.target hibernate.target hybrid-sleep.target
EOF

    sudo systemctl daemon-reload
    sudo systemctl enable --now battery-charge-threshold.service >/dev/null 2>&1

    print_success "Battery charge threshold set to ${target_threshold}% (persistent across reboots)."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    set -euo pipefail
    if [[ "$EUID" -eq 0 ]]; then
        print_error "Run this script as a regular user."
        exit 1
    fi
    setup_battery "${1:-60}"
fi
