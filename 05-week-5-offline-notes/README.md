# week5_offline_notes

- Nama: Handino Asa Galih
- Nim: 244107020237
- Kelas: TI 3E

### Tujuan Praktikum
1. Memahami arsitektur penyimpanan data lokal di Flutter (*SharedPreferences* vs *SQLite*).
2. Mengimplementasikan manajemen state reaktif menggunakan *Riverpod*.
3. Menerapkan strategi *Cache-First* untuk pembacaan data API agar aplikasi tetap responsif saat offline.
4. Membangun mekanisme antrean sinkronisasi (*dirty flag queue*) dan simulasi deterministik mode offline.

## Fitur Utama pada Praktikum
- **Preferensi Lokal**: Pengaturan tema (*Dark Mode*) tersimpan permanen menggunakan `shared_preferences`.
- **Manajemen Catatan Offline**: Operasi CRUD catatan lokal menggunakan database SQLite (`sqflite`).
- **Penanda Antrean Sync (*Dirty Flag*)**: Pelacakan catatan yang dibuat saat offline untuk diunggah saat online.
- **Cache-First API**: Membaca data post secara instan dari cache SQLite dan memperbarui di latar belakang via `dio`.
- **Simulasi Mode Offline**: Toggle pengujian deterministik langsung melalui antarmuka aplikasi.

### Stack Teknologi
- **Framework**: Flutter & Dart
- **State Management**: `flutter_riverpod`
- **Penyimpanan Lokal**: `shared_preferences`, `sqflite`, `path`
- **Jaringan & HTTP Client**: `dio`



## Praktikum 1: SharedPreferences

1. **Repository Preferensi**: [lib/data/prefs.dart](lib/data/prefs.dart)
   - Mengelola penyimpanan key-value lokal untuk tema gelap dan riwayat waktu buka aplikasi.
2. **Provider & Notifier**: [lib/pages/settings_page.dart](lib/pages/settings_page.dart)
   - Menyediakan `DarkModeNotifier` menggunakan Riverpod untuk reaktivitas UI.


## Praktikum 2: SQLite dan repository catatan

1. Model catatan
[lib/data/local/note.dart](lib/data/local/note.dart). field `dirty` menandai catatan yang belum tersingkron:

2. Pembuka Database
[lib/data/local/db.dart](lib/data/local/db.dart).

3. Repository sebagai satu-satunya pintu akses data
[lib/data/repositories/note_repository.dart](lib/data/repositories/note_repository.dart)

4. Halaman catatan offline
[lib/pages/notes_page.dart](lib/pages/notes_page.dart)

## Praktikum 3: Cache-first dan antrean sync

1. **Cache-first read untuk data API**
   - Model Post: [lib/data/local/post.dart](lib/data/local/post.dart)
   - Repository: [lib/data/repositories/post_repository.dart](lib/data/repositories/post_repository.dart)
   - Alur kerja: Membaca data seketika dari tabel SQLite `cached_posts` agar UI tidak blank saat offline. Di background, data di-fetch dari JSONPlaceholder (`GET /posts`) menggunakan Dio, disimpan kembali ke SQLite, lalu provider di-update.

2. **Sinkronisasi catatan kotor (dirty)**
   - Fungsi: `syncNotes()` di [lib/data/repositories/note_repository.dart](lib/data/repositories/note_repository.dart)
   - Alur kerja: Menghitung jumlah catatan yang belum sinkron (`dirty == 1`). Jika ada, dilakukan simulasi upload ke server dengan delay 1 detik, lalu catatan ditandai bersih (`dirty = 0`).

3. **Simulasi offline yang deterministik & Aturan Konflik**
   - Toggle `forceOfflineProvider` di [lib/pages/notes_page.dart](lib/pages/notes_page.dart) untuk pengujian deterministik langsung melalui UI (chip Online/Offline di AppBar).
   - **Aturan Resolusi Konflik (*Conflict Resolution*)**: Mengadopsi **Last-Write-Wins (LWW)** berdasarkan timestamp `updated_at`. Catatan dengan waktu modifikasi paling akhir menjadi versi definitif bila terjadi divergensi antara klien dan server.

## AI Challenge

Dokumentasi teknis lengkap juga tersimpan di: [docs/ai_comparison.md](docs/ai_comparison.md).

### 1. AI Prompt Challenge
```text
Aplikasi Flutter Offline Notes: CRUD catatan + preferensi tema.
Bandingkan SharedPreferences, Hive, sqflite (SQLite), dan Drift
untuk dua kebutuhan ini. Requirements:
- Kriteria: kompleksitas query, kebutuhan relasi, reaktivitas (stream),
  type-safety, ukuran boilerplate, dan kemudahan testing.
- Beri rekomendasi final: mana untuk preferensi, mana untuk catatan,
  beserta alasannya dalam 1 tabel.
- Tunjukkan skema tabel/kotak untuk 1000+ catatan.
Jelaskan trade-off setiap pilihan.
```

### 2. AI Response Summary

#### A. Tabel Perbandingan Kriteria
| Kriteria | SharedPreferences | Hive | sqflite (SQLite) | Drift (Moor) |
| :--- | :--- | :--- | :--- | :--- |
| **Kompleksitas Query** | Sangat Rendah (Key-Value) | Rendah (Filter manual in-memory) | Sangat Tinggi (Raw SQL, WHERE, LIMIT) | Sangat Tinggi (Fluent Dart API) |
| **Kebutuhan Relasi** | Tidak Ada | Tidak Ada (NoSQL manual ref) | Native (Foreign Key, JOIN, CASCADE) | Native (Type-safe Relations) |
| **Reaktivitas (Stream)** | Tidak Ada | Ada (`box.watch()`) | Tidak Ada (Perlu Riverpod/DAO) | Sangat Kuat (Native Auto Query Streams) |
| **Type-Safety** | Lemah (Dynamic casting) | Menengah (TypeAdapter) | Lemah (Map dynamic runtime) | Sempurna (100% Compile-time Type-Safe) |
| **Boilerplate & Setup**| Sangat Kecil (Zero setup) | Sedang (`@HiveType` + build_runner) | Sedang (Tulis skema & helper manual) | Besar (`drift_dev` + build_runner) |
| **Kemudahan Testing** | Sangat Mudah (Mock built-in) | Sedang (In-memory box) | Mudah (In-memory SQLite DB) | Sangat Mudah (In-memory backend) |

#### B. Rekomendasi Final
| Kebutuhan | Storage Rekomendasi | Alasan Teknis |
| :--- | :--- | :--- |
| **Preferensi Tema** (`dark_mode`) | **SharedPreferences** | Hanya menyimpan data skalar sederhana (boolean/string), overhead memori/CPU minimal, tanpa perlu skema relasional. |
| **Catatan Offline** (1000+ Catatan & Sync) | **sqflite** *(atau Drift)* | Membutuhkan *indexing* pada kolom `dirty` & `updated_at`, paginasi data (*LIMIT/OFFSET*) agar hemat memori, serta jaminan transaksi ACID. |

#### C. Skema Data (SQLite 1000+ Catatan dengan Antrean Sync)
```sql
CREATE TABLE notes (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  uuid TEXT UNIQUE NOT NULL,
  title TEXT NOT NULL,
  body TEXT NOT NULL DEFAULT '',
  updated_at TEXT NOT NULL,
  dirty INTEGER NOT NULL DEFAULT 1,
  deleted INTEGER NOT NULL DEFAULT 0
);

CREATE INDEX idx_notes_dirty ON notes(dirty);
CREATE INDEX idx_notes_updated_at ON notes(updated_at DESC);
```

### 3. AI Verification Checklist

1. **Apakah AI menempatkan daftar catatan di SharedPreferences?**  
   * **Hasil Evaluasi (Ditolak)**: Menyimpan daftar catatan dinamis berukuran besar ke SharedPreferences via serialisasi JSON adalah anti-pattern yang rapuh (*fragile*), memicu *lagging* UI karena harus membaca/menulis seluruh koleksi setiap kali ada satu perubahan data kecil.
2. **Apakah skema AI mendukung antrean sync (dirty flag / updated_at) atau hanya CRUD polos?**  
   * **Hasil Evaluasi (Terverifikasi)**: Skema menyertakan kolom `dirty` (status sinkronisasi antrean) dan `updated_at` (resolusi konflik *Last-Write-Wins*), bukan sekadar CRUD polos.
3. **Apakah klaim "real-time" AI didukung stream (Drift/watch) atau hanya asumsi?**  
   * **Hasil Evaluasi (Terverifikasi)**: SQLite murni (`sqflite`) tidak memiliki stream reaktif bawaan sehingga harus dipadukan dengan State Management (Riverpod `AsyncNotifier`). Sedangkan Drift dan Hive secara native memang mendukung stream query.
4. **Apakah estimasi boilerplate AI masuk akal setelah dicoba?**  
   * **Hasil Evaluasi (Masuk Akal)**: Benar. Kombinasi `SharedPreferences` + `sqflite` tidak membutuhkan `build_runner` (proses build tetap instan). Sebaliknya, Drift memerlukan dependensi dev dan *code generation* yang memakan waktu.
5. **Keputusan Final Mahasiswa:**  
   * Memilih kombinasi arsitektur **Hybrid**: **SharedPreferences** untuk preferensi aplikasi (tema gelap) dan **sqflite (SQLite)** untuk penyimpanan koleksi catatan offline beserta antrean sinkronisasinya.

## Screenshoot
1. Praktikum 1: SharedPreferences & State Management
   Tampilan awal aplikasi saat pengujian integrasi SharedPreferences (`PrefsRepository`) dan Riverpod Notifier untuk manajemen state preferensi (tema dan riwayat akses).
   
<img src="screenshoot/Praktikum%201.jpeg" width="300" alt="Pengujian Praktikum 1"> 

2. Praktikum 2: Halaman Catatan Offline
   Halaman ini digunakan untuk menampilkan catatan offline berbasis SQLite dengan fitur penambahan, penghapusan, dan badge dirty.
   
<img src="screenshoot/Praktikum%202.jpeg" width="300" alt="Halaman Catatan Offline">

3. Praktikum 3: Cache-first dan antrean sync
   Menampilkan integrasi antrean sync dengan badge dinamis, simulasi toggle offline/online pada AppBar, dan tab kedua Cache-First API posts.

<img src="screenshoot/Praktikum%203.jpeg" width="300" alt="Praktikum 3">
