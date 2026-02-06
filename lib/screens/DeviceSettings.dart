import 'dart:async';
import 'package:flutter/material.dart';

import '../services/EsptoolService.dart';


class FirmwareFlashPage extends StatefulWidget {
  const FirmwareFlashPage({super.key});

  @override
  State<FirmwareFlashPage> createState() => _FirmwareFlashPageState();
}

class _FirmwareFlashPageState extends State<FirmwareFlashPage> {
  final EsptoolService _service = EsptoolService();
  double _progress = 0;
  bool _isBusy = false;
  String _statusMessage = "Device Standby";
  String _port = "COM5";
  String _currentVersion = "v1.2.0";
  String _latestVersion = "v1.5.8 (Available)";

  Map<String, String> _deviceConfig = {
    "Device ID": "IOT-SNSR-G2-9910",
    "MAC Address": "48:3F:DA:56:22:90",
    "Uptime": "14 days, 2 hours",
    "Signal Strength": "-67 dBm",
    "Power Source": "Battery (88%)",
  };

  @override
  void initState() {
    super.initState();
    _service.initAssets(); // Deploy tools on load
  }

  // --- HANDLERS (Calling Real CLI Service) ---

  Future<void> _handleReadConfig() async {
    setState(() => _isBusy = true);
    String config = await _service.readDeviceMode(_port);
    setState(() {
      _statusMessage = "Config Read Complete";
      _isBusy = false;
    });
    _showConfigDialog(config);
  }

  Future<void> _handleFlash() async {
    setState(() {
      _isBusy = true;
      _progress = 0;
    });

    await _service.writeFlash(
      port: _port,
      onStatus: (msg) {
        // Only show the last meaningful line of CLI output
        if (msg.isNotEmpty) {
          setState(() => _statusMessage = msg.split('\n').last);
        }
      },
      onProgress: (p) => setState(() => _progress = p),
    );

    setState(() {
      _isBusy = false;
      if (_progress >= 1.0) _currentVersion = "v1.5.8";
    });
  }

  Future<void> _handleErase() async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Factory Reset?"),
        content: const Text("This will erase all local logs and reset configuration. Action is irreversible."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("CANCEL")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("ERASE ALL", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _isBusy = true;
        _progress = 0;
      });
      await _service.eraseFlash(
        port: _port,
        onStatus: (msg) => setState(() => _statusMessage = msg),
        onProgress: (p) => setState(() => _progress = p),
      );
      setState(() => _isBusy = false);
    }
  }

  // --- UI BUILDERS ---

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Device Maintenance", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          const Text("Hardware diagnostics and real-time CLI flashing."),
          const SizedBox(height: 30),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: Column(children: [_buildVersionCard(), const SizedBox(height: 30), _buildProgressSection()])),
              const SizedBox(width: 30),
              Expanded(flex: 2, child: Column(children: [_buildConfigPanel(), const SizedBox(height: 20), _buildActionButtons()])),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVersionCard() {
    return Card(
      elevation: 0,
      color: Colors.indigo.withOpacity(0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            const Icon(Icons.developer_board, size: 48, color: Colors.indigo),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Industrial Sensor G2", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  Text("Installed: $_currentVersion | Latest: $_latestVersion"),
                ],
              ),
            ),
            IconButton(onPressed: _isBusy ? null : () => _service.initAssets(), icon: const Icon(Icons.refresh)),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressSection() {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Text(_statusMessage, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, fontFamily: 'monospace')),
          const SizedBox(height: 20),
          LinearProgressIndicator(
            value: _progress,
            minHeight: 10,
            borderRadius: BorderRadius.circular(10),
            backgroundColor: Colors.grey.shade100,
            color: _statusMessage.contains("successfully") || _statusMessage.contains("Hash") ? Colors.green : Colors.indigo,
          ),
          const SizedBox(height: 10),
          Text("${(_progress * 100).toInt()}%", style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: _isBusy ? null : _handleFlash,
            icon: const Icon(Icons.flash_on),
            label: const Text("START FIRMWARE UPDATE"),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 50)),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigPanel() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(children: [Icon(Icons.info_outline, size: 20), SizedBox(width: 8), Text("Device Configuration", style: TextStyle(fontWeight: FontWeight.bold))]),
            const Divider(),
            ..._deviceConfig.entries.map((e) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(e.key, style: const TextStyle(color: Colors.grey)), Text(e.value, style: const TextStyle(fontWeight: FontWeight.w500))]),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        OutlinedButton.icon(
          onPressed: _isBusy ? null : _handleReadConfig,
          icon: const Icon(Icons.settings_remote),
          label: const Text("READ CONFIGURATION"),
          style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _isBusy ? null : _handleErase,
          icon: const Icon(Icons.delete_sweep, color: Colors.red),
          label: const Text("ERASE DEVICE", style: TextStyle(color: Colors.red)),
          style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 50), side: const BorderSide(color: Colors.red)),
        ),
      ],
    );
  }

  void _showConfigDialog(String data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("CLI Mode Output"),
        content: SingleChildScrollView(child: Text(data, style: const TextStyle(fontFamily: 'monospace', fontSize: 12))),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("CLOSE"))],
      ),
    );
  }
}

