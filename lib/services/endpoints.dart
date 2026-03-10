import 'package:Elevate/services/aws_iot_services.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class EndpointController extends GetxController {
  final topicController = TextEditingController();
  var isTopicSet = false.obs;

  // Get the instance managed by GetX
  final AwsIotService _awsIotService = Get.find<AwsIotService>();

  void setTopic() {
    if (topicController.text.isNotEmpty) {
      // Updating this value automatically triggers 'ever' in the service
      _awsIotService.topicName.value = topicController.text;
      isTopicSet.value = true;

      Get.snackbar("Success", "Topic set to: ${topicController.text}");
    } else {
      Get.snackbar("Error", "Please enter a valid topic name");
    }
  }
}

class EndpointsPage extends StatelessWidget {
  EndpointController controller = Get.put(EndpointController());

   EndpointsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Configure Topic")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: controller.topicController,
              decoration: const InputDecoration(
                labelText: "Enter AWS IoT Topic",
                border: OutlineInputBorder(),
                hintText: "e.g., esp8266/Sensor1/data",
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: controller.setTopic,
              child: const Text("Feed Topic"),
            ),
            const SizedBox(height: 20),
            Obx(() => controller.isTopicSet.value
                ? Text("Active Topic: ${controller}",
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green))
                : const Text("No topic configured")),
          ],
        ),
      ),
    );
  }
}