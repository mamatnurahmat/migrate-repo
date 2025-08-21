# Repository Migration Tools

Kumpulan script untuk migrasi dan manajemen repositori dari Bitbucket ke GitHub.

## 📋 Daftar Script

### 1. `1-create.sh` - Repository Creation
Script untuk membuat repositori private di GitHub atau mengubah repositori publik menjadi private.

### 2. `2-migrate.sh` - Repository Migration  
Script untuk migrasi repositori dari Bitbucket ke GitHub dengan bulk processing.

### 3. `3-check.sh` - Repository Validation
Script untuk validasi keberadaan branch/tag di repositori dengan logging.

## 🚀 Penggunaan

### Prerequisites

1. **GitHub CLI** - Akan diinstal otomatis jika belum ada
2. **Git** - Untuk operasi repository
3. **File `repos.txt`** - Berisi daftar nama repositori (satu per baris)

### Setup Authentication

#### GitHub CLI Login
```bash
gh auth login
```

#### Atau gunakan .netrc file
```bash
# ~/.netrc
machine github.com
login your-username
password your-token

machine bitbucket.org
login your-username
password your-app-password
```

### File repos.txt
Buat file `repos.txt` dengan daftar nama repositori:
```
my-app
backend-api
frontend-ui
# database-service (commented out)
```

## 📖 Detail Script

### 1. `1-create.sh` - Repository Creation

**Fitur:**
- ✅ Membuat repositori private baru
- ✅ Mengubah repositori publik menjadi private
- ✅ Auto-install GitHub CLI
- ✅ Auto-authentication dengan .netrc
- ✅ Bulk processing dari file repos.txt
- ✅ Support CentOS/RHEL/Debian/Ubuntu

**Penggunaan:**
```bash
chmod +x 1-create.sh
./1-create.sh
```

**Output:**
```
Memulai proses dengan organisasi: Qoin-Digital-Indonesia
File repositori: repos.txt

----------------------------------------
Memproses repositori: Qoin-Digital-Indonesia/my-app
✅ Berhasil membuat repositori private 'Qoin-Digital-Indonesia/my-app'
```

### 2. `2-migrate.sh` - Repository Migration

**Fitur:**
- ✅ Migrasi dari Bitbucket ke GitHub
- ✅ Bulk processing dari file repos.txt
- ✅ Auto-install GitHub CLI
- ✅ Auto-authentication dengan .netrc
- ✅ Membuat repositori private di GitHub
- ✅ Migrasi semua branch dan tag
- ✅ Summary report dengan statistik

**Penggunaan:**
```bash
chmod +x 2-migrate.sh
./2-migrate.sh
```

**Output:**
```
Memulai proses migrasi dengan organisasi: Qoin-Digital-Indonesia
File repositori: repos.txt

----------------------------------------
Memigrasi repositori: my-app
Dari: https://bitbucket.org/loyaltoid/my-app
Ke: https://github.com/Qoin-Digital-Indonesia/my-app
✅ Migrasi 'my-app' berhasil!

========================================
RINGKASAN MIGRASI
========================================
Total repositori diproses: 3
Berhasil: 2
Gagal: 1
```

### 3. `3-check.sh` - Repository Validation

**Fitur:**
- ✅ Validasi branch/tag di GitHub (default)
- ✅ Validasi branch/tag di Bitbucket
- ✅ Validasi di kedua platform
- ✅ Auto-install GitHub CLI
- ✅ Auto-authentication dengan .netrc
- ✅ Logging ke file check.logs
- ✅ Detailed reporting

**Penggunaan:**

**Default (GitHub only):**
```bash
chmod +x 3-check.sh
./3-check.sh develop
```

**Bitbucket only:**
```bash
./3-check.sh main bitbucket
```

**Both platforms:**
```bash
./3-check.sh v1.0.0 both
```

**Output:**
```
Memulai validasi repositori...
Ref yang dicari: develop
Source: github
File repositori: repos.txt
Log file: check.logs

----------------------------------------
Validating repository: my-app
Looking for ref: develop
Source: github
  Checking GitHub: https://github.com/Qoin-Digital-Indonesia/my-app
    ✅ Branch 'develop' exists

  Summary for my-app:
    ✅ GitHub has 'develop'

========================================
RINGKASAN VALIDASI
========================================
Ref yang divalidasi: develop
Source: github
Total repositori diproses: 3
✅ GitHub memiliki ref: 2
❌ GitHub tidak memiliki ref: 1

📝 Log file tersimpan di: check.logs
```

## 📝 Log Files

### check.logs
File log untuk script `3-check.sh` yang berisi:
```
# Check Logs - 2024-01-15 10:30:45
# Ref: develop, Source: github
# Format: [timestamp] TYPE: repo_name - description

[2024-01-15 10:30:45] GITHUB_MISSING: frontend-ui - ref 'develop' not found
[2024-01-15 10:30:46] PARTIAL_MISSING: backend-api - ref 'develop' only exists on Bitbucket
```

## 🔧 Konfigurasi

### Organisasi Default
- **GitHub**: `Qoin-Digital-Indonesia`
- **Bitbucket**: `loyaltoid`

### File Konfigurasi
- `repos.txt` - Daftar repositori
- `check.logs` - Log hasil validasi

## 🛠️ Troubleshooting

### GitHub CLI tidak terinstal
Script akan otomatis menginstal GitHub CLI untuk:
- CentOS/RHEL: `sudo dnf install -y gh` atau `sudo yum install -y gh`
- Debian/Ubuntu: `sudo apt install -y gh`

### Authentication Error
```bash
# Login manual ke GitHub CLI
gh auth login

# Atau gunakan token
echo "your-token" | gh auth login --with-token
```

### Repository tidak ditemukan
- Pastikan nama repositori benar di `repos.txt`
- Pastikan memiliki akses ke organisasi
- Pastikan kredensial .netrc benar

## 📊 Workflow Lengkap

### 1. Persiapan
```bash
# Buat file repos.txt
echo "my-app" > repos.txt
echo "backend-api" >> repos.txt
echo "frontend-ui" >> repos.txt

# Setup authentication
gh auth login
```

### 2. Validasi Sebelum Migrasi
```bash
# Cek branch develop di Bitbucket
./3-check.sh develop bitbucket

# Cek branch develop di GitHub
./3-check.sh develop github
```

### 3. Buat Repositori di GitHub
```bash
./1-create.sh
```

### 4. Migrasi Konten
```bash
./2-migrate.sh
```

### 5. Validasi Setelah Migrasi
```bash
# Cek di kedua platform
./3-check.sh develop both
```

## 🎯 Use Cases

- **Pre-migration validation** - Cek status repositori sebelum migrasi
- **Bulk repository creation** - Buat banyak repositori sekaligus
- **Post-migration verification** - Pastikan migrasi berhasil
- **Release management** - Validasi tag release di kedua platform
- **Branch strategy** - Cek konsistensi branch di kedua sistem

## 📄 License

Script ini dibuat untuk internal use di Qoin Digital Indonesia.
