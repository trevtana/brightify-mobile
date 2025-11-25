import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class DeviceInitializationService {
  static const String _baseUrl = 'http://localhost:3000/api/v1';
  
  // Device initialization status
  static Future<Map<String, dynamic>?> getDeviceInitializationStatus(
    String deviceId, 
    String authToken
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/devices/$deviceId/initialization-status'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
      );

      print('🔍 Device initialization status response: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          print('✅ Device initialization status: ${data['data']['status']}');
          return data['data'];
        }
      }
      
      print('⚠️ Failed to get device initialization status: ${response.body}');
      return null;
    } catch (e) {
      print('❌ Error getting device initialization status: $e');
      return null;
    }
  }

  // Check if device is ready for control
  static Future<bool> isDeviceReady(String deviceId, String authToken) async {
    final status = await getDeviceInitializationStatus(deviceId, authToken);
    return status?['is_initialized'] == true;
  }

  // Get human-readable status message
  static String getStatusMessage(Map<String, dynamic>? status) {
    if (status == null) return 'Status tidak diketahui';
    
    switch (status['status']) {
      case 'ready':
        return 'Device siap digunakan';
      case 'initializing':
        return 'Device sedang inisialisasi...';
      case 'offline':
        return 'Device offline';
      default:
        return status['message'] ?? 'Status tidak diketahui';
    }
  }

  // Get status color for UI
  static String getStatusColor(Map<String, dynamic>? status) {
    if (status == null) return 'gray';
    
    switch (status['status']) {
      case 'ready':
        return 'green';
      case 'initializing':
        return 'yellow';
      case 'offline':
        return 'red';
      default:
        return 'gray';
    }
  }

  // Get progress percentage for initializing status
  static double getInitializationProgress(Map<String, dynamic>? status) {
    if (status == null) return 0.0;
    
    switch (status['status']) {
      case 'offline':
        return 0.0;
      case 'initializing':
        // Estimate progress based on available data
        double progress = 0.25; // Base progress for being online
        
        final networkInfo = status['network_info'];
        if (networkInfo != null) {
          if (networkInfo['ip_address'] != null) progress += 0.25;
          if (networkInfo['rssi'] != null) progress += 0.25;
        }
        
        final timeSinceLastSeen = status['time_since_last_seen'];
        if (timeSinceLastSeen != null && timeSinceLastSeen < 30) {
          progress += 0.25;
        }
        
        return progress;
      case 'ready':
        return 1.0;
      default:
        return 0.0;
    }
  }

  // Stream for periodic status checking
  static Stream<Map<String, dynamic>?> watchDeviceInitialization(
    String deviceId, 
    String authToken, {
    Duration interval = const Duration(seconds: 10),
  }) async* {
    while (true) {
      final status = await getDeviceInitializationStatus(deviceId, authToken);
      yield status;
      
      // Stop watching if device is ready or offline
      if (status?['status'] == 'ready' || status?['status'] == 'offline') {
        break;
      }
      
      await Future.delayed(interval);
    }
  }
}
