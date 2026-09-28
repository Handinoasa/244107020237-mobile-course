import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// AsyncNotifier untuk mensimulasikan pengambilan data statistik
class StatsNotifier extends AsyncNotifier<List<String>> {
  @override
  Future<List<String>> build() async {
    return _fetchData();
  }

  // Fungsi internal untuk mengambil data dengan simulasi delay dan kemungkinan gagal
  Future<List<String>> _fetchData() async {
    // 1. Simulasi delay 2 detik sesuai requirements
    await Future.delayed(const Duration(seconds: 2));

    // 2. Simulasi kadang gagal 30% (angka acak dari 0-9, jika < 3 maka dilempar exception)
    final random = Random();
    if (random.nextInt(10) < 3) {
      throw Exception('Gagal mengambil data statistik');
    }

    // 3. Jika berhasil, kembalikan 3 item list
    return ['Total Pengguna: 1500', 'Pendapatan: \$5000', 'Kunjungan: 300'];
  }

  // Fungsi untuk mencoba ulang pengambilan data
  Future<void> retry() async {
    // Set state menjadi loading saat mulai mengambil ulang
    state = const AsyncValue.loading();
    // AsyncValue.guard secara otomatis akan menangkap error dan mengubah state menjadi AsyncError jika gagal
    state = await AsyncValue.guard(() => _fetchData());
  }
}

// Provider untuk StatsNotifier agar bisa dibaca dari UI
final statsProvider = AsyncNotifierProvider<StatsNotifier, List<String>>(StatsNotifier.new);
