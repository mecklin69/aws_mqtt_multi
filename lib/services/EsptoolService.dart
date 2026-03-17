import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:flutter_libserialport/flutter_libserialport.dart';
class EsptoolService {
  bool _isPortBusy = false;
  String? _localEsptoolPath;
  String? _localFirmwarePath;

  /// Initializes local paths by copying assets to the application document directory
  Future<void> initAssets() async {
    try {
      final directory = await getApplicationSupportDirectory();
      _localEsptoolPath = p.join(directory.path, 'esptool.exe');
      _localFirmwarePath = p.join(directory.path, 'firmware.ino.bin');

      // 1. Keep the check for esptool.exe (It never changes)
      if (!await File(_localEsptoolPath!).exists()) {
        ByteData esptoolData = await rootBundle.load('assets/esptool.exe');
        await File(_localEsptoolPath!).writeAsBytes(esptoolData.buffer
            .asUint8List(esptoolData.offsetInBytes, esptoolData.lengthInBytes));
        debugPrint("esptool.exe extracted.");
      }

      // 2. REMOVE THE IF CHECK: Always overwrite the firmware
      // This ensures your latest binary is always used
      ByteData firmwareData = await rootBundle.load('assets/firmware.ino.bin');
      await File(_localFirmwarePath!).writeAsBytes(firmwareData.buffer
          .asUint8List(firmwareData.offsetInBytes, firmwareData.lengthInBytes));

      debugPrint("Firmware updated in local storage.");
      debugPrint("Assets ready at: ${directory.path}");
    } catch (e) {
      debugPrint("Asset error: $e");
    }
  }

  /// ERASE FLASH
  Future<void> eraseFlash({
    required String port,
    required Function(String) onStatus,
    required Function(double) onProgress,
  }) async {
    if (_localEsptoolPath == null) await initAssets();

    onStatus("Initializing Erase...");
    final process = await Process.start(_localEsptoolPath!, ['--port', port, 'erase_flash']);

    process.stdout.transform(utf8.decoder).listen((data) {
      if (data.contains("successfully")) onProgress(1.0);
      onStatus(data.trim());
    });

    await process.exitCode;
  }

  // Add this to your EsptoolService class
  void forceCloseAllPorts() {
    final ports = SerialPort.availablePorts;
    for (final portName in ports) {
      final port = SerialPort(portName);
      if (port.isOpen) {
        debugPrint("Force closing dangling port: $portName");
        port.close();
        port.dispose();
      }
    }
  }
// Inside your EsptoolService class:
  Future<String?> readSerialCommand(String portName, String command) async {
    // 1. Prevent concurrent access
    if (_isPortBusy) {
      debugPrint("Read attempt blocked: Port is busy.");
      return "Error: Port in use";
    }

    _isPortBusy = true;

    // 2. Declare variables outside the try-catch block for accessibility
    SerialPort? port;
    SerialPortReader? reader;
    String response = "";

    try {
      port = SerialPort(portName);

      // ADD THIS BLOCK: Force specific config before opening
      final config = SerialPortConfig();
      config.baudRate = 115200;
      config.bits = 8;
      config.parity = SerialPortParity.none;
      config.stopBits = 1;
      config.setFlowControl(SerialPortFlowControl.none);
      port.config = config;

      debugPrint("Attempting to open: ${port.name}");
      if (!port.openReadWrite()) {
        final err = SerialPort.lastError;
        throw Exception("OS Error $err: ${err?.message}");
      }
      // Initialize reader
      reader = SerialPortReader(port);

      // Send the command
      port.write(Uint8List.fromList('$command\n'.codeUnits));

      // 3. Read the response with a safety timeout
      // (Crucial: prevents the app from hanging if the device doesn't respond)
      await for (final data in reader.stream.timeout(
        const Duration(seconds: 2),
        onTimeout: (sink) => sink.close(),
      )) {
        response = String.fromCharCodes(data).trim();
        if (response.isNotEmpty) break;
      }

      return response.isEmpty ? "No response" : response;

    } catch (e) {
      debugPrint("Serial Error: $e");
      return "Error: $e";
    } finally {
      if (reader != null) reader.close();
      if (port != null) {
        port.close();
        port.dispose();
      }
      // Force the OS to catch up
      await Future.delayed(const Duration(milliseconds: 300));
      _isPortBusy = false;
    }
  }
  /// WRITE FLASH (With Real Percentage Logic)

  //
  //     reader.close();
  //     port.close();
  Future<void> writeFlash({
    required String port,
    required Function(String) onStatus,
    required Function(double) onProgress,
  }) async {
    if (_localEsptoolPath == null) await initAssets();

    onStatus("Connecting to ESP8266...");

    // Command based on your working CLI:
    // esptool.exe --chip esp8266 --port COM4 --baud 115200 write_flash -fm dio 0x00000 firmware.bin
    final process = await Process.start(_localEsptoolPath!, [
      '--chip', 'esp8266',
      '--port', port,
      '--baud', '9600',
      'write_flash', '-fm', 'dio', '0x00000', _localFirmwarePath!
    ]);

    process.stdout.transform(utf8.decoder).listen((data) {
      // REGEX: Looks for digits before a % sign (e.g. " 45%")
      final RegExp regExp = RegExp(r'(\d+)\s*%');
      final matches = regExp.allMatches(data);

      if (matches.isNotEmpty) {
        final String? percentageStr = matches.last.group(1);
        if (percentageStr != null) {
          double val = double.parse(percentageStr) / 100.0;
          onProgress(val); // Moves the UI Progress Bar
        }
      }
      onStatus(data);
    });

    await process.exitCode;
  }

  /// READ MODE (Windows mode command)
  Future<String> readMode(String port) async {
    final result = await Process.run('mode', [port]);
    return result.stdout.toString();
  }
  Future<String> readDeviceMode(String port) async {
    final result = await Process.run('mode', [port]);
    return result.stdout.toString();
  }
}


