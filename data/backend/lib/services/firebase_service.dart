import 'dart:convert';
import 'package:dotenv/dotenv.dart';

class FirebaseService {
  static final DotEnv _env = DotEnv(includePlatformEnvironment: true);
  static String? _projectId;

  static Future<void> initialize() async {
    try {
      _env.load();
      _projectId = _env['FIREBASE_PROJECT_ID'];
      
      if (_projectId == null || _projectId!.isEmpty) {
        throw Exception('FIREBASE_PROJECT_ID not found in .env file');
      }
      
      print('🔥 Firebase Project ID: $_projectId');
      
      print('✅ Firebase service initialized for project: $_projectId');
    } catch (e) {
      print('❌ Firebase initialization error: $e');
      rethrow;
    }
  }

  static String get projectId {
    if (_projectId == null) {
      throw Exception('Firebase not initialized. Call FirebaseService.initialize() first.');
    }
    return _projectId!;
  }

  /// Verify Firebase ID token (simplified version)
  static Future<String?> verifyIdToken(String idToken) async {
    try {
      // For now, we'll do a simple validation
      // In production, you'd want to verify the token properly
      if (idToken.isEmpty) return null;
      
      // Extract user ID from token (simplified)
      final parts = idToken.split('.');
      if (parts.length != 3) return null;
      
      // Decode payload (basic validation)
      final payload = parts[1];
      final normalizedPayload = base64.normalize(payload);
      final decodedBytes = base64.decode(normalizedPayload);
      final decodedJson = utf8.decode(decodedBytes);
      final tokenData = jsonDecode(decodedJson);
      
      return tokenData['user_id'] ?? tokenData['sub'];
    } catch (e) {
      print('❌ Token verification failed: $e');
      return null;
    }
  }

  /// Update device data via Firestore REST API
  static Future<bool> updateDeviceInHome(
    String userId, 
    String homeId, 
    String roomName, 
    String deviceId, 
    Map<String, dynamic> updates
  ) async {
    try {
      // For now, we'll just log the update
      // In production, you'd use Firestore REST API or Firebase Admin SDK
      print('📝 Firebase update request:');
      print('   User: $userId');
      print('   Home: $homeId');
      print('   Room: $roomName');
      print('   Device: $deviceId');
      print('   Updates: $updates');
      
      // Simulate successful update
      await Future.delayed(Duration(milliseconds: 100));
      
      print('✅ Firebase update completed (simulated)');
      return true;
    } catch (e) {
      print('❌ Firebase update error: $e');
      return false;
    }
  }

  /// Get document (simplified)
  static Future<Map<String, dynamic>?> getDocument(String collection, String documentId) async {
    try {
      print('📖 Firebase read request: $collection/$documentId');
      
      // Simulate document read
      await Future.delayed(Duration(milliseconds: 50));
      
      // Return mock data for now
      return {
        'id': documentId,
        'exists': true,
        'data': {'mock': true}
      };
    } catch (e) {
      print('❌ Error getting document: $e');
      return null;
    }
  }

  /// Update document (simplified)
  static Future<bool> updateDocument(String collection, String documentId, Map<String, dynamic> data) async {
    try {
      print('📝 Firebase update: $collection/$documentId');
      print('   Data: $data');
      
      // Simulate update
      await Future.delayed(Duration(milliseconds: 50));
      
      print('✅ Document updated (simulated)');
      return true;
    } catch (e) {
      print('❌ Error updating document: $e');
      return false;
    }
  }

  /// Set document (simplified)
  static Future<bool> setDocument(String collection, String documentId, Map<String, dynamic> data) async {
    try {
      print('📝 Firebase set: $collection/$documentId');
      print('   Data: $data');
      
      // Simulate set operation
      await Future.delayed(Duration(milliseconds: 50));
      
      print('✅ Document set (simulated)');
      return true;
    } catch (e) {
      print('❌ Error setting document: $e');
      return false;
    }
  }

  /// Get user home (simplified)
  static Future<Map<String, dynamic>?> getUserHome(String userId, String homeId) async {
    try {
      print('📖 Getting user home: $userId/$homeId');
      
      // Simulate home data
      await Future.delayed(Duration(milliseconds: 50));
      
      return {
        'id': homeId,
        'name': 'Mock Home',
        'rooms': {
          'Kamar Arkan': {
            'room_name': 'Kamar Arkan',
            'devices': {
              'D92F2B14': {
                'device_name': 'Lampu Kamar',
                'chip_id': 'D92F2B14',
                'power': false,
                'brightness': 255,
                'red': 255,
                'green': 255,
                'blue': 255,
              }
            }
          }
        }
      };
    } catch (e) {
      print('❌ Error getting user home: $e');
      return null;
    }
  }
}
