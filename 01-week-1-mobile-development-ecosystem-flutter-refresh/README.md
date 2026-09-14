# Minggu 1 – Mobile Development Ecosystem & Flutter Refresh

- **Nama:** Handino Asa Galih R
- **Nim:** 2434107020237
- **Kelas:** TI 3E

## Tujuan Praktikum
Memahami evolusi ekosistem pengembangan mobile (native vs cross-platform), melakukan instalasi dan verifikasi environment Flutter, menyegarkan kembali pemahaman dasar bahasa Dart (type safety, null safety, OOP), serta membuat aplikasi Profil Mahasiswa sebagai Mini Assignment.

---

## Fitur Utama Pada Praktikum
| Fitur | Keterangan |
|---|---|
| **Avatar** | `CircleAvatar` berisi ikon `school` dengan shadow |
| **Nama Mahasiswa** | Ditampilkan dengan `Text` + styling bold |
| **Nim Badge** | `244107020030` – tampil dalam pill/badge berwarna biru |
| **Info Kartu** | Program Studi, Angkatan, Minat Utama, Platform – menggunakan widget `_InfoCard` reusable  |
| **Tema** | Material 3 + `ColorScheme.fromSeed` biru navy |
| **Latihan Mandiri** | [Nama file latihan] – [ringkasan materi yang dilatih] |

---

## Stack Teknologi
- **Bahasa:** Dart 3.13.2 (null safety penuh)
- **Framework:** Flutter SDK 3.47.2 (stable channel)
- **Tools:** Android Studio Meerkat, Git, Flutter CLI
- **Testing:** `flutter_test` (widget tests)

---

## Cara Menjalankan
```bash
# 1. Masuk ke folder project
cd 01-week-1-mobile-development-ecosystem-flutter-refresh

# 2. Install dependencies
flutter pub get

# 3. Jalankan aplikasi
flutter run

# 4. Jalankan test
flutter test
```

---

## Hasil yang Dicapai
- NIM `244107020030` ditampilkan sebagai badge biru
- Informasi tambahan: Program Studi, Angkatan, Minat Utama, Platform
- Widget test baru memverifikasi nama, NIM, AppBar, dan widget tree
- Environment Flutter berhasil dikonfigurasi (`flutter doctor` clean)
- Widget tree default diganti menjadi **Profil Mahasiswa** lengkap
- Latihan mandiri Dart: fungsi, class, null safety (`??` operator)

---

## Screenshot & Bukti Visual Mini Assignment

### Versi Terbaru (setelah revisi/upgrade)
<img src="Screenshot/mini%20assignment.jpeg" width="250" title="Hasil ketika di run pada mobile">

Hasil ketika di run pada mobile

<img src="Screenshot/MINI%20ASSIGNMENT.png" width="800" title="Tampilan code Program">

Tampilan code program

---

### Versi Awal (sebelum revisi)
<img src="Screenshot/Tampilan%20awal.jpeg" width="250" alt="[deskripsi gambar versi awal]">

> Penambahan detail seperti NIM dan Kelas di bawah nama mahasiswa lalu Perubahan pada format teks bold

---

## Kendala Setup & Solusi

### Kendala: instalasi aplikasi pada mobile
HP menolak instalasi aplikasi melalui USB. Untuk mengatasinya, periksa opsi USB Debugging dan Install via USB (jika tersedia) pada pengaturan pengembang, lalu setujui permintaan izin yang muncul pada HP.
```
E/flutter (24029): [ERROR:flutter/runtime/dart_isolate.cc(146)] Could not prepare isolate.
E/flutter (24029): [ERROR:flutter/runtime/runtime_controller.cc(567)] Could not create root isolate.
E/flutter (24029): [ERROR:flutter/shell/common/shell.cc(799)] Could not launch engine with configuration.
```

**Penyebab:** HP menolak instalasi aplikasi melalui USB.

**Solusi:**
1. Periksa pada pengaturan pengembang.
2. Cari opsi USB Debugging dan Install via USB (jika tersedia).
3. Lalu setujui permintaan izin yang muncul pada HP.

---

## Refleksi

### 1. Kapan native lebih tepat dipilih daripada cross-platform?

Ketika pengembangan native lebih tepat dipilih Ketika membutuhkan performa komputasi yang sangat tinggi misalnya untuk aplikasi game berat atau pemrosesan grafik 3D/AR real time, Akses yang mendalam dan ketergantungan penuh terhadap fitur hardware atau API bawaan sistem operasi terbaru yang belum didukung secara optimal oleh plugin cross-platform, Ukuran aplikasi (app size) yang harus sangat dioptimalkansekecil mungkin tanpa Pustaka tambahan yang besar.

---

### 2. Bagaimana perubahan state berhubungan dengan widget tree dan UI deklaratif?

Dalam pendekatan UI deklaratif (seperti Flutter), UI adalah representasi dari State: Tampilan antarmuka digambarkan berdasarkan kondisi data (state) saat itu. Ketika terjadi perubahan state (misalnya variabel berubah karena interaksi pengguna), Flutter akan memicu proses rebuild pada bagian widget tree yang terdampak. Kerangka kerja akan membandingkan pohon widget yang lama dengan yang baru (diffing), lalu memperbarui layar secara efisien tanpa harus memanipulasi elemen DOM atau view secara manual satu per satu.

---

### 3. Mengapa commit kecil dengan pesan jelas bermanfaat bagi pekerjaan tim dan portfolio?

**Manfaat bagi tim/proyek:**
Memudahkan pelacakan (tracking) bug, memudahkan proses code review karena perubahan dilakukan secara bertahap dan spesifik, serta menghindari konflik penggabungan kode (merge conflict) yang besar

**Manfaat bagi pengembangan diri/portfolio:**
Menunjukkan alur kerja (workflow) pengembangan yang profesional, disiplin, dan terstruktur, sehingga calon perekor atau dosen dapat melihat riwayat progres penyelesaian proyek secara transparan.

---

