/// ✅ CLOUD-FIRST API SERVICE
/// 
/// Architecture baru:
/// - Device Control: MQTT Cloud (HiveMQ) - Real-time
/// - Data Storage: Firebase Firestore - Cloud database
/// - Authentication: Firebase Auth
/// 
/// API Service sekarang optional, hanya untuk features tertentu
/// yang memerlukan backend processing.

import 'package:firebase_auth/firebase_auth.dart';
import 'backend_discovery.dart';
import 'mqtt_cloud_service.dart';

class ApiService {
  static bool _isCloudMode = true;
  static bool _isInitialized = false;

  /// ✅ Initialize API service for cloud-first architecture
  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    print('☁️ Initializing Cloud-First API Service...');
    
    // Check cloud services
    await BackendDiscovery.initializeCloudServices();
    
    _isCloudMode = BackendDiscovery.isCloudMode;
    _isInitialized = true;
    
    print('✅ API Service initialized (Cloud Mode: $_isCloudMode)');
  }

  /// ✅ Check if cloud services are available
  static bool get isApiAvailable => _isCloudMode;
  
  /// ✅ Check if using cloud mode
  static bool get isCloudMode => _isCloudMode;

  /// ✅ Refresh cloud connection
  static Future<bool> refreshConnection() async {
    print('🔄 Refreshing cloud connection...');
    await BackendDiscovery.initializeCloudServices();
    return BackendDiscovery.isCloudMode;
  }

  /// ✅ NEW: Control device via MQTT Cloud (Direct)
  /// No backend server needed, direct to HiveMQ Cloud
  static Future<Map<String, dynamic>> controlDevice({
    required String deviceId,
    String? homeId,
    String? roomId,
    bool? power,
    int? brightness,
    int? red,
    int? green,
    int? blue,
    int? preset,
    int? speed,
  }) async {
    try {
      // Ensure cloud services are initialized
      if (!_isInitialized) {
        await initialize();
      }
      
      // Check authentication
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }
      
      // Prepare MQTT command
      final Map<String, dynamic> command = {};
      if (power != null) command['power'] = power;
      if (brightness != null) command['brightness'] = brightness;
      if (red != null) command['red'] = red;
      if (green != null) command['green'] = green;
      if (blue != null) command['blue'] = blue;
      if (preset != null) command['preset'] = preset;
      if (speed != null) command['speed'] = speed;
      
      print('🎮 Sending MQTT command to device $deviceId: $command');
      
      // Send via MQTT Cloud Service (Direct to HiveMQ)
      final success = await MqttCloudService.controlDevice(deviceId, command);
      
      if (success) {
        print('✅ MQTT command sent successfully');
        return {
          'success': true,
          'message': 'Device control command sent via MQTT Cloud',
          'data': command,
        };
      } else {
        print('❌ MQTT command failed');
        return {
          'success': false,
          'message': 'Failed to send MQTT command',
        };
      }
    } catch (e) {
      print('❌ Error sending MQTT command: $e');
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Failed to send MQTT command to cloud',
      };
    }
  }
  
  /// ⚠️ DEPRECATED: Use FirebaseService directly instead
  /// Cloud-first: Data management via Firestore, not backend API
  @Deprecated('Use FirebaseService.addHome() instead')
  static Future<Map<String, dynamic>> addHome({
    required String name,
    required String address,
    String? country,
  }) async {
    print('⚠️ addHome() via API is deprecated - Use FirebaseService.addHome() instead');
    return {
      'success': false,
      'error': 'Use FirebaseService.addHome() for cloud-first architecture',
    };
  }
  
  /// ⚠️ DEPRECATED: Use FirebaseService directly instead
  /// Cloud-first: Data management via Firestore, not backend API
  @Deprecated('Use FirebaseService.addRoom() instead')
  static Future<Map<String, dynamic>> addRoom({
    required String homeId,
    required String roomName,
    required String roomType,
  }) async {
    print('⚠️ addRoom() via API is deprecated - Use FirebaseService.addRoom() instead');
    return {
      'success': false,
      'error': 'Use FirebaseService.addRoom() for cloud-first architecture',
    };
  }

  /// ⚠️ DEPRECATED: Use FirebaseService directly instead
  /// Cloud-first: Data management via Firestore, not backend API
  @Deprecated('Use FirebaseService.addDevice() instead')
  static Future<Map<String, dynamic>> addDevice({
    required String homeId,
    required String roomId,
    required String deviceName,
    required String chipId,
    String? pairingCode,
  }) async {
    print('⚠️ addDevice() via API is deprecated - Use FirebaseService.addDevice() instead');
    return {
      'success': false,
      'error': 'Use FirebaseService.addDevice() for cloud-first architecture',
    };
  }
}
