import 'package:flutter/material.dart';
import 'package:Elevate/widgets/dashboard/LocationLineChart.dart';
import 'connected_devices_location.dart';
import 'header.dart';
import 'statistics_section.dart';

/// This widget contains the main content of the dashboard.
class MainContent extends StatelessWidget {
  const MainContent({super.key});

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DashboardHeader(),
          SizedBox(height: 24),
          StatisticsSection(),
          SizedBox(height: 24),
          ConnectedDevicesLocation(),
          // LocationLineChart(),
        ],
      ),
    );
  }
}
