import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:responsive_dashboard/main.dart';

void main() {
  // ---------------------------------------------------------------------------
  // Grup: Responsive Layout Tests
  // Memverifikasi bahwa dashboard menyesuaikan jumlah kolom berdasarkan lebar
  // layar menggunakan tester.view untuk meng-override ukuran fisik layar.
  // ---------------------------------------------------------------------------

  group('Responsive Dashboard Layout', () {
    // -------------------------------------------------------------------------
    // Test 1 – Layar sempit (< 600 dp) → satu kolom
    // Lebar Card diharapkan lebih kecil dari lebar layar (700 < satu kolom).
    // -------------------------------------------------------------------------
    testWidgets('Dashboard satu kolom di layar sempit', (tester) async {
      // Override ukuran layar menjadi 400 × 800 logical pixels (dp).
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      // Kembalikan ukuran layar ke default setelah test selesai.
      addTearDown(tester.view.reset);

      await tester.pumpWidget(const DashboardApp());

      // Ambil lebar Card pertama yang ditemukan di tree.
      final width = tester.getSize(find.byType(Card).first).width;

      // Pada satu kolom, Card mengisi hampir seluruh lebar layar (400 dp),
      // sehingga width pasti lebih kecil dari 700.
      expect(
        width,
        lessThan(700),
        reason:
            'Pada layar sempit (400 dp), Card harus mengisi satu kolom '
            'sehingga lebarnya < 700 dp.',
      );
    });

    // -------------------------------------------------------------------------
    // Test 2 – Layar lebar (≥ 600 dp) → dua kolom
    // Lebar Card diharapkan lebih besar dari 500 dp (setengah layar 1200 dp).
    // -------------------------------------------------------------------------
    testWidgets('Dashboard dua kolom di layar lebar', (tester) async {
      // Override ukuran layar menjadi 1200 × 800 logical pixels (dp).
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(const DashboardApp());

      final width = tester.getSize(find.byType(Card).first).width;

      // Pada dua kolom, tiap Card menempati ~(1200 - padding - spacing) / 2
      // ≈ 584 dp, sehingga lebih besar dari 500.
      expect(
        width,
        greaterThan(500),
        reason:
            'Pada layar lebar (1200 dp), Card harus berbagi dua kolom '
            'sehingga lebarnya > 500 dp.',
      );
    });

    // -------------------------------------------------------------------------
    // Test 3 – Tepat di breakpoint (kWideBreakpoint = 700 dp) → dua kolom
    // -------------------------------------------------------------------------
    testWidgets('Dashboard dua kolom tepat di breakpoint kWideBreakpoint', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(kWideBreakpoint, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(const DashboardApp());

      // Verifikasi GridView menggunakan crossAxisCount = 2.
      final gridView = tester.widget<GridView>(find.byType(GridView));
      final delegate =
          gridView.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(
        delegate.crossAxisCount,
        equals(2),
        reason:
            'Tepat di kWideBreakpoint ($kWideBreakpoint dp), layout harus beralih ke dua kolom.',
      );
    });

    // -------------------------------------------------------------------------
    // Test 4 – Di bawah breakpoint (kWideBreakpoint - 1) → tetap satu kolom
    // -------------------------------------------------------------------------
    testWidgets('Dashboard satu kolom di bawah breakpoint kWideBreakpoint', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(kWideBreakpoint - 1, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(const DashboardApp());

      final gridView = tester.widget<GridView>(find.byType(GridView));
      final delegate =
          gridView.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(
        delegate.crossAxisCount,
        equals(1),
        reason:
            'Di bawah kWideBreakpoint (${kWideBreakpoint - 1} dp), layout harus tetap satu kolom.',
      );
    });

    // -------------------------------------------------------------------------
    // Test 5 – Semua card ter-render (4 DashboardCard)
    // -------------------------------------------------------------------------
    testWidgets('Dashboard menampilkan 4 card di layar apapun', (tester) async {
      tester.view.physicalSize = const Size(800, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(const DashboardApp());

      // Harus ada tepat 4 widget Card yang di-render.
      expect(
        find.byType(Card),
        findsNWidgets(4),
        reason: 'Dashboard harus selalu menampilkan 4 Card.',
      );
    });

    // -------------------------------------------------------------------------
    // Test 6 – Konten Card terlihat (judul & nilai)
    // -------------------------------------------------------------------------
    testWidgets('Card menampilkan judul dan nilai dengan benar', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(const DashboardApp());

      expect(find.text('Total Mahasiswa'), findsOneWidget);
      expect(find.text('1,240'), findsOneWidget);
      expect(find.text('Mata Kuliah Aktif'), findsOneWidget);
      expect(find.text('8'), findsOneWidget);
      expect(find.text('Tugas Selesai'), findsOneWidget);
      expect(find.text('24'), findsOneWidget);
      expect(find.text('IPK Sementara'), findsOneWidget);
      expect(find.text('3.85'), findsOneWidget);
    });
  });
}
