# Week 6 - Authentication, Security & FCM

- Nama: Handino Asa Galih
- NIM: 244107020237
- Kelas: TI 3E

---

### Tujuan Praktikum
1. Menerapkan autentikasi token (JWT) dengan penyimpanan kredensial aman di `flutter_secure_storage` (Android Keystore / iOS Keychain).
2. Membangun interceptor HTTP (`dio`) untuk injeksi Bearer Token dan automasi peremajaan token (HTTP 401 Unauthorized).
3. Melindungi rute navigasi (*Route Guard*) menggunakan `go_router` dan `flutter_riverpod`.
4. Mengintegrasikan Firebase Cloud Messaging (FCM) dan siklus hidup token (`getToken`, `onTokenRefresh`).
5. Menangani notifikasi pada 3 status aplikasi (*Foreground*, *Background*, *Terminated*) serta deep-routing payload (`/announcements`).
6. Menerapkan Topic Messaging untuk siaran pengumuman kampus.

---

## Fitur Utama Praktikum
- **Secure Token Storage**: Enkripsi perangkat keras untuk Access & Refresh Token via Keystore/Keychain.
- **Auto Token Refresh**: Interceptor Dio memperbarui token kedaluwarsa secara otomatis di latar belakang (*silent retry*).
- **Route Guarding**: Proteksi rute otomatis berbasis status autentikasi Riverpod (`/login` ↔ `/home`).
- **Multi-State FCM**:
  - *Foreground*: Pop-up banner lokal via `flutter_local_notifications` (High Importance Channel).
  - *Background*: Ditangani oleh isolate terpisah dengan *top-level function* `@pragma('vm:entry-point')`.
  - *Terminated*: Menangkap payload peluncuran aplikasi via `getInitialMessage()`.
- **Payload Deep Routing**: Menekan banner notifikasi langsung mengarahkan pengguna ke `/announcements`.
- **Topic Subscription**: Mekanisme Pub/Sub untuk siaran massal pengumuman (`campus_announcements`).

---

### Stack Teknologi
| Komponen | Pustaka / Teknologi | Versi | Fungsi |
| :--- | :--- | :--- | :--- |
| **Framework** | Flutter & Dart SDK | ^3.11.5 | Pengembangan aplikasi lintas platform |
| **State Management** | `flutter_riverpod` | ^2.6.1 | Manajemen state autentikasi reaktif |
| **Routing & Guard** | `go_router` | ^17.5.0 | Navigasi deklaratif dan proteksi rute halaman |
| **HTTP Client** | `dio` | ^5.11.1 | Interceptor jaringan & retry otomatis |
| **Secure Storage** | `flutter_secure_storage` | ^11.2.0 | Penyimpanan kredensial terenkripsi di Keystore/Keychain |
| **Push Notification**| `firebase_core` & `firebase_messaging` | ^4.15.0 / ^16.7.0 | Layanan pesan awan FCM |
| **Local Notification**| `flutter_local_notifications` | ^22.3.2 | Banner heads-up saat aplikasi di foreground |

---

## Praktikum 1: Login + Secure Storage + Token Refresh

1. **Penyimpanan Token Aman**: [token_store.dart](lib/data/token_store.dart)
   - Menggunakan `flutter_secure_storage` untuk enkripsi hardware `access_token` dan `refresh_token`, menggantikan `shared_preferences` yang rentan.
2. **Repository Auth**: [auth_repository.dart](lib/data/auth_repository.dart)
   - Mengelola autentikasi, menyimpan pasangan token saat login, dan membersihkan seluruh sesi saat logout.
3. **Dio Refresh Otomatis**: [api_client.dart](lib/data/api_client.dart)
   - `onRequest`: Menyisipkan header `Authorization: Bearer <token>`.
   - `onError`: Saat menerima HTTP 401, client menggunakan refresh token untuk meminta access token baru, lalu melakukan *retry* request awal secara transparan.
4. **Provider Auth & Route Guard**: [auth_provider.dart](lib/providers/auth_provider.dart) & [main.dart](lib/main.dart)
   - `AuthStateNotifier` memvalidasi status login. `GoRouter` mengarahkan user non-login ke `/login` dan user aktif ke `/home`.

---

## Praktikum 2: FCM, Permission, dan Token Lifecycle

1. **Registrasi Firebase**: [AndroidManifest.xml](android/app/src/main/AndroidManifest.xml)
   - Mendaftarkan paket `com.example.campus_notify` dan izin `INTERNET`, `POST_NOTIFICATIONS`, dan `VIBRATE`.
2. **Runtime Permission**: [android_permissions.dart](lib/services/android_permissions.dart) & [push_service.dart](lib/messaging/push_service.dart)
   - Meminta izin runtime `POST_NOTIFICATIONS` untuk Android 13+ (API 33+).
3. **Token Lifecycle**: [firebase_service.dart](lib/services/firebase_service.dart) & [push_service.dart](lib/messaging/push_service.dart)
   - `getToken()`: Mengambil token unik perangkat dengan sanitasi masking pada log konsol.
   - `onTokenRefresh`: Mendengarkan rotasi token dari Google Play Services dan menyinkronkan token baru ke backend.
4. **Uji Kirim Firebase Console**:
   - Kirim notifikasi percobaan ke aplikasi pada kondisi **Background**. Banner sistem muncul di status bar dan dapat diketuk untuk membuka aplikasi.

---

## Praktikum 3: Payload, Tiga App State, Klik dan Topik

### 1. Background Handler Wajib Top-Level
Berkas: [push_service.dart](lib/messaging/push_service.dart)
```dart
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  log('Handling background message: ${message.messageId}');
}
```
*Alasan*: Handler dijalankan pada isolate Dart terpisah tanpa UI. Anotasi `@pragma('vm:entry-point')` mencegah fungsi terhapus oleh *tree-shaking* kompilator AOT Dart.

### 2. Tiga Handler & Contoh Payload
- **Foreground (`onMessage`)**: FCM dicegat dan ditampilkan manual via `flutter_local_notifications`.
- **Background (`onBackgroundMessage` & `onMessageOpenedApp`)**: Ditangani isolate latar belakang; klik banner membawa aplikasi ke depan dan membaca payload rute.
- **Terminated (`getInitialMessage`)**: Menangkap payload saat aplikasi dibuka dari kondisi mati total (*cold start*).

**Contoh Payload Gabungan**:
```json
{
  "notification": {
    "title": "Jadwal UTS",
    "body": "Jadwal Ujian Tengah Semester telah dirilis."
  },
  "data": {
    "route": "/announcements",
    "importance": "high"
  }
}
```

### 3. Matriks Pengujian
| Kondisi (*State*) | Pemicu | Tampilan Notifikasi | Aksi Klik | Hasil Navigasi | Status |
| :--- | :--- | :--- | :--- | :--- | :---: |
| **Foreground** | Kirim FCM saat app terbuka | Heads-up banner lokal | Ketuk banner | Buka `/announcements` | **PASS** |
| **Background** | Kirim FCM saat layar di Home | Banner status bar sistem | Ketuk banner | Resume app & buka `/announcements` | **PASS** |
| **Terminated** | Kirim FCM saat app tertutup | Banner status bar sistem | Ketuk banner | Cold start & buka `/announcements` | **PASS** |
| **Token Rotasi** | Reset cache / perbarui token | Event `onTokenRefresh` | - | Token baru disinkronkan ke server | **PASS** |
| **Topic Broadcast** | Kirim ke `/topics/campus_announcements` | Banner diterima semua subscriber | Ketuk banner | Masuk ke dashboard pengumuman | **PASS** |

### 4. Topic Messaging
Menggunakan `subscribeToTopic('campus_announcements')` untuk distribusi pesan massal satu-ke-banyak (*1-to-many*) secara efisien tanpa menyimpan daftar token per perangkat di server.

---

## AI Challenge

### AI Prompt Challenge
```text
Buat arsitektur Flutter untuk:
1. Simpan Access & Refresh Token via hardware-backed secure storage.
2. Dio interceptor auto-refresh token (HTTP 401) dan retry request transparan.
3. FCM push notification 3 state (Foreground, Background, Terminated) + Android 13 permission.
4. Rotasi token onTokenRefresh dan topic messaging pengumuman kampus.
Tunjukkan potensi celah keamanan dan checklist verifikasinya.
```

### AI Verification Checklist
1. **Background handler top-level & `@pragma('vm:entry-point')`**: **Terverifikasi**. Wajib berupa fungsi top-level di luar kelas agar isolate Android tidak crash.
2. **`onTokenRefresh` sinkron ke backend**: **Terverifikasi**. Token baru diteruskan ke backend kampus, bukan sekadar di-print di log.
3. **Foreground pakai local notification manual**: **Terverifikasi**. Wajib menggunakan `flutter_local_notifications` karena FCM tidak otomatis memunculkan banner di foreground.
4. **Klik dari ketiga state membuka rute yang benar**: **Terverifikasi**. Seluruh state berhasil mengekstrak payload `data['route']` menuju `/announcements`.
5. **Token/secret tidak di-hardcode & log disanitasi**: **Terverifikasi**. Kredensial disimpan di Keystore dan log token disamarkan (*masked*).
6. **Keputusan final**: Mengadopsi arsitektur hybrid Secure Storage + Dio Interceptor + PushService modular.

---

## Tugas & Refleksi

### Mini Project: Campus Notify System
Sistem siaran kampus terpadu dengan autentikasi sesi aman (token refresh transparan) dan distribusi notifikasi hibrida: pesan massal publik via **Topic Messaging** dan notifikasi akademik personal sensitif via **Device Token**.

### Refleksi
1. **Mengapa refresh token tidak boleh di SharedPreferences?**  
   SharedPreferences menyimpan file XML mentah tanpa enkripsi. Pada perangkat rooted atau via ADB backup, file mudah dicuri dan penyerang dapat terus membuat access token baru (*account takeover*).
2. **Dampak jika `onTokenRefresh` diabaikan selama satu semester?**  
   FCM token dapat berubah saat update OS atau pembersihan cache. Jika tidak diperbarui ke server, backend mengirim notifikasi ke token mati (`NotRegistered`), sehingga mahasiswa kehilangan info darurat/ujian.
3. **Kapan memakai topik vs token perangkat?**  
   - *Topik*: Pengumuman massal satu-ke-banyak (contoh: info libur kuliah, edaran wisuda).  
   - *Token Perangkat*: Notifikasi personal rahasia (contoh: tagihan UKT, revisi KRS dosen wali).
4. **Bagian draf AI yang ditolak/diperbaiki?**  
   Menolak background handler di dalam class method (memicu crash isolate), menambahkan banner manual foreground, serta menyamarkan token pada konsol log.

---

## Panduan Pengujian & Checklist Bukti Screenshot

Lakukan pengujian berikut secara bertahap dan simpan tangkapan layar ke folder `screenshoot/`:

### 1. Form Login & Validasi (Praktikum 1)
Jalankan aplikasi (`flutter run`), uji validasi form kosong, lalu masukkan email valid.  
<img src="screenshoot/form login.jpeg" width="250" alt="Halaman Form Login">

---

### 2. Dashboard Home & Route Guard (Praktikum 1)
Tekan Login, pastikan token tersimpan di Secure Storage dan halaman otomatis berpindah ke `/home`.  
<img src="screenshoot/Home Page.jpeg" width="250" alt="Halaman Dashboard Home">

---

### 3. Dialog Izin Notifikasi Android 13+ (Praktikum 2)
Amati dialog sistem *"Allow notifications"*, tekan **Allow**.  
<img src="screenshoot/allow notifications.jpeg" width="250" alt="Izin Notifikasi Runtime Android">

---

### 4. Log Konsol FCM Token (Praktikum 2)
Buka Debug Console/Logcat, verifikasi log pengambilan token FCM yang disanitasi.  
<img src="screenshoot/fcm token log.jpeg" width="500" alt="Log FCM Token di Konsol">

---

### 5. Notifikasi State Background (Praktikum 2)
Minimalkan aplikasi (tekan Home), kirim pesan dari Firebase Console, amati banner di status bar.  
<img src="screenshoot/notifikasi firebase.jpeg" width="300" alt="Uji FCM State Background">

---

### 6. Pop-up Banner di Foreground (Praktikum 3)
Biarkan aplikasi terbuka di layar depan, kirim FCM, amati heads-up banner lokal yang muncul.  
<img src="screenshoot/uji pop up banner foreground.jpeg" width="300" alt="Banner Notifikasi State Foreground">

---

### 7. Hasil Klik / Deep Routing ke Pengumuman (Praktikum 3)
Ketuk notifikasi yang masuk, pastikan payload terbaca dan aplikasi langsung membuka rute `/announcements`.  
<img src="screenshoot/announcement detail.jpeg" width="300" alt="Navigasi ke Halaman Pengumuman">
