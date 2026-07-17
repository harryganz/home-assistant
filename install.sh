#!/usr/bin/env bash
# Installs Podman + podman-compose + make on the current Linux host.
# Safe to re-run: skips anything already installed.
set -euo pipefail

log() { printf '==> %s\n' "$1"; }
err() { printf 'ERROR: %s\n' "$1" >&2; }

have() { command -v "$1" >/dev/null 2>&1; }

install_debian() {
    sudo apt-get update
    sudo apt-get install -y podman make
    if have podman-compose; then
        return
    fi
    if apt-cache show podman-compose >/dev/null 2>&1; then
        sudo apt-get install -y podman-compose
    else
        log "podman-compose not available via apt; installing via pip instead"
        sudo apt-get install -y python3-pip
        pip3 install --user podman-compose
    fi
}

install_fedora() {
    sudo dnf install -y podman podman-compose make
}

install_arch() {
    sudo pacman -S --noconfirm --needed podman podman-compose make
}

main() {
    if have podman && have podman-compose && have make; then
        log "podman, podman-compose, and make already installed, nothing to do"
        podman --version
        podman-compose --version
        make --version | head -n1
        exit 0
    fi

    if [ -f /etc/os-release ]; then
        # shellcheck disable=SC1091
        . /etc/os-release
        ID_LIKE="${ID_LIKE:-}"
    else
        err "/etc/os-release not found; cannot detect distro"
        exit 1
    fi

    case "${ID:-}" in
        fedora|rhel|centos|rocky|almalinux)
            log "Detected Fedora/RHEL-family distro (${ID})"
            install_fedora
            ;;
        debian|ubuntu)
            log "Detected Debian/Ubuntu-family distro (${ID})"
            install_debian
            ;;
        arch|manjaro|endeavouros)
            log "Detected Arch-family distro (${ID})"
            install_arch
            ;;
        *)
            case "$ID_LIKE" in
                *fedora*|*rhel*)
                    log "Detected Fedora/RHEL-like distro (${ID:-unknown}, like: ${ID_LIKE})"
                    install_fedora
                    ;;
                *debian*)
                    log "Detected Debian-like distro (${ID:-unknown}, like: ${ID_LIKE})"
                    install_debian
                    ;;
                *arch*)
                    log "Detected Arch-like distro (${ID:-unknown}, like: ${ID_LIKE})"
                    install_arch
                    ;;
                *)
                    err "Unsupported/unrecognized distro (ID=${ID:-unknown}, ID_LIKE=${ID_LIKE:-unknown})."
                    err "Please install 'podman', 'podman-compose', and 'make' manually using your package manager."
                    exit 1
                    ;;
            esac
            ;;
    esac

    log "Verifying installation"
    podman --version
    podman-compose --version
    make --version | head -n1
    log "Done. Run: make install"
}

main "$@"
