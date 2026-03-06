import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/aws_iot_services.dart'; // Adjust path as needed

class DataBucketPage extends StatelessWidget {
  const DataBucketPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Access the existing service instance
    final AwsIotService iotService = Get.find<AwsIotService>();

    return Scaffold(
      appBar: AppBar(title: const Text("Device Data Buckets")),
      body: Obx(() {
        // Obx listens to changes in the 'devices' map
        if (iotService.devices.isEmpty) {
          return const Center(child: Text("No device data received yet."));
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, // 2 columns
            childAspectRatio: 1.5,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: iotService.devices.length,
          itemBuilder: (context, index) {
            String deviceId = iotService.devices.keys.elementAt(index);
            Map<String, String> data = iotService.devices[deviceId]!;

            return Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(deviceId, style: const TextStyle(fontWeight: FontWeight.bold)),
                    const Divider(),
                    Text("Temp: ${data['temperature']}°C"),
                    Text("Hum: ${data['humidity']}%"),
                    Text("Turb: ${data['turbidity']} NTU"),
                  ],
                ),
              ),
            );
          },
        );
      }),
    );
  }
}