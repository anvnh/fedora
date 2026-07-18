# GEMINI.md

## Project Overview

This project automates Fedora setup after a fresh installation.

The project consists of Bash scripts that install packages, configure the system, and apply personal preferences.

Primary goals:

- Scripts must be idempotent.
- Scripts must be safe to run multiple times.
- Scripts should provide consistent terminal output.
- Avoid reinstalling software that already exists.

---

## Bash Style

- Use `#!/usr/bin/env bash`
- Use `set -euo pipefail`
- Quote all variables.
- Prefer functions over duplicated code.
- Keep functions small and focused.
- Avoid unnecessary subshells.

---

## Installation Rules

NEVER, NEVER, NEVER run directly script on the host machine. The developer will test the script on a virtual machine, any errors or requests will be send back to you via chat.

Every installation function MUST follow this workflow:

1. Check whether the package/application is already installed.
2. If installed:
   - Do not reinstall.
   - Call:

```bash
print_installed "<package>"
```

3. If not installed:
   - Call:

```bash
print_info "Installing <package>..."
```

4. Run the installation command.

5. If installation succeeds:

```bash
print_success "<package> installed."
```

Example:

```bash
install_git() {
    if command -v git >/dev/null 2>&1; then
        print_installed "Git"
        return
    fi

    print_info "Installing Git..."

    sudo dnf install -y git

    print_success "Git"
}
```

Never install a package without checking first.

---

## Output Functions

Always use these helper functions.

```bash
print_installed() {
    echo -e "${CYAN}[SKIP] $1${NC}"
}

print_info() {
    echo -e "${YELLOW}[INFO] $1${NC}"
}

print_success() {
    echo -e "${GREEN}[SUCCESS] $1${NC}"
}

print_error() {
    echo -e "${RED}[ERROR] $1${NC}"
}
```

Never use plain `echo` for status messages.

---

## Package Detection

Prefer checks in this order:

For commands:

```bash
command -v <command>
```

For RPM packages:

```bash
rpm -q <package>
```

For Flatpak:

```bash
flatpak info <app>
```

For systemd services:

```bash
systemctl list-unit-files
```

Choose the check that best matches how the software is installed.

---

## Script Requirements

Scripts should:

- be safe to rerun
- avoid duplicate configuration
- avoid interactive prompts when possible
- use `dnf5` instead of `dnf`
- prefer official Fedora repositories
- install COPR repositories only when required

---

## Code Organization

Keep installation logic separated.

Example:

```
scripts/
    common.sh
    packages.sh
    development.sh
    desktop.sh
    fonts.sh
    flatpak.sh
```

Each file should expose installation functions only.

---

## Error Handling

If an installation fails:

- stop immediately unless explicitly intended
- print an error message
- never silently ignore failures

---

## What Gemini Should Do

When generating new installation functions:

- Follow the standard installation workflow.
- Reuse existing helper functions.
- Never duplicate output formatting.
- Always check whether software is already installed.
- Prefer reusable helper functions over repeated logic.
- Match the style of the existing project.