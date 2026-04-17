
import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:flutter_libserialport/flutter_libserialport.dart';

class EsptoolService {
  String? _localEsptoolPath;
  String? _localFirmwarePath;

  SerialPort? _port;
  String? _openPortName;
  StreamSubscription<Uint8List>? _subscription;
  final List<int> _rxBuffer = [];
  bool _isPortBusy = false;

  // ─── Assets ──────────────────────────────────────────────────────────────

  Future<void> initAssets() async {
    try {
      final directory = await getApplicationSupportDirectory();
      _localEsptoolPath = p.join(directory.path, 'esptool.exe');
      _localFirmwarePath = p.join(directory.path, 'firmware.ino.bin');

      if (!await File(_localEsptoolPath!).exists()) {
        ByteData esptoolData = await rootBundle.load('assets/esptool.exe');
        await File(_localEsptoolPath!).writeAsBytes(esptoolData.buffer
            .asUint8List(esptoolData.offsetInBytes, esptoolData.lengthInBytes));
      }

      ByteData firmwareData = await rootBundle.load('assets/firmware.ino.bin');
      await File(_localFirmwarePath!).writeAsBytes(firmwareData.buffer
          .asUint8List(firmwareData.offsetInBytes, firmwareData.lengthInBytes));
    } catch (e) {
      debugPrint("Asset error: $e");
    }
  }

  // ─── Port Management ─────────────────────────────────────────────────────

  Future<bool> _ensurePortOpen(String portName) async {
    if (_port != null && _openPortName == portName && _port!.isOpen) {
      debugPrint("[PORT] Already open: $portName");
      return true;
    }

    _closePort();

    try {
      debugPrint("[PORT] Opening $portName...");
      final port = SerialPort(portName);

      final config = SerialPortConfig()
        ..baudRate = 115200
        ..bits = 8
        ..stopBits = 1
        ..parity = SerialPortParity.none
        ..setFlowControl(SerialPortFlowControl.none);

      port.config = config;

      if (!port.openReadWrite()) {
        debugPrint("[PORT] OPEN FAILED: ${SerialPort.lastError}");
        return false;
      }

      _port = port;
      _openPortName = portName;
      _rxBuffer.clear();

      _subscription = SerialPortReader(port).stream.listen(
            (Uint8List bytes) {
          final hex = bytes.map((b) => '0x${b.toRadixString(16).padLeft(2, '0')}').join(' ');
          final ascii = String.fromCharCodes(bytes.map((b) => (b >= 32 && b < 127) ? b : 46));
          debugPrint("[RX RAW] ${bytes.length} bytes | HEX: $hex | ASCII: '$ascii'");
          _rxBuffer.addAll(bytes);
        },
        onError: (e) => debugPrint("[RX ERROR] $e"),
        onDone: () => debugPrint("[RX] Stream closed"),
      );

      debugPrint("[PORT] Waiting 2s for ESP8266 boot...");
      await Future.delayed(const Duration(milliseconds: 2000));
      debugPrint("[PORT] Ready.");
      return true;

    } catch (e) {
      debugPrint("[PORT] Exception: $e");
      return false;
    }
  }
// ─── Public Port Control (called from UI) ────────────────────────────────

  Future<bool> openPort(String portName) async {
    return await _ensurePortOpen(portName);
  }

  void closePort(String portName) {
    if (_openPortName == portName) {
      _closePort();
    }
  }

  bool isPortOpen(String portName) {
    return _port != null && _openPortName == portName && (_port?.isOpen ?? false);
  }

  void _closePort() {
    _subscription?.cancel();
    _subscription = null;
    if (_port != null) {
      if (_port!.isOpen) _port!.close();
      _port!.dispose();
      _port = null;
    }
    _openPortName = null;
    _rxBuffer.clear();
    debugPrint("[PORT] Closed.");
  }

  void forceCloseAllPorts() {
    _closePort();
    _isPortBusy = false;
  }

  // ─── Core Command ─────────────────────────────────────────────────────────

  Future<String?> readSerialCommand(String portName, String command) async {
    if (_isPortBusy) {
      debugPrint("[CMD] SKIPPED (busy): $command");
      return "Error: Port Busy";
    }
    _isPortBusy = true;

    try {
      if (!await _ensurePortOpen(portName)) {
        return "Error: Cannot open port $portName";
      }
      // Flush stale bytes
      if (_rxBuffer.isNotEmpty) {
        debugPrint("[CMD] Flushing ${_rxBuffer.length} stale bytes.");
        _rxBuffer.clear();
      }

      // ── TX ────────────────────────────────────────────────────────────────
      final cmdBytes = Uint8List.fromList('$command\n'.codeUnits);
    final written = _port!.write(cmdBytes);
    debugPrint("[TX] '$command\\n' → $written / ${cmdBytes.length} bytes written");

    if (written != cmdBytes.length) {
    debugPrint("[TX] WARNING: partial write ($written of ${cmdBytes.length})");
    }

    // ── WAIT FOR LINE ─────────────────────────────────────────────────────
    debugPrint("[CMD] Waiting for response to '$command'...");
    final String? response = await _waitForLine(
    timeout: const Duration(seconds: 5),
    );

    if (response == null) {
    debugPrint(
    "[CMD] TIMEOUT for '$command'. Buffer: ${_rxBuffer.length} bytes.");
    if (_rxBuffer.isNotEmpty) {
    final hex = _rxBuffer
        .map((b) => '0x${b.toRadixString(16).padLeft(2, '0')}')
        .join(' ');
    debugPrint("[CMD] Buffer at timeout HEX: $hex");
    debugPrint(
    "[CMD] Buffer ASCII: '${String.fromCharCodes(_rxBuffer.map((b) => (b >= 32 && b < 127) ? b : 46))}'");
    } else {
    debugPrint("[CMD] Buffer EMPTY → ESP sent NOTHING back.");
    }
    }

    debugPrint("[CMD] '$command' → response: '$response'");
    return response;
    } catch (e) {
    debugPrint("[CMD] Exception: $e");
    _closePort();
    return "Error: $e";
    } finally {
    await Future.delayed(const Duration(milliseconds: 200));
    _isPortBusy = false;
    }
  }

  Future<String?> _waitForLine({required Duration timeout}) async {
    final deadline = DateTime.now().add(timeout);

    while (DateTime.now().isBefore(deadline)) {
      final newlineIdx = _rxBuffer.indexOf(0x0A); // '\n'

      if (newlineIdx != -1) {
        final lineBytes = _rxBuffer.sublist(0, newlineIdx);
        _rxBuffer.removeRange(0, newlineIdx + 1);
        final line =
        String.fromCharCodes(lineBytes).replaceAll('\r', '').trim();
        debugPrint("[LINE] Extracted: '$line'");
        if (line.isNotEmpty) return line;
        // Empty line (bare \r\n) — keep waiting for the real response
      }

      await Future.delayed(const Duration(milliseconds: 20));
    }

    return null; // Timed out
  }

  // ─── Flash / Erase ───────────────────────────────────────────────────────

  Future<void> eraseFlash({
    required String port,
    required Function(String) onStatus,
    required Function(double) onProgress,
  }) async {
    forceCloseAllPorts();
    if (_localEsptoolPath == null) await initAssets();
    final process =
    await Process.start(_localEsptoolPath!, ['--port', port, 'erase_flash']);
    process.stdout.transform(utf8.decoder).listen((data) {
      if (data.contains("successfully")) onProgress(1.0);
      onStatus(data.trim());
    });
    await process.exitCode;
  }

  Future<void> writeFlash({
    required String port,
    required Function(String) onStatus,
    required Function(double) onProgress,
  }) async {
    forceCloseAllPorts();
    if (_localEsptoolPath == null) await initAssets();
    final process = await Process.start(_localEsptoolPath!, [
      '--chip', 'esp8266', '--port', port, '--baud', '115200',
      'write_flash', '-fm', 'dio', '0x00000', _localFirmwarePath!
    ]);
    process.stdout.transform(utf8.decoder).listen((data) {
      final RegExp regExp = RegExp(r'(\d+)\s*%');
      final matches = regExp.allMatches(data);
      if (matches.isNotEmpty) {
        final String? percentageStr = matches.last.group(1);
        if (percentageStr != null) {
          onProgress(double.parse(percentageStr) / 100.0);
        }
      }
      onStatus(data);
    });
    await process.exitCode;
  }
}
