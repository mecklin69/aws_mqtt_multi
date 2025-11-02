// // aws_iot_service.dart
// import 'dart:convert';
// import 'dart:io';
// import 'package:get/get.dart';
// import 'package:mqtt_client/mqtt_client.dart';
// import 'package:mqtt_client/mqtt_server_client.dart';
// import 'package:flutter/services.dart' show rootBundle;
//
// class AwsIotService extends GetxService {
//   final String awsEndpoint = 'a1uik643utyg4s-ats.iot.ap-south-1.amazonaws.com';
//   final String thingName = 'esp8266_mqtt';
//   final String dataTopic = 'esp8266/data';
//   final String statusTopic = 'esp8266/status';
//
//   /// --- Reactive State ---
//   var isConnected = false.obs;
//   var temperature = '--'.obs;
//   var humidity = '--'.obs;
//   var connectedDeviceCount = 0.obs;
//
//   late MqttServerClient client;
//
//   final Function(String temp, String hum)? onDataReceived;
//   final Function(String status)? onStatusChange;
//
//   AwsIotService({this.onDataReceived, this.onStatusChange});
//
//   Future<void> connect() async {
//     final clientId =
//         '${thingName}_flutter_${DateTime.now().millisecondsSinceEpoch}';
//     client = MqttServerClient(awsEndpoint, clientId)
//       ..setProtocolV311()
//       ..port = 8883
//       ..secure = true
//       ..keepAlivePeriod = 60
//       ..logging(on: true);
//
//     // --- MQTT Events ---
//     client.onConnected = () {
//       print('✅ Connected to AWS IoT as $clientId');
//       isConnected.value = true;
//       onStatusChange?.call('Connected to AWS IoT ✅');
//       _subscribeTopics();
//     };
//
//     client.onDisconnected = () {
//       print('❌ Disconnected from AWS IoT');
//       isConnected.value = false;
//       onStatusChange?.call('Disconnected ❌');
//     };
//
//     client.onSubscribed = (t) => print('✅ Subscription confirmed: $t');
//     client.pongCallback = () => print('🏓 Ping response received');
//
//     // --- Load Certificates ---
//     try {
//       print('🔑 Loading certificates...');
//       final context = SecurityContext.defaultContext;
//       context.setTrustedCertificatesBytes(
//           (await rootBundle.load('assets/AmazonRootCA1.pem'))
//               .buffer
//               .asUint8List());
//       context.useCertificateChainBytes(
//           (await rootBundle.load('assets/flutter-certificate.pem.crt'))
//               .buffer
//               .asUint8List());
//       context.usePrivateKeyBytes(
//           (await rootBundle.load('assets/flutter-private.pem.key'))
//               .buffer
//               .asUint8List());
//       client.securityContext = context;
//       print('✅ Certificates loaded');
//     } catch (e) {
//       print('❌ Failed to load certs: $e');
//       onStatusChange?.call('Certificate load failed ❌');
//       return;
//     }
//
//     // --- Connect to AWS IoT ---
//     try {
//       print('🚀 Connecting to AWS IoT...');
//       await client.connect();
//
//       if (client.connectionStatus?.state == MqttConnectionState.connected) {
//         print('✅ Connection accepted by AWS IoT');
//         onStatusChange?.call('Connected to AWS IoT ✅');
//       } else {
//         print('❌ Connection failed: ${client.connectionStatus}');
//         onStatusChange?.call('Connection failed ❌');
//       }
//     } on Exception catch (e) {
//       print('❌ Connection error: $e');
//       onStatusChange?.call('Connection error ❌');
//       client.disconnect();
//       return;
//     }
//
//     // --- Listen to MQTT messages ---
//     client.updates!.listen((List<MqttReceivedMessage<MqttMessage?>>? messages) {
//       final recMess = messages![0].payload as MqttPublishMessage;
//       final topic = messages[0].topic;
//       final payload =
//       MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
//
//       print('📩 Message on $topic: $payload');
//
//       if (topic == statusTopic) {
//         _handleDeviceStatus(payload);
//       } else if (topic == dataTopic) {
//         _handleSensorData(payload);
//       }
//     });
//   }
//
//   void _subscribeTopics() {
//     client.subscribe('esp8266/+/data', MqttQos.atMostOnce);
//     client.subscribe('esp8266/+/status', MqttQos.atMostOnce);
//     print('📡 Subscribed to $dataTopic and $statusTopic');
//   }
//
//   void _handleSensorData(String payload) {
//     try {
//       final data = jsonDecode(payload);
//       final temp = data['temperature']?.toString() ?? '--';
//       final hum = data['humidity']?.toString() ?? '--';
//
//       temperature.value = temp;
//       humidity.value = hum;
//       onDataReceived?.call(temp, hum);
//     } catch (e) {
//       print('⚠️ JSON parse error (data): $e');
//     }
//   }
//
//   void _handleDeviceStatus(String payload) {
//     try {
//       final data = jsonDecode(payload);
//       final status = data['status']?.toString();
//
//       if (status == 'connected') {
//         connectedDeviceCount.value++;
//       } else if (status == 'disconnected') {
//         connectedDeviceCount.value =
//             (connectedDeviceCount.value - 1).clamp(0, 9999);
//       }
//
//       print(
//           '📟 Device ${data['device']} is now $status | Total connected: ${connectedDeviceCount.value}');
//     } catch (e) {
//       print('⚠️ JSON parse error (status): $e');
//     }
//   }
//
//   void disconnect() {
//     client.disconnect();
//   }
// }



// aws_iot_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:get/get.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:flutter/services.dart' show rootBundle;

class AwsIotService extends GetxService {
  final String awsEndpoint = 'a1uik643utyg4s-ats.iot.ap-south-1.amazonaws.com';
  final String thingName = 'esp8266_mqtt';

  /// --- MQTT Topics (wildcard for all ESPs) ---
  final String dataTopicWildcard = 'esp8266/+/data';
  final String statusTopicWildcard = 'esp8266/+/status';

  /// --- Reactive State ---
  var isConnected = false.obs;
  var connectedDeviceCount = 0.obs;

  /// Store each device's latest data
  /// { "esp8266_1": {"temperature":"29","humidity":"61"}, ... }
  var devices = <String, Map<String, String>>{}.obs;

  /// Store each device’s online/offline status
  /// { "esp8266_1": "connected", "esp8266_2": "disconnected" }
  var deviceStatus = <String, String>{}.obs;

  late MqttServerClient client;

  final Function(String topic, Map<String, dynamic> payload)? onMessage;
  final Function(String status)? onConnectionStatus;

  AwsIotService({this.onMessage, this.onConnectionStatus});

  /// Connect to AWS IoT Core securely
  Future<void> connect() async {
    final clientId = '${thingName}_${DateTime.now().millisecondsSinceEpoch}';
    client = MqttServerClient(awsEndpoint, clientId)
      ..setProtocolV311()
      ..port = 8883
      ..secure = true
      ..keepAlivePeriod = 60
      ..logging(on: true);

    // --- MQTT Event Callbacks ---
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

    // --- Connect to AWS IoT ---
    try {
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

    // --- Handle incoming MQTT messages ---
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

      // Optional external callback
      try {
        final parsed = jsonDecode(payload);
        onMessage?.call(topic, parsed);
      } catch (_) {}
    });
  }

  /// Subscribe to all devices’ data and status topics using wildcard
  void _subscribeToTopics() {
    client.subscribe(dataTopicWildcard, MqttQos.atMostOnce);
    client.subscribe(statusTopicWildcard, MqttQos.atMostOnce);
    print('📡 Subscribed to $dataTopicWildcard and $statusTopicWildcard');
  }

  /// Handle incoming sensor readings from any device
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

  /// Handle status messages (connected/disconnected)
  void _handleDeviceStatus(String topic, String payload) {
    try {
      final data = jsonDecode(payload);
      final deviceId = data['device'] ?? 'unknown';
      final status = data['status']?.toString() ?? 'unknown';

      deviceStatus[deviceId] = status;

      if (status == 'connected') {
        connectedDeviceCount.value++;
      } else if (status == 'disconnected') {
        connectedDeviceCount.value =
            (connectedDeviceCount.value - 1).clamp(0, 9999);
        devices.remove(deviceId);
      }

      print(
          '📟 Device $deviceId is now $status | Total connected: ${connectedDeviceCount.value}');
    } catch (e) {
      print('⚠️ JSON parse error (status): $e');
    }
  }

  /// Disconnect safely
  void disconnect() {
    try {
      client.disconnect();
      isConnected.value = false;
      print('🔌 MQTT client disconnected');
    } catch (e) {
      print('⚠️ Disconnect error: $e');
    }
  }
}
