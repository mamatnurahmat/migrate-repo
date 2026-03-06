#!/bin/bash

# --- Load Environment Variables ---
ENV_FILE=".env"
if [ -f "$ENV_FILE" ]; then
    export $(grep -v '^#' "$ENV_FILE" | xargs)
else
    echo "Error: File $ENV_FILE tidak ditemukan."
    exit 1
fi

# --- Fungsi ---
function detect_os() {
    if [ -f /etc/redhat-release ]; then
        echo "centos"
    elif [ -f /etc/debian_version ]; then
        echo "debian"
    elif [ -f /etc/arch-release ] || grep -q "arch" /etc/os-release || grep -q "cachyos" /etc/os-release; then
        echo "arch"
    else
        echo "unknown"
    fi
}

function install_gh_cli() {
    local os_type=$(detect_os)
    echo "GitHub CLI tidak ditemukan. Mencoba menginstal..."
    case $os_type in
        "centos")
            if command -v dnf &> /dev/null; then sudo dnf install -y gh
            elif command -v yum &> /dev/null; then
                sudo yum install -y https://cli.github.com/packages/rpm/gh-cli.repo
                sudo yum install -y gh
            fi ;;
        "debian")
            curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
            sudo apt update && sudo apt install -y gh ;;
        "arch")
            sudo pacman -Sy --noconfirm github-cli ;;
        *) echo "Error: Sistem tidak didukung untuk instalasi otomatis."; exit 1 ;;
    esac
}

function check_command() {
    if ! command -v "$1" &> /dev/null; then
        if [ "$1" = "gh" ]; then install_gh_cli
        else echo "Error: '$1' tidak ditemukan."; exit 1; fi
    fi
}

function migrate_single_repo() {
    local repo_name="$1"
    local bitbucket_repo_slug="${BITBUCKET_ORG}/${repo_name}"
    local github_repo_owner="${GITHUB_ORG}"
    local github_repo_name="${repo_name}"
    local github_url="https://github.com/${github_repo_owner}/${github_repo_name}"

    echo "----------------------------------------"
    echo "Memigrasi repositori: $repo_name"
    
    local temp_dir=$(mktemp -d)
    cd "$temp_dir" || return 1

    echo "Langkah 1: Mengklon repositori Bitbucket..."
    if ! git clone --mirror "https://bitbucket.org/${bitbucket_repo_slug}.git"; then
        echo "❌ Error: Gagal mengklon Bitbucket."
        cd - > /dev/null && rm -rf "$temp_dir"; return 1
    fi

    cd "${repo_name}.git" || { cd - > /dev/null; rm -rf "$temp_dir"; return 1; }

    echo "Langkah 2: Memeriksa repositori di GitHub..."
    if ! gh repo view "${github_repo_owner}/${github_repo_name}" &> /dev/null; then
        if ! gh repo create "${github_repo_owner}/${github_repo_name}" --private; then
            echo "❌ Error: Gagal membuat repo GitHub."
            cd - > /dev/null && rm -rf "$temp_dir"; return 1
        fi
    fi
    
    git remote set-url origin "$github_url"

    echo "Langkah 3: Push konten ke GitHub..."
    if ! git push --mirror; then
        echo "❌ Error: Gagal push ke GitHub."
        cd - > /dev/null && rm -rf "$temp_dir"; return 1
    fi

    cd - > /dev/null && rm -rf "$temp_dir"
    echo "✅ Migrasi '${repo_name}' berhasil!"
    return 0
}

# --- Persiapan ---
check_command "git"
check_command "gh"

if ! gh auth status &> /dev/null; then
    echo "Silakan jalankan 'gh auth login' terlebih dahulu."
    exit 1
fi

if [ ! -f "$REPO_FILE" ]; then
    echo "Error: File $REPO_FILE tidak ditemukan."
    exit 1
fi

if ! gh api "users/${GITHUB_ORG}" &> /dev/null; then
    echo "Error: Tidak dapat mengakses '${GITHUB_ORG}'."
    exit 1
fi

# --- Logika Utama ---
echo "Memulai migrasi ke: ${GITHUB_ORG}"

success_count=0
failed_count=0
failed_repos=()

while IFS= read -r repo_name || [[ -n "$repo_name" ]]; do
    if [ -z "$repo_name" ] || [[ "$repo_name" =~ ^[[:space:]]*# ]]; then continue; fi
    repo_name=$(echo "$repo_name" | xargs)

    if migrate_single_repo "$repo_name"; then ((success_count++))
    else ((failed_count++)); failed_repos+=("$repo_name"); fi
done < "$REPO_FILE"

echo "========================================"
echo "RINGKASAN: Berhasil: $success_count, Gagal: $failed_count"
