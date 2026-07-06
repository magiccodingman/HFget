#!/usr/bin/env bash
set -euo pipefail

# ------------------------------
# Helpers
# ------------------------------

error() {
    echo -e "\e[31m[ERROR]\e[0m $1" >&2
    exit 1
}

info() {
    echo -e "\e[34m[INFO]\e[0m $1"
}

ok() {
    echo -e "\e[32m[OK]\e[0m $1"
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

run_as_root() {
    if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
        "$@"
    else
        command_exists sudo || error "sudo is required to install missing dependencies."
        sudo "$@"
    fi
}

usage() {
    cat <<'EOF'
Usage:
  hfget [options] <repo_id> <base_local_dir>

Examples:
  hfget Qwen/Qwen3-4B-Thinking-2507 /mnt/world7/AI/Models/
  hfget --force unsloth/Qwen3-4B-Instruct-2507 /mnt/world7/AI/Models/

Options:
  -f, --force    Force Hugging Face CLI to re-download files.
  -h, --help     Show this help message.

Default behavior:
  Existing completed files are reused/skipped by the Hugging Face CLI.
  Use --force only when you intentionally want a fresh download.
EOF
}

install_pipx() {
    info "pipx not found. Installing it with the detected package manager..."

    if command_exists apt-get; then
        run_as_root apt-get update
        run_as_root apt-get install -y pipx python3-venv
    elif command_exists dnf; then
        run_as_root dnf install -y pipx
    elif command_exists pacman; then
        run_as_root pacman -Sy --needed --noconfirm python-pipx
    else
        error "pipx is missing and I couldn't detect apt, dnf, or pacman. Please install pipx, then re-run hfget."
    fi

    ok "pipx installed."
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

ensure_hf_cli() {
    if HF_BIN="$(find_hf_cli)"; then
        ok "'hf' CLI detected at $HF_BIN."
        return 0
    fi

    command_exists pipx || install_pipx

    info "'hf' CLI not found. Installing huggingface-hub via pipx..."
    pipx install huggingface-hub

    # Make future shells friendlier, but do not require the user to reload PATH.
    pipx ensurepath >/dev/null 2>&1 || true

    if HF_BIN="$(find_hf_cli)"; then
        ok "'hf' CLI installed at $HF_BIN."
        return 0
    fi

    error "huggingface-hub installed, but I still can't find the 'hf' command. Try opening a new shell or check pipx."
}

pause_for_confirmation() {
    read -r -p "⚠️  Continue anyway? (y/N): " answer
    case "$answer" in
        y|Y) ;;
        *) echo "Aborted."; exit 1 ;;
    esac
}

# ------------------------------
# Arg Parsing
# ------------------------------

FORCE_DOWNLOAD=0
POSITIONAL=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        -f|--force)
            FORCE_DOWNLOAD=1
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        --)
            shift
            while [[ $# -gt 0 ]]; do
                POSITIONAL+=("$1")
                shift
            done
            ;;
        -*)
            error "Unknown option: $1"
            ;;
        *)
            POSITIONAL+=("$1")
            shift
            ;;
    esac
done

if [[ ${#POSITIONAL[@]} -ne 2 ]]; then
    usage
    exit 1
fi

REPO_ID="${POSITIONAL[0]}"      # e.g. unsloth/Qwen3-4B-Instruct-2507
BASE_DIR="${POSITIONAL[1]}"     # e.g. /mnt/world7/AI/Models/

[[ "$REPO_ID" == */* ]] || error "Repo ID must look like owner/model, for example: Qwen/Qwen3-4B-Thinking-2507"

# Trim trailing slash if present
BASE_DIR="${BASE_DIR%/}"

# ------------------------------
# Validate HF CLI
# ------------------------------

ensure_hf_cli

# ------------------------------
# Repo parsing
# ------------------------------

USER_NAME="${REPO_ID%%/*}"
MODEL_NAME="${REPO_ID##*/}"

# Folder naming convention:
#   Qwen3-4B-Instruct-2507-unsloth
TARGET_FOLDER="${MODEL_NAME}-${USER_NAME}"
TARGET_PATH="${BASE_DIR}/${TARGET_FOLDER}"

info "Derived folder name: $TARGET_FOLDER"
info "Full download path: $TARGET_PATH"

# ------------------------------
# Folder Existence Check
# ------------------------------

if [[ -d "$TARGET_PATH" ]]; then
    if [[ -n "$(ls -A "$TARGET_PATH" 2>/dev/null)" ]]; then
        echo "⚠️  Target folder already exists and contains files:"
        echo "    $TARGET_PATH"
        echo "Existing completed files will be reused/skipped unless --force is used."
        if [[ "$FORCE_DOWNLOAD" -eq 1 ]]; then
            echo "Force mode is enabled, so files may be re-downloaded."
            pause_for_confirmation
        fi
    else
        info "Folder exists but is empty. Continuing..."
    fi
else
    info "Creating folder: $TARGET_PATH"
    mkdir -p "$TARGET_PATH"
fi

# ------------------------------
# Download
# ------------------------------

info "Starting Hugging Face download…"

HF_ARGS=(
    download "$REPO_ID"
    --local-dir "$TARGET_PATH"
)

if [[ "$FORCE_DOWNLOAD" -eq 1 ]]; then
    HF_ARGS+=(--force-download)
fi

"$HF_BIN" "${HF_ARGS[@]}"

ok "Download complete!"
echo -e "\n✨ Your model is ready at:"
echo "   $TARGET_PATH"
