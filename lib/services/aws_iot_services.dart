// aws_iot_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:get/get.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/widgets.dart';

import 'notification_service.dart'; // ✅ for WidgetsBindingObserver

class AwsIotService extends GetxService with WidgetsBindingObserver {
  final String awsEndpoint = 'a1uik643utyg4s-ats.iot.ap-south-1.amazonaws.com';
  final String thingName = 'esp8266_mqtt';

  final String dataTopicWildcard = 'esp8266/+/data';
  final String statusTopicWildcard = 'esp8266/+/status';

  var isConnected = false.obs;
  var connectedDeviceCount = 0.obs;

  var devices = <String, Map<String, String>>{}.obs;
  var deviceStatus = <String, String>{}.obs;

  late MqttServerClient client;

  final Function(String topic, Map<String, dynamic> payload)? onMessage;
  final Function(String status)? onConnectionStatus;

  AwsIotService({this.onMessage, this.onConnectionStatus});

  // ------------------------------------------------------------
  // 🌍 Initialize lifecycle observer
  // ------------------------------------------------------------
  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
  }

  // ------------------------------------------------------------
  // 🚀 Connect to AWS IoT
  // ------------------------------------------------------------
  Future<void> connect() async {
    final clientId = '${thingName}_${DateTime.now().millisecondsSinceEpoch}';
    client = MqttServerClient(awsEndpoint, clientId)
      ..setProtocolV311()
      ..port = 8883
      ..secure = true
      ..keepAlivePeriod = 60
      ..logging(on: true);

    client.onConnected = () {
      print('✅ Connected to AWS IoT as $clientId');
      isConnected.value = true;
      onConnectionStatus?.call('Connected ✅');
      _subscribeToTopics();
    };

    client.onDisconnected = () {
      print('❌ Disconnected from AWS IoT');
      isConnected.value = false;
      onConnectionStatus?.call('Disconnected ❌');
    };

    client.onSubscribed = (topic) => print('📡 Subscribed: $topic');
    client.pongCallback = () => print('🏓 Ping response from AWS IoT');

    // --- Load Certificates ---
    if (!kIsWeb) {
      try {
        print('🔑 Loading certificates...');
        final context = SecurityContext.defaultContext;
        context.setTrustedCertificatesBytes(
            (await rootBundle.load('assets/AmazonRootCA1.pem'))
                .buffer
                .asUint8List());
        context.useCertificateChainBytes(
            (await rootBundle.load('assets/flutter-certificate.pem.crt'))
                .buffer
                .asUint8List());
        context.usePrivateKeyBytes(
            (await rootBundle.load('assets/flutter-private.pem.key'))
                .buffer
                .asUint8List());
        client.securityContext = context;
        print('✅ Certificates loaded');
      } catch (e) {
        print('❌ Certificate load failed: $e');
        onConnectionStatus?.call('Certificate load failed ❌');
        return;
      }
    } else {
      print('🌐 Web build detected → Skipping SecurityContext (TLS handled by browser)');
    }

    // --- Establish Connection ---
    try {
      if (kIsWeb) {
        print('⚠️ MQTT direct TLS connection not supported in Web build.');
        onConnectionStatus?.call('Web build: MQTT not available ⚠️');
        return;
      }

      print('🚀 Connecting to AWS IoT...');
      await client.connect();

      if (client.connectionStatus?.state == MqttConnectionState.connected) {
        print('✅ Connection established with AWS IoT');
        onConnectionStatus?.call('Connected to AWS IoT ✅');
      } else {
        print('❌ Connection rejected: ${client.connectionStatus}');
        onConnectionStatus?.call('Connection failed ❌');
      }
    } catch (e) {
      print('❌ Connection error: $e');
      onConnectionStatus?.call('Connection error ❌');
      client.disconnect();
      return;
    }

    client.updates!.listen((List<MqttReceivedMessage<MqttMessage?>>? messages) {
      final recMess = messages![0].payload as MqttPublishMessage;
      final topic = messages[0].topic;
      final payload =
      MqttPublishPayload.bytesToStringAsString(recMess.payload.message);

      print('📩 [$topic] → $payload');

      if (topic.contains('/status')) {
        _handleDeviceStatus(topic, payload);
      } else if (topic.contains('/data')) {
        _handleSensorData(topic, payload);
      }

      try {
        final parsed = jsonDecode(payload);
        onMessage?.call(topic, parsed);
      } catch (_) {}
    });
  }

  void _subscribeToTopics() {
    client.subscribe(dataTopicWildcard, MqttQos.atMostOnce);
    client.subscribe(statusTopicWildcard, MqttQos.atMostOnce);
    print('📡 Subscribed to $dataTopicWildcard and $statusTopicWildcard');
  }

  void _handleSensorData(String topic, String payload) {
    try {
      final data = jsonDecode(payload);
      final deviceId = data['device'] ?? 'unknown';
      final temp = data['temperature']?.toString() ?? '--';
      final hum = data['humidity']?.toString() ?? '--';

      devices[deviceId] = {
        'temperature': temp,
        'humidity': hum,
      };

      print('🌡️ $deviceId → Temp: $temp °C | Hum: $hum %');
    } catch (e) {
      print('⚠️ JSON parse error (data): $e');
    }
  }

  Future<void> _handleDeviceStatus(String topic, String payload) async {
    try {
      final data = jsonDecode(payload);
      final deviceId = data['device'] ?? 'unknown';
      final status = data['status']?.toString() ?? 'unknown';

      deviceStatus[deviceId] = status;

      if (status == 'connected') {
        connectedDeviceCount.value++;
        await NotificationService.showNotification(
          title: 'Device Connected',
          body: '✅ $deviceId just connected to AWS IoT.',
        );
      } else if (status == 'disconnected') {
        connectedDeviceCount.value =
            (connectedDeviceCount.value - 1).clamp(0, 9999);
        devices.remove(deviceId);
        await NotificationService.showNotification(
          title: 'Device Disconnected',
          body: '⚠️ $deviceId just went offline.',
        );
      }


      print(
          '📟 Device $deviceId is now $status | Total connected: ${connectedDeviceCount.value}');
    } catch (e) {
      print('⚠️ JSON parse error (status): $e');
    }
  }

  void disconnect() {
    try {
      client.disconnect();
      isConnected.value = false;
      print('🔌 MQTT client disconnected');
    } catch (e) {
      print('⚠️ Disconnect error: $e');
    }
  }

  void disposeService() {
    try {
      print('🧹 Disposing AWS IoT Service...');
      client.disconnect();
      isConnected.value = false;
      connectedDeviceCount.value = 0;
      devices.clear();
      deviceStatus.clear();
      onConnectionStatus?.call('Disconnected ❌ (logged out)');
    } catch (e) {
      print('⚠️ Dispose error: $e');
    } finally {
      if (Get.isRegistered<AwsIotService>()) {
        Get.delete<AwsIotService>();
      }
    }
  }

  // ------------------------------------------------------------
  // 🩺 Lifecycle: Handle background/foreground transitions
  // ------------------------------------------------------------
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      print('📴 App in background → disconnecting MQTT...');
      disconnect();
    } else if (state == AppLifecycleState.resumed) {
      print('🔁 App resumed → checking MQTT connection...');
      await Future.delayed(const Duration(seconds: 1));
      await reconnectIfNeeded();
    }
  }

  // ------------------------------------------------------------
  // ♻️ Attempt reconnection if disconnected
  // ------------------------------------------------------------
  Future<void> reconnectIfNeeded() async {
    try {
      if (!isConnected.value ||
          client.connectionStatus?.state == MqttConnectionState.disconnected ||
          client.connectionStatus?.state == MqttConnectionState.faulted) {
        print('🔌 Attempting AWS IoT reconnect...');
        await connect();
      } else {
        print('✅ AWS IoT still connected, no need to reconnect');
      }
    } catch (e) {
      print('⚠️ Reconnect error: $e');
    }
  }

  // ------------------------------------------------------------
  // 🧹 Cleanup
  // ------------------------------------------------------------
  @override
  void onClose() {
    print('🧹 AwsIotService onClose() called');
    WidgetsBinding.instance.removeObserver(this);
    try {
      client.disconnect();
    } catch (_) {}
    super.onClose();
  }
}
