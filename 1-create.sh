#!/bin/bash

# Skrip untuk membuat repositori GitHub sebagai private,
# atau mengubah repositori publik yang ada menjadi private.

# --- Load Environment Variables ---
ENV_FILE=".env"
if [ -f "$ENV_FILE" ]; then
    export $(grep -v '^#' "$ENV_FILE" | xargs)
else
    echo "Error: File $ENV_FILE tidak ditemukan."
    exit 1
fi

# --- Fungsi Utilitas ---
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
            echo "Mendeteksi sistem CentOS/RHEL..."
            if command -v dnf &> /dev/null; then
                sudo dnf install -y gh
            elif command -v yum &> /dev/null; then
                sudo yum install -y https://cli.github.com/packages/rpm/gh-cli.repo
                sudo yum install -y gh
            else
                echo "Error: Tidak dapat menemukan package manager yang didukung."
                echo "Silakan instal GitHub CLI secara manual."
                exit 1
            fi
            ;;
        "debian")
            echo "Mendeteksi sistem Debian/Ubuntu..."
            if command -v apt &> /dev/null; then
                curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
                echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
                sudo apt update
                sudo apt install -y gh
            else
                echo "Error: Tidak dapat menemukan package manager apt."
                exit 1
            fi
            ;;
        "arch")
            echo "Mendeteksi sistem Arch-based (CachyOS)..."
            if command -v pacman &> /dev/null; then
                sudo pacman -Sy --noconfirm github-cli
            else
                echo "Error: Tidak dapat menemukan package manager pacman."
                exit 1
            fi
            ;;
        *)
            echo "Error: Sistem operasi tidak didukung untuk instalasi otomatis."
            echo "Silakan instal GitHub CLI secara manual:"
            echo "1. Kunjungi: https://cli.github.com/"
            echo "2. Ikuti instruksi untuk sistem operasi Anda"
            exit 1
            ;;
    esac
    
    # Verifikasi instalasi
    if command -v gh &> /dev/null; then
        echo "GitHub CLI berhasil diinstal!"
    else
        echo "Error: Gagal menginstal GitHub CLI."
        exit 1
    fi
}

function check_netrc_credentials() {
    if [ -f ~/.netrc ]; then
        if grep -q "github.com" ~/.netrc; then
            return 0
        else
            return 1
        fi
    else
        return 1
    fi
}

function setup_gh_auth() {
    echo "Mengatur autentikasi GitHub CLI..."
    
    if gh auth status &> /dev/null; then
        return 0
    fi
    
    if check_netrc_credentials; then
        local token=$(grep -A 2 "github.com" ~/.netrc | grep "password" | awk '{print $2}')
        if [ -n "$token" ]; then
            if echo "$token" | gh auth login --with-token; then
                return 0
            fi
        fi
    fi
    
    echo "Silakan login ke GitHub CLI secara interaktif: gh auth login"
    exit 1
}

# --- Validasi ---
function check_command() {
    if ! command -v "$1" &> /dev/null; then
        if [ "$1" = "gh" ]; then
            install_gh_cli
        else
            echo "Harap instal '$1' dan coba lagi."
            exit 1
        fi
    fi
}

# Cek dependensi
check_command "gh"

# Cek autentikasi
if ! gh auth status &> /dev/null; then
    setup_gh_auth
fi

# Verifikasi akses ke akun/organisasi
if ! gh api "users/${GITHUB_ORG}" &> /dev/null; then
    echo "Error: Tidak dapat mengakses akun atau organisasi '${GITHUB_ORG}'."
    exit 1
fi

if [ ! -f "$REPO_FILE" ]; then
    echo "Error: File repositori '$REPO_FILE' tidak ditemukan."
    exit 1
fi

# --- Logika Utama ---
echo "Memulai proses dengan tujuan: ${GITHUB_ORG}"
echo "File repositori: ${REPO_FILE}"
echo ""

while IFS= read -r repo_name || [[ -n "$repo_name" ]]; do
    if [ -z "$repo_name" ] || [[ "$repo_name" =~ ^[[:space:]]*# ]]; then
        continue
    fi
    
    repo_name=$(echo "$repo_name" | xargs)
    full_repo_path="${GITHUB_ORG}/${repo_name}"

    echo "----------------------------------------"
    echo "Memproses repositori: $full_repo_path"

    visibility=$(gh repo view "$full_repo_path" --json visibility --jq .visibility 2>/dev/null)
    exit_code=$?

    if [ $exit_code -ne 0 ]; then
        echo "Repositori '$full_repo_path' tidak ada. Membuat sebagai private..."
        if gh repo create "$full_repo_path" --private; then
            echo "✅ Berhasil membuat repositori private '$full_repo_path'."
        else
            echo "❌ Gagal membuat repositori '$full_repo_path'."
        fi
    else
        if [ "$visibility" = "PUBLIC" ]; then
            echo "Repositori '$full_repo_path' ada dan bersifat publik. Mengubah ke private..."
            if gh repo edit "$full_repo_path" --visibility private; then
                echo "✅ Berhasil mengubah repositori '$full_repo_path' menjadi private."
            else
                echo "❌ Gagal mengubah visibilitas repositori '$full_repo_path'."
            fi
        elif [ "$visibility" = "PRIVATE" ]; then
            echo "✅ Repositori '$full_repo_path' sudah private. Tidak ada tindakan."
        fi
    fi
done < "$REPO_FILE"

echo "----------------------------------------"
echo "✅ Selesai memproses semua repositori."