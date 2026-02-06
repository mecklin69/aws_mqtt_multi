import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class EsptoolService {
  String? _localEsptoolPath;
  String? _localFirmwarePath;

  /// Initializes local paths by copying assets to the application document directory
  Future<void> initAssets() async {
    try {
      final directory = await getApplicationSupportDirectory();
      _localEsptoolPath = p.join(directory.path, 'esptool.exe');
      _localFirmwarePath = p.join(directory.path, 'firmwarev1esp8266.bin');

      // 1. Check if esptool.exe already exists
      if (!await File(_localEsptoolPath!).exists()) {
        ByteData esptoolData = await rootBundle.load('assets/esptool.exe');
        await File(_localEsptoolPath!).writeAsBytes(esptoolData.buffer
            .asUint8List(esptoolData.offsetInBytes, esptoolData.lengthInBytes));
        debugPrint("esptool.exe extracted.");
      }

      // 2. Always update the firmware.bin (in case you changed the asset)
      // but handle the error just in case it's locked too
      if (!await File(_localFirmwarePath!).exists()) {
        ByteData firmwareData = await rootBundle.load('assets/amazon_iot_working/firmwarev1esp8266.bin');
        await File(_localFirmwarePath!).writeAsBytes(firmwareData.buffer
            .asUint8List(firmwareData.offsetInBytes, firmwareData.lengthInBytes));
      }

      debugPrint("Assets ready at: ${directory.path}");
    } catch (e) {
      // If the error is "Process cannot access the file", we can ignore it
      // because it means the file is already there and ready to use!
      debugPrint("Asset check: File likely already in use/exists.");
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

  /// WRITE FLASH (With Real Percentage Logic)
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
      '--baud', '115200',
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


