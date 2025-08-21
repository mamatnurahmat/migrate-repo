#!/bin/bash

# Skrip untuk membuat repositori GitHub sebagai private,
# atau mengubah repositori publik yang ada menjadi private.

# --- Konfigurasi ---
# Skrip ini dikonfigurasi untuk bekerja HANYA dengan organisasi Qoin-Digital-Indonesia.
GITHUB_ORG="Qoin-Digital-Indonesia"

# File yang berisi daftar nama repositori, satu per baris.
REPO_FILE="repos.txt"

# --- Fungsi Utilitas ---
function detect_os() {
    if [ -f /etc/redhat-release ]; then
        echo "centos"
    elif [ -f /etc/debian_version ]; then
        echo "debian"
    elif [ -f /etc/arch-release ]; then
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
                echo "Menggunakan dnf untuk menginstal GitHub CLI..."
                sudo dnf install -y gh
            elif command -v yum &> /dev/null; then
                echo "Menggunakan yum untuk menginstal GitHub CLI..."
                # Tambahkan repository GitHub CLI untuk CentOS
                sudo yum install -y https://cli.github.com/packages/rpm/gh-cli.repo
                sudo yum install -y gh
            else
                echo "Error: Tidak dapat menemukan package manager (dnf/yum) yang didukung."
                echo "Silakan instal GitHub CLI secara manual:"
                echo "1. Kunjungi: https://cli.github.com/"
                echo "2. Ikuti instruksi untuk CentOS/RHEL"
                exit 1
            fi
            ;;
        "debian")
            echo "Mendeteksi sistem Debian/Ubuntu..."
            if command -v apt &> /dev/null; then
                echo "Menggunakan apt untuk menginstal GitHub CLI..."
                curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
                echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
                sudo apt update
                sudo apt install -y gh
            else
                echo "Error: Tidak dapat menemukan package manager apt."
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
        echo "File .netrc ditemukan. Mencoba menggunakan kredensial dari .netrc..."
        if grep -q "github.com" ~/.netrc; then
            echo "Kredensial GitHub ditemukan di .netrc."
            return 0
        else
            echo "File .netrc ada tetapi tidak berisi kredensial GitHub."
            return 1
        fi
    else
        echo "File .netrc tidak ditemukan."
        return 1
    fi
}

function setup_gh_auth() {
    echo "Mengatur autentikasi GitHub CLI..."
    
    # Cek apakah sudah ada token yang tersimpan
    if gh auth status &> /dev/null; then
        echo "GitHub CLI sudah terautentikasi."
        return 0
    fi
    
    # Cek .netrc terlebih dahulu
    if check_netrc_credentials; then
        echo "Mencoba login menggunakan kredensial dari .netrc..."
        # Ekstrak username dan token dari .netrc
        local username=$(grep -A 2 "github.com" ~/.netrc | grep "login" | awk '{print $2}')
        local token=$(grep -A 2 "github.com" ~/.netrc | grep "password" | awk '{print $2}')
        
        if [ -n "$username" ] && [ -n "$token" ]; then
            echo "Menggunakan kredensial dari .netrc untuk login..."
            if echo "$token" | gh auth login --with-token; then
                echo "Berhasil login menggunakan kredensial dari .netrc."
                return 0
            else
                echo "Gagal login menggunakan kredensial dari .netrc."
            fi
        fi
    fi
    
    # Jika .netrc tidak berhasil, gunakan interaktif
    echo "Silakan login ke GitHub CLI secara interaktif:"
    echo "Command: gh auth login"
    echo "Pilih opsi yang sesuai dengan preferensi Anda."
    echo ""
    echo "Atau jika Anda memiliki token GitHub, gunakan:"
    echo "Command: echo 'YOUR_TOKEN' | gh auth login --with-token"
    echo ""
    echo "Setelah login berhasil, jalankan script ini lagi."
    exit 1
}

# --- Validasi ---
function check_command() {
    if ! command -v "$1" &> /dev/null; then
        echo "Error: '$1' tidak ditemukan."
        if [ "$1" = "gh" ]; then
            install_gh_cli
        else
            echo "Harap instal '$1' dan coba lagi."
            exit 1
        fi
    fi
}

# Cek dan instal GitHub CLI jika diperlukan
check_command "gh"

# Cek autentikasi
if ! gh auth status &> /dev/null; then
    setup_gh_auth
fi

# Verifikasi akses ke organisasi
if ! gh api "orgs/${GITHUB_ORG}" &> /dev/null; then
    echo "Error: Tidak dapat mengakses organisasi '${GITHUB_ORG}'."
    echo "Pastikan Anda memiliki akses ke organisasi tersebut."
    echo "Atau periksa apakah nama organisasi benar."
    exit 1
fi

if [ ! -f "$REPO_FILE" ]; then
    echo "Error: File repositori '$REPO_FILE' tidak ditemukan."
    echo "Buat file '$REPO_FILE' dengan daftar nama repositori (satu per baris)."
    exit 1
fi

# --- Logika Utama ---
echo "Memulai proses dengan organisasi: ${GITHUB_ORG}"
echo "File repositori: ${REPO_FILE}"
echo ""

while IFS= read -r repo_name || [[ -n "$repo_name" ]]; do
    # Lewati baris kosong dan komentar
    if [ -z "$repo_name" ] || [[ "$repo_name" =~ ^[[:space:]]*# ]]; then
        continue
    fi
    
    # Bersihkan whitespace
    repo_name=$(echo "$repo_name" | xargs)

    # Tentukan path lengkap repo (dengan organisasi)
    full_repo_path="${GITHUB_ORG}/${repo_name}"

    echo "----------------------------------------"
    echo "Memproses repositori: $full_repo_path"

    # Periksa visibilitas repositori
    visibility=$(gh repo view "$full_repo_path" --json visibility --jq .visibility 2>/dev/null)
    exit_code=$?

    if [ $exit_code -ne 0 ]; then
        # Jika perintah gagal, repositori tidak ada. Buat sebagai private.
        echo "Repositori '$full_repo_path' tidak ada. Membuat sebagai private..."
        if gh repo create "$full_repo_path" --private --source .; then
            echo "✅ Berhasil membuat repositori private '$full_repo_path'."
        else
            echo "❌ Gagal membuat repositori '$full_repo_path'."
            echo "   Pastikan Anda memiliki izin untuk membuat repositori di organisasi."
        fi
    else
        # Repositori sudah ada.
        if [ "$visibility" = "PUBLIC" ]; then
            echo "Repositori '$full_repo_path' ada dan bersifat publik. Mengubah ke private..."
            if gh repo edit "$full_repo_path" --visibility private; then
                echo "✅ Berhasil mengubah repositori '$full_repo_path' menjadi private."
            else
                echo "❌ Gagal mengubah visibilitas repositori '$full_repo_path'."
                echo "   Pastikan Anda memiliki izin admin untuk repositori ini."
            fi
        elif [ "$visibility" = "PRIVATE" ]; then
            echo "✅ Repositori '$full_repo_path' sudah private. Tidak ada tindakan."
        else
            echo "⚠️  Status visibilitas repositori '$full_repo_path' tidak dikenali: $visibility"
        fi
    fi
done < "$REPO_FILE"

echo "----------------------------------------"
echo "✅ Selesai memproses semua repositori."