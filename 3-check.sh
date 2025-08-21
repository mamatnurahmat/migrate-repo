#!/bin/bash

# Script untuk validasi repositori dari repos.txt berdasarkan refs (branch/tag)
# Penggunaan: ./3-check.sh <branch-or-tag-name> [source]
# Source: github (default), bitbucket, both

# --- Validasi Argumen ---
if [ -z "$1" ]; then
    echo "Error: Nama branch atau tag harus diberikan sebagai argumen pertama."
    echo "Penggunaan: $0 <branch-or-tag-name> [source]"
    echo ""
    echo "Source options:"
    echo "  github     - Check GitHub only (default)"
    echo "  bitbucket  - Check Bitbucket only"
    echo "  both       - Check both GitHub and Bitbucket"
    echo ""
    echo "Contoh:"
    echo "  $0 develop"
    echo "  $0 main github"
    echo "  $0 v1.0.0 bitbucket"
    echo "  $0 feature/new-ui both"
    exit 1
fi

REF_NAME="$1"
SOURCE="${2:-github}"  # Default to github if not specified

# --- Konfigurasi Default ---
BITBUCKET_ORG="loyaltoid"
GITHUB_ORG="Qoin-Digital-Indonesia"

# File yang berisi daftar nama repositori, satu per baris.
REPO_FILE="repos.txt"
LOG_FILE="check.logs"

# --- Fungsi ---
function check_command() {
    if ! command -v "$1" &> /dev/null; then
        echo "Error: '$1' tidak ditemukan. Harap instal '$1' dan coba lagi."
        exit 1
    fi
}

function log_missing() {
    local repo_name="$1"
    local ref_name="$2"
    local source="$3"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    case "$source" in
        "github")
            echo "[$timestamp] GITHUB_MISSING: $repo_name - ref '$ref_name' not found" >> "$LOG_FILE"
            ;;
        "bitbucket")
            echo "[$timestamp] BITBUCKET_MISSING: $repo_name - ref '$ref_name' not found" >> "$LOG_FILE"
            ;;
        "both")
            echo "[$timestamp] BOTH_MISSING: $repo_name - ref '$ref_name' not found on both platforms" >> "$LOG_FILE"
            ;;
    esac
}

function log_partial() {
    local repo_name="$1"
    local ref_name="$2"
    local platform="$3"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    echo "[$timestamp] PARTIAL_MISSING: $repo_name - ref '$ref_name' only exists on $platform" >> "$LOG_FILE"
}

function check_bitbucket_ref() {
    local repo_name="$1"
    local ref_name="$2"
    local bitbucket_url="https://bitbucket.org/${BITBUCKET_ORG}/${repo_name}"
    
    echo "  Checking Bitbucket: ${bitbucket_url}"
    
    # Cek branch
    if git ls-remote --heads "https://bitbucket.org/${BITBUCKET_ORG}/${repo_name}.git" | grep -q "refs/heads/${ref_name}$"; then
        echo "    ✅ Branch '${ref_name}' exists"
        return 0
    fi
    
    # Cek tag
    if git ls-remote --tags "https://bitbucket.org/${BITBUCKET_ORG}/${repo_name}.git" | grep -q "refs/tags/${ref_name}$"; then
        echo "    ✅ Tag '${ref_name}' exists"
        return 0
    fi
    
    echo "    ❌ Ref '${ref_name}' not found"
    return 1
}

function check_github_ref() {
    local repo_name="$1"
    local ref_name="$2"
    local github_url="https://github.com/${GITHUB_ORG}/${repo_name}"
    
    echo "  Checking GitHub: ${github_url}"
    
    # Cek apakah repo ada di GitHub
    if ! gh repo view "${GITHUB_ORG}/${repo_name}" &> /dev/null; then
        echo "    ⚠️  Repository not found on GitHub"
        return 1
    fi
    
    # Cek branch menggunakan GitHub CLI
    if gh api "repos/${GITHUB_ORG}/${repo_name}/branches/${ref_name}" &> /dev/null; then
        echo "    ✅ Branch '${ref_name}' exists"
        return 0
    fi
    
    # Cek tag menggunakan GitHub CLI
    if gh api "repos/${GITHUB_ORG}/${repo_name}/tags" --jq ".[] | select(.name == \"${ref_name}\")" &> /dev/null; then
        local tag_exists=$(gh api "repos/${GITHUB_ORG}/${repo_name}/tags" --jq ".[] | select(.name == \"${ref_name}\") | .name" 2>/dev/null)
        if [ -n "$tag_exists" ]; then
            echo "    ✅ Tag '${ref_name}' exists"
            return 0
        fi
    fi
    
    echo "    ❌ Ref '${ref_name}' not found"
    return 1
}

function validate_single_repo() {
    local repo_name="$1"
    local ref_name="$2"
    local source="$3"
    
    echo "----------------------------------------"
    echo "Validating repository: $repo_name"
    echo "Looking for ref: $ref_name"
    echo "Source: $source"
    
    case "$source" in
        "github")
            if check_github_ref "$repo_name" "$ref_name"; then
                echo ""
                echo "  Summary for $repo_name:"
                echo "    ✅ GitHub has '${ref_name}'"
                return 0
            else
                echo ""
                echo "  Summary for $repo_name:"
                echo "    ❌ GitHub missing '${ref_name}'"
                log_missing "$repo_name" "$ref_name" "github"
                return 1
            fi
            ;;
        "bitbucket")
            if check_bitbucket_ref "$repo_name" "$ref_name"; then
                echo ""
                echo "  Summary for $repo_name:"
                echo "    ✅ Bitbucket has '${ref_name}'"
                return 0
            else
                echo ""
                echo "  Summary for $repo_name:"
                echo "    ❌ Bitbucket missing '${ref_name}'"
                log_missing "$repo_name" "$ref_name" "bitbucket"
                return 1
            fi
            ;;
        "both")
            bitbucket_exists=false
            github_exists=false
            
            # Cek Bitbucket
            if check_bitbucket_ref "$repo_name" "$ref_name"; then
                bitbucket_exists=true
            fi
            
            # Cek GitHub
            if check_github_ref "$repo_name" "$ref_name"; then
                github_exists=true
            fi
            
            # Tampilkan hasil
            echo ""
            echo "  Summary for $repo_name:"
            if [ "$bitbucket_exists" = true ] && [ "$github_exists" = true ]; then
                echo "    ✅ Both Bitbucket and GitHub have '${ref_name}'"
                return 0
            elif [ "$bitbucket_exists" = true ]; then
                echo "    ⚠️  Only Bitbucket has '${ref_name}' (GitHub missing)"
                log_partial "$repo_name" "$ref_name" "Bitbucket"
                return 1
            elif [ "$github_exists" = true ]; then
                echo "    ⚠️  Only GitHub has '${ref_name}' (Bitbucket missing)"
                log_partial "$repo_name" "$ref_name" "GitHub"
                return 1
            else
                echo "    ❌ Neither Bitbucket nor GitHub has '${ref_name}'"
                log_missing "$repo_name" "$ref_name" "both"
                return 1
            fi
            ;;
        *)
            echo "Error: Invalid source '$source'. Use 'github', 'bitbucket', or 'both'"
            return 1
            ;;
    esac
}

# --- Persiapan ---
echo "Memeriksa dependensi..."
check_command "git"

# Cek GitHub CLI hanya jika diperlukan
if [ "$SOURCE" = "github" ] || [ "$SOURCE" = "both" ]; then
    check_command "gh"
    
    # Pastikan sudah login ke GitHub CLI
    if ! gh auth status &> /dev/null; then
        echo "Anda belum login ke GitHub CLI."
        echo "Silakan jalankan 'gh auth login' dan coba lagi."
        exit 1
    fi
fi

# Cek file repositori
if [ ! -f "$REPO_FILE" ]; then
    echo "Error: File repositori '$REPO_FILE' tidak ditemukan."
    echo "Buat file '$REPO_FILE' dengan daftar nama repositori (satu per baris)."
    exit 1
fi

# Inisialisasi log file
echo "# Check Logs - $(date '+%Y-%m-%d %H:%M:%S')" > "$LOG_FILE"
echo "# Ref: $REF_NAME, Source: $SOURCE" >> "$LOG_FILE"
echo "# Format: [timestamp] TYPE: repo_name - description" >> "$LOG_FILE"
echo "" >> "$LOG_FILE"

# --- Logika Utama ---
echo "Memulai validasi repositori..."
echo "Ref yang dicari: $REF_NAME"
echo "Source: $SOURCE"
echo "File repositori: $REPO_FILE"
echo "Log file: $LOG_FILE"
echo ""

success_count=0
warning_count=0
failed_count=0
missing_bitbucket=()
missing_github=()
missing_both=()

while IFS= read -r repo_name || [[ -n "$repo_name" ]]; do
    # Lewati baris kosong dan komentar
    if [ -z "$repo_name" ] || [[ "$repo_name" =~ ^[[:space:]]*# ]]; then
        continue
    fi
    
    # Bersihkan whitespace
    repo_name=$(echo "$repo_name" | xargs)

    # Validasi repositori
    if validate_single_repo "$repo_name" "$REF_NAME" "$SOURCE"; then
        ((success_count++))
    else
        # Kategorisasi berdasarkan source
        case "$SOURCE" in
            "github")
                ((failed_count++))
                missing_github+=("$repo_name")
                ;;
            "bitbucket")
                ((failed_count++))
                missing_bitbucket+=("$repo_name")
                ;;
            "both")
                # Cek status untuk kategorisasi
                if git ls-remote --heads "https://bitbucket.org/${BITBUCKET_ORG}/${repo_name}.git" | grep -q "refs/heads/${REF_NAME}$" || \
                   git ls-remote --tags "https://bitbucket.org/${BITBUCKET_ORG}/${repo_name}.git" | grep -q "refs/tags/${REF_NAME}$"; then
                    # Ada di Bitbucket, tidak ada di GitHub
                    ((warning_count++))
                    missing_github+=("$repo_name")
                elif gh repo view "${GITHUB_ORG}/${repo_name}" &> /dev/null && \
                     (gh api "repos/${GITHUB_ORG}/${repo_name}/branches/${REF_NAME}" &> /dev/null || \
                      gh api "repos/${GITHUB_ORG}/${repo_name}/tags" --jq ".[] | select(.name == \"${REF_NAME}\") | .name" 2>/dev/null | grep -q "$REF_NAME"); then
                    # Ada di GitHub, tidak ada di Bitbucket
                    ((warning_count++))
                    missing_bitbucket+=("$repo_name")
                else
                    # Tidak ada di keduanya
                    ((failed_count++))
                    missing_both+=("$repo_name")
                fi
                ;;
        esac
    fi

    echo ""
done < "$REPO_FILE"

# --- Ringkasan ---
echo "========================================"
echo "RINGKASAN VALIDASI"
echo "========================================"
echo "Ref yang divalidasi: $REF_NAME"
echo "Source: $SOURCE"
echo "Total repositori diproses: $((success_count + warning_count + failed_count))"

case "$SOURCE" in
    "github")
        echo "✅ GitHub memiliki ref: $success_count"
        echo "❌ GitHub tidak memiliki ref: $failed_count"
        ;;
    "bitbucket")
        echo "✅ Bitbucket memiliki ref: $success_count"
        echo "❌ Bitbucket tidak memiliki ref: $failed_count"
        ;;
    "both")
        echo "✅ Kedua platform memiliki ref: $success_count"
        echo "⚠️  Hanya satu platform memiliki ref: $warning_count"
        echo "❌ Tidak ada platform yang memiliki ref: $failed_count"
        ;;
esac

if [ ${#missing_github[@]} -gt 0 ]; then
    echo ""
    echo "Repositori yang hanya ada di Bitbucket:"
    for repo in "${missing_github[@]}"; do
        echo "  - $repo"
    done
fi

if [ ${#missing_bitbucket[@]} -gt 0 ]; then
    echo ""
    echo "Repositori yang hanya ada di GitHub:"
    for repo in "${missing_bitbucket[@]}"; do
        echo "  - $repo"
    done
fi

if [ ${#missing_both[@]} -gt 0 ]; then
    echo ""
    echo "Repositori yang tidak memiliki ref '$REF_NAME' di kedua platform:"
    for repo in "${missing_both[@]}"; do
        echo "  - $repo"
    done
fi

echo ""
case "$SOURCE" in
    "github")
        if [ $success_count -gt 0 ]; then
            echo "✅ Validasi selesai! $success_count repositori memiliki ref '$REF_NAME' di GitHub."
        else
            echo "❌ Tidak ada repositori yang memiliki ref '$REF_NAME' di GitHub."
        fi
        ;;
    "bitbucket")
        if [ $success_count -gt 0 ]; then
            echo "✅ Validasi selesai! $success_count repositori memiliki ref '$REF_NAME' di Bitbucket."
        else
            echo "❌ Tidak ada repositori yang memiliki ref '$REF_NAME' di Bitbucket."
        fi
        ;;
    "both")
        if [ $success_count -gt 0 ]; then
            echo "✅ Validasi selesai! $success_count repositori memiliki ref '$REF_NAME' di kedua platform."
        else
            echo "❌ Tidak ada repositori yang memiliki ref '$REF_NAME' di kedua platform."
        fi
        ;;
esac

echo ""
echo "📝 Log file tersimpan di: $LOG_FILE"
