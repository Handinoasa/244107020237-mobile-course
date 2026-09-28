import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weeek3_todo/providers/stats_provider.dart';

void main() {
  test('StatsNotifier inisialisasi awal harus berupa loading', () {
    // Mempersiapkan container provider
    final container = ProviderContainer();
    addTearDown(container.dispose); // Pastikan provider dihapus setelah test

    // Karena proses pengambilan data memakan waktu (delay 2 detik),
    // state pertama yang terbaca secara sinkron haruslah loading
    final state = container.read(statsProvider);
    
    // Verifikasi bahwa state awal adalah AsyncLoading
    expect(state, isA<AsyncLoading<List<String>>>());
  });
  
  test('StatsNotifier retry harus merubah state menjadi loading kembali', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // Memanggil fungsi retry secara asinkron (tidak ditunggu untuk membaca state terkininya)
    final retryFuture = container.read(statsProvider.notifier).retry();
    
    // Sesaat setelah dipanggil, state harus menjadi loading
    final state = container.read(statsProvider);
    expect(state, isA<AsyncLoading<List<String>>>());
    
    // Selesaikan future agar tidak menggantung di test
    try {
      await retryFuture;
    } catch (_) {
      // Abaikan jika ternyata masuk probabilitas 30% gagal
    }
  });
}
