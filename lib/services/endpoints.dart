import 'package:Elevate/services/aws_iot_services.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EndpointController extends GetxController {
  final topicController = TextEditingController();

  var isTopicSet = false.obs;
  var activeTopic = ''.obs;
  var savedTopics = <String>[].obs;

  static const _activeTopicKey = 'active_topic';
  static const _savedTopicsKey = 'saved_topics';

  final AwsIotService _awsIotService = Get.find<AwsIotService>();

  @override
  void onInit() {
    super.onInit();
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();

    final active = prefs.getString(_activeTopicKey) ?? '';
    final saved = prefs.getStringList(_savedTopicsKey) ?? [];

    savedTopics.assignAll(saved);

    if (active.isNotEmpty) {
      activeTopic.value = active;
      isTopicSet.value = true;
      topicController.text = active;
      _awsIotService.topicName.value = active;
    }
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activeTopicKey, activeTopic.value);
    await prefs.setStringList(_savedTopicsKey, savedTopics.toList());
  }

  void setTopic() {
    final topic = topicController.text.trim();
    if (topic.isEmpty) {
      Get.snackbar(
        "Error", "Please enter a valid topic name",
        backgroundColor: const Color(0xFFFCEBEB),
        colorText: const Color(0xFF791F1F),
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    activeTopic.value = topic;
    isTopicSet.value = true;
    _awsIotService.topicName.value = topic;

    if (!savedTopics.contains(topic)) {
      savedTopics.add(topic);
    }

    _saveToPrefs();

    Get.snackbar(
      "Connected", "Active topic: $topic",
      backgroundColor: const Color(0xFFEAF3DE),
      colorText: const Color(0xFF3B6D11),
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
    );
  }

  void selectSavedTopic(String topic) {
    topicController.text = topic;
    setTopic();
  }

  Future<void> deleteSavedTopic(String topic) async {
    savedTopics.remove(topic);
    if (activeTopic.value == topic) {
      activeTopic.value = '';
      isTopicSet.value = false;
    }
    await _saveToPrefs();
  }

  @override
  void onClose() {
    topicController.dispose();
    super.onClose();
  }
}


class EndpointsPage extends StatelessWidget {
  final EndpointController controller = Get.put(EndpointController());

  EndpointsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAF8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 20, color: Color(0xFF6B6960)),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          "Configure Topic",
          style: TextStyle(
            fontFamily: 'DMSans',
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Color(0xFF1C1B18),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(height: 0.5, color: const Color(0xFFE4E2DC)),
        ),
        actions: [
          Obx(() => controller.isTopicSet.value
              ? Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF3DE),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6, height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFF63A022),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                const Text(
                  "Connected",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF3B6D11),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          )
              : Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F3EE),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6, height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFFB8B4AC),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                const Text(
                  "Idle",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFA09D94),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),

            // Eyebrow
            const Text(
              "AWS IOT",
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                letterSpacing: 1.2,
                color: Color(0xFFA09D94),
              ),
            ),
            const SizedBox(height: 6),

            // Headline
            const Text(
              "Topic endpoint",
              style: TextStyle(
                fontFamily: 'DMSerifDisplay',
                fontSize: 30,
                fontWeight: FontWeight.w400,
                color: Color(0xFF1C1B18),
                letterSpacing: -0.5,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 8),

            const Text(
              "Set an IoT topic to begin subscribing to incoming messages from your device fleet.",
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w300,
                color: Color(0xFF8A877E),
                height: 1.6,
              ),
            ),
            const SizedBox(height: 32),

            // Topic input field
            const Text(
              "TOPIC NAME",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF5A5750),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),

            TextField(
              controller: controller.topicController,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF1C1B18),
                fontFamily: 'DMSans',
              ),
              decoration: InputDecoration(
                hintText: "e.g. asus/sensors/data",
                hintStyle: const TextStyle(color: Color(0xFFB8B4AC), fontSize: 14),
                prefixIcon: const Icon(Icons.sensors, size: 20, color: Color(0xFFB8B4AC)),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFDDD9D2), width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF1C1B18), width: 1.5),
                ),
              ),
              onSubmitted: (_) => controller.setTopic(),
            ),
            const SizedBox(height: 8),

            const Text(
              "Use path notation like  device/telemetry  for nested topics.",
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFFA09D94),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),

            // Feed Topic button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: controller.setTopic,
                icon: const Icon(Icons.cable_rounded, size: 18),
                label: const Text(
                  "Feed topic",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1C1B18),
                  foregroundColor: const Color(0xFFF5F3EE),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Active topic status
            Obx(() => AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: controller.isTopicSet.value
                  ? _StatusCard(
                key: const ValueKey('active'),
                icon: Icons.check_circle_outline_rounded,
                iconColor: const Color(0xFF3B6D11),
                background: const Color(0xFFEAF3DE),
                border: const Color(0xFFC0DD97),
                label: "Active topic",
                value: controller.activeTopic.value,
                valueColor: const Color(0xFF2B5209),
              )
                  : _StatusCard(
                key: const ValueKey('idle'),
                icon: Icons.radio_button_unchecked_rounded,
                iconColor: const Color(0xFFB8B4AC),
                background: const Color(0xFFF5F3EE),
                border: const Color(0xFFE4E2DC),
                label: "No topic configured",
                value: "Enter a topic name above to connect.",
                valueColor: const Color(0xFF8A877E),
              ),
            )),

            // Saved topics dropdown
            Obx(() {
              if (controller.savedTopics.isEmpty) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 28),
                  const Divider(color: Color(0xFFE8E5DF), thickness: 0.5),
                  const SizedBox(height: 20),

                  Row(
                    children: [
                      const Text(
                        "SAVED TOPICS",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1.0,
                          color: Color(0xFFA09D94),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0EDE8),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          "${controller.savedTopics.length}",
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF6B6960),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  ...controller.savedTopics.map((topic) => _SavedTopicRow(
                    topic: topic,
                    isActive: controller.activeTopic.value == topic,
                    onTap: () => controller.selectSavedTopic(topic),
                    onDelete: () => controller.deleteSavedTopic(topic),
                  )),
                ],
              );
            }),

            const SizedBox(height: 28),
            const Divider(color: Color(0xFFE8E5DF), thickness: 0.5),
            const SizedBox(height: 20),

            // Info card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F3EE),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE4E2DC), width: 0.5),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFFA09D94)),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Topics are lightweight message channels used to route data between your devices and the AWS IoT broker. Changes take effect immediately on confirmation.",
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF7A776E),
                        height: 1.6,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // Footer
            Center(
              child: Column(
                children: const [
                  Text(
                    "Mecklin Research Private Limited",
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFFC4C1B8),
                      fontWeight: FontWeight.w300,
                      letterSpacing: 0.2,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    "priyanshu@mecklin.in",
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFFA09D94),
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}


class _StatusCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color background;
  final Color border;
  final String label;
  final String value;
  final Color valueColor;

  const _StatusCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.background,
    required this.border,
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border, width: 0.5),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: iconColor),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF5A5750),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  color: valueColor,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}


class _SavedTopicRow extends StatelessWidget {
  final String topic;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _SavedTopicRow({
    required this.topic,
    required this.isActive,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFEAF3DE) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive ? const Color(0xFFC0DD97) : const Color(0xFFE4E2DC),
            width: isActive ? 1 : 0.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isActive ? Icons.wifi_tethering_rounded : Icons.wifi_tethering_off_rounded,
              size: 16,
              color: isActive ? const Color(0xFF3B6D11) : const Color(0xFFB8B4AC),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                topic,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isActive ? FontWeight.w500 : FontWeight.w400,
                  color: isActive ? const Color(0xFF2B5209) : const Color(0xFF4A4840),
                  fontFamily: 'DMSans',
                ),
              ),
            ),
            if (isActive)
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B6D11),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  "active",
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            GestureDetector(
              onTap: onDelete,
              child: Container(
                padding: const EdgeInsets.all(4),
                child: const Icon(
                  Icons.delete_outline_rounded,
                  size: 16,
                  color: Color(0xFFB8B4AC),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
