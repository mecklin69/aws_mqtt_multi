// aws_iot_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:Elevate/services/endpoints.dart';
import 'package:get/get.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode, debugPrint;
import 'package:flutter/widgets.dart';

import 'notification_service.dart'; // ✅ for WidgetsBindingObserver

class AwsIotService extends GetxService with WidgetsBindingObserver {


  final String awsEndpoint = 'a1uik643utyg4s-ats.iot.ap-south-1.amazonaws.com';
  final String thingName = 'esp8266_mqtt';
  var topicName = 'default/topic'.obs;
  late final String dataTopicWildcard = '$topicName/+/data';
  late final String statusTopicWildcard = '$topicName/+/status';
// ADD THESE:
  var isLogging = false.obs;
  var logBuffer = <Map<String, dynamic>>[].obs;
  var isConnected = false.obs;
  var connectedDeviceCount = 0.obs;
  var devices = <String, Map<String, dynamic>>{}.obs;
  var deviceStatus = <String, String>{}.obs;

  late MqttServerClient client;

  final Function(String topic, Map<String, dynamic> payload)? onMessage;
  final Function(String status)? onConnectionStatus;

  AwsIotService({this.onMessage, this.onConnectionStatus});

  // ---------- Helpers ----------
  void dprint(Object? msg) {
    if (kDebugMode) {
      // use debugPrint to avoid long-line truncation issues with print
      debugPrint(msg?.toString());
    }
  }

  // ------------------------------------------------------------
  // 🌍 Initialize lifecycle observer
  // ------------------------------------------------------------
  @override
  void onInit() {
    super.onInit();
    ever(topicName, (_) => _reconnectWithNewTopic());
    WidgetsBinding.instance.addObserver(this);
  }
  Future<void> _reconnectWithNewTopic() async {
    debugPrint('Topic changed to ${topicName.value}, reconnecting...');
    if (isConnected.value) {
      // Unsubscribe from old topics if necessary, then disconnect
      client.disconnect();
    }

    devices.clear();
    deviceStatus.clear();
    // Re-run the connection flow
    await connect();
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
      dprint('✅ Connected to AWS IoT as $clientId');
      isConnected.value = true;
      onConnectionStatus?.call('Connected ✅');
      _subscribeToTopics();
    };

    client.onDisconnected = () {
      dprint('❌ Disconnected from AWS IoT');
      isConnected.value = false;
      onConnectionStatus?.call('Disconnected ❌');
    };

    client.onSubscribed = (topic) => dprint('📡 Subscribed: $topic');
    client.pongCallback = () => dprint('🏓 Ping response from AWS IoT');

    // --- Load Certificates ---
    if (!kIsWeb) {
      try {
        dprint('🔑 Loading certificates...');
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
        dprint('✅ Certificates loaded');
      } catch (e) {
        dprint('❌ Certificate load failed: $e');
        onConnectionStatus?.call('Certificate load failed ❌');
        return;
      }
    } else {
      dprint(
          '🌐 Web build detected → Skipping SecurityContext (TLS handled by browser)');
    }

    // --- Establish Connection ---
    try {
      if (kIsWeb) {
        dprint('⚠️ MQTT direct TLS connection not supported in Web build.');
        onConnectionStatus?.call('Web build: MQTT not available ⚠️');
        return;
      }

      dprint('🚀 Connecting to AWS IoT...');
      await client.connect();

      if (client.connectionStatus?.state == MqttConnectionState.connected) {
        dprint('✅ Connection established with AWS IoT');
        onConnectionStatus?.call('Connected to AWS IoT ✅');
      } else {
        dprint('❌ Connection rejected: ${client.connectionStatus}');
        onConnectionStatus?.call('Connection failed ❌');
      }
    } catch (e) {
      dprint('❌ Connection error: $e');
      onConnectionStatus?.call('Connection error ❌');
      client.disconnect();
      return;
    }

    client.updates!.listen((List<MqttReceivedMessage<MqttMessage?>>? messages) {
      final recMess = messages![0].payload as MqttPublishMessage;
      final topic = messages[0].topic;
      final payload =
      MqttPublishPayload.bytesToStringAsString(recMess.payload.message);

      dprint('📩 [$topic] → $payload');

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

  // Ensure _subscribeToTopics() uses the latest topicName.value
  void _subscribeToTopics() {
    final dataTopic = '${topicName.value}/+/data';
    final statusTopic = '${topicName.value}/+/status';
    client.subscribe(dataTopic, MqttQos.atMostOnce);
    client.subscribe(statusTopic, MqttQos.atMostOnce);
  }

  // Inside AwsIotService
  void _handleSensorData(String topic, String payload) {
    try {
      final data = jsonDecode(payload);
      final deviceId = data['device'] ?? 'unknown';
      final parsedData = {
        'device': deviceId,
        'temperature': data['temperature']?.toString() ?? '--',
        'humidity': data['humidity']?.toString() ?? '--',
        'turbidity': data['turbidity']?.toString() ?? '--',
        'timestamp': DateTime.now().toString(), // Add timestamp here
      };

      devices[deviceId] = parsedData; // Updates the dashboard view

      // ONLY add to logBuffer if the service-level flag is true
      if (isLogging.value) {
        logBuffer.add(parsedData);
        dprint('📝 Logged data for $deviceId');
      }
    } catch (e) {
      dprint('⚠️ Error: $e');
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

      dprint(
          '📟 Device $deviceId is now $status | Total connected: ${connectedDeviceCount.value}');
    } catch (e) {
      dprint('⚠️ JSON parse error (status): $e');
    }
  }

  void disconnect() {
    try {
      client.disconnect();
      isConnected.value = false;
      dprint('🔌 MQTT client disconnected');
    } catch (e) {
      dprint('⚠️ Disconnect error: $e');
    }
  }

  void disposeService() {
    try {
      dprint('🧹 Disposing AWS IoT Service...');
      client.disconnect();
      isConnected.value = false;
      connectedDeviceCount.value = 0;
      devices.clear();
      deviceStatus.clear();
      onConnectionStatus?.call('Disconnected ❌ (logged out)');
    } catch (e) {
      dprint('⚠️ Dispose error: $e');
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
   if (state == AppLifecycleState.resumed) {
      dprint('🔁 App resumed → checking MQTT connection...');
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
        dprint('🔌 Attempting AWS IoT reconnect...');
        await connect();
      } else {
        dprint('✅ AWS IoT still connected, no need to reconnect');
      }
    } catch (e) {
      dprint('⚠️ Reconnect error: $e');
    }
  }

  // ------------------------------------------------------------
  // 🧹 Cleanup
  // ------------------------------------------------------------
  @override
  void onClose() {
    dprint('🧹 AwsIotService onClose() called');
    WidgetsBinding.instance.removeObserver(this);
    try {
      client.disconnect();
    } catch (_) {}
    super.onClose();
  }
}
