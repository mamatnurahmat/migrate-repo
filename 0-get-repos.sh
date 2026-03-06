#!/bin/bash

# Script untuk mendapatkan daftar nama repositori dari Bitbucket
# berdasarkan Project ID, menggunakan kredensial dari ~/.netrc.

BITBUCKET_ORG="loyaltoid"
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

# --- Ekstrak Kredensial dari .netrc ---
if [ ! -f "$NETRC_FILE" ]; then
    echo "Error: File $NETRC_FILE tidak ditemukan."
    exit 1
fi

# Mengambil username dan password untuk bitbucket.org
BITBUCKET_USER=$(grep -A 2 "machine bitbucket.org" "$NETRC_FILE" | grep "login" | awk '{print $2}')
BITBUCKET_PASS=$(grep -A 2 "machine bitbucket.org" "$NETRC_FILE" | grep "password" | awk '{print $2}')

if [ -z "$BITBUCKET_USER" ] || [ -z "$BITBUCKET_PASS" ]; then
    echo "Error: Kredensial bitbucket.org tidak ditemukan di $NETRC_FILE."
    exit 1
fi

echo "Mencari repositori untuk Project: $PROJECT_ID di Workspace: $BITBUCKET_ORG..."
echo "Menyimpan ke: $OUTPUT_FILE"
echo "----------------------------------------------------------------------"

# Kosongkan file jika sudah ada
> "$OUTPUT_FILE"

# --- Fungsi untuk Fetch Repositori ---
# Bitbucket API menggunakan pagination, jadi kita perlu loop sampai 'next' kosong.
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
