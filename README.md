# Skrip Migrasi Repositori Git

Proyek ini berisi sekumpulan skrip shell untuk mengotomatiskan proses migrasi repositori Git dari satu sumber ke GitHub. Proses ini dibagi menjadi dua langkah utama:

1.  **`1-create.sh`**: Membuat repositori baru di akun GitHub Anda.
2.  **`2-migrate.sh`**: Mendorong (push) kode dari repositori lokal ke repositori yang baru dibuat di GitHub.

## Prasyarat

Sebelum memulai, pastikan Anda telah menginstal perangkat lunak berikut:

*   **Git**: Diperlukan untuk semua operasi Git.
*   **GitHub CLI (`gh`)**: Digunakan untuk berinteraksi dengan GitHub API dari baris perintah.
*   **Shell (seperti Git Bash di Windows)**: Diperlukan untuk menjalankan skrip `.sh`.

## Konfigurasi

Untuk menjalankan skrip secara non-interaktif, Anda perlu mengkonfigurasi autentikasi untuk Git dan GitHub CLI.

### 1. Instalasi GitHub CLI

Jika Anda belum menginstalnya, berikut adalah cara instalasi untuk beberapa sistem operasi umum:

*   **Windows (via Winget atau Chocolatey):**
    ```sh
    winget install GitHub.Cli
    # atau
    choco install gh
    ```

*   **macOS (via Homebrew):**
    ```sh
    brew install gh
    ```

*   **Linux (Debian, Ubuntu, Raspbian):**
    ```sh
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
    sudo apt update
    sudo apt install gh
    ```

Untuk sistem operasi lain, kunjungi halaman instalasi resmi: [https://cli.github.com/](https://cli.github.com/)

### 2. Buat File `.netrc` untuk Multi-Host

Untuk memungkinkan `git` melakukan autentikasi secara otomatis ke berbagai host (misalnya GitHub dan Bitbucket), Anda dapat membuat satu file `.netrc` di direktori home Anda.

-   **Untuk GitHub:** Gunakan **Personal Access Token (PAT)**.
-   **Untuk Bitbucket:** Gunakan **App Password**.

Buat file bernama `.netrc` di direktori home Anda (`C:\Users\<NamaPengguna>\.netrc` di Windows) dengan konten berikut:

```
# Kredensial GitHub
machine github.com
login <NAMA_PENGGUNA_GITHUB_ANDA>
password <PERSONAL_ACCESS_TOKEN_GITHUB_ANDA>

# Kredensial Bitbucket
machine bitbucket.org
login <NAMA_PENGGUNA_BITBUCKET_ANDA>
password <PASSWORD_APLIKASI_BITBUCKET_ANDA>
```

### 3. Verifikasi Autentikasi GitHub CLI

Setelah `.netrc` dikonfigurasi, verifikasi bahwa GitHub CLI dapat terhubung dengan benar.

Jalankan perintah berikut untuk memeriksa status autentikasi Anda:


Cara termudah adalah dengan memverifikasi status login Anda. Jika file `.netrc` sudah benar, `gh` akan terautentikasi.

Jalankan perintah berikut untuk memeriksa status autentikasi Anda:

```sh
gh auth status
```

Jika Anda melihat output yang menunjukkan bahwa Anda login ke `github.com` dengan protokol HTTPS, maka konfigurasi Anda sudah berhasil. `gh` akan menggunakan kredensial dari `.netrc` untuk operasi selanjutnya.

## Cara Penggunaan

1.  **Siapkan Daftar Repositori**: Buat file `repos.txt` di direktori ini dan isi dengan nama-nama repositori yang ingin Anda buat (satu nama per baris).

2.  **Jalankan Skrip Pembuatan Repositori**:
    Buka Git Bash atau terminal sejenis, lalu jalankan:
    ```sh
    bash 1-create.sh
    ```
    Skrip ini akan membaca `repos.txt` dan membuat setiap repositori di akun GitHub Anda.

3.  **Jalankan Skrip Migrasi**:
    Setelah repositori berhasil dibuat, jalankan skrip migrasi:
    ```sh
    bash 2-migrate.sh
    ```
    Skrip ini akan melakukan migrasi konten dari repositori lokal Anda ke repositori yang sesuai di GitHub.
