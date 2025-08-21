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

Untuk menjalankan skrip secara non-interaktif, Anda perlu mengkonfigurasi autentikasi untuk GitHub CLI.

### 1. Instal GitHub CLI

Jika Anda belum menginstalnya, unduh dan instal dari situs resminya: [https://cli.github.com/](https://cli.github.com/)

### 2. Buat File `.netrc`

Untuk memungkinkan `git` dan `gh` melakukan autentikasi secara otomatis tanpa meminta kredensial setiap saat, Anda dapat membuat file `.netrc` di direktori home Anda.

**Penting:** Metode ini menggunakan **Personal Access Token (PAT)**, bukan kata sandi akun GitHub Anda.

1.  **Buat Personal Access Token (PAT)** di GitHub dengan cakupan (scope) yang diperlukan, seperti `repo` untuk mengakses repositori.
2.  Buat file bernama `.netrc` di direktori home Anda. Untuk pengguna Windows, path-nya adalah `C:\Users\<NamaPengguna>\.netrc`.
3.  Tambahkan konten berikut ke dalam file `.netrc`, ganti placeholder dengan informasi Anda:

    ```
    machine github.com
    login <NAMA_PENGGUNA_GITHUB_ANDA>
    password <PERSONAL_ACCESS_TOKEN_ANDA>
    ```

    **Contoh:**
    ```
    machine github.com
    login octocat
    password ghp_aBcDeFgHiJkLmNoPqRsTuVwXyZ1234567890
    ```

### 3. Login dengan GitHub CLI (Satu Perintah)

Meskipun `git` akan menggunakan file `.netrc` secara otomatis, untuk memastikan **GitHub CLI (`gh`)** terautentikasi dengan benar, Anda bisa menggunakan perintah berikut. Perintah ini akan menggunakan token yang ada di file `.netrc` jika `gh` dikonfigurasi untuk itu, atau Anda bisa login menggunakan token secara eksplisit.

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
