#!/bin/bash

# --- Konfigurasi Default ---
BITBUCKET_ORG="loyaltoid"
GITHUB_ORG="Qoin-Digital-Indonesia"

# File yang berisi daftar nama repositori, satu per baris.
REPO_FILE="repos.txt"

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
            echo "Mendeteksi sistem CentOS/RHEL..."
            if command -v dnf &> /dev/null; then
                sudo dnf install -y gh
            elif command -v yum &> /dev/null; then
                sudo yum install -y https://cli.github.com/packages/rpm/gh-cli.repo
                sudo yum install -y gh
            else
                echo "Error: Tidak dapat menemukan package manager yang didukung."
                exit 1
            fi
            ;;
        "debian")
            echo "Mendeteksi sistem Debian/Ubuntu..."
            curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
            sudo apt update
            sudo apt install -y gh
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
            echo "Silakan instal GitHub CLI secara manual."
            exit 1
            ;;
    esac
}

function check_command() {
    if ! command -v "$1" &> /dev/null; then
        if [ "$1" = "gh" ]; then
            install_gh_cli
        else
            echo "Error: '$1' tidak ditemukan. Harap instal '$1' dan coba lagi."
            exit 1
        fi
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
    echo "Dari: https://bitbucket.org/${bitbucket_repo_slug}"
    echo "Ke: ${github_url}"

    # Buat direktori sementara dan masuk ke dalamnya
    local temp_dir=$(mktemp -d)
    echo "Menggunakan direktori sementara: $temp_dir"
    cd "$temp_dir" || return 1

    echo "---"
    echo "Langkah 1: Mengklon repositori Bitbucket..."
    echo "Repositori: https://bitbucket.org/${bitbucket_repo_slug}.git"
    if ! git clone --mirror "https://bitbucket.org/${bitbucket_repo_slug}.git"; then
        echo "❌ Error: Gagal mengklon repositori Bitbucket. Pastikan repositori '${repo_name}' ada di '${BITBUCKET_ORG}' dan kredensial .netrc benar."
        cd - > /dev/null
        rm -rf "$temp_dir"
        return 1
    fi
    echo "✅ Kloning Bitbucket selesai."

    # Masuk ke direktori repositori kloning
    cd "${repo_name}.git" || {
        cd - > /dev/null
        rm -rf "$temp_dir"
        return 1
    }

    echo "---"
    echo "Langkah 2: Memeriksa dan membuat repositori di GitHub..."

    # Cek apakah repo sudah ada
    if gh repo view "${github_repo_owner}/${github_repo_name}" &> /dev/null; then
        echo "Repositori '${github_repo_name}' di GitHub sudah ada."
        # Jika sudah ada, kita hanya perlu set URL remote-nya
        git remote set-url origin "$github_url"
    else
        echo "Repositori '${github_repo_name}' tidak ditemukan. Mencoba membuatnya..."
        # Buat repo baru dengan opsi --source dan --push
        if ! gh repo create "${github_repo_owner}/${github_repo_name}" --source=. --push --private --remote=origin; then
            echo "❌ Error: Gagal membuat repositori di GitHub. Pastikan Anda memiliki izin yang memadai di organisasi '${GITHUB_ORG}'."
            cd - > /dev/null
            rm -rf "$temp_dir"
            return 1
        fi
    fi

    echo "---"
    echo "Langkah 3: Push semua konten ke GitHub..."
    # Kita menggunakan 'push --mirror' lagi untuk memastikan sinkronisasi penuh
    if ! git push --mirror; then
        echo "❌ Error: Gagal push ke GitHub. Silakan periksa kredensial dan izin Anda."
        cd - > /dev/null
        rm -rf "$temp_dir"
        return 1
    fi
    echo "✅ Push ke GitHub selesai. Semua branch dan tag telah dimigrasi."

    # --- Pembersihan ---
    echo "---"
    echo "Langkah 4: Membersihkan direktori sementara..."
    cd - > /dev/null
    rm -rf "$temp_dir"
    echo "✅ Pembersihan selesai."

    echo "---"
    echo "✅ Migrasi '${repo_name}' berhasil!"
    echo "Anda dapat melihat repositori baru di: ${github_url}"
    return 0
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

# Cek file repositori
if [ ! -f "$REPO_FILE" ]; then
    echo "Error: File repositori '$REPO_FILE' tidak ditemukan."
    echo "Buat file '$REPO_FILE' dengan daftar nama repositori (satu per baris)."
    exit 1
fi

# Verifikasi akses ke organisasi
if ! gh api "orgs/${GITHUB_ORG}" &> /dev/null; then
    echo "Error: Tidak dapat mengakses organisasi '${GITHUB_ORG}'."
    echo "Pastikan Anda memiliki akses ke organisasi tersebut."
    exit 1
fi

# --- Logika Utama ---
echo "Memulai proses migrasi dengan organisasi: ${GITHUB_ORG}"
echo "File repositori: ${REPO_FILE}"
echo ""

success_count=0
failed_count=0
failed_repos=()

while IFS= read -r repo_name || [[ -n "$repo_name" ]]; do
    # Lewati baris kosong dan komentar
    if [ -z "$repo_name" ] || [[ "$repo_name" =~ ^[[:space:]]*# ]]; then
        continue
    fi
    
    # Bersihkan whitespace
    repo_name=$(echo "$repo_name" | xargs)

    if migrate_single_repo "$repo_name"; then
        ((success_count++))
    else
        ((failed_count++))
        failed_repos+=("$repo_name")
    fi

    echo ""
done < "$REPO_FILE"

# --- Ringkasan ---
echo "========================================"
echo "RINGKASAN MIGRASI"
echo "========================================"
echo "Total repositori diproses: $((success_count + failed_count))"
echo "Berhasil: $success_count"
echo "Gagal: $failed_count"

if [ ${#failed_repos[@]} -gt 0 ]; then
    echo ""
    echo "Repositori yang gagal dimigrasi:"
    for repo in "${failed_repos[@]}"; do
        echo "  - $repo"
    done
fi

if [ $success_count -gt 0 ]; then
    echo ""
    echo "✅ Migrasi selesai! $success_count repositori berhasil dimigrasi."
else
    echo ""
    echo "❌ Tidak ada repositori yang berhasil dimigrasi."
    exit 1
fi
