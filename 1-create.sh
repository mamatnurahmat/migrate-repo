#!/bin/bash

# --- Validasi Argumen ---
if [ -z "$1" ]; then
    echo "Error: Nama repositori harus diberikan sebagai argumen pertama."
    echo "Penggunaan: $0 <nama-repositori>"
    exit 1
fi

REPO_NAME="$1"

# --- Konfigurasi ---
GITHUB_ORG="Qoin-Digital-Indonesia"

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
check_command "gh"

# Pastikan sudah login ke GitHub CLI
if ! gh auth status &> /dev/null; then
    echo "Anda belum login ke GitHub CLI."
    echo "Silakan jalankan 'gh auth login' dan coba lagi."
    exit 1
fi

echo "---"
echo "Langkah 1: Membuat repositori '${REPO_NAME}' di GitHub..."
echo "Organisasi: ${GITHUB_ORG}"

# Buat repositori baru. --public atau --private bisa disesuaikan.
if ! gh repo create "${GITHUB_ORG}/${REPO_NAME}" --public; then
    echo "Error: Gagal membuat repositori. Repositori mungkin sudah ada, atau Anda tidak memiliki izin yang memadai."
    exit 1
fi

echo "Repositori '${REPO_NAME}' berhasil dibuat!"
echo "URL: https://github.com/${GITHUB_ORG}/${REPO_NAME}"

echo "---"
echo "Langkah 2: Menginisialisasi repositori Git lokal dan push..."

# Anda bisa menambahkan perintah Git di sini,
# seperti: git init, git add, git commit, dan git remote add origin
# Contoh:
# git init
# git remote add origin https://github.com/${GITHUB_ORG}/${REPO_NAME}.git
# git add .
# git commit -m "Initial commit"
# git push -u origin main

echo "Penciptaan repositori selesai. Anda sekarang bisa memulai pekerjaan di repositori lokal dan melakukan push."
