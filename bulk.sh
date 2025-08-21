#!/bin/bash

# Script bulk untuk membuat dan migrasi repositori dari Bitbucket ke GitHub
# Penggunaan: ./bulk.sh [create|migrate] [nama-repo1] [nama-repo2] ...

if [ $# -lt 2 ]; then
    echo "Usage: $0 [create|migrate] [repo1] [repo2] ..."
    echo ""
    echo "Examples:"
    echo "  $0 create my-app backend-api frontend-ui"
    echo "  $0 migrate my-app backend-api frontend-ui"
    exit 1
fi

ACTION="$1"
shift
REPO_NAMES=("$@")

BITBUCKET_ORG="loyaltoid"
GITHUB_ORG="Qoin-Digital-Indonesia"

# Install GitHub CLI jika belum ada
if ! command -v gh &> /dev/null; then
    echo "Installing GitHub CLI..."
    if command -v dnf &> /dev/null; then
        sudo dnf install -y gh
    elif command -v yum &> /dev/null; then
        sudo yum install -y https://cli.github.com/packages/rpm/gh-cli.repo && sudo yum install -y gh
    elif command -v apt &> /dev/null; then
        curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
        sudo apt update && sudo apt install -y gh
    else
        echo "Error: Package manager tidak didukung. Install GitHub CLI manual: https://cli.github.com/"
        exit 1
    fi
fi

# Login dengan .netrc atau interaktif
if ! gh auth status &> /dev/null; then
    if [ -f ~/.netrc ] && grep -q "github.com" ~/.netrc; then
        token=$(grep -A 2 "github.com" ~/.netrc | grep "password" | awk '{print $2}')
        echo "$token" | gh auth login --with-token
    else
        echo "Login ke GitHub CLI diperlukan. Jalankan: gh auth login"
        exit 1
    fi
fi

# Fungsi untuk membuat repositori
create_repos() {
    echo "=== BULK CREATE REPOSITORIES ==="
    for repo_name in "${REPO_NAMES[@]}"; do
        if [ -n "$repo_name" ]; then
            full_repo="${GITHUB_ORG}/${repo_name}"
            echo "Processing: $full_repo"
            
            if gh repo view "$full_repo" &> /dev/null; then
                # Repo exists, make private
                if gh repo edit "$full_repo" --visibility private; then
                    echo "✅ $full_repo -> private"
                else
                    echo "❌ Failed to make $full_repo private"
                fi
            else
                # Create new private repo
                if gh repo create "$full_repo" --private; then
                    echo "✅ Created private $full_repo"
                else
                    echo "❌ Failed to create $full_repo"
                fi
            fi
        fi
    done
}

# Fungsi untuk migrasi repositori
migrate_repos() {
    echo "=== BULK MIGRATE REPOSITORIES ==="
    for repo_name in "${REPO_NAMES[@]}"; do
        if [ -n "$repo_name" ]; then
            echo "----------------------------------------"
            echo "Migrating: $repo_name"
            
            # Buat direktori sementara
            TEMP_DIR=$(mktemp -d)
            cd "$TEMP_DIR"
            
            # Clone dari Bitbucket
            if git clone --mirror "https://bitbucket.org/${BITBUCKET_ORG}/${repo_name}.git"; then
                cd "${repo_name}.git"
                
                # Buat repo di GitHub (jika belum ada) dan push
                if ! gh repo view "${GITHUB_ORG}/${repo_name}" &> /dev/null; then
                    if gh repo create "${GITHUB_ORG}/${repo_name}" --source=. --push --private --remote=origin; then
                        echo "✅ Created and migrated $repo_name"
                    else
                        echo "❌ Failed to create GitHub repo for $repo_name"
                    fi
                else
                    git remote set-url origin "https://github.com/${GITHUB_ORG}/${repo_name}"
                    if git push --mirror; then
                        echo "✅ Migrated $repo_name to existing GitHub repo"
                    else
                        echo "❌ Failed to push $repo_name to GitHub"
                    fi
                fi
                
                cd - > /dev/null
            else
                echo "❌ Failed to clone $repo_name from Bitbucket"
            fi
            
            # Cleanup
            rm -rf "$TEMP_DIR"
        fi
    done
}

# Eksekusi berdasarkan action
case "$ACTION" in
    "create")
        create_repos
        ;;
    "migrate")
        migrate_repos
        ;;
    *)
        echo "Error: Action '$ACTION' tidak valid. Gunakan 'create' atau 'migrate'"
        exit 1
        ;;
esac

echo "----------------------------------------"
echo "✅ Bulk operation completed!"
