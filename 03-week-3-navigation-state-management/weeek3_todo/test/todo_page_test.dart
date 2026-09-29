import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:weeek3_todo/main.dart';

void main() {
  testWidgets('menambah tugas baru', (tester) async {
    // 1. Inisialisasi widget tree dengan ProviderScope
    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    
    // Pastikan UI menampilkan status awal (Belum ada tugas)
    expect(find.text('Belum ada tugas'), findsOneWidget);

    // 2. Simulasi tap tombol tambah (+)
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle(); // Tunggu animasi dialog selesai

    // 3. Simulasi ketik text dan tekan tambah
    await tester.enterText(find.byType(TextField), 'Kerjakan PR minggu 3');
    await tester.tap(find.text('Tambah'));
    await tester.pumpAndSettle(); // Rebuild dan tunggu dialog tertutup sepenuhnya

    // 4. Verifikasi bahwa item baru muncul di UI
    expect(find.text('Kerjakan PR minggu 3'), findsOneWidget);
  });
}
