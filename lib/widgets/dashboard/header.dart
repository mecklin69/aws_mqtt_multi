import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/extension_instance.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:get/get_navigation/src/snackbar/snackbar.dart';
import '../../constants/app_colors.dart' as app_colors;
import '../../data/statistics_data.dart';
import '../../services/aws_iot_services.dart';

class DashboardHeader extends StatelessWidget {
  const DashboardHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Title
        const Text(
          'Statistics',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),

        // Action Button - Restart Connections
        // Inside DashboardHeader build method...
        OutlinedButton.icon(
          onPressed: () async {
            // Show a snackbar or loading indicator if desired
            Get.snackbar(
              'System',
              'Restarting connections...',
              snackPosition: SnackPosition.BOTTOM,
              duration: const Duration(seconds: 1),
            );

            // Find the service and trigger the restart
            final awsService = Get.find<AwsIotService>();
            await awsService.restartService();
          },
          icon: const Icon(Icons.refresh, size: 18),
          label: const Text('Restart Connections'),
          style: OutlinedButton.styleFrom(
            foregroundColor: app_colors.slateGrey,
            side: const BorderSide(color: app_colors.slateGrey),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),

        // User Profile Section
        Row(
          children: [
            const Icon(
              Icons.account_circle,
              color: app_colors.slateGrey,
              size: 28,
            ),
            const SizedBox(width: 8),
            Text(
              StatisticsData.userName,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down, color: app_colors.slateGrey),
          ],
        ),
      ],
    );
  }
}