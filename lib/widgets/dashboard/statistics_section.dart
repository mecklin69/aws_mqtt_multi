import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/app_colors.dart' as app_colors;
import '../../data/statistics_data.dart';
import '../../services/aws_iot_services.dart';
import 'stat_circle.dart';

class StatisticsSection extends StatelessWidget {
  const StatisticsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final AwsIotService awsService = Get.find<AwsIotService>();

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
          // --- HEADER ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 🟢 Reactive Connected Status (GetX Obx)
              Obx(() {
                final count = awsService.connectedDeviceCount.value;
                final connected = awsService.isConnected.value;

                Color bgColor;
                String text;
                final AwsIotService aws = Get.find<AwsIotService>();
                final deviceEntries = aws.devices.entries.toList();
                if (!connected) {
                  bgColor = Colors.orangeAccent;
                  text = 'Connecting...';
                } else if (deviceEntries.isNotEmpty) {
                  int n=deviceEntries.length;
                  bgColor = Colors.green;
                  text = 'Connected Devices: $n';
                } else {
                  bgColor = Colors.redAccent;
                  text = 'No Devices Connected';
                }

                return Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              }),

              const Text(
                'Account Stats',
                style: TextStyle(
                  color: app_colors.activeBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // --- STAT CIRCLES ---
          // --- STAT CIRCLES ---
          Obx(() {
            // Accessing awsService.devices inside Obx tells GetX to listen for changes
            final deviceEntries = awsService.devices.entries.toList();

            return LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 600;

                // Now this method runs every time awsService.devices updates
                final statWidgets = StatisticsData.getStatCircles(awsService)
                    .map((data) => StatCircle(
                  value: data.value,
                  total: data.total,
                  label: data.label,
                ))
                    .toList();

                return isNarrow
                    ? Wrap(
                  spacing: 20.0,
                  runSpacing: 24.0,
                  alignment: WrapAlignment.spaceBetween,
                  children: statWidgets,
                )
                    : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: statWidgets,
                );
              },
            );
          }),
        ],
      ),
    );
  }
}
