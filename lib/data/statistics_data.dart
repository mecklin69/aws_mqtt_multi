import '../models/stat_circle_data.dart';
import '../services/aws_iot_services.dart';
import '../services/storage_service.dart';

class StatisticsData {
  static String userName = StorageService.getUsername();

  // Pass the service here so we use the reactive data
  static List<StatCircleData> getStatCircles(AwsIotService aws) {
    final deviceCount = StorageService.getDeviceCount();
    final deviceEntries = aws.devices.entries.toList();

    return [
      StatCircleData(
          value: deviceEntries.length,
          total: deviceCount,
          label: 'Devices'
      ),
      const StatCircleData(value: 0, total: 4, label: 'Alarms'),
      const StatCircleData(value: 0, total: 4, label: 'Critical'),
      const StatCircleData(value: 0, total: 4, label: 'Locations'),
    ];
  }
}