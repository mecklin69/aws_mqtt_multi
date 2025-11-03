import 'package:flutter/material.dart';

import '../../services/notification_service.dart';

class AlarmsPage extends StatelessWidget {
  const AlarmsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F112A),
      appBar: AppBar(
        title: const Text(
          'Alarms & Notifications',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1A1D3A),
      ),
      body: Center(
        child: ElevatedButton.icon(
          icon: const Icon(Icons.notifications_active, color: Colors.white),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1F8EFE),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: () async {
            await NotificationService.showNotification(
              title: 'Test Notification',
              body: 'If you see this, notifications work ✅',
            );
          },
          label: const Text(
            'Test Notification',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
