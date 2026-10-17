import 'dart:developer';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Background message handler must be a top-level function annotated with @pragma('vm:entry-point')
/// so that the Flutter engine can execute it in a background isolate.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  log('Handling background message: ${message.messageId}');
  log('Payload data: ${message.data}');
}

class PushService {
  FirebaseMessaging? get _fcm {
    try {
      return FirebaseMessaging.instance;
    } catch (_) {
      return null;
    }
  }

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  /// Initialize FCM listeners, local notification channels, and routing callbacks
  Future<void> initialize({Function(String route)? onNotificationTap}) async {
    // 1. Request notification permissions (required for Android 13+ & iOS)
    try {
      final settings = await _fcm?.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      if (settings != null) {
        log('User granted permission: ${settings.authorizationStatus}');
      }
    } catch (e) {
      log('FCM permission initialization notice: $e');
    }

    // 2. Set background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 3. Setup local notification channel for Android (High Importance)
    const androidChannel = AndroidNotificationChannel(
      'campus_announcements_channel',
      'Campus Announcements',
      description: 'Channel for campus notification alerts',
      importance: Importance.high,
    );

    const initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _localNotifications.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload != null && onNotificationTap != null) {
          log('Foreground local notification tapped with payload: $payload');
          onNotificationTap(payload);
        }
      },
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    // 4. Foreground FCM messages: manually show banner using FlutterLocalNotifications
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      final android = message.notification?.android;
      final targetRoute = message.data['route'] ?? '/announcements';

      if (notification != null && android != null) {
        _localNotifications.show(
          id: notification.hashCode,
          title: notification.title,
          body: notification.body,
          payload: targetRoute,
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              androidChannel.id,
              androidChannel.name,
              channelDescription: androidChannel.description,
              icon: android.smallIcon ?? '@mipmap/ic_launcher',
              importance: Importance.high,
              priority: Priority.high,
            ),
          ),
        );
      }
    });

    // 5. Background state click: app is in background and user taps notification banner
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      final route = message.data['route'] ?? '/announcements';
      log('Background notification tapped, navigating to: $route');
      if (onNotificationTap != null) {
        onNotificationTap(route);
      }
    });

    // 6. Terminated state click: app was killed and opened via notification tap
    final initialMessage = await _fcm?.getInitialMessage();
    if (initialMessage != null) {
      final route = initialMessage.data['route'] ?? '/announcements';
      log('Terminated notification tapped on app launch, navigating to: $route');
      if (onNotificationTap != null) {
        onNotificationTap(route);
      }
    }

    // 7. Token lifecycle: listen to token refresh and sync with backend
    _fcm?.onTokenRefresh.listen((newToken) {
      final masked = newToken.length > 10
          ? '${newToken.substring(0, 6)}...${newToken.substring(newToken.length - 4)}'
          : newToken;
      log('FCM Token rotated: $masked. Syncing to backend server...');
      // Mengirimkan token baru ke server backend kampus
    });
  }

  /// Retrieve current device registration token
  Future<String?> getToken() async {
    try {
      final token = await _fcm?.getToken();
      final masked = token != null && token.length > 10
          ? '${token.substring(0, 6)}...${token.substring(token.length - 4)}'
          : token;
      log('FCM Token: $masked');
      return token;
    } catch (e) {
      log('Failed to get FCM token: $e');
      return null;
    }
  }

  /// Topic Messaging
  Future<void> subscribeToTopic(String topic) async {
    await _fcm?.subscribeToTopic(topic);
    log('Subscribed to topic: $topic');
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    await _fcm?.unsubscribeFromTopic(topic);
    log('Unsubscribed from topic: $topic');
  }
}
