import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/app_colors.dart' as app_colors;
import '../../responsive/responsive_layout.dart';
import '../../services/aws_iot_services.dart';

class ConnectedDevicesLocation extends StatelessWidget {
  const ConnectedDevicesLocation({super.key});

  @override
  Widget build(BuildContext context) {
    final AwsIotService aws = Get.find<AwsIotService>();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Connected Device Metrics',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 24),

          /// --- Reactive AWS IoT Data Stream ---
          Obx(() {
            if (!aws.isConnected.value) {
              return const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(
                      color: app_colors.activeBlue,
                      strokeWidth: 5,
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Connecting to AWS IoT...',
                      style: TextStyle(color: app_colors.slateGrey),
                    ),
                  ],
                ),
              );
            }

            final deviceEntries = aws.devices.entries.toList();

            if (deviceEntries.isEmpty) {
              return const Center(
                child: Text(
                  'No devices currently online.',
                  style: TextStyle(color: app_colors.slateGrey),
                ),
              );
            }

            // Responsive Layout: Column for mobile, Wrap for desktop
            return Responsive.isMobile(context)
                ? Column(
              children: deviceEntries
                  .map((entry) => _buildDeviceCard(
                entry.key,
                entry.value,
                aws.deviceStatus[entry.key] ?? 'unknown',
              ))
                  .toList(),
            )
                : Wrap(
              spacing: 16,
              runSpacing: 16,
              children: deviceEntries
                  .map((entry) => _buildDeviceCard(
                entry.key,
                entry.value,
                aws.deviceStatus[entry.key] ?? 'unknown',
                width:
                MediaQuery.of(context).size.width * 0.42, // two per row
              ))
                  .toList(),
            );
          }),
        ],
      ),
    );
  }

  /// --- DEVICE CARD (simple temperature & humidity display) ---
  Widget _buildDeviceCard(String deviceId, Map<String, String> data,
      String status, {double? width}) {
    final temp = data['temperature'] ?? '--';
    final hum = data['humidity'] ?? '--';
    final isOnline = status == 'connected';

    return Container(
      width: width,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isOnline
              ? app_colors.activeBlue.withOpacity(0.7)
              : Colors.redAccent.withOpacity(0.6),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          /// Left: Device ID + Status Indicator
          Row(
            children: [
              Icon(
                Icons.circle,
                color: isOnline ? Colors.green : Colors.redAccent,
                size: 10,
              ),
              const SizedBox(width: 8),
              Text(
                deviceId,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: app_colors.slateGrey,
                  fontSize: 15,
                ),
              ),
            ],
          ),

          /// Right: Temperature & Humidity
          Row(
            children: [
              _buildMetric(
                icon: Icons.thermostat,
                label: 'Temp',
                value: '$temp°C',
                color: app_colors.activeBlue,
              ),
              const SizedBox(width: 20),
              _buildMetric(
                icon: Icons.water_drop,
                label: 'Hum',
                value: '$hum%',
                color: Colors.teal,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// --- Metric Tile (used for temperature & humidity) ---
  Widget _buildMetric({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: app_colors.slateGrey,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
