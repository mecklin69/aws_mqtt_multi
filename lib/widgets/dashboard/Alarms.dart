import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../services/notification_service.dart';

class AlarmsPage extends StatefulWidget {
  const AlarmsPage({super.key});

  @override
  State<AlarmsPage> createState() => _AlarmsPageState();
}

class _AlarmsPageState extends State<AlarmsPage> {
  // Threshold States
  double _tempThreshold = 45.0;
  double _humidityThreshold = 80.0;
  bool _alarmsEnabled = true;

  // Timer for the 15-minute interval check
  Timer? _intervalTimer;

  @override
  void initState() {
    super.initState();
    _startAlarmCheck();
  }

  @override
  void dispose() {
    _intervalTimer?.cancel();
    super.dispose();
  }

  void _startAlarmCheck() {
    // Check every 15 minutes
    _intervalTimer = Timer.periodic(const Duration(minutes: 15), (timer) {
      if (_alarmsEnabled) {
        _evaluateThresholds();
      }
    });
  }

  // Mock logic: In a real app, you'd compare these against live sensor data
  void _evaluateThresholds() async {
    // Example: if currentTemp > _tempThreshold
    await NotificationService.showNotification(
      title: 'Threshold Alert',
      body: 'Environmental parameters have exceeded set limits.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F112A),
      appBar: AppBar(
        elevation: 0,
        title: const Text('Device Thresholds', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1A1D3A),
        actions: [
          Transform.scale(
            scale: 0.8,
            child: CupertinoSwitch(
              value: _alarmsEnabled,
              activeColor: const Color(0xFF1F8EFE),
              onChanged: (val) => setState(() => _alarmsEnabled = val),
            ),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoCard(),
            const SizedBox(height: 32),
            _buildThresholdSlider(
              label: "Temperature Limit",
              value: _tempThreshold,
              min: 0,
              max: 100,
              unit: "°C",
              icon: CupertinoIcons.thermometer,
              color: Colors.orangeAccent,
              onChanged: (val) => setState(() => _tempThreshold = val),
            ),
            const SizedBox(height: 24),
            _buildThresholdSlider(
              label: "Humidity Limit",
              value: _humidityThreshold,
              min: 0,
              max: 100,
              unit: "%",
              icon: CupertinoIcons.drop,
              color: Colors.cyanAccent,
              onChanged: (val) => setState(() => _humidityThreshold = val),
            ),
            const SizedBox(height: 40),
            _buildTestButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1D3A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          const Icon(CupertinoIcons.info_circle, color: Color(0xFF1F8EFE)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              "Alarms will trigger every 15 minutes if sensors exceed your defined limits.",
              style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThresholdSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required String unit,
    required IconData icon,
    required Color color,
    required Function(double) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              ],
            ),
            Text(
              "${value.toInt()}$unit",
              style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        const SizedBox(height: 8),
        CupertinoSlider(
          value: value,
          min: min,
          max: max,
          activeColor: color,
          thumbColor: Colors.white,
          onChanged: _alarmsEnabled ? onChanged : null,
        ),
      ],
    );
  }

  Widget _buildTestButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: const Icon(CupertinoIcons.bell_fill, color: Colors.white, size: 20),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1F8EFE),
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        onPressed: () async {
          await NotificationService.showNotification(
            title: 'Threshold System Active',
            body: 'Temp: ${_tempThreshold.toInt()}°C | Hum: ${_humidityThreshold.toInt()}%',
          );
        },
        label: const Text('TEST ALARM SYSTEM', style: TextStyle(letterSpacing: 1.1, fontWeight: FontWeight.bold)),
      ),
    );
  }
}