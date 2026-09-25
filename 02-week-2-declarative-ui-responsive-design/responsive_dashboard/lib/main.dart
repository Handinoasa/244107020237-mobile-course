import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart'; // Tambahkan baris ini untuk CupertinoSwitch

/// Lebar minimum (logical pixels) untuk beralih ke layout dua kolom.
/// Didefinisikan sekali di sini agar mudah diubah dan konsisten di seluruh app.
const double kWideBreakpoint = 700;

void main() => runApp(const DashboardApp());

class DashboardApp extends StatefulWidget {
  const DashboardApp({super.key});

  @override
  State<DashboardApp> createState() => _DashboardAppState();
}

class _DashboardAppState extends State<DashboardApp> {
  bool isDark = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
      darkTheme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          colorSchemeSeed: Colors.indigo),
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      home: DashboardPage(
        isDark: isDark,
        onDarkChanged: (value) => setState(() => isDark = value),
      ),
    );
  }
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({
    required this.isDark,
    required this.onDarkChanged,
    super.key,
  });
  final bool isDark;
  final ValueChanged<bool> onDarkChanged;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Dashboard'),
        actions: [
          Semantics(
            label: isDark ? 'Mode gelap aktif' : 'Mode terang aktif',
            hint: 'Ketuk untuk mengganti tema',
            toggled: isDark,
            excludeSemantics: true,
            child: Row(
              children: [
                Icon(
                  isDark ? Icons.dark_mode : Icons.light_mode,
                  semanticLabel: isDark ? 'Ikon bulan' : 'Ikon matahari',
                ),
                const SizedBox(width: 4),
                CupertinoSwitch(
                  value: isDark,
                  onChanged: onDarkChanged,
                ),
                const SizedBox(width: 12),
              ],
            ),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Gunakan konstanta kWideBreakpoint agar breakpoint hanya ada satu tempat.
          final columns = constraints.maxWidth >= kWideBreakpoint ? 2 : 1;
          return GridView.count(
            padding: const EdgeInsets.all(16),
            crossAxisCount: columns,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 2.6,
            children: const [
              InfoCard(title: 'Total Mahasiswa', value: '1,240'),
              InfoCard(title: 'Mata Kuliah Aktif', value: '8'),
              InfoCard(title: 'Tugas Selesai', value: '24'),
              InfoCard(title: 'IPK Sementara', value: '3.85'),
            ],
          );
        },
      ),
    );
  }
}

/// Widget kartu informasi yang reusable.
/// Menerima [title] sebagai label dan [value] sebagai angka/teks utama.
/// Seluruh warna dan tipografi diambil dari [Theme.of(context)] sehingga
/// otomatis menyesuaikan tema terang maupun gelap.
class InfoCard extends StatelessWidget {
  const InfoCard({required this.title, required this.value, super.key});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Semantics(
      label: '$title: $value',
      button: false,
      child: Card(
        // Warna surface Card mengikuti ColorScheme aktif (terang/gelap).
        color: colorScheme.surfaceContainerHighest,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  semanticsLabel: '',
                  // Gunakan token tipografi dari tema, bukan hardcode.
                  style: textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              Text(
                value,
                semanticsLabel: '',
                style: textTheme.headlineSmall?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}