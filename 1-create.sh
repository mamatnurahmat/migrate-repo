#!/bin/bash

# Skrip untuk membuat repositori GitHub sebagai private,
# atau mengubah repositori publik yang ada menjadi private.

# --- Konfigurasi ---
# Skrip ini dikonfigurasi untuk bekerja HANYA dengan organisasi Qoin-Digital-Indonesia.
GITHUB_ORG="Qoin-Digital-Indonesia"

# File yang berisi daftar nama repositori, satu per baris.
REPO_FILE="repos.txt"

# --- Validasi ---
function check_command() {
    if ! command -v "$1" &> /dev/null; then
        echo "Error: '$1' tidak ditemukan. Harap instal '$1' dan coba lagi."
        echo "Untuk GitHub CLI, instalasi bisa dilihat di: https://cli.github.com/"
        exit 1
    fi
}

check_command "gh"

if ! gh auth status &> /dev/null; then
    echo "Anda belum login ke GitHub CLI. Silakan jalankan 'gh auth login' dan coba lagi."
    exit 1
fi

if [ ! -f "$REPO_FILE" ]; then
    echo "Error: File repositori '$REPO_FILE' tidak ditemukan."
    exit 1
fi

# --- Logika Utama ---
while IFS= read -r repo_name || [[ -n "$repo_name" ]]; do
    # Lewati baris kosong
    if [ -z "$repo_name" ]; then
        continue
    fi

    # Tentukan path lengkap repo (dengan atau tanpa organisasi)
    if [ -n "$GITHUB_ORG" ]; then
        full_repo_path="${GITHUB_ORG}/${repo_name}"
    else
        full_repo_path="$repo_name"
    fi

    echo "----------------------------------------"
    echo "Memproses repositori: $full_repo_path"

    # Periksa visibilitas repositori
    visibility=$(gh repo view "$full_repo_path" --json visibility --jq .visibility 2>/dev/null)
    exit_code=$?

    if [ $exit_code -ne 0 ]; then
        # Jika perintah gagal, repositori tidak ada. Buat sebagai private.
        echo "Repositori '$full_repo_path' tidak ada. Membuat sebagai private..."
        if gh repo create "$full_repo_path" --private; then
            echo "Berhasil membuat repositori private '$full_repo_path'."
        else
            echo "Gagal membuat repositori '$full_repo_path'."
        fi
    else
        # Repositori sudah ada.
        if [ "$visibility" = "PUBLIC" ]; then
            echo "Repositori '$full_repo_path' ada dan bersifat publik. Mengubah ke private..."
            if gh repo edit "$full_repo_path" --visibility private; then
                echo "Berhasil mengubah repositori '$full_repo_path' menjadi private."
            else
                echo "Gagal mengubah visibilitas repositori '$full_repo_path'."
            fi
        elif [ "$visibility" = "PRIVATE" ]; then
            echo "Repositori '$full_repo_path' sudah private. Tidak ada tindakan."
        fi
    fi
done < "$REPO_FILE"

echo "----------------------------------------"
echo "Selesai."