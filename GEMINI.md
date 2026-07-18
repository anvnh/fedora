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

## Project Structure

### setup.sh

`setup.sh` is the application's entry point.

It MUST follow this structure:

1. Source all libraries.
2. Source all modules.
3. Execute each module's public function.

Example:

```bash
source lib/common.sh
source lib/check.sh
source lib/install.sh

source modules/dnf.sh
source modules/flatpak.sh
source modules/git.sh
source modules/gnome.sh

setup_dnf
setup_flatpak
setup_git
setup_gnome
```

Do NOT interleave sourcing and execution.

Incorrect:

```bash
source modules/dnf.sh
setup_dnf

source modules/git.sh
setup_git
```

Always load every dependency before executing any setup function.

---

## Bash Style

- Use `#!/usr/bin/env bash`
- Use `set -euo pipefail`
- Quote all variables.
- Prefer functions over duplicated code.
- Each module should expose one public entry function.
- Helper functions should remain private to the module.
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
print_skip "<package>"
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
        print_skip "Git"
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
print_skip() {
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

```
.
├── lib
│   ├── common.sh
│   ├── check.sh
│   └── install.sh
│
├── modules
│   ├── dnf.sh
│   ├── flatpak.sh
│   ├── git.sh
│   ├── gnome.sh
│   └── ghostty.sh
│
└── setup.sh
```

### lib/

Contains reusable helper functions only.

Examples:

- `print_info`
- `print_success`
- `has_flatpak`
- `install_flatpak`
- `install_dnf_group`

### modules/

Each module represents one part of the Fedora setup.

Each module should expose **one public function** named:

```bash
setup_<module>()
```

Examples:

```bash
setup_dnf()
setup_git()
setup_gnome()
setup_ghostty()
```

Private helper functions should begin with an underscore.

Example:

```bash
_configure_git_identity()
_configure_git_editor()
```

---

## Module Design

Each module should:

- Expose one public `setup_<module>()` function.
- Use helper functions from `lib/`.
- Keep implementation details inside the module.
- Avoid executing code when sourced.

Example:

```bash
setup_git() {
    _configure_identity
    _configure_editor
}
```

Do not execute setup logic immediately when the module is sourced.

---

## Public API

Only these functions should be called from `setup.sh`:

```bash
setup_dnf
setup_flatpak
setup_git
setup_gnome
...
```

All other functions are considered internal to their module and should not be called outside that file.

---

## Error Handling

If an installation fails:

- stop immediately unless explicitly intended
- print an error message
- never silently ignore failures

---

## What Gemini Should Do

When generating new modules:

- Expose exactly one public `setup_<module>()` function.
- Use existing helper functions from `lib/`.
- Create private helper functions only when needed.
- Avoid duplicating installation logic.
- Keep modules focused on a single responsibility.