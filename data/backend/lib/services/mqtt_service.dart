import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:dotenv/dotenv.dart';

class MqttService {
  static MqttServerClient? _client;
  static bool _isConnected = false;

  static Future<void> initialize() async {
    try {
      // Load environment variables fresh each time
      final env = DotEnv(includePlatformEnvironment: true);
      env.load();
      
      // Use HiveMQ configuration from .env
      final broker = env['HIVEMQ_BROKER'] ?? env['MQTT_BROKER'] ?? 'broker.hivemq.com';
      final port = int.parse(env['HIVEMQ_PORT'] ?? env['MQTT_PORT'] ?? '1883');
      final username = env['HIVEMQ_USERNAME'] ?? env['MQTT_USERNAME'];
      final password = env['HIVEMQ_PASSWORD'] ?? env['MQTT_PASSWORD'];
      final useSSL = port == 8883; // HiveMQ Cloud uses SSL on port 8883
      
      print('🔍 Debug - Username from env: $username');
      print('🔍 Debug - Password from env: $password');

      // If using HiveMQ Cloud but no credentials, fallback to public broker
      if (broker.contains('hivemq.cloud') && 
          (username == null || username.isEmpty || username == 'your-mqtt-username')) {
        print('⚠️ HiveMQ Cloud requires authentication, falling back to public broker');
        return await _connectToPublicBroker();
      }

      print('📡 Connecting to MQTT broker: $broker:$port');
      
      _client = MqttServerClient.withPort(broker, 'brightify_dart_backend', port);
      _client!.logging(on: false);
      _client!.keepAlivePeriod = 20;
      _client!.onDisconnected = _onDisconnected;
      _client!.onConnected = _onConnected;
      _client!.onSubscribed = _onSubscribed;

      // SSL Configuration
      if (useSSL) {
        _client!.secure = true;
        _client!.securityContext = SecurityContext.defaultContext;
      }

      // Connection message
      final connMessage = MqttConnectMessage()
          .withClientIdentifier('brightify_dart_backend_${DateTime.now().millisecondsSinceEpoch}')
          .withWillTopic('brightify/backend/status')
          .withWillMessage('offline')
          .startClean()
          .withWillQos(MqttQos.atLeastOnce);

      // Authenticate with HiveMQ Cloud credentials
      if (username != null && password != null && 
          username.isNotEmpty && password.isNotEmpty) {
        print('🔐 Using HiveMQ authentication with username: $username');
        connMessage.authenticateAs(username, password);
      } else {
        print('⚠️ No MQTT authentication provided');
      }

      _client!.connectionMessage = connMessage;

      await _client!.connect();
      
      if (_client!.connectionStatus!.state == MqttConnectionState.connected) {
        _isConnected = true;
        print('✅ MQTT Connected to HiveMQ Cloud successfully');
        
        // Publish backend online status
        await publishMessage('brightify/backend/status', 'online');
      } else {
        print('❌ MQTT Connection failed: ${_client!.connectionStatus}');
        print('⚠️ Falling back to public broker...');
        await _connectToPublicBroker();
      }
    } catch (e) {
      print('❌ MQTT initialization error: $e');
      print('⚠️ Attempting fallback to public broker...');
      try {
        await _connectToPublicBroker();
      } catch (fallbackError) {
        print('❌ Public broker also failed: $fallbackError');
        print('⚠️ Backend will continue without MQTT');
      }
    }
  }

  static void _onConnected() {
    print('✅ MQTT Client connected');
    _isConnected = true;
  }

  static void _onDisconnected() {
    print('⚠️ MQTT Client disconnected');
    _isConnected = false;
  }

  static void _onSubscribed(String topic) {
    print('📡 Subscribed to topic: $topic');
  }

  static bool get isConnected => _isConnected;

  static Future<bool> publishMessage(String topic, String message) async {
    if (!_isConnected || _client == null) {
      print('❌ MQTT not connected, cannot publish to $topic');
      return false;
    }

    try {
      final builder = MqttClientPayloadBuilder();
      builder.addString(message);
      
      _client!.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
      print('📤 Published to $topic: $message');
      return true;
    } catch (e) {
      print('❌ Failed to publish to $topic: $e');
      return false;
    }
  }

  static Future<bool> publishDeviceControl(String chipId, Map<String, dynamic> command) async {
    final topic = 'brightify/devices/$chipId/control';
    final message = jsonEncode(command);
    return await publishMessage(topic, message);
  }

  static Future<bool> publishPower(String chipId, bool power) async {
    final topic = 'brightify/devices/$chipId/power';
    final message = jsonEncode({'power': power});
    return await publishMessage(topic, message);
  }

  static Future<bool> publishBrightness(String chipId, int brightness) async {
    final topic = 'brightify/devices/$chipId/brightness';
    final message = jsonEncode({'brightness': brightness});
    return await publishMessage(topic, message);
  }

  static Future<bool> publishColor(String chipId, int red, int green, int blue) async {
    final topic = 'brightify/devices/$chipId/color';
    final message = jsonEncode({
      'red': red,
      'green': green,
      'blue': blue,
    });
    return await publishMessage(topic, message);
  }

  static Future<bool> publishPreset(String chipId, int preset) async {
    final topic = 'brightify/devices/$chipId/preset';
    final message = jsonEncode({'preset': preset});
    return await publishMessage(topic, message);
  }

  static Future<bool> publishSpeed(String chipId, int speed) async {
    final topic = 'brightify/devices/$chipId/speed';
    final message = jsonEncode({'speed': speed});
    return await publishMessage(topic, message);
  }

  static Future<void> _connectToPublicBroker() async {
    try {
      print('📡 Connecting to public MQTT broker: broker.hivemq.com:1883');
      
      _client = MqttServerClient.withPort('broker.hivemq.com', 'brightify_dart_backend', 1883);
      _client!.logging(on: false);
      _client!.keepAlivePeriod = 20;
      _client!.onDisconnected = _onDisconnected;
      _client!.onConnected = _onConnected;
      _client!.onSubscribed = _onSubscribed;

      // No SSL for public broker
      _client!.secure = false;

      // Connection message without authentication
      final connMessage = MqttConnectMessage()
          .withClientIdentifier('brightify_dart_backend_${DateTime.now().millisecondsSinceEpoch}')
          .withWillTopic('brightify/backend/status')
          .withWillMessage('offline')
          .startClean()
          .withWillQos(MqttQos.atLeastOnce);

      _client!.connectionMessage = connMessage;

      await _client!.connect();
      
      if (_client!.connectionStatus!.state == MqttConnectionState.connected) {
        _isConnected = true;
        print('✅ MQTT Connected to public broker successfully');
        
        // Publish backend online status
        await publishMessage('brightify/backend/status', 'online');
      } else {
        print('❌ MQTT Connection to public broker failed: ${_client!.connectionStatus}');
      }
    } catch (e) {
      print('❌ Public MQTT broker connection error: $e');
    }
  }

  static Future<void> disconnect() async {
    if (_client != null) {
      await publishMessage('brightify/backend/status', 'offline');
      _client!.disconnect();
      _isConnected = false;
      print('📡 MQTT Disconnected');
    }
  }
}
