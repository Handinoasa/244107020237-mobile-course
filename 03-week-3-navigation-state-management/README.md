# Week 3 - Navigation & State Management

 - Nama : Handino Asa Galih R
 - Nim : 244107020237
 - Kelas : TI 3E
 
### Tujuan Praktikum
*mahasiswa mampu membangun arsitektur aplikasi Flutter modern melalui penguasaan sistem navigasi lanjutan menggunakan GoRouter (termasuk passing argument dan deep link) serta pengelolaan state asinkron menggunakan ekosistem Riverpod. Mahasiswa tidak hanya akan memahami teori transisi dari Navigator 1.0 dan penanganan UI reaktif menggunakan AsyncValue untuk merespons status loading, error, maupun success, tetapi juga mampu mengimplementasikan seluruh konsep tersebut secara terintegrasi dengan membangun aplikasi ToDo fungsional yang keandalannya divalidasi langsung melalui widget test.*

### Stack Teknologi

| Kategori | Teknologi |
|---|---|
| Bahasa | Dart 3.11.5 |
| Framework | Flutter 3.41.9 |
| Navigasi | `go_router` (declarative routing, nested route, path parameter) |
| State management | `flutter_riverpod` (`Notifier`, `AsyncNotifier`, `AsyncValue`) |
| Pengujian | `flutter_test` (widget test) |
| Tools | VS Code / Android Studio, Git & GitHub |

## Praktikum 1 - Aplikasi multi-page dengan GoRouter
### Navigation Dasar flutter
Navigasi adalah mekanisme berpindah antar layar. Di Flutter, setiap layar adalah route yang ditumpuk pada Navigator (stack). Cara lama (Navigator 1.0) menggunakan Navigator.push dan Navigator.pop
```dart
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => const DetailPage()),
);
```

### GoRouter
GoRouter adalah library navigasi resmi untuk Flutter yang menggunakan pola declarative routing (mendefinisikan rute sebagai variabel). GoRouter sangat fleksibel dan mendukung deep linking, nested routes, code splitting, dan fitur navigasi modern lainnya.

1. Penggunaan MaterialApp.router
Untuk mengaktifkan GoRouter, kita perlu menggunakan MaterialApp.router() alih-alih MaterialApp() biasa.
```dart
MaterialApp.router(
  title: 'Week 3 - Navigation',
  routerConfig: _router,
  theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
);
```
2. Definisi Route
Kita mendefinisikan rute dalam sebuah variabel GoRouter yang berisi list GoRoute.
```dart
final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const Homepage(),
      routes: [
        GoRoute(
          path: 'detail/:id',
          builder: (context, state) =>
              DetailPage(id: state.pathParameters['id']!),
        ),
      ],
    ),
  ],
);
```
3. Nested Routing
Kita bisa membuat nested routes dengan menambahkan GoRoute di dalam children dari GoRoute parent. Ini berguna untuk membuat layout yang memiliki AppBar atau BottomNavigationBar yang sama di beberapa halaman.
```dart
GoRoute(
  path: '/',
  builder: (context, state) => const HomeScreenWrapper(),
  routes: [
    GoRoute(path: 'settings', builder: (context, state) => const SettingsScreen()),
    GoRoute(path: 'profile', builder: (context, state) => const ProfileScreen()),
  ],
),
```
4. Jalankan dan Amati
*Buka item, lalu tekan tombol back sistem. Perhatikan bahwa path berubah mengikuti layar aktif, path yang sama juga dapat diakses langsung tanpa melewati Home. Inilah keunggulan router deklaratif dibanding Navigator 1.0.*

<img src="screenshot/test praktikum 1.png" width="250"/>

## Praktikum 2 - State management dengan Riverpod
### Mengapa perlu state management?
setState hanya cocok untuk state lokal. Jika data perlu digunakan di banyak halaman, state management memisahkannya dari widget tree untuk mencegah kode yang rumit (prop drilling), sehingga:
UI lebih konsisten, logika bisnis mudah diuji, dan data tidak hilang meskipun widget ditutup.

### Konsep inti Riverpod

| Konsep | Penjelasan |
|---|---|
| `ProviderScope` | Wadah global yang menyimpan semua provider, membungkus root aplikasi. |
| `Provider` | Nilai read-only/immutable (misal konfigurasi, service). |
| `Notifier` + `NotifierProvider` | State yang bisa berubah melalui method; UI memanggil method, bukan mengubah state langsung. |
| `ConsumerWidget` | Widget yang bisa membaca provider lewat `ref`. |
| `ref.watch` vs `ref.read` | `watch`: build ulang saat state berubah (di dalam `build`). `read`: sekali baca (di callback/event). |

1. Bungkus aplikasi dengan ProviderScope di lib/main.dart:
```dart
void main() {
  runApp(const ProviderScope(child: MyApp()));
}
```
2. Definisi Provider untuk state (todo_provider.dart):
```dart
class Todo {
  final String id, title;
  final bool done;
  Todo({required this.id, required this.title, this.done = false});
}

class TodoNotifier extends Notifier<List<Todo>> {
  @override
  List<Todo> build() => [];

  void add(String title) =>
      state = [...state, Todo(id: DateTime.now().toString(), title: title)];

  void toggle(String id) => state = [
        for (final t in state)
          t.id == id ? Todo(id: t.id, title: t.title, done: !t.done) : t,
      ];
}

final todoProvider =
    NotifierProvider<TodoNotifier, List<Todo>>(TodoNotifier.new);
```
Catatan: `Notifier` adalah class dasar untuk state mutable, `NotifierProvider` adalah provider yang membungkus `Notifier` tersebut.

3. Tampilkan list & tombol action di UI (home_page.dart):
```dart
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todos = ref.watch(todoProvider); // rebuild saat state berubah

    return Scaffold(
      appBar: AppBar(title: const Text('Todo List')),
      body: ListView(
        children: [
          // TextField + tombol Add -> ref.read(todoProvider.notifier).add(text)
          ...todos.map((t) => ListTile(
                title: Text(t.title,
                    style: TextStyle(
                        decoration: t.done ? TextDecoration.lineThrough : null)),
                onTap: () => ref.read(todoProvider.notifier).toggle(t.id),
              )),
        ],
      ),
    );
  }
}
```
4. Jalankan dan Amati
*Ubah input di Home, lalu buka Detail. Perhatikan bahwa data di Home tetap ada. Jika di-close lalu dibuka lagi, data tetap tersimpan. Inilah manfaat state management yang memisahkan data dari lifecycle widget.*

<img src="screenshot/test praktikum 2.png" width="250"/>

### AsyncValue: loading, error, success
`AsyncValue` adalah class wrapper yang digunakan Riverpod untuk merepresentasikan nilai yang belum tersedia saat ini (loading), gagal diambil (error), atau berhasil (data). Ini membantu kita menangani UI reaktif sesuai status data tanpa kode boilerplate yang rumit.

**Keuntungan:**
- Memisahkan state UI menjadi loading, error, dan success
- Mengurangi penggunaan ternary operator dan null check yang berulang
- Memudahkan dalam menangani kondisi error dengan pesan yang informatif
- Mendukung state reaktif yang otomatis rebuild saat nilai berubah

### AsyncValue: Menangani State Asinkron

Riverpod menyediakan `AsyncValue<T>` yang memodelkan tiga kondisi dalam satu tipe:

| Kondisi | Kelas | Keterangan |
|---|---|---|
| Memuat | `AsyncLoading` | Data sedang diambil |
| Gagal | `AsyncError` | Terjadi error saat fetch |
| Berhasil | `AsyncData` | Data tersedia |

Gunakan `AsyncNotifier` untuk state asinkron:

```dart
class ProductsNotifier extends AsyncNotifier<List<String>> {
  @override
  Future<List<String>> build() async {
    await Future.delayed(const Duration(seconds: 2)); // simulasi network
    return ['Keyboard', 'Mouse', 'Monitor'];
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetch());
  }

  Future<List<String>> _fetch() async {
    await Future.delayed(const Duration(seconds: 1));
    return ['Keyboard', 'Mouse', 'Monitor', 'Headset'];
  }
}

final productsProvider =
    AsyncNotifierProvider<ProductsNotifier, List<String>>(ProductsNotifier.new);
```

> **Catatan:** `AsyncValue.guard` otomatis menangkap exception dan mengubahnya menjadi `AsyncError`, hindari blok `try/catch` manual yang tersebar.

Di sisi UI, `AsyncValue` dapat dipola dengan `.when()`:

```dart
final productsAsync = ref.watch(productsProvider);

return Scaffold(
  appBar: AppBar(title: const Text('Produk')),
  body: productsAsync.when(
    loading: () => const Center(child: CircularProgressIndicator()),
    error: (err, stack) => Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Gagal memuat: $err'),
          FilledButton(
            onPressed: () => ref.invalidate(productsProvider),
            child: const Text('Coba lagi'),
          ),
        ],
      ),
    ),
    data: (products) => ListView(
      children: [for (final p in products) ListTile(title: Text(p))],
    ),
  ),
);
```

1. Amati tampilan loading selama 2 detik pertama, lalu data muncul. Tekan tombol refresh untuk melihat kembali state loading sebelum data baru tampil. maka fungsi AsyncValue — UI reaktif tanpa boilerplate try/catch.

**Apa yang terjadi selama 2 detik tersebut?**

`Future.delayed(2 detik)` mensimulasikan **HTTP request ke server**. Selama menunggu, Riverpod otomatis mengatur state menjadi `AsyncLoading`, sehingga `.when()` merender spinner. Begitu Future selesai, state berubah ke `AsyncData` dan UI rebuild otomatis — tanpa `setState` atau variabel `isLoading` manual.

| State | UI |
|---|---|
| `AsyncLoading` | ⏳ Spinner berputar (0–2 detik) |
| `AsyncData` | ✅ ListView dengan 3 item muncul |
| `AsyncError` | ❌ Pesan error + tombol "Coba lagi" |
<img src="screenshot/test asyncvalue.png" width="250"/>

2. Ubah `build()` sementara untuk melempar error lalu amati UI error beserta tombol Coba lagi:
```dart
@override
Future<List<String>> build() async {
  await Future.delayed(const Duration(seconds: 2));
  throw Exception('Gagal terhubung ke server'); // sementara untuk uji error UI
}
```
Setelah 2 detik, UI menampilkan pesan error dan tombol **Coba lagi**. Tekan tombol tersebut untuk memanggil `ref.invalidate(productsProvider)` yang akan me-reset provider dan memanggil `build()`.

<img src="screenshot/test error server.png" width="250"/>

3. Tekan tombol **Coba lagi**, `ref.invalidate` membuat provider dijalankan ulang. Pulihkan kode `build()` seperti semula, pastikan state success tampil:
```dart
@override
Future<List<String>> build() async {
  await Future.delayed(const Duration(seconds: 2)); // simulasi network
  return ['Keyboard', 'Mouse', 'Monitor']; // kembalikan ke return data
}
```
Setelah dipulihkan, state akan berubah menjadi loading selama 2 detik lalu menampilkan data.

<img src="screenshot/halaman produk.png" width="250"/>

4. Mengapa menampilkan data lama (stale data) lebih baik daripada mengosongkan layar?

Menampilkan ulang data lama dengan indikator refresh lebih baik daripada mengosongkan layar dengan spinner penuh, karena:

1. **Menjaga Konteks:** Pengguna tetap bisa melihat/membaca data lama (seperti feed sosmed atau berita) sambil menunggu data baru.
2. **Kesan Responsif:** Mencegah aplikasi terlihat "blank" atau macet.
3. **Mencegah Layout Shift:** Layar tidak tiba-tiba kosong lalu melompat saat data baru masuk (posisi scroll terjaga).

Pada Riverpod, pola ini mudah dicapai. Saat refresh, Riverpod tetap memberikan `AsyncData` yang lama, sambil mengubah status `.isRefreshing` menjadi `true` di belakang layar, sehingga UI tidak tiba-tiba lenyap.

## Refleksi
- `Kapan setState masih cukup, dan kapan state harus naik ke Riverpod?` setState cukup untuk state lokal satu widget, misalnya isi TextField atau tab aktif. Riverpod dipakai saat data dipakai banyak halaman atau harus tetap ada setelah widget ditutup, seperti daftar todo yang tetap tersimpan saat berpindah antara Home dan Detail.

- `Apa perbedaan context.go dan context.push, dan kapan masing-masing tepat digunakan?` context.go mengganti tumpukan navigasi sesuai path tujuan, cocok untuk pindah antar bagian utama dan deep link. Lalu, context.push menambah halaman di atas tumpukan, cocok untuk halaman sementara yang perlu tombol back, seperti form tambah todo.

- `Bagaimana AsyncValue mencegah bug dibanding tiga boolean terpisah?` Yang akan terjadi ketika Tiga boolean terpisah yaitu loading dan error bersamaan. AsyncValue hanya bisa di satu kondisi (AsyncLoading, AsyncError, AsyncData), dan .when() memaksa ketiganya ditangani.`

- `Bagian mana dari hasil AI yang Anda perbaiki, dan mengapa?` Logika toggle yang terbalik (item yang diketuk tidak berubah, item lain yang berubah), _ctrl yang dipakai tanpa dideklarasikan, dan blok kode HomePage yang duplikat. Kode dari AI belum tentu benar, jadi harus dijalankan dan diuji dulu.

## Referensi pendukung
- Slide: Navigation & State Management
- Flutter: Navigation overview
- GoRouter package
- Riverpod: Getting started
- Riverpod: AsyncNotifier dan AsyncValue
- Learn Dart in Y Minutes