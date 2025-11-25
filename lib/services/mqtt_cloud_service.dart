import 'dart:convert';
import 'dart:io';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// MQTT Cloud Service - Direct connection ke HiveMQ Cloud
/// Tidak perlu backend discovery, langsung connect ke cloud MQTT broker
class MqttCloudService {
  static MqttServerClient? _client;
  static bool _isConnected = false;
  static bool _isInitialized = false;

  /// Initialize MQTT connection ke HiveMQ Cloud
  static Future<bool> initialize() async {
    if (_isInitialized) {
      print('🔄 MQTT already initialized');
      return _isConnected;
    }

    try {
      print('🚀 Initializing MQTT Cloud Service...');
      
      // Load config dari .env
      final broker = dotenv.env['MQTT_BROKER'] ?? '';
      final port = int.parse(dotenv.env['MQTT_PORT'] ?? '8883');
      final username = dotenv.env['MQTT_USERNAME'] ?? '';
      final password = dotenv.env['MQTT_PASSWORD'] ?? '';

      if (broker.isEmpty || username.isEmpty) {
        print('❌ MQTT configuration missing in .env');
        return false;
      }

      // Create client with unique ID
      final clientId = 'brightify_mobile_${DateTime.now().millisecondsSinceEpoch}';
      _client = MqttServerClient.withPort(broker, clientId, port);

      // Configure client
      _client!.logging(on: false);
      _client!.keepAlivePeriod = 60;
      _client!.secure = true;
      _client!.securityContext = SecurityContext.defaultContext;
      
      // Set callbacks
      _client!.onConnected = _onConnected;
      _client!.onDisconnected = _onDisconnected;
      _client!.onSubscribed = _onSubscribed;

      // Connection message
      final connMessage = MqttConnectMessage()
          .withClientIdentifier(clientId)
          .authenticateAs(username, password)
          .withWillTopic('brightify/mobile/status')
          .withWillMessage('offline')
          .startClean()
          .withWillQos(MqttQos.atLeastOnce);

      _client!.connectionMessage = connMessage;

      // Connect
      print('📡 Connecting to HiveMQ Cloud: $broker:$port');
      await _client!.connect(username, password);

      if (_client!.connectionStatus!.state == MqttConnectionState.connected) {
        print('✅ Connected to MQTT Cloud successfully');
        _isConnected = true;
        _isInitialized = true;
        
        // Publish online status
        _publishStatus('online');
        
        return true;
      } else {
        print('❌ MQTT connection failed: ${_client!.connectionStatus}');
        _client = null;
        return false;
      }
    } catch (e) {
      print('❌ MQTT initialization error: $e');
      _client = null;
      _isInitialized = false;
      return false;
    }
  }

  /// Callbacks
  static void _onConnected() {
    print('✅ MQTT Client connected');
    _isConnected = true;
  }

  static void _onDisconnected() {
    print('⚠️ MQTT Client disconnected');
    _isConnected = false;
  }

  static void _onSubscribed(String topic) {
    print('📥 Subscribed to topic: $topic');
  }

  /// Publish status
  static void _publishStatus(String status) {
    if (_client == null || !_isConnected) return;
    
    final topic = 'brightify/mobile/status';
    final payload = jsonEncode({
      'status': status,
      'timestamp': DateTime.now().toIso8601String(),
    });
    
    final builder = MqttClientPayloadBuilder();
    builder.addString(payload);
    
    _client!.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
  }

  /// Check if connected
  static bool get isConnected => _isConnected && _client != null;

  /// Control device via MQTT
  static Future<bool> controlDevice(String chipId, Map<String, dynamic> command) async {
    if (!isConnected) {
      print('❌ MQTT not connected, attempting to reconnect...');
      await initialize();
      if (!isConnected) return false;
    }

    try {
      final topic = 'brightify/devices/$chipId/control';
      final payload = jsonEncode(command);
      
      print('📤 Publishing to $topic: $payload');
      
      final builder = MqttClientPayloadBuilder();
      builder.addString(payload);
      
      _client!.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
      
      return true;
    } catch (e) {
      print('❌ Error publishing to MQTT: $e');
      return false;
    }
  }

  /// Subscribe to device status
  static void subscribeToDevice(String chipId, Function(Map<String, dynamic>) onMessage) {
    if (!isConnected) {
      print('❌ MQTT not connected');
      return;
    }

    final topic = 'brightify/devices/$chipId/status';
    print('📥 Subscribing to $topic');
    
    _client!.subscribe(topic, MqttQos.atLeastOnce);
    
    _client!.updates!.listen((List<MqttReceivedMessage<MqttMessage>> messages) {
      for (var message in messages) {
        final recMess = message.payload as MqttPublishMessage;
        final payload = MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
        
        try {
          final data = jsonDecode(payload) as Map<String, dynamic>;
          onMessage(data);
        } catch (e) {
          print('❌ Error parsing MQTT message: $e');
        }
      }
    });
  }

  /// Subscribe to multiple devices
  static void subscribeToDevices(List<String> chipIds, Function(String chipId, Map<String, dynamic>) onMessage) {
    for (var chipId in chipIds) {
      subscribeToDevice(chipId, (data) => onMessage(chipId, data));
    }
  }

  /// Disconnect
  static void disconnect() {
    if (_client != null) {
      print('🔌 Disconnecting from MQTT Cloud');
      _publishStatus('offline');
      _client!.disconnect();
      _client = null;
      _isConnected = false;
    }
  }

  /// Reconnect if disconnected
  static Future<bool> reconnect() async {
    disconnect();
    _isInitialized = false;
    return await initialize();
  }
}
