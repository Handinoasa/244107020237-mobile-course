import 'dart:developer';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class AndroidPermissions {
  /// Request POST_NOTIFICATIONS permission for Android 13+ (API 33+) & iOS
  static Future<bool> requestNotificationPermission() async {
    bool isGranted = false;

    // 1. Android 13+ native permission via FlutterLocalNotificationsPlugin
    try {
      final localNotifications = FlutterLocalNotificationsPlugin();
      final androidImplementation = localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      final granted =
          await androidImplementation?.requestNotificationsPermission();
      log('User notification permission granted via Android API: $granted');
      if (granted == true) {
        isGranted = true;
      }
    } catch (e) {
      log('Error requesting permission via local notifications: $e');
    }

    // 2. FCM permission
    try {
      final fcm = FirebaseMessaging.instance;
      final settings = await fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        announcement: false,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
      );
      log('User notification permission status: ${settings.authorizationStatus}');
      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        isGranted = true;
      }
    } catch (e) {
      log('FCM requestPermission info/fallback: $e');
    }

    return isGranted;
  }
}

