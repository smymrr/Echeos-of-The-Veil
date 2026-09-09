# 🎮 Aturan & Alur Kerja GitHub Tim

Dokumen ini berisi panduan resmi alur kerja (workflow) penggunaan GitHub untuk tim pengembang game Godot. **Semua anggota tim wajib membaca dan mematuhi aturan ini.**

Budayakan membaca.
---

## 📌 Aturan Emas (The Golden Rules)

* **Jangan pernah commit langsung ke `main`.** Branch `main` harus selalu berisi versi game yang stabil, bisa dijalankan, dan bebas dari error parah.
* **Selalu *pull* sebelum mulai kerja.** Sebelum membuat branch baru atau mulai koding/desain, lakukan *pull* dari `main` agar kamu tidak mengerjakan kode versi lama.
* **Satu fitur = Satu branch.** Jangan mencoba membuat seluruh fitur game dalam satu branch. Buatlah tugas tetap kecil dan terfokus.
* **Selalu berkomunikasi!** Jika kamu sedang mengedit scene Godot tertentu (misalnya `Level1.tscn`), beri tahu tim di WhatsApp/Trello agar tidak ada yang mengedit file yang sama secara bersamaan.

### 🚨 NOTE SANGAT PENTING!

⚠️ PEMBERITAHUAN UNTUK SEMUA ANGGOTA TIM:
  1. Jika ingin membuat atau mengubah sesuatu yang bukan merupakan tugas yang diberikan oleh PM (Project Manager), kamu **WAJIB** melapork dan berkomunikasi dengan tim terlebih dahulu melalui WhatsApp.
  2. Jika tugas dari PM sudah selesai, segera check-in ke PM untuk arahan tugas selanjutnya.
  3. **HARUS RAJIN CEK TRELLO!** Selalu periksa kartu Trello secara berkala untuk melihat pembaruan tugas, status pengerjaan, dan catatan dari tim.
  4. Yang push langsung ke main tanpa bikin pull request atau branch, siap siap ditimpuk.

---

## 💻 Panduan Perintah Git (Git Workflow Commands)

Jika kamu menggunakan **Terminal / Command Line / VS Code**, gunakan urutan perintah resmi ini untuk alur pengerjaan tugas:

### 0: Setup Awal Git (Pertama Kali Saja)

Sebelum mulai menggunakan Git, pastikan komputer setiap anggota tim sudah menginstal **Git** dan mengenalkan identitas akun GitHub mereka.

1. **Download & Install Git:**
* Download dan instal Git dari [git-scm.com](https://git-scm.com/) (gunakan pengaturan *default* saat instalasi).

2. **Buka Terminal / Command Prompt / VS Code Terminal**, lalu masukkan perintah berikut untuk mendaftarkan nama dan email GitHub kamu:

```bash
# Masukkan nama panggilan atau nama akun GitHub kamu
git config --global user.name "Nama Kamu"

# Masukkan email yang terdaftar di akun GitHub kamu
git config --global user.email "emailkamu@example.com"

```
3. **Clone Git**

**Buka Terminal**
Ketik perintah ini untuk clone projek Git:

```bash
git clone https://github.com/smymrr/Echeos-of-The-Veil
```

### 1. Sebelum Mulai Koding (Ambil Update Terbaru)

**Buka Terminal**

```bash
# 1. Pindah directory terminal ke folder projek
cd ...... (ganti titik dengan directory projek)
(contoh: cd /home/smymr/Personal/PROJECTS/GAMES/Echeos-of-The-Veil)

# 2. Pindah ke branch main
git switch main

# 3. Ambil update terbaru dari repository server
git pull origin main

# 4. Buat dan langsung berpindah ke branch baru kamu
git switch -c feature/namamu/deskripsi-tugas

```

### 2. Saat / Setelah Selesai Koding (Simpan & Unggah)

```bash
# 1. Cek file apa saja yang sudah kamu ubah
git status

# 2. Tambahkan semua perubahan file ke staging area
git add .

# 3. Simpan perubahan dengan pesan commit yang jelas
git commit -m "Deskripsi singkat tentang apa yang kamu tambahkan/perbaiki" (Contoh: git commit -m "Add slime animation")

# 4. Push branch kamu ke GitHub
git push -u origin feature/namamu/deskripsi-tugas

# 5. Ajukan PR (Pull Request)
Kembali ke GitHub, lalu klik tombol Compare & Pull Request. Kalau tidak ada, pergi ke tab Pull Request dan ajukan PR dari situ. Pastikan base branch adalah **main** dan compare branch adalah branch tugas kamu.
```

### Catatan

Ada alternatif yang lebih mudah untuk digunakan, yaitu GitHub Desktop. GitHub Desktop akan otomatis konek ke folder projek yang ada di device-mu.

---


---

## 🔄 Alur Kerja Harian (Daily Workflow)

Ikuti langkah-langkah ini setiap kali kamu mengerjakan project:

1. **Ambil update terbaru:** Pindah ke branch `main` lalu klik **Pull** untuk mengunduh hasil kerja terbaru dari tim.
2. **Buat branch baru:** Buat branch baru (contoh: `feature/namamu/combat`) dan berpindahlah ke branch tersebut.
3. **Kerjakan tugas:** Buka Godot, tulis kodenya, tes di game, lalu simpan.
4. **Commit perubahan:** Di GitHub / GitHub Desktop, pilih file yang kamu ubah, tulis pesan commit yang jelas, lalu klik **Commit**.
5. **Push ke GitHub:** Klik **Push origin** untuk mengirimkan branch kamu ke server GitHub.
6. **Buat Pull Request (PR):** Buka situs web GitHub dan buat *Pull Request*. Minta **Project Manager** (Sergian) untuk mengecek kodenya. Setelah disetujui, klik **Merge** untuk menggabungkannya ke branch `main`!

---

## 🎨 Pengelolaan Asset Game (Best Practices & File Limit)

GitHub bisa digunakan untuk menyimpan sprite, audio, model 3D, dan tilemap. Namun, perhatikan aturan ini agar *repository* tidak berat atau terblokir:

### 🚨 Batas Ukuran File (100 MB Limit)

* **GitHub menolak file tunggal yang berukuran lebih dari 100 MB.** Jika kamu mencoba mengunggah file di atas 100 MB, proses *push* akan ditolak (*error*).
* Ukuran total *repository* usahakan tetap di bawah **1 GB – 2 GB**.

### 💡 Best Practices

**Gunakan Format Terkompresi:**
* Gambar/Sprite: Gunakan `.png` atau `.webp` (hindari `.bmp` atau `.tga`).
* Audio: Gunakan `.ogg` atau `.mp3` untuk musik durasi panjang (hindari `.wav` tanpa kompresi jika ukurannya sangat besar).

**Simpan File Mentah di Luar GitHub:**
* File mentah seperti `.psd` (Photoshop), `.blend` (Blender), atau video resolusi tinggi **TIDAK BOLEH** diunggah ke GitHub.
* Simpan file mentah di Google Drive / OneDrive / Dropbox, dan **hanya unggah hasil ekspornya** (seperti `.png`, `.gltf`, atau `.tscn`) ke dalam folder project GitHub.


---

## 🌿 Aturan Penamaan Branch

Saat membuat branch baru, gunakan format berikut agar semua anggota tim paham apa yang sedang kamu kerjakan:

```text
[tipe]/[nama-kamu]/[deskripsi-singkat]

```

### Tipe yang Bisa Digunakan:

* `feature/` $\rightarrow$ untuk fitur/mekanik baru (misal: pergerakan, musuh baru, UI)
* `bugfix/` $\rightarrow$ untuk memperbaiki bug/error
* `art/` $\rightarrow$ untuk menambahkan sprite, audio, atau animasi

> **Contoh:**
> * ✅ `feature/sergi/8-way-movement`
> * ✅ `bugfix/azzam/player-stuck-in-wall`
> * ✅ `art/tasya/builder-npc`
> * ❌ `hal-hal-sergi` *(Gak jelas)*
> * ❌ `update` *(Apa yang di-update?)*
> 
> 

---

## 📝 Aturan Pesan Commit (Commit Message)

Tulis pesan commit seolah-olah kamu memberikan perintah langsung kepada kode. Gunakan kata kerja aktif.

> **Contoh:**
> * ✅ `Add attack animation to player` *(Tambahkan animasi serang pada player)*
> * ✅ `Fix diagonal movement speed glitch` *(Perbaiki glitch kecepatan gerak diagonal)*
> * ❌ `added attacks` *(Nambah attack kemana?)*
> * ❌ `fixed it` *(Tidak menjelaskan apa yang diperbaiki)*

---

## 

## ⚠️ Zona Bahaya Khusus Godot: Merge Conflict

Godot menyimpan scene (file `.tscn`) dalam bentuk teks biasa yang cukup panjang. Jika dua orang mengedit scene yang sama persis di waktu yang bersamaan di branch berbeda, GitHub akan mengalami **Merge Conflict** yang sangat sangat sangat **SANGAT** ngeselin untuk diresolve.

### Cara Menghindarinya:

1. **Komunikasi:** Jangan mengedit scene utama jika ada anggota tim lain yang sedang mengerjakannya.
2. **Pecah Scene:** Pecah game kamu menjadi scene-scene kecil! (Contoh: Buat Player jadi scene sendiri, Musuh jadi scene sendiri, dan UI jadi scene sendiri). Dengan begitu, Orang A bisa fokus ke Player sementara Orang B fokus ke Musuh tanpa berbenturan pada file yang sama.
