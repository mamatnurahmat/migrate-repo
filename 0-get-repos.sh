#!/bin/bash

# Script untuk mendapatkan daftar nama repositori dari Bitbucket
# berdasarkan Project ID.

# --- Load Environment Variables ---
ENV_FILE=".env"
if [ -f "$ENV_FILE" ]; then
    export $(grep -v '^#' "$ENV_FILE" | xargs)
else
    echo "Error: File $ENV_FILE tidak ditemukan."
    exit 1
fi

NETRC_FILE="$HOME/.netrc"

# --- Validasi Argumen ---
if [ -z "$1" ]; then
    echo "Error: Project ID harus diberikan sebagai argumen pertama."
    echo "Penggunaan: $0 <PROJECT_ID>"
    echo "Contoh: $0 NW"
    exit 1
fi

PROJECT_ID="$1"
OUTPUT_FILE="${PROJECT_ID}.txt"

# --- Ekstrak Kredensial ---
# Cek apakah variabel sudah ada dari .env, jika tidak ambil dari .netrc
if [ -z "$BITBUCKET_USER" ] || [ -z "$BITBUCKET_PASS" ]; then
    if [ -f "$NETRC_FILE" ]; then
        BITBUCKET_USER=$(grep -A 2 "machine bitbucket.org" "$NETRC_FILE" | grep "login" | awk '{print $2}')
        BITBUCKET_PASS=$(grep -A 2 "machine bitbucket.org" "$NETRC_FILE" | grep "password" | awk '{print $2}')
    fi
fi

if [ -z "$BITBUCKET_USER" ] || [ -z "$BITBUCKET_PASS" ]; then
    echo "Error: Kredensial bitbucket.org tidak ditemukan di $ENV_FILE atau $NETRC_FILE."
    exit 1
fi

echo "Mencari repositori untuk Project: $PROJECT_ID di Workspace: $BITBUCKET_ORG..."
echo "Menyimpan ke: $OUTPUT_FILE"
echo "----------------------------------------------------------------------"

# Kosongkan file jika sudah ada
> "$OUTPUT_FILE"

# --- Fungsi untuk Fetch Repositori ---
# Bitbucket API menggunakan pagination
NEXT_URL="https://api.bitbucket.org/2.0/repositories/${BITBUCKET_ORG}?q=project.key=\"${PROJECT_ID}\"&pagelen=100"

while [ -n "$NEXT_URL" ] && [ "$NEXT_URL" != "null" ]; do
    # Fetch data
    RESPONSE=$(curl -s -u "${BITBUCKET_USER}:${BITBUCKET_PASS}" "$NEXT_URL")
    
    # Periksa error API
    ERROR_MSG=$(echo "$RESPONSE" | jq -r '.error.message // empty')
    if [ -n "$ERROR_MSG" ]; then
        echo "Error dari Bitbucket API: $ERROR_MSG"
        exit 1
    fi

    # Ekstrak nama repositori (slug) dan simpan ke file
    echo "$RESPONSE" | jq -r '.values[].slug' >> "$OUTPUT_FILE"
    
    # Ambil URL halaman berikutnya jika ada
    NEXT_URL=$(echo "$RESPONSE" | jq -r '.next // empty')
done

echo "----------------------------------------------------------------------"
echo "✅ Selesai. Daftar repositori disimpan di: $OUTPUT_FILE"
echo "Jumlah baris: $(wc -l < "$OUTPUT_FILE")"
