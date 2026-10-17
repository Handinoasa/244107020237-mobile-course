import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../messaging/push_service.dart';
import '../providers/auth_provider.dart';
import '../services/android_permissions.dart';
import '../services/firebase_service.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final FirebaseService _firebaseService = FirebaseService();
  final PushService _pushService = PushService();
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _isPermissionGranted = false;
  String _maskedToken = 'Loading...';
  String? _rawToken;
  bool _isTopicSubscribed = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initNotificationSystem();
    });
  }

  Future<void> _initNotificationSystem() async {
    // 1. Setup local notification channel
    const androidChannel = AndroidNotificationChannel(
      'campus_announcements_channel',
      'Campus Announcements',
      description: 'Channel for campus notification alerts',
      importance: Importance.high,
    );

    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );

    await _localNotifications.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload != null && mounted) {
          log('Notification tapped with payload: $payload. Navigating...');
          context.push(payload);
        }
      },
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(androidChannel);

    // 2. Request Android 13+ Notification Permission (Dialog Sistem)
    await _requestPermission();

    // 3. Initialize PushService for FCM listeners & background handlers
    await _pushService.initialize(
      onNotificationTap: (route) {
        if (mounted) {
          context.push(route);
        }
      },
    );

    // 4. Fetch FCM Token (Praktikum 2 Step 4)
    await _fetchToken();
  }

  Future<void> _requestPermission() async {
    final granted = await AndroidPermissions.requestNotificationPermission();
    if (mounted) {
      setState(() {
        _isPermissionGranted = granted;
      });
    }
  }

  Future<void> _fetchToken() async {
    final token = await _firebaseService.getToken();
    _rawToken = token;
    final masked = token != null && token.length > 10
        ? '${token.substring(0, 6)}...${token.substring(token.length - 4)}'
        : (token ?? 'Unavailable');
    log('====================================');
    log('[FCM TOKEN LOGCAT] Current device token: $masked');
    log('[FCM TOKEN RAW] $token');
    log('====================================');
    debugPrint('>>> FCM FULL TOKEN: $token <<<');
    if (mounted) {
      setState(() {
        _maskedToken = masked;
      });
    }
  }

  Future<void> _showTestForegroundNotification() async {
    const androidDetails = AndroidNotificationDetails(
      'campus_announcements_channel',
      'Campus Announcements',
      channelDescription: 'Channel for campus notification alerts',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    await _localNotifications.show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: 'Jadwal Ujian Tengah Semester (UTS)',
      body: 'Jadwal UTS telah dirilis resmi. Ketuk untuk membuka pengumuman.',
      payload: '/announcements',
      notificationDetails: const NotificationDetails(android: androidDetails),
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Banner notifikasi foreground berhasil dimunculkan!'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _toggleTopic(bool value) async {
    setState(() {
      _isTopicSubscribed = value;
    });
    if (_isTopicSubscribed) {
      await _firebaseService.subscribeToTopic('campus_announcements');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Berhasil subscribe topik: campus_announcements'),
          ),
        );
      }
    } else {
      await _firebaseService.unsubscribeFromTopic('campus_announcements');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unsubscribe dari topik: campus_announcements'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Campus Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              await ref.read(authStateProvider.notifier).logout();
              if (context.mounted) {
                context.go('/login');
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Profil Mahasiswa / User Card
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 28,
                    child: Icon(Icons.person, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          authState.user?.name ?? 'Handino Asa Galih',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          authState.user?.email ?? 'Logged in',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Praktikum 2: Section Status Izin & Token FCM
          Text(
            'Praktikum 2: FCM & Permission',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
            ),
          ),
          const SizedBox(height: 8),

          // Card Izin Notifikasi (Android 13+)
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: Icon(
                _isPermissionGranted
                    ? Icons.notifications_active
                    : Icons.notifications_off,
                color: _isPermissionGranted ? Colors.green : Colors.orange,
              ),
              title: const Text('Izin Notifikasi (Android 13+)'),
              subtitle: Text(
                _isPermissionGranted
                    ? 'Status: Granted (Diizinkan)'
                    : 'Status: Belum diizinkan / Perlu izin',
              ),
              trailing: ElevatedButton(
                onPressed: _requestPermission,
                child: const Text('Minta Izin'),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Card Token FCM Sanitasi
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: const Icon(Icons.key, color: Colors.blue),
              title: const Text('FCM Device Token (Sanitasi)'),
              subtitle: Text(
                _maskedToken,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.copy),
                    tooltip: 'Salin Token Lengkap',
                    onPressed: () {
                      if (_rawToken != null) {
                        Clipboard.setData(ClipboardData(text: _rawToken!));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Token FCM lengkap berhasil disalin ke clipboard!',
                            ),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Token belum tersedia. Silakan tekan refresh.',
                            ),
                          ),
                        );
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Ambil Ulang Token',
                    onPressed: _fetchToken,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Praktikum 3: Section Notifikasi Multi-State & Topik
          Text(
            'Praktikum 3: Notifikasi & Deep Routing',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
            ),
          ),
          const SizedBox(height: 8),

          // Tombol Trigger Notifikasi Heads-up Foreground
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Uji Pop-up Banner Foreground & Deep Routing',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Tekan tombol untuk memunculkan notifikasi heads-up lokal. Ketuk notifikasi untuk menguji navigasi langsung ke /announcements.',
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      icon: const Icon(Icons.send_rounded),
                      label: const Text('Kirim Notifikasi Pop-up'),
                      onPressed: _showTestForegroundNotification,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Switch Topic Subscription
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: SwitchListTile(
              secondary: const Icon(Icons.hub, color: Colors.deepOrange),
              title: const Text('Topik: campus_announcements'),
              subtitle: const Text('Langganan siaran massal informasi kampus'),
              value: _isTopicSubscribed,
              onChanged: _toggleTopic,
            ),
          ),
          const SizedBox(height: 16),

          // Quick Access Langsung ke Halaman Pengumuman
          Card(
            elevation: 0,
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: const Icon(Icons.campaign, color: Colors.deepPurple),
              title: const Text('Buka Halaman Pengumuman'),
              subtitle: const Text(
                'Daftar riwayat seluruh siaran notifikasi kampus',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                context.push('/announcements');
              },
            ),
          ),
        ],
      ),
    );
  }
}
