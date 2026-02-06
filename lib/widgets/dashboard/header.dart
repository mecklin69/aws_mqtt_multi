import 'package:flutter/material.dart';
import '../../constants/app_colors.dart' as app_colors;
import '../../data/statistics_data.dart';

class DashboardHeader extends StatelessWidget {
  const DashboardHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('Statistics',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        Row(
          children: [
            const Icon(Icons.account_circle,
                color: app_colors.slateGrey, size: 28),
            const SizedBox(width: 8),
             Text(StatisticsData.userName,
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down, color: app_colors.slateGrey),
          ],
        ),
      ],
    );
  }
}
