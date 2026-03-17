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

  final EsptoolService _service = EsptoolService();
  final TextEditingController _deviceIdController = TextEditingController();
  final TextEditingController _firmwareController = TextEditingController(); // New
  final TextEditingController _batchController = TextEditingController();
// Add this to your _buildSidePanel list
  late Future<LocationData> locationFuture;

  @override
  bool get wantKeepAlive => true;

  double _progress = 0;
  bool _isBusy = false;

  String _statusMessage = "System Standby";

  String? _selectedPort;
  List<String> _availablePorts = [];

  String _currentVersion = "v1.2.0";
  final String _latestVersion = "v1.5.8 (Available)";

  Map<String, String> _deviceConfig = {
    "Device ID": "Fetching...",
    "Geo-Location": "Fetching...",
    "Batch ID": "Fetching...",
    "Firmware Version": "Fetching...",
  };

  @override
  void initState() {
    super.initState();

    _initSequence();

    /// Load GPS + Location Name
    locationFuture = LocationService.loadLocation();
  }

  Future<void> _initSequence() async {
    await _service.initAssets();
    await _scanPorts();
  }

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
            ['query', 'HKEY_LOCAL_MACHINE\\HARDWARE\\DEVICEMAP\\SERIALCOMM']
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

        _statusMessage =
        found.isNotEmpty
            ? "Hardware Connected"
            : "No Device Detected";

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
      onProgress: (p) {
        setState(() => _progress = p);
      },
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
      onProgress: (p) {
        setState(() => _progress = p);
      },
    );

    setState(() {
      _isBusy = false;
      _progress = 1.0;
    });
  }

  void _showAndroidWarning() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
            "Firmware flashing is only supported on Windows Desktop."),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(

      backgroundColor: const Color(0xFFF0F2F5),

      body: LayoutBuilder(

        builder: (context, constraints) {
          if (constraints.maxWidth < 900) {
            return Column(

              children: [

                _buildMainPanel(isMobile: true),

                const SizedBox(height: 16),

                _buildSidePanel(isMobile: true),

              ],

            );
          }

          return Center(

            child: Row(

              children: [

                Expanded(
                    flex: 3,
                    child: _buildMainPanel(isMobile: false)
                ),

                Expanded(
                    flex: 2,
                    child: _buildSidePanel(isMobile: false)
                ),

              ],

            ),

          );
        },

      ),

    );
  }

  Widget locationCard({required bool isMobile}) {
    return Padding(

      padding: EdgeInsets.all(isMobile ? 20 : 40),

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
                      "Lng: ${pos.longitude.toStringAsFixed(5)}"
              ),

            );
          },

        ),

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

          locationCard(isMobile: isMobile),

        ],

      ),

    );
  }

  Widget _buildSidePanel({required bool isMobile}) {
    return Container(
      // Ensure the container itself has a background color to help with hit testing
      color: Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column( // Main wrapper
        children: [
          Expanded( // This makes the scrollable area take up available space
            child: Scrollbar( // Added a scrollbar for a "cooler" pro look
              thumbVisibility: true,
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
          // Keep buttons at the bottom outside the scroll view so they are always visible
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
        // The "Glass" base: white with very low opacity
        color: Colors.white.withOpacity(0.4),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Column(
          children: _deviceConfig.entries.map((e) {
            // Define distinct glass colors
            Color baseColor;
            if (e.key.contains("ID")) {
              baseColor = const Color(0xFF2196F3); // Blue
            } else if (e.key.contains("Geo")) {
              baseColor = const Color(0xFF00BFA5); // Teal
            } else if (e.key.contains("Batch")) {
              baseColor = const Color(0xFFF57C00); // Orange
            } else {
              baseColor = const Color(0xFF673AB7); // Purple
            }

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.white.withOpacity(0.1)),
                ),
                // Glass glow effect on the left
                gradient: LinearGradient(
                  colors: [
                    baseColor.withOpacity(0.12),
                    baseColor.withOpacity(0.02),
                    Colors.transparent
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // GLASS TAG
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
                        color: baseColor.withOpacity(0.9), // Use opacity instead of shade
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),

                  // DATA VALUE
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

        Text(
          "Installed: $_currentVersion • Stable: $_latestVersion",
        ),

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

            Text(_statusMessage.toUpperCase()),

          ],

        ),

        const SizedBox(height: 16),

        LinearProgressIndicator(value: _progress),

      ],

    );
  }

  // Enhance the Flash Action Card to look more like a "Big Red Button"
  Widget _buildFlashActionCard() {
    bool canFlash = !_isBusy && _selectedPort != null;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: canFlash ? 1.0 : 0.5,
      child: InkWell(
        onTap: canFlash ? _handleFlash : null,
        borderRadius: BorderRadius.circular(16),
        child: Center( // Wrap in Center so it doesn't stretch to full width
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400), // Limits size on large screens
            width: double.infinity, // Takes available space UP TO 400
            margin: const EdgeInsets.symmetric(vertical: 12),
            child: InkWell(
              onTap: (_isBusy || _selectedPort == null) ? null : _handleFlash,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24), // Tighter padding
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade800, Colors.blue.shade900],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
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
                  mainAxisSize: MainAxisSize.min, // Content-hugging
                  children: [
                    const Icon(Icons.bolt_rounded, color: Colors.white, size: 22),
                    const SizedBox(width: 12),
                    Text(
                      "UPDATE FIRMWARE", // Uppercase for industrial feel
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
        )
      ),
    );
  }
  Future<void> _syncDeviceConfig() async {

    if (_selectedPort == null) return;

    setState(() {
      _statusMessage = "Syncing with hardware...";
    });

    final Map<String, String> commands = {
      "Device ID": "GET_DID",
      "Geo-Location": "GET_LOC",
      "Batch ID": "GET_BID",
      "Firmware Version": "GET_FID",
    };

    final Map<String, String> newConfig = {};

    try {

      for (var entry in commands.entries) {

        final result = await _service.readSerialCommand(
          _selectedPort!,
          entry.value,
        );

        newConfig[entry.key] = result ?? "Error";

        await Future.delayed(const Duration(milliseconds: 50));
      }

      setState(() {
        _deviceConfig = newConfig;
        _statusMessage = "Configuration Synced";
      });

    } catch (e) {

      setState(() {
        _statusMessage = "Sync Failed: $e";
      });

    }

  }
  Widget _buildPortCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.blueGrey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blueGrey.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
              // THE REFRESH BUTTON
              IconButton(
                icon: Icon(
                    Icons.refresh,
                    size: 20,
                    color: _isBusy ? Colors.grey : Colors.blue
                ),
                onPressed: _isBusy ? null : _scanPorts,
                tooltip: "Rescan Hardware",
              ),
            ],
          ),
          DropdownButtonHideUnderline(
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
                    fontFamily: 'Courier', // Tech look
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ))
                  .toList(),
              onChanged: (v) {
                setState(() => _selectedPort = v);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManualEntryBox() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blueGrey.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "HARDWARE PROVISIONING",
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey,
                  letterSpacing: 1.1
              ),
            ),
            const SizedBox(height: 16),
        
            // DEVICE ID
            _buildProvisionField(
              label: "DEVICE ID",
              controller: _deviceIdController,
              hint: "MECKLIN4269",
              commandPrefix: "SET_DID",
            ),
        
            const SizedBox(height: 12),
        
            // FIRMWARE NAME
            _buildProvisionField(
              label: "FIRMWARE NAME",
              controller: _firmwareController,
              hint: "G2_CORE_STABLE",
              commandPrefix: "SET_FID",
            ),
        
            const SizedBox(height: 12),
        
            // BATCH ID (Date, Topic, Client)
            _buildProvisionField(
              label: "BATCH ID",
              controller: _batchController,
              hint: "2024-05, THERMAL, SPACEX",
              commandPrefix: "SET_BID",
            ),
        
            const SizedBox(height: 12),
        
            // GEO-LOCATION (Auto-fetch)
            FutureBuilder<LocationData>(
              future: locationFuture,
              builder: (context, snapshot) {
                String locString = snapshot.hasData
                    ? "${snapshot.data!.position.latitude.toStringAsFixed(4)},${snapshot.data!.position.longitude.toStringAsFixed(4)}"
                    : "Fetching GPS...";
        
                return _buildProvisionField(
                  label: "GEO-LOCATION",
                  hint: locString,
                  commandPrefix: "SET_LOC",
                  isReadOnly: true,
                  customValue: locString,
                  icon: Icons.location_on_outlined,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

// A helper to keep the UI consistent and code clean
  Widget _buildProvisionField({
    required String label,
    TextEditingController? controller,
    required String hint,
    required String commandPrefix,
    bool isReadOnly = false,
    String? customValue,
    IconData icon = Icons.code,
  }) {
    return TextField(
      controller: controller,
      readOnly: isReadOnly,
      style: const TextStyle(fontSize: 13, fontFamily: 'Courier'),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 16),
        filled: isReadOnly,
        fillColor: isReadOnly ? Colors.grey.shade50 : null,
        suffixIcon: IconButton(
          icon: const Icon(Icons.send_rounded, size: 18, color: Colors.blue),
          onPressed: () {
            final value = customValue ?? controller?.text ?? "";
            if (value.isNotEmpty && value != "Fetching GPS...") {
              _sendManualCommand("$commandPrefix:$value");
            }
          },
        ),
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        isDense: true,
      ),
    );
  }

// Logic to handle the transfer
  Future<void> _sendManualCommand(String fullCommand) async {
    if (_selectedPort == null) return;

    setState(() => _statusMessage = "Sending: $fullCommand");

    try {
      // Assuming your service has a write method
      await _service.readSerialCommand(_selectedPort!, fullCommand);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Transferred: $fullCommand"), backgroundColor: Colors.green),
      );

      // Refresh the config list to show the new data
      _syncDeviceConfig();
    } catch (e) {
      setState(() => _statusMessage = "Transfer Failed");
    }
  }
  Widget _buildSideButtons() {
    return Column(

      children: [

        _sideButton("READ CONFIGURATION",
            Icons.settings_input_component,
            _syncDeviceConfig),

        const SizedBox(height: 12),

        _sideButton("FACTORY ERASE",
            Icons.delete_sweep_outlined,
            _handleErase,
            isDestructive: true),

      ],

    );
  }

  Widget _sideButton(String label, IconData icon, VoidCallback action,
      {bool isDestructive = false}) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: isDestructive ? Colors.red.shade50 : Colors.white,
          foregroundColor: isDestructive ? Colors.red : Colors.blueGrey.shade800,
          elevation: 0,
          side: BorderSide(
            color: isDestructive ? Colors.red.withOpacity(0.5) : Colors.blueGrey.withOpacity(0.2),
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