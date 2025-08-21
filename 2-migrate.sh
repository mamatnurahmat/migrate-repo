#!/bin/bash

# --- Validasi Argumen ---
if [ -z "$1" ]; then
    echo "Error: Nama repositori harus diberikan sebagai argumen pertama."
    echo "Penggunaan: $0 <nama-repositori>"
    exit 1
fi

REPO_NAME="$1"

# --- Konfigurasi Default ---
BITBUCKET_ORG="loyaltoid"
GITHUB_ORG="Qoin-Digital-Indonesia"

BITBUCKET_REPO_SLUG="${BITBUCKET_ORG}/${REPO_NAME}"
GITHUB_REPO_OWNER="${GITHUB_ORG}"
GITHUB_REPO_NAME="${REPO_NAME}"
GITHUB_URL="https://github.com/${GITHUB_REPO_OWNER}/${GITHUB_REPO_NAME}"

# --- Fungsi ---
function check_command() {
    if ! command -v "$1" &> /dev/null; then
        echo "Error: '$1' tidak ditemukan. Harap instal '$1' dan coba lagi."
        echo "Untuk GitHub CLI, instalasi bisa dilihat di: https://github.com/cli/cli#installation"
        exit 1
    fi
}

# --- Persiapan ---
echo "Memeriksa dependensi..."
check_command "git"
check_command "gh"

# Pastikan sudah login ke GitHub CLI
if ! gh auth status &> /dev/null; then
    echo "Anda belum login ke GitHub CLI."
    echo "Silakan jalankan 'gh auth login' dan coba lagi."
    exit 1
fi

# Buat direktori sementara dan masuk ke dalamnya
TEMP_DIR=$(mktemp -d)
echo "Menggunakan direktori sementara: $TEMP_DIR"
cd "$TEMP_DIR" || exit

# --- Proses Migrasi ---

echo "---"
echo "Langkah 1: Mengklon repositori Bitbucket..."
echo "Repositori: https://bitbucket.org/${BITBUCKET_REPO_SLUG}.git"
if ! git clone --mirror "https://bitbucket.org/${BITBUCKET_REPO_SLUG}.git"; then
    echo "Error: Gagal mengklon repositori Bitbucket. Pastikan repositori '${REPO_NAME}' ada di '${BITBUCKET_ORG}' dan kredensial .netrc benar."
    exit 1
fi
echo "Kloning Bitbucket selesai."

# Masuk ke direktori repositori kloning
cd "${REPO_NAME}.git" || exit

echo "---"
echo "Langkah 2: Memeriksa dan membuat repositori di GitHub..."

# Cek apakah repo sudah ada
if gh repo view "${GITHUB_REPO_OWNER}/${GITHUB_REPO_NAME}" &> /dev/null; then
    echo "Repositori '${GITHUB_REPO_NAME}' di GitHub sudah ada."
    # Jika sudah ada, kita hanya perlu set URL remote-nya
    git remote set-url origin "$GITHUB_URL"
else
    echo "Repositori '${GITHUB_REPO_NAME}' tidak ditemukan. Mencoba membuatnya..."
    # Buat repo baru dengan opsi --source dan --push
    if ! gh repo create "${GITHUB_REPO_OWNER}/${GITHUB_REPO_NAME}" --source=. --push --public --remote=origin; then
        echo "Error: Gagal membuat repositori di GitHub. Pastikan Anda memiliki izin yang memadai di organisasi '${GITHUB_ORG}'."
        exit 1
    fi
fi

echo "---"
echo "Langkah 3: Push semua konten ke GitHub..."
# Kita menggunakan 'push --mirror' lagi untuk memastikan sinkronisasi penuh
if ! git push --mirror; then
    echo "Error: Gagal push ke GitHub. Silakan periksa kredensial dan izin Anda."
    exit 1
fi
echo "Push ke GitHub selesai. Semua branch dan tag telah dimigrasi."

# --- Pembersihan ---
echo "---"
echo "Langkah 4: Membersihkan direktori sementara..."
cd - > /dev/null
rm -rf "$TEMP_DIR"
echo "Pembersihan selesai."

echo "---"
echo "Migrasi '${REPO_NAME}' berhasil!"
echo "Anda dapat melihat repositori baru di: ${GITHUB_URL}"
