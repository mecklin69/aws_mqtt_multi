import '../models/stat_circle_data.dart';

// Centralized data for the statistics section.
// This allows you to easily update the values and labels for the stat circles.

class StatisticsData {
  static const String userName = 'mecklin69';

  static final List<StatCircleData> statCircles = [
    const StatCircleData(value: 0, total: 2, label: 'Devices'),
    const StatCircleData(value: 0, total: 4, label: 'Dashboards'),
    const StatCircleData(value: 0, total: 4, label: 'Data Buckets'),
    const StatCircleData(value: 0, total: 4, label: 'Endpoints'),
  ];
}
