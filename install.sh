#!/usr/bin/env bash
set -euo pipefail

HFGET_OWNER="${HFGET_OWNER:-magiccodingman}"
HFGET_REPO="${HFGET_REPO:-HFget}"
HFGET_REF="${HFGET_REF:-main}"
HFGET_RAW_BASE="${HFGET_RAW_BASE:-https://raw.githubusercontent.com/${HFGET_OWNER}/${HFGET_REPO}/${HFGET_REF}}"
HFGET_INSTALL_PATH="${HFGET_INSTALL_PATH:-/usr/local/bin/hfget}"

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

info() {
    echo -e "\e[34m[INFO]\e[0m $1"
}

ok() {
    echo -e "\e[32m[OK]\e[0m $1"
}

error() {
    echo -e "\e[31m[ERROR]\e[0m $1" >&2
    exit 1
}

run_as_root() {
    if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
        "$@"
    else
        command_exists sudo || error "sudo is required for installation."
        sudo "$@"
    fi
}

detect_package_manager() {
    if command_exists apt-get; then
        echo "apt"
    elif command_exists dnf; then
        echo "dnf"
    elif command_exists pacman; then
        echo "pacman"
    else
        echo "unknown"
    fi
}

install_system_dependencies() {
    local pm
    pm="$(detect_package_manager)"

    info "Checking system dependencies..."

    case "$pm" in
        apt)
            run_as_root apt-get update
            run_as_root apt-get install -y curl ca-certificates pipx python3-venv
            ;;
        dnf)
            run_as_root dnf install -y curl ca-certificates pipx
            ;;
        pacman)
            run_as_root pacman -Sy --needed --noconfirm curl ca-certificates python-pipx
            ;;
        *)
            error "Unsupported package manager. Please install curl and pipx manually, then re-run this installer."
            ;;
    esac

    ok "System dependencies are ready."
}

find_hf_cli() {
    if command_exists hf; then
        command -v hf
        return 0
    fi

    if [[ -x "$HOME/.local/bin/hf" ]]; then
        echo "$HOME/.local/bin/hf"
        return 0
    fi

    return 1
}

install_huggingface_cli() {
    if find_hf_cli >/dev/null; then
        ok "Hugging Face CLI is already installed."
        return 0
    fi

    command_exists pipx || install_system_dependencies

    info "Installing huggingface-hub via pipx..."
    pipx install huggingface-hub
    pipx ensurepath >/dev/null 2>&1 || true

    if find_hf_cli >/dev/null; then
        ok "Hugging Face CLI installed."
    else
        error "huggingface-hub installed, but the 'hf' command was not found. Try opening a new shell and running hfget again."
    fi
}

download_hfget() {
    local tmpfile
    tmpfile="$(mktemp)"

    info "Downloading hfget from ${HFGET_RAW_BASE}/hfget.sh"

    if command_exists curl; then
        curl -fsSL "${HFGET_RAW_BASE}/hfget.sh" -o "$tmpfile"
    elif command_exists wget; then
        wget -qO "$tmpfile" "${HFGET_RAW_BASE}/hfget.sh"
    else
        error "curl or wget is required to download hfget."
    fi

    chmod +x "$tmpfile"
    run_as_root install -m 0755 "$tmpfile" "$HFGET_INSTALL_PATH"
    rm -f "$tmpfile"

    ok "Installed hfget to $HFGET_INSTALL_PATH"
}

install_system_dependencies
install_huggingface_cli
download_hfget

echo
ok "hfget is installed."
echo "Try:"
echo "  hfget Qwen/Qwen3-4B-Thinking-2507 /mnt/world7/AI/Models/"
