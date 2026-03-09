#!/bin/bash

# --- Load Environment Variables ---
ENV_FILE=".env"
if [ -f "$ENV_FILE" ]; then
    export $(grep -v '^#' "$ENV_FILE" | xargs)
else
    echo "Error: File $ENV_FILE tidak ditemukan."
    exit 1
fi

LOG_FILE="check.logs"

# --- Validasi Argumen ---
if [ -z "$1" ]; then
    echo "Usage: $0 <branch-or-tag-name> [source: github|bitbucket|both]"
    exit 1
fi

REF_NAME="$1"
SOURCE="${2:-github}"

# --- Fungsi ---
function detect_os() {
    if [ -f /etc/redhat-release ]; then echo "centos"
    elif [ -f /etc/debian_version ]; then echo "debian"
    elif [ -f /etc/arch-release ] || grep -q "arch" /etc/os-release || grep -q "cachyos" /etc/os-release; then echo "arch"
    else echo "unknown"; fi
}

function install_gh_cli() {
    local os_type=$(detect_os)
    case $os_type in
        "centos") sudo dnf install -y gh || sudo yum install -y gh ;;
        "debian") sudo apt update && sudo apt install -y gh ;;
        "arch") sudo pacman -Sy --noconfirm github-cli ;;
        *) exit 1 ;;
    esac
}

function check_command() {
    if ! command -v "$1" &> /dev/null; then
        if [ "$1" = "gh" ]; then install_gh_cli
        else exit 1; fi
    fi
}

function check_bitbucket_ref() {
    local repo_name="$1"
    local ref="$2"
    if git ls-remote --heads "https://bitbucket.org/${BITBUCKET_ORG}/${repo_name}.git" | grep -q "refs/heads/${ref}$" || \
       git ls-remote --tags "https://bitbucket.org/${BITBUCKET_ORG}/${repo_name}.git" | grep -q "refs/tags/${ref}$"; then
        return 0
    fi
    return 1
}

function check_github_ref() {
    local repo_name="$1"
    local ref="$2"
    if gh api "repos/${GITHUB_ORG}/${repo_name}/branches/${ref}" &> /dev/null || \
       gh api "repos/${GITHUB_ORG}/${repo_name}/tags" --jq ".[] | select(.name == \"${ref}\") | .name" 2>/dev/null | grep -q "^${ref}$"; then
        return 0
    fi
    return 1
}

# --- Persiapan ---
check_command "git"
if [ "$SOURCE" != "bitbucket" ]; then
    check_command "gh"
    if ! gh auth status &> /dev/null; then exit 1; fi
fi

if [ ! -f "$REPO_FILE" ]; then exit 1; fi

echo "# Check Logs - $(date '+%Y-%m-%d %H:%M:%S')" > "$LOG_FILE"

# --- Logika Utama ---
while IFS= read -r repo_name || [[ -n "$repo_name" ]]; do
    if [ -z "$repo_name" ] || [[ "$repo_name" =~ ^[[:space:]]*# ]]; then continue; fi
    repo_name=$(echo "$repo_name" | xargs)
    
    echo "Checking $repo_name..."
    
    if [ "$SOURCE" == "github" ] || [ "$SOURCE" == "both" ]; then
        if check_github_ref "$repo_name" "$REF_NAME"; then echo "  ✅ GitHub: OK"; else echo "  ❌ GitHub: Missing"; fi
    fi
    
    if [ "$SOURCE" == "bitbucket" ] || [ "$SOURCE" == "both" ]; then
        if check_bitbucket_ref "$repo_name" "$REF_NAME"; then echo "  ✅ Bitbucket: OK"; else echo "  ❌ Bitbucket: Missing"; fi
    fi
done < "$REPO_FILE"
