// lib/services/notification_service.dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
  FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    // Android
    const AndroidInitializationSettings androidInit =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS / macOS (Darwin)
    final DarwinInitializationSettings darwinInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // Linux (optional)
    final LinuxInitializationSettings linuxInit =
    LinuxInitializationSettings(defaultActionName: 'Open');

    // Windows — REQUIRED when targeting Windows
    final WindowsInitializationSettings windowsInit = WindowsInitializationSettings(appName: 'Elevate', appUserModelId: '', guid: ''
      // optional: appId: 'com.example.yourapp',
    );

    final InitializationSettings initSettings = InitializationSettings(
      android: androidInit,
      iOS: darwinInit,
      macOS: darwinInit,
      linux: linuxInit,
      windows: windowsInit,
    );

    await _plugin.initialize(
      initSettings,
      // optional handlers:
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // handle notification tap
      },
      onDidReceiveBackgroundNotificationResponse: (NotificationResponse response) {
        // optional background handler
      },
    );
  }

  static Future<void> showNotification({
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'aws_iot_channel',
      'AWS IoT Alerts',
      channelDescription: 'Device status and updates',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
    );

    const NotificationDetails details = NotificationDetails(android: androidDetails);
    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
    );
  }
}
