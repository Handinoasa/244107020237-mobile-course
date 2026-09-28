import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/stats_provider.dart';

// Halaman menggunakan ConsumerWidget untuk mengakses state Riverpod
class StatsPage extends ConsumerWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Membaca state dari statsProvider
    // ref.watch dipanggil di dalam build agar widget rebuild jika state berubah
    final statsState = ref.watch(statsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Halaman Statistik'),
      ),
      // statsState adalah AsyncValue, sehingga kita bisa menggunakan .when
      // untuk menangani ketiga kemungkinan statenya: loading, error, dan data (success)
      body: statsState.when(
        // 1. Kondisi Loading: menampilkan spinner
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        
        // 2. Kondisi Error: menampilkan pesan dan tombol retry
        error: (error, stackTrace) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Terjadi Kesalahan:\n$error', textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                // ref.read digunakan dalam callback (onPressed) untuk memanggil aksi
                // Memanggil method retry dari notifier
                onPressed: () => ref.read(statsProvider.notifier).retry(),
                child: const Text('Coba Lagi (Retry)'),
              ),
            ],
          ),
        ),
        
        // 3. Kondisi Success/Data: menampilkan ListView berisi 3 item
        data: (stats) => ListView.builder(
          itemCount: stats.length, // Seharusnya panjangnya 3 sesuai provider
          itemBuilder: (context, index) {
            return ListTile(
              leading: const Icon(Icons.show_chart),
              title: Text(stats[index]),
            );
          },
        ),
      ),
    );
  }
}
