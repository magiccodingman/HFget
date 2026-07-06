#!/usr/bin/env bash
set -euo pipefail

HFGET_INSTALL_PATH="${HFGET_INSTALL_PATH:-/usr/local/bin/hfget}"
PURGE_HF=0

usage() {
    cat <<'EOF'
Usage:
  uninstall.sh [options]

Options:
  --purge-hf    Also uninstall huggingface-hub from pipx if it was installed there.
  -h, --help    Show this help message.

By default, this only removes the hfget command and leaves pipx / Hugging Face CLI alone.
EOF
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

run_as_root() {
    if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
        "$@"
    else
        command_exists sudo || { echo "[ERROR] sudo is required to remove $HFGET_INSTALL_PATH" >&2; exit 1; }
        sudo "$@"
    fi
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --purge-hf)
            PURGE_HF=1
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "[ERROR] Unknown option: $1" >&2
            usage
            exit 1
            ;;
    esac
done

if [[ -e "$HFGET_INSTALL_PATH" || -L "$HFGET_INSTALL_PATH" ]]; then
    run_as_root rm -f "$HFGET_INSTALL_PATH"
    echo "[OK] Removed $HFGET_INSTALL_PATH"
else
    echo "[INFO] hfget was not found at $HFGET_INSTALL_PATH"
fi

if [[ "$PURGE_HF" -eq 1 ]]; then
    if command_exists pipx; then
        pipx uninstall huggingface-hub || true
        echo "[OK] Requested pipx uninstall for huggingface-hub"
    else
        echo "[INFO] pipx is not installed, so there is nothing to purge."
    fi
fi

echo "[OK] Uninstall complete."
