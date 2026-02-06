import 'dart:async';
import 'dart:io';
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
  String _statusMessage = "System Standby";
  String? _selectedPort;
  List<String> _availablePorts = [];

  String _currentVersion = "v1.2.0";
  final String _latestVersion = "v1.5.8 (Available)";

  final Map<String, String> _deviceConfig = {
    "Device ID": "IOT-SNSR-G2-9910",
    "MAC Address": "48:3F:DA:56:22:90",
    "Uptime": "14 days, 2 hours",
    "Signal Strength": "-67 dBm",
    "Power Source": "Battery (88%)",
  };

  @override
  void initState() {
    super.initState();
    _initSequence();
  }

  Future<void> _initSequence() async {
    await _service.initAssets();
    await _scanPorts();
  }

  // --- CLEAN LOGIC HANDLERS ---

  Future<void> _scanPorts() async {
    setState(() {
      _isBusy = true;
      _statusMessage = "Scanning for hardware...";
    });

    try {
      List<String> found = [];

      // Registry scan only works on Windows
      if (Platform.isWindows) {
        final result = await Process.run('reg', ['query', 'HKEY_LOCAL_MACHINE\\HARDWARE\\DEVICEMAP\\SERIALCOMM']);
        if (result.exitCode == 0) {
          final RegExp regExp = RegExp(r'COM\d+');
          final matches = regExp.allMatches(result.stdout.toString());
          for (var match in matches) {
            if (!found.contains(match.group(0))) found.add(match.group(0)!);
          }
        }
      } else {
        // Android/Other fallback
        _statusMessage = "Platform not supported for scan";
      }

      setState(() {
        _availablePorts = found;
        _selectedPort = found.isNotEmpty ? found.first : null;
        _statusMessage = found.isNotEmpty ? "Hardware Connected" : "No Device Detected";
        _isBusy = false;
      });
    } catch (e) {
      setState(() {
        _statusMessage = "Scan Error";
        _isBusy = false;
      });
    }
  }

  Future<void> _handleFlash() async {
    if (_selectedPort == null) return;
    if (Platform.isAndroid) {
      _showAndroidWarning();
      return;
    }

    setState(() { _isBusy = true; _progress = 0; _statusMessage = "Preparing Flash..."; });

    await _service.writeFlash(
      port: _selectedPort!,
      onStatus: (msg) {
        if (msg.contains("Writing at")) {
          setState(() => _statusMessage = "Flashing Firmware...");
        } else if (msg.contains("Hash of data verified")) {
          setState(() => _statusMessage = "Verifying Integrity...");
        }
      },
      onProgress: (p) => setState(() => _progress = p),
    );

    setState(() {
      _isBusy = false;
      if (_progress >= 0.9) {
        _currentVersion = "v1.5.8";
        _statusMessage = "Update Successful";
      } else {
        _statusMessage = "Flash Failed";
      }
    });
  }

  Future<void> _handleErase() async {
    if (_selectedPort == null) return;
    if (Platform.isAndroid) {
      _showAndroidWarning();
      return;
    }

    setState(() { _isBusy = true; _progress = 0; _statusMessage = "Wiping Device..."; });

    await _service.eraseFlash(
      port: _selectedPort!,
      onStatus: (msg) {
        if (msg.contains("successfully")) {
          setState(() => _statusMessage = "Memory Cleared");
        }
      },
      onProgress: (p) => setState(() => _progress = p),
    );
    setState(() {
      _isBusy = false;
      _progress = 1.0;
    });
  }

  void _showAndroidWarning() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Firmware flashing is only supported on Windows Desktop.")),
    );
  }

  // --- ADAPTIVE UI BUILDER ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // If width is small (Mobile), use a scrollable column
          if (constraints.maxWidth < 900) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildMainPanel(isMobile: true),
                  const SizedBox(height: 16),
                  _buildSidePanel(isMobile: true),
                ],
              ),
            );
          }

          // Desktop: Centered fixed-size dashboard
          return Center(
            child: Container(
              height: 650,
              width: 1000,
              margin: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 30, spreadRadius: 10)],
              ),
              child: Row(
                children: [
                  Expanded(flex: 3, child: _buildMainPanel(isMobile: false)),
                  Expanded(flex: 2, child: _buildSidePanel(isMobile: false)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMainPanel({required bool isMobile}) {
    return Padding(
      padding: EdgeInsets.all(isMobile ? 20 : 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(isMobile),
          if (!isMobile) const Spacer(),
          const SizedBox(height: 32),
          _buildStatusIndicator(),
          const SizedBox(height: 40),
          _buildFlashActionCard(),
          if (!isMobile) const Spacer(),
        ],
      ),
    );
  }

  Widget _buildSidePanel({required bool isMobile}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: isMobile
            ? BorderRadius.circular(24)
            : const BorderRadius.only(topRight: Radius.circular(24), bottomRight: Radius.circular(24)),
        border: isMobile ? null : Border(left: BorderSide(color: Colors.grey.shade200)),
      ),
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildConfigList(),
          const SizedBox(height: 24),
          _buildPortCard(),
          if (!isMobile) const Spacer(),
          const SizedBox(height: 32),
          _buildSideButtons(),
        ],
      ),
    );
  }

  // --- REUSABLE SUB-WIDGETS ---

  Widget _buildHeader(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: Colors.indigo.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
          child: Text("Device Info & Update", style: TextStyle(color: Colors.indigo.shade700, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1.2)),
        ),
        const SizedBox(height: 16),
        Text("Industrial Sensor G2", style: TextStyle(fontSize: isMobile ? 24 : 32, fontWeight: FontWeight.w900, color: const Color(0xFF1E293B))),
        Text("Installed: $_currentVersion  •  Stable: $_latestVersion", style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
      ],
    );
  }

  Widget _buildStatusIndicator() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: _isBusy ? Colors.orange : Colors.green)),
            const SizedBox(width: 8),
            Text(_statusMessage.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5, fontSize: 12, color: Color(0xFF64748B))),
          ],
        ),
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: _progress,
            minHeight: 12,
            backgroundColor: const Color(0xFFE2E8F0),
            color: Colors.indigoAccent,
          ),
        ),
        const SizedBox(height: 8),
        Align(alignment: Alignment.centerRight, child: Text("${(_progress * 100).toInt()}%", style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.indigo))),
      ],
    );
  }

  Widget _buildFlashActionCard() {
    return InkWell(
      onTap: (_isBusy || _selectedPort == null) ? null : _handleFlash,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [Colors.indigo.shade700, Colors.indigo.shade500]),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.indigo.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bolt, color: Colors.white),
            SizedBox(width: 12),
            Text("Update device firmware", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("HARDWARE PROFILE", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 16),
        ...['Device ID', 'MAC Address', 'Signal Strength'].map((key) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(key, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
              Text(_deviceConfig[key]!, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF334155), fontSize: 13)),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildPortCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
      child: Row(
        children: [
          const Icon(Icons.lan_outlined, size: 20, color: Colors.indigo),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButton<String>(
              value: _selectedPort,
              isExpanded: true,
              underline: const SizedBox(),
              hint: const Text("Select Port"),
              style: const TextStyle(fontSize: 14, color: Colors.black, fontWeight: FontWeight.bold),
              items: _availablePorts.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
              onChanged: _isBusy ? null : (val) => setState(() => _selectedPort = val),
            ),
          ),
          IconButton(icon: const Icon(Icons.refresh, size: 18), onPressed: _isBusy ? null : _scanPorts),
        ],
      ),
    );
  }

  Widget _buildSideButtons() {
    return Column(
      children: [
        _sideButton("READ CONFIGURATION", Icons.settings_input_component, () => _service.readDeviceMode(_selectedPort ?? "")),
        const SizedBox(height: 12),
        _sideButton("FACTORY ERASE", Icons.delete_sweep_outlined, _handleErase, isDestructive: true),
      ],
    );
  }

  Widget _sideButton(String label, IconData icon, VoidCallback? action, {bool isDestructive = false}) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: (_isBusy || _selectedPort == null) ? null : action,
        icon: Icon(icon, size: 18),
        label: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        style: OutlinedButton.styleFrom(
          foregroundColor: isDestructive ? Colors.red.shade700 : Colors.blueGrey.shade700,
          side: BorderSide(color: isDestructive ? Colors.red.shade100 : Colors.grey.shade300),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}