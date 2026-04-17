import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';

import '../services/EsptoolService.dart';
import '../services/location.dart';

class FirmwareFlashPage extends StatefulWidget {
  const FirmwareFlashPage({super.key});

  @override
  State<FirmwareFlashPage> createState() => _FirmwareFlashPageState();
}

class _FirmwareFlashPageState extends State<FirmwareFlashPage>
    with AutomaticKeepAliveClientMixin {

  // ─── Service & Port State ─────────────────────────────────────────────────

  final EsptoolService _service = EsptoolService();

  bool get _isPortOpen => _service.isPortOpen(_selectedPort ?? '');

  String? _selectedPort;
  List<String> _availablePorts = [];

  // ─── UI State ─────────────────────────────────────────────────────────────

  double _progress = 0;
  bool _isBusy = false;
  String _statusMessage = "System Standby";

  String _currentVersion = "v1.2.0";
  final String _latestVersion = "v1.5.8 (Available)";

  Map<String, String> _deviceConfig = {
    "Device ID": "Fetching...",
    "Geo-Location": "Fetching...",
    "Batch ID": "Fetching...",
    "Firmware Version": "Fetching...",
    "SSID": "Fetching...",
    "Thing Name": "Fetching...",
    "Base Topic": "Fetching...",
  };

  // ─── Controllers ─────────────────────────────────────────────────────────

  final TextEditingController _deviceIdController = TextEditingController();
  final TextEditingController _firmwareController = TextEditingController();
  final TextEditingController _batchController = TextEditingController();
  final TextEditingController _ssidController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  final TextEditingController _thingController = TextEditingController();
  final TextEditingController _topicController = TextEditingController();

  late Future<LocationData> locationFuture;

  @override
  bool get wantKeepAlive => true;

  // ─── Lifecycle ────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _initSequence();
    locationFuture = LocationService.loadLocation();
  }

  @override
  void dispose() {
    _deviceIdController.dispose();
    _firmwareController.dispose();
    _batchController.dispose();
    _ssidController.dispose();
    _passController.dispose();
    _thingController.dispose();
    _topicController.dispose();
    super.dispose();
  }

  // ─── Initialization ───────────────────────────────────────────────────────

  Future<void> _initSequence() async {
    await _service.initAssets();
    await _scanPorts();
  }

  // ─── Port Scanning ────────────────────────────────────────────────────────

  Future<void> _scanPorts() async {
    _service.forceCloseAllPorts();

    setState(() {
      _isBusy = true;
      _statusMessage = "Scanning for hardware...";
    });

    try {
      List<String> found = [];

      if (Platform.isWindows) {
        final result = await Process.run(
          'reg',
          ['query', 'HKEY_LOCAL_MACHINE\\HARDWARE\\DEVICEMAP\\SERIALCOMM'],
        );

        if (result.exitCode == 0) {
          final RegExp regExp = RegExp(r'COM\d+');
          final matches = regExp.allMatches(result.stdout.toString());
          for (var match in matches) {
            if (!found.contains(match.group(0))) {
              found.add(match.group(0)!);
            }
          }
        }
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

  // ─── Port Open / Close ────────────────────────────────────────────────────

  Future<void> _openPort() async {
    if (_selectedPort == null || _isBusy) return;
    setState(() => _statusMessage = "Opening Port...");
    final success = await _service.openPort(_selectedPort!);
    setState(() {
      _statusMessage = success
          ? "Port $_selectedPort Opened"
          : "Failed to Open Port";
    });
  }

  Future<void> _closePort() async {
    if (_selectedPort == null) return;
    _service.closePort(_selectedPort!);
    setState(() => _statusMessage = "Port Closed");
  }

  // ─── Flash / Erase ────────────────────────────────────────────────────────

  Future<void> _handleFlash() async {
    if (_selectedPort == null) return;

    if (Platform.isAndroid) {
      _showAndroidWarning();
      return;
    }

    setState(() {
      _isBusy = true;
      _progress = 0;
      _statusMessage = "Preparing Flash...";
    });

    await _service.writeFlash(
      port: _selectedPort!,
      onStatus: (msg) {
        if (msg.contains("Writing at")) {
          setState(() => _statusMessage = "Flashing Firmware...");
        }
        if (msg.contains("Hash of data verified")) {
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

    setState(() {
      _isBusy = true;
      _progress = 0;
      _statusMessage = "Wiping Device...";
    });

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

  // ─── Config Sync ──────────────────────────────────────────────────────────

  Future<void> _syncDeviceConfig() async {
    if (_selectedPort == null || _isBusy) return;

    setState(() {
      _isBusy = true;
      _statusMessage = "Syncing Atria® Configuration...";
    });

    final Map<String, String> commands = {
      "Device ID": "GET_DID",
      "Geo-Location": "GET_LOC",
      "Batch ID": "GET_BID",
      "Firmware Version": "GET_FID",
      "SSID": "GET_SSID",
      "Thing Name": "GET_THING",
      "Base Topic": "GET_TOPIC",
    };

    final Map<String, String> fetchedConfig = {};

    try {
      for (var entry in commands.entries) {
        final result = await _service.readSerialCommand(
          _selectedPort!,
          entry.value,
        );

        fetchedConfig[entry.key] =
        (result == null || result.isEmpty || result.startsWith("Error"))
            ? "N/A"
            : result;

        debugPrint("Synced ${entry.key}: $result");
      }

      setState(() {
        _deviceConfig = fetchedConfig;
        _statusMessage = "Configuration Synced";
      });
    } catch (e) {
      debugPrint("Sync Error: $e");
      setState(() => _statusMessage = "Sync Failed: Device Unreachable");
    } finally {
      setState(() => _isBusy = false);
    }
  }

  // ─── Provisioning ─────────────────────────────────────────────────────────

  Future<void> _handleBatchProvisioning() async {
    if (_selectedPort == null || _isBusy) return;

    setState(() {
      _isBusy = true;
      _progress = 0.0;
      _statusMessage = "Initializing Secure Provisioning...";
    });

    final Map<String, String> data = {
      "SSID": "SET_SSID:${_ssidController.text}",
      "Password": "SET_PASS:${_passController.text}",
      "Thing Name": "SET_THING:${_thingController.text}",
      "Topic": "SET_TOPIC:${_topicController.text}",
      "Device ID": "SET_DID:${_deviceIdController.text}",
      "Firmware ID": "SET_FID:${_firmwareController.text}",
      "Batch ID": "SET_BID:${_batchController.text}",
    };

    int completed = 0;
    final int totalCommands =
        data.values.where((v) => v.split(':')[1].isNotEmpty).length;

    try {
      for (var entry in data.entries) {
        final String command = entry.value;
        final String value = command.split(':')[1];

        if (value.isEmpty) continue;

        setState(() => _statusMessage = "Writing ${entry.key}...");

        final result = await _service.readSerialCommand(
          _selectedPort!,
          command,
        );

        if (result == "OK") {
          completed++;
          setState(() => _progress = completed / totalCommands);
          debugPrint("Confirmed: ${entry.key} provisioned.");
        } else {
          throw Exception("Failed to set ${entry.key}: $result");
        }
      }

      setState(() {
        _statusMessage = "Provisioning Complete";
        _progress = 1.0;
      });

      await Future.delayed(const Duration(milliseconds: 500));
      await _syncDeviceConfig();
    } catch (e) {
      debugPrint("Provisioning Error: $e");
      setState(() => _statusMessage = e.toString().toUpperCase());
    } finally {
      setState(() => _isBusy = false);
    }
  }

  Future<void> _sendManualCommand(String fullCommand) async {
    if (_selectedPort == null) return;

    setState(() => _statusMessage = "Sending: $fullCommand");

    try {
      await _service.readSerialCommand(_selectedPort!, fullCommand);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Transferred: $fullCommand"),
            backgroundColor: Colors.green,
          ),
        );
      }

      _syncDeviceConfig();
    } catch (e) {
      setState(() => _statusMessage = "Transfer Failed");
    }
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  void _showAndroidWarning() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Firmware flashing is only supported on Windows Desktop."),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 900) {
            return SingleChildScrollView(
              child: Column(
                children: [
                  _buildMainPanel(isMobile: true),
                  const SizedBox(height: 16),
                  _buildSidePanel(isMobile: true),
                ],
              ),
            );
          }

          return Row(
            children: [
              Expanded(flex: 3, child: _buildMainPanel(isMobile: false)),
              Expanded(flex: 2, child: _buildSidePanel(isMobile: false)),
            ],
          );
        },
      ),
    );
  }

  // ─── Main Panel ───────────────────────────────────────────────────────────

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
          _locationCard(isMobile: isMobile),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          "Industrial Sensor G2",
          style: TextStyle(
            fontSize: isMobile ? 24 : 32,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text("Installed: $_currentVersion • Stable: $_latestVersion"),
      ],
    );
  }

  Widget _buildStatusIndicator() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isBusy ? Colors.orange : Colors.green,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _statusMessage.toUpperCase(),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        LinearProgressIndicator(value: _progress),
      ],
    );
  }

  Widget _buildFlashActionCard() {
    final bool canFlash = !_isBusy && _selectedPort != null;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: canFlash ? 1.0 : 0.5,
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          width: double.infinity,
          margin: const EdgeInsets.symmetric(vertical: 12),
          child: InkWell(
            onTap: canFlash ? _handleFlash : null,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade800, Colors.blue.shade900],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.4),
                    blurRadius: 15,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.bolt_rounded, color: Colors.white, size: 22),
                  const SizedBox(width: 12),
                  Text(
                    "UPDATE FIRMWARE",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.95),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _locationCard({required bool isMobile}) {
    return Padding(
      padding: EdgeInsets.only(top: isMobile ? 20 : 40),
      child: Card(
        child: FutureBuilder<LocationData>(
          future: locationFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const ListTile(
                leading: CircularProgressIndicator(),
                title: Text("Determining Location..."),
                subtitle: Text("Searching GPS satellites"),
              );
            }

            if (snapshot.hasError) {
              return ListTile(
                leading: const Icon(Icons.error, color: Colors.red),
                title: const Text("Location Error"),
                subtitle: Text(snapshot.error.toString()),
              );
            }

            final data = snapshot.data!;
            final pos = data.position;

            return ListTile(
              leading: const Icon(Icons.place, color: Colors.blue),
              title: Text(
                data.locationName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                "Lat: ${pos.latitude.toStringAsFixed(5)} | "
                    "Lng: ${pos.longitude.toStringAsFixed(5)}",
              ),
            );
          },
        ),
      ),
    );
  }

  // ─── Side Panel ───────────────────────────────────────────────────────────

  Widget _buildSidePanel({required bool isMobile}) {
    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildConfigList(),
                  const SizedBox(height: 16),
                  _buildPortCard(),
                  const SizedBox(height: 16),
                  _buildManualEntryBox(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          const Divider(),
          _buildSideButtons(),
        ],
      ),
    );
  }

  Widget _buildConfigList() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.4),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Column(
          children: _deviceConfig.entries.map((e) {
            Color baseColor;
            if (e.key.contains("ID")) {
              baseColor = const Color(0xFF2196F3);
            } else if (e.key.contains("SSID") || e.key.contains("Topic")) {
              baseColor = const Color(0xFFE91E63);
            } else if (e.key.contains("Thing")) {
              baseColor = const Color(0xFF9C27B0);
            } else if (e.key.contains("Geo")) {
              baseColor = const Color(0xFF00BFA5);
            } else {
              baseColor = const Color(0xFFF57C00);
            }

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.white.withOpacity(0.1)),
                ),
                gradient: LinearGradient(
                  colors: [
                    baseColor.withOpacity(0.12),
                    baseColor.withOpacity(0.02),
                    Colors.transparent,
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: baseColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: baseColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      e.key.toUpperCase(),
                      style: TextStyle(
                        color: baseColor.withOpacity(0.9),
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  Flexible(
                    child: Text(
                      e.value,
                      textAlign: TextAlign.end,
                      style: TextStyle(
                        fontFamily: 'Courier',
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2C3E50).withOpacity(0.85),
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildPortCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.blueGrey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blueGrey.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row ────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "COMMUNICATION PORT",
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: Colors.blueGrey,
                ),
              ),
              // Port status pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _isPortOpen
                      ? Colors.green.withOpacity(0.12)
                      : Colors.red.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _isPortOpen
                        ? Colors.green.withOpacity(0.4)
                        : Colors.red.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isPortOpen ? Colors.green : Colors.red,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _isPortOpen ? "OPEN" : "CLOSED",
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.1,
                        color: _isPortOpen
                            ? Colors.green.shade700
                            : Colors.red.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // ── Dropdown + Rescan ──────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _selectedPort,
                    hint: const Text("Select Port..."),
                    icon: const Icon(Icons.arrow_drop_down_circle_outlined),
                    items: _availablePorts
                        .map((p) => DropdownMenuItem(
                      value: p,
                      child: Text(
                        p,
                        style: const TextStyle(
                          fontFamily: 'Courier',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ))
                        .toList(),
                    onChanged: _isPortOpen
                        ? null
                        : (v) => setState(() => _selectedPort = v),
                  ),
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.refresh,
                  size: 20,
                  color: (_isBusy || _isPortOpen) ? Colors.grey : Colors.blue,
                ),
                onPressed: (_isBusy || _isPortOpen) ? null : _scanPorts,
                tooltip: "Rescan Hardware",
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // ── Action Buttons Row ─────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _portActionButton(
                  label: "SELECT",
                  icon: Icons.usb_rounded,
                  tooltip: "Confirm selected port",
                  color: Colors.blueGrey,
                  onPressed: (_selectedPort == null || _isBusy || _isPortOpen)
                      ? null
                      : () {
                    setState(() =>
                    _statusMessage = "Port $_selectedPort Selected");
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Port $_selectedPort selected"),
                        duration: const Duration(seconds: 1),
                        backgroundColor: Colors.blueGrey.shade700,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _portActionButton(
                  label: "OPEN",
                  icon: Icons.lock_open_rounded,
                  tooltip: "Open serial connection",
                  color: Colors.green,
                  onPressed: (_selectedPort == null || _isBusy || _isPortOpen)
                      ? null
                      : _openPort,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _portActionButton(
                  label: "CLOSE",
                  icon: Icons.lock_rounded,
                  tooltip: "Close serial connection",
                  color: Colors.red,
                  isDestructive: true,
                  onPressed: (!_isPortOpen || _isBusy) ? null : _closePort,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _portActionButton({
    required String label,
    required IconData icon,
    required String tooltip,
    required Color color,
    required VoidCallback? onPressed,
    bool isDestructive = false,
  }) {
    final bool enabled = onPressed != null;
    return Tooltip(
      message: tooltip,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: enabled ? 1.0 : 0.4,
        child: ElevatedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, size: 14),
          label: Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: enabled
                ? color.withOpacity(isDestructive ? 0.08 : 0.10)
                : Colors.grey.withOpacity(0.06),
            foregroundColor: enabled ? color : Colors.grey,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
            side: BorderSide(
              color: enabled
                  ? color.withOpacity(0.35)
                  : Colors.grey.withOpacity(0.2),
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ),
    );
  }

  Widget _buildManualEntryBox() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blueGrey.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "NETWORK & AWS CONFIGURATION",
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 16),
          _buildProvisionField(
            label: "WIFI SSID",
            controller: _ssidController,
            hint: "Home_WiFi",
            icon: Icons.wifi,
          ),
          const SizedBox(height: 12),
          _buildProvisionField(
            label: "WIFI PASSWORD",
            controller: _passController,
            hint: "********",
            icon: Icons.lock_outline,
          ),
          const SizedBox(height: 12),
          _buildProvisionField(
            label: "AWS THING NAME",
            controller: _thingController,
            hint: "esp8266_mqtt",
            icon: Icons.cloud_queue,
          ),
          const SizedBox(height: 12),
          _buildProvisionField(
            label: "MQTT BASE TOPIC",
            controller: _topicController,
            hint: "mecklin/sensors",
            icon: Icons.topic,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Divider(),
          ),
          const Text(
            "HARDWARE PROVISIONING",
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 16),
          _buildProvisionField(
            label: "DEVICE ID",
            controller: _deviceIdController,
            hint: "MECKLIN4269",
          ),
          const SizedBox(height: 12),
          _buildProvisionField(
            label: "FIRMWARE NAME",
            controller: _firmwareController,
            hint: "G2_CORE_STABLE",
          ),
          const SizedBox(height: 12),
          _buildProvisionField(
            label: "BATCH ID",
            controller: _batchController,
            hint: "2024-05, THERMAL",
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 45,
            child: ElevatedButton.icon(
              onPressed:
              (_isBusy || _selectedPort == null) ? null : _handleBatchProvisioning,
              icon: const Icon(Icons.send_and_archive_rounded, size: 18),
              label: const Text("PROVISION HARDWARE"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProvisionField({
    required String label,
    required TextEditingController controller,
    required String hint,
    IconData icon = Icons.code,
  }) {
    return TextField(
      controller: controller,
      style: const TextStyle(fontSize: 13, fontFamily: 'Courier'),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 16),
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        isDense: true,
      ),
    );
  }

  Widget _buildSideButtons() {
    return Column(
      children: [
        _sideButton(
          "READ CONFIGURATION",
          Icons.settings_input_component,
          _syncDeviceConfig,
        ),
        const SizedBox(height: 12),
        _sideButton(
          "FACTORY ERASE",
          Icons.delete_sweep_outlined,
          _handleErase,
          isDestructive: true,
        ),
      ],
    );
  }

  Widget _sideButton(
      String label,
      IconData icon,
      VoidCallback action, {
        bool isDestructive = false,
      }) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: isDestructive ? Colors.red.shade50 : Colors.white,
          foregroundColor:
          isDestructive ? Colors.red : Colors.blueGrey.shade800,
          elevation: 0,
          side: BorderSide(
            color: isDestructive
                ? Colors.red.withOpacity(0.5)
                : Colors.blueGrey.withOpacity(0.2),
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: (_isBusy || _selectedPort == null) ? null : action,
        icon: Icon(icon, size: 18),
        label: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        ),
      ),
    );
  }
}
