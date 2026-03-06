# Repository Migration Tools

Kumpulan script untuk migrasi dan manajemen repositori dari Bitbucket ke GitHub.

## 📋 Daftar Script

### 0. `0-get-repos.sh` - Fetch Repositories
Script untuk mengambil daftar nama repositori dari Bitbucket berdasarkan **Project ID**.

### 1. `1-create.sh` - Repository Creation
Script untuk membuat repositori private di GitHub atau mengubah repositori publik menjadi private.

### 2. `2-migrate.sh` - Repository Migration  
Script untuk migrasi repositori (mirror push) dari Bitbucket ke GitHub secara massal.

### 3. `3-check.sh` - Repository Validation
Script untuk validasi keberadaan branch/tag di repositori dengan logging.

## 🚀 Penggunaan

### Prerequisites

1. **GitHub CLI** - Akan diinstal otomatis jika belum ada (mendukung CentOS, Debian, Arch/CachyOS).
2. **Git** - Untuk operasi repository.
3. **jq** - Diperlukan oleh `0-get-repos.sh` untuk parsing API.
4. **File `.env`** - Untuk konfigurasi variabel lingkungan.

### Setup Konfigurasi (`.env`)

Buat file `.env` di direktori utama:
```bash
BITBUCKET_ORG="loyaltoid"
GITHUB_ORG="mamatnurahmat" # Bisa username personal atau organisasi
REPO_FILE="repos.txt"
```

### Setup Authentication

#### GitHub CLI Login
```bash
echo 'YOUR_TOKEN' | gh auth login --with-token
```

#### Bitbucket & GitHub (Fallback .netrc)
Skrip mendukung pengambilan kredensial dari `~/.netrc`:
```bash
# ~/.netrc
machine github.com
  login your-username
  password your-token

machine bitbucket.org
  login your-username
  password your-app-password
```

## 📖 Detail Script

### 0. `0-get-repos.sh` - Fetch Repositories
Mencari daftar repositori di Bitbucket berdasarkan Project ID.

**Penggunaan:**
```bash
chmod +x 0-get-repos.sh
./0-get-repos.sh NW
```
*Hasil akan disimpan otomatis ke `NW.txt`.*

### 1. `1-create.sh` - Repository Creation
Membuat repositori private di GitHub akun personal atau organisasi.

**Fitur:**
- ✅ Mendukung akun personal dan organisasi
- ✅ Auto-install GitHub CLI (CentOS/Ubuntu/Arch/CachyOS)
- ✅ Membuat repositori private baru secara massal

**Penggunaan:**
```bash
# Pastikan REPO_FILE di .env mengarah ke file yang benar
./1-create.sh
```

### 2. `2-migrate.sh` - Repository Migration
Melakukan migrasi penuh (mirror) dari Bitbucket ke GitHub.

**Fitur:**
- ✅ Migrasi semua branch dan tag
- ✅ Menggunakan direktori sementara (`/tmp`) yang bersih
- ✅ Report summary di akhir proses

**Penggunaan:**
```bash
./2-migrate.sh
```

### 3. `3-check.sh` - Repository Validation
Validasi apakah branch/tag tertentu sudah ada di target target.

**Penggunaan:**
```bash
./3-check.sh develop both # Cek di GitHub dan Bitbucket
```

## ⚠️ Isu Umum (Troubleshooting)

### GitHub File Size Limit (100MB)
GitHub membatasi ukuran file maksimal 100MB. Jika repositori memiliki file besar (seperti `.tar` atau binary > 100MB) tanpa LFS, proses `push` akan gagal.
*Solusi: Gunakan [Git LFS](https://git-lfs.github.com/) atau bersihkan file besar dari history git menggunakan tool seperti `bfg`.*

### Remote Origin Already Exists
Jika menjalankan `1-create.sh` di folder yang sudah merupakan git repo, skrip mungkin menampilkan error saat mencoba menambahkan remote `origin`. Hal ini bisa diabaikan karena repositori di GitHub tetap berhasil dibuat.

## 📊 Workflow Migrasi Lengkap

1. **Setup Env**: Isi file `.env` dengan target yang benar.
2. **Get List**: Jalankan `./0-get-repos.sh PROJECT_ID > repos.txt` untuk mendapatkan daftar repo.
3. **Create Repo**: Jalankan `./1-create.sh` untuk menyiapkan wadah di GitHub.
4. **Migrate**: Jalankan `./2-migrate.sh` untuk memindahkan data.
5. **Verify**: Jalankan `./3-check.sh main both` untuk memastikan data sinkron.

## 🛠️ Sistem Operasi Didukung
Skrip ini memiliki fitur *self-setup* untuk instalasi `github-cli` di:
- **CentOS / RHEL**
- **Debian / Ubuntu**
- **Arch Linux / CachyOS**

---
📝 *Dibuat untuk mempermudah migrasi repositori skala besar.*
