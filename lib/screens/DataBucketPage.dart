import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import '../services/aws_iot_services.dart';

class DataBucketPage extends StatelessWidget {
  const DataBucketPage({super.key});

  Future<void> _exportLogs(List<Map<String, dynamic>> logs) async {
    if (logs.isEmpty) return;

    // 1. Convert logs to CSV
    List<List<dynamic>> rows = [
      ['DeviceID', 'Temperature', 'Humidity', 'Turbidity', 'Timestamp'],
      ...logs.map((e) => [
        e['device'],
        e['temperature'],
        e['humidity'],
        e['turbidity'],
        e['timestamp']
      ])
    ];
    String csv = const ListToCsvConverter().convert(rows);
    String fileName = 'sensor_logs_${DateTime.now().millisecondsSinceEpoch}.csv';

    // 2. Platform-specific export logic
    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      // Desktop: Open "Save As" dialog
      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Please select where to save your file:',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (outputFile != null) {
        await File(outputFile).writeAsString(csv);
        Get.snackbar("Success", "File saved to: $outputFile",
            snackPosition: SnackPosition.BOTTOM);
      }
    } else {
      // Mobile (Android/iOS): Save to temp directory and trigger Share sheet
      final directory = await getTemporaryDirectory();
      final filePath = "${directory.path}/$fileName";
      final file = File(filePath);
      await file.writeAsString(csv);

      await Share.shareXFiles([XFile(filePath)], text: 'Exported sensor logs');
    }
  }

  @override
  Widget build(BuildContext context) {
    final AwsIotService iotService = Get.find<AwsIotService>();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        if (iotService.logBuffer.isNotEmpty) {
          final shouldExit = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text("Unsaved Logs"),
              content: const Text(
                  "You have unsaved data. Do you want to export before exiting?"),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text("Stay")),
                TextButton(
                    onPressed: () {
                      _exportLogs(iotService.logBuffer);
                      Navigator.pop(ctx, true);
                    },
                    child: const Text("Save & Exit")),
                TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text("Discard")),
              ],
            ),
          );
          if (shouldExit == true) Navigator.of(context).pop();
        } else {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Real-Time Data Logger"),
          actions: [
            Obx(() => IconButton(
              icon: Icon(
                iotService.isLogging.value
                    ? Icons.stop_circle
                    : Icons.play_circle,
                color: iotService.isLogging.value ? Colors.red : Colors.green,
                size: 32,
              ),
              onPressed: () => iotService.isLogging.value =
              !iotService.isLogging.value,
            )),
            Obx(() => IconButton(
              icon: const Icon(Icons.download),
              onPressed: iotService.logBuffer.isEmpty
                  ? null
                  : () => _exportLogs(iotService.logBuffer),
            )),
          ],
        ),
        body: Obx(() {
          if (iotService.logBuffer.isEmpty) {
            return const Center(
                child: Text("Logging inactive or no data received."));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: iotService.logBuffer.length,
            itemBuilder: (ctx, i) {
              final log = iotService.logBuffer[i];
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.sensors, color: Colors.indigo),
                  title: Text("Device: ${log['device']}"),
                  subtitle: Text(
                    "Temp: ${log['temperature']}°C | Hum: ${log['humidity']}% | Turb: ${log['turbidity']} NTU",
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  trailing: Text(log['timestamp']
                      .toString()
                      .split(' ')
                      .last
                      .split('.')
                      .first),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}