import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart'; // Tambahkan baris ini untuk CupertinoSwitch

void main() => runApp(const DashboardApp());

class DashboardApp extends StatefulWidget {
  const DashboardApp({super.key});

  @override
  State<DashboardApp> createState() => _DashboardAppState();
}

class _DashboardAppState extends State<DashboardApp> {
  // Eksperimen: Menggunakan ThemeMode agar mendukung light, dark, dan system
  ThemeMode _themeMode = ThemeMode.system;

  @override
  Widget build(BuildContext context) {
    // Mengevaluasi apakah mode saat ini sedang gelap
    final bool isDark = _themeMode == ThemeMode.dark ||
        (_themeMode == ThemeMode.system &&
            MediaQuery.platformBrightnessOf(context) == Brightness.dark);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
      darkTheme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          colorSchemeSeed: Colors.indigo),
      themeMode: _themeMode,
      home: DashboardPage(
        isDark: isDark,
        onThemeModeChanged: (ThemeMode newMode) {
          setState(() {
            _themeMode = newMode;
          });
        },
      ),
    );
  }
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({
    required this.isDark,
    required this.onThemeModeChanged,
    super.key,
  });
  
  final bool isDark;
  final ValueChanged<ThemeMode> onThemeModeChanged;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Dashboard'),
        actions: [
          Row(
            children: [
              Icon(isDark ? Icons.dark_mode : Icons.light_mode),
              const SizedBox(width: 4),
              // Eksperimen Aksesibilitas: Menambahkan Semantics untuk Screen Reader
              Semantics(
                label: 'Pengalih mode tema gelap atau terang',
                toggled: isDark,
                child: CupertinoSwitch(
                  value: isDark,
                  onChanged: (bool value) {
                    onThemeModeChanged(value ? ThemeMode.dark : ThemeMode.light);
                  },
                ),
              ),
              const SizedBox(width: 12),
            ],
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Eksperimen Breakpoint: Menyesuaikan jumlah kolom berdasarkan lebar layar
          int crossAxisCount = 1;
          if (constraints.maxWidth >= 900) {
            crossAxisCount = 3; // Tampilan Desktop / Layar Besar
          } else if (constraints.maxWidth >= 600) {
            crossAxisCount = 2; // Tampilan Tablet
          }

          // Data dummy untuk kartu dashboard
          final List<Map<String, String>> dashboardData = [
            {'title': 'Total Mahasiswa', 'value': '1,240'},
            {'title': 'Mata Kuliah Aktif', 'value': '8'},
            {'title': 'Tugas Selesai', 'value': '24'},
            {'title': 'IPK Sementara', 'value': '3.85'},
          ];

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 2.5,
            ),
            itemCount: dashboardData.length,
            itemBuilder: (context, index) {
              final item = dashboardData[index];
              return DashboardCard(
                title: item['title']!,
                value: item['value']!,
              );
            },
          );
        },
      ),
    );
  }
}

class DashboardCard extends StatelessWidget {
  const DashboardCard({required this.title, required this.value, super.key});
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(children: [
          Expanded(
            child: Text(
              title, 
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Text(value, style: Theme.of(context).textTheme.headlineSmall),
        ]),
      ),
    );
  }
}