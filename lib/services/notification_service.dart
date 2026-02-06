import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
  FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    // 1. Android Settings
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    // 2. Windows Settings (This replaces the 'register' method)
    // GUID can be any unique string; AppName is what shows in the toast
    const WindowsInitializationSettings initializationSettingsWindows =
    WindowsInitializationSettings(
      appName: 'Elevate Engineer',
      appUserModelId: 'com.example.elevate', // A unique identifier for Windows
      guid: 'E621E1F8-C36C-495A-93FC-0C247A3E6E5F', // A random unique GUID
    );

    // 3. Combine Settings
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      windows: initializationSettingsWindows,
    );

    // 4. Initialize everything
    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        if (kDebugMode) {
          print("Notification Interaction Detected");
        }
      },
    );
  }

  static Future<void> showNotification({required String title, required String body}) async {
    // Standard platform details
    const NotificationDetails platformDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        'alarm_channel',
        'Alarms',
        importance: Importance.max,
        priority: Priority.high,
      ),
      // Windows implementation inherits the main initialize settings
    );

    try {
      await _notificationsPlugin.show(
        DateTime.now().millisecond, // Ensures each notification has a fresh ID
        title,
        body,
        platformDetails,
      );
    } catch (e) {
      print("Windows Notification failed: $e");
    }
  }
}