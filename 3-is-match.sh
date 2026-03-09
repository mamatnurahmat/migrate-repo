#!/bin/bash

# --- Load Environment Variables ---
ENV_FILE=".env"
if [ -f "$ENV_FILE" ]; then
    export $(grep -v '^#' "$ENV_FILE" | xargs)
else
    echo "Error: File $ENV_FILE tidak ditemukan."
    exit 1
fi

# --- Konfigurasi Log ---
MATCH_LOG="match_success.log"
UNMATCH_LOG="unmatched_refs.log"

# Mengosongkan file log dari eksekusi sebelumnya
> "$MATCH_LOG"
> "$UNMATCH_LOG"

# --- Validasi Awal ---
if ! command -v git &> /dev/null; then
    echo "Error: 'git' tidak ditemukan."
    exit 1
fi

if [ ! -f "$REPO_FILE" ]; then
    echo "Error: File $REPO_FILE tidak ditemukan."
    exit 1
fi

# --- Logika Utama Komparasi ---
echo "Memulai komparasi branch & tag antara Bitbucket dan GitHub..."
echo "========================================"

while IFS= read -r repo_name || [[ -n "$repo_name" ]]; do
    # Abaikan baris kosong dan komentar
    if [ -z "$repo_name" ] || [[ "$repo_name" =~ ^[[:space:]]*# ]]; then continue; fi
    repo_name=$(echo "$repo_name" | xargs)

    timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    echo "Memeriksa repositori: $repo_name"

    bb_url="https://bitbucket.org/${BITBUCKET_ORG}/${repo_name}.git"
    gh_url="https://github.com/${GITHUB_ORG}/${repo_name}.git"

    # Verifikasi akses ke repo sumber (Bitbucket)
    if ! git ls-remote "$bb_url" &>/dev/null; then
        echo "❌ Error: Tidak dapat mengakses Bitbucket untuk $repo_name"
        echo "[$timestamp] ERROR: Akses gagal ke Bitbucket - $repo_name" >> "$UNMATCH_LOG"
        echo "----------------------------------------"
        continue
    fi

    # Verifikasi akses ke repo tujuan (GitHub)
    if ! git ls-remote "$gh_url" &>/dev/null; then
        echo "❌ Error: Tidak dapat mengakses GitHub untuk $repo_name (Mungkin belum dimigrasi)"
        echo "[$timestamp] ERROR: Repo GitHub tidak ditemukan - $repo_name" >> "$UNMATCH_LOG"
        echo "----------------------------------------"
        continue
    fi

    # 1. Ambil daftar branch, hapus prefix 'refs/heads/', lalu urutkan
    bb_branches=$(git ls-remote --heads "$bb_url" | awk '{print $2}' | sed 's#refs/heads/##' | sort | uniq)
    gh_branches=$(git ls-remote --heads "$gh_url" | awk '{print $2}' | sed 's#refs/heads/##' | sort | uniq)

    # 2. Ambil daftar tag, hapus prefix 'refs/tags/' dan suffix '^{}' (untuk annotated tags), lalu urutkan
    bb_tags=$(git ls-remote --tags "$bb_url" | awk '{print $2}' | sed 's#refs/tags/##' | sed 's/\^{}//' | sort | uniq)
    gh_tags=$(git ls-remote --tags "$gh_url" | awk '{print $2}' | sed 's#refs/tags/##' | sed 's/\^{}//' | sort | uniq)

    # 3. Cari perbedaan (Hanya mencari yang ada di BB tapi TIDAK ADA di GH)
    # comm -23 menampilkan baris yang unik di file pertama (file1 = BB, file2 = GH)
    missing_branches=$(comm -23 <(echo "$bb_branches" | grep -v '^$') <(echo "$gh_branches" | grep -v '^$'))
    missing_tags=$(comm -23 <(echo "$bb_tags" | grep -v '^$') <(echo "$gh_tags" | grep -v '^$'))

    has_unmatched=false

    # Pencatatan ke log jika ada branch yang hilang
    if [ -n "$missing_branches" ]; then
        echo "[$timestamp] UNMATCHED BRANCH in $repo_name:" >> "$UNMATCH_LOG"
        while read -r branch; do
            echo "  -> Branch hilang di GitHub: $branch" >> "$UNMATCH_LOG"
        done <<< "$missing_branches"
        has_unmatched=true
    fi

    # Pencatatan ke log jika ada tag yang hilang
    if [ -n "$missing_tags" ]; then
        echo "[$timestamp] UNMATCHED TAG in $repo_name:" >> "$UNMATCH_LOG"
        while read -r tag; do
            echo "  -> Tag hilang di GitHub: $tag" >> "$UNMATCH_LOG"
        done <<< "$missing_tags"
        has_unmatched=true
    fi

    # Output Terminal & Log Kesimpulan
    if [ "$has_unmatched" = true ]; then
        echo "⚠️  Ditemukan ketidakcocokan! (Cek log unmatch)"
    else
        echo "✅ Semua branch dan tag MATCH."
        echo "[$timestamp] MATCH: Semua branch & tag sinkron untuk $repo_name" >> "$MATCH_LOG"
    fi
    echo "----------------------------------------"

done < "$REPO_FILE"

echo "========================================"
echo "Proses komparasi selesai."
echo "Log repositori yang MATCH disimpan di   : $MATCH_LOG"
echo "Log repositori yang UNMATCH disimpan di : $UNMATCH_LOG"