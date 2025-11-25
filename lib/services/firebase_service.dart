import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'api_service.dart';

class FirebaseService {
  // Singleton pattern
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  // Firebase instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Get current user
  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ========== AUTHENTICATION ==========

  /// Register with email and password
  Future<UserCredential?> registerWithEmailPassword({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update display name
      await credential.user?.updateDisplayName(name);

      // Create user document in Firestore
      if (credential.user != null) {
        await _firestore.collection('users').doc(credential.user!.uid).set({
          'uid': credential.user!.uid,
          'email': email,
          'displayName': name,
          'photoURL': null,
          'createdAt': FieldValue.serverTimestamp(),
          'lastLogin': FieldValue.serverTimestamp(),
          'provider': 'email',
        });
      }

      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Sign in with email and password
  Future<UserCredential?> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update or create user document if doesn't exist
      if (credential.user != null) {
        final userDoc = _firestore.collection('users').doc(credential.user!.uid);
        final docSnapshot = await userDoc.get();
        
        if (!docSnapshot.exists) {
          // User exists in Auth but not in Firestore (maybe created via web)
          await userDoc.set({
            'uid': credential.user!.uid,
            'email': email,
            'displayName': credential.user!.displayName ?? email.split('@')[0],
            'photoURL': credential.user!.photoURL,
            'createdAt': FieldValue.serverTimestamp(),
            'lastLogin': FieldValue.serverTimestamp(),
            'provider': 'email',
          });
        } else {
          await userDoc.update({
            'lastLogin': FieldValue.serverTimestamp(),
          });
        }
      }

      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Trigger Google Sign-In flow
      await _googleSignIn.signOut(); // Clear any cached account
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        // User canceled the sign-in
        return null;
      }

      // Obtain auth details
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase
      final userCredential = await _auth.signInWithCredential(credential);

      // Create or update user document
      if (userCredential.user != null) {
        final userDoc = _firestore.collection('users').doc(userCredential.user!.uid);
        final docSnapshot = await userDoc.get();

        if (!docSnapshot.exists) {
          // New user - create document
          await userDoc.set({
            'uid': userCredential.user!.uid,
            'email': userCredential.user!.email ?? '',
            'displayName': userCredential.user!.displayName ?? googleUser.displayName ?? '',
            'photoURL': userCredential.user!.photoURL ?? googleUser.photoUrl ?? '',
            'createdAt': FieldValue.serverTimestamp(),
            'lastLogin': FieldValue.serverTimestamp(),
            'provider': 'google',
          });
        } else {
          // Existing user - update last login
          await userDoc.update({
            'lastLogin': FieldValue.serverTimestamp(),
            'displayName': userCredential.user!.displayName ?? googleUser.displayName ?? '',
            'photoURL': userCredential.user!.photoURL ?? googleUser.photoUrl ?? '',
          });
        }
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      debugPrint('Google Sign-In Error: $e');
      throw Exception('Gagal masuk dengan Google: ${e.toString()}');
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
      ]);
    } catch (e) {
      throw Exception('Gagal keluar: ${e.toString()}');
    }
  }

  /// Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // ========== FIRESTORE OPERATIONS ==========

  /// Get user data
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.data();
    } catch (e) {
      throw Exception('Gagal mengambil data user: ${e.toString()}');
    }
  }

  /// Get user homes (from users subcollection)
  Stream<QuerySnapshot> getUserHomes(String userId) {
    // Homes are stored as subcollection under users
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('homes')
        .snapshots();
  }

  /// Get devices for a home (from nested structure)
  Stream<DocumentSnapshot> getHomeData(String userId, String homeId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('homes')
        .doc(homeId)
        .snapshots();
  }

  /// Get user devices (extract from nested maps in homes)
  Stream<List<Map<String, dynamic>>> getUserDevices(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('homes')
        .snapshots()
        .map((homesSnapshot) {
          List<Map<String, dynamic>> allDevices = [];
          
          // For each home
          for (var homeDoc in homesSnapshot.docs) {
            final homeId = homeDoc.id;
            final homeData = homeDoc.data();
            final homeName = homeData['name'] ?? 'Unknown Home';
            
            // Rooms are stored as nested map field, NOT subcollection
            // Convert Map<dynamic, dynamic> to Map<String, dynamic>
            final roomsRaw = homeData['rooms'];
            final Map<String, dynamic>? rooms = roomsRaw != null ? Map<String, dynamic>.from(roomsRaw) : null;
            
            if (rooms != null) {
              // For each room in the map
              rooms.forEach((roomKey, roomData) {
                if (roomData == null || roomData is! Map) return;
                
                final roomMap = Map<String, dynamic>.from(roomData);
                final roomName = roomMap['room_name'] ?? roomMap['name'] ?? roomKey;
                
                // Devices are nested in the room map
                final devicesRaw = roomMap['devices'];
                final Map<String, dynamic>? devices = devicesRaw != null ? Map<String, dynamic>.from(devicesRaw) : null;
                
                if (devices != null) {
                  // For each device in the room
                  devices.forEach((deviceId, deviceData) {
                    if (deviceData == null || deviceData is! Map) return;
                    
                    final device = Map<String, dynamic>.from(deviceData);
                    
                    // Get device name from various possible fields
                    final deviceName = device['device_name'] ?? 
                                     device['deviceName'] ?? 
                                     device['lamp_name'] ?? 
                                     'LED Strip';
                    
                    allDevices.add({
                      'id': deviceId,
                      'homeId': homeId,
                      'homeName': homeName,
                      'roomId': roomKey,  // Use room key as ID
                      'roomName': roomName,
                      'deviceName': deviceName,
                      'chip_id': device['chipId'] ?? device['chip_id'] ?? deviceId,
                      'pairing_code': device['pairingCode'] ?? device['pairing_code'],
                      'device_type': device['type'] ?? device['device_type'] ?? 'LED_STRIP',
                      'power': device['power'] ?? false,
                      'brightness': device['brightness'] ?? 255,
                      'red': device['red'] ?? 255,
                      'green': device['green'] ?? 255,
                      'blue': device['blue'] ?? 255,
                      'preset': device['preset'] ?? 0,
                      'status': device['status'] ?? 'offline',
                      'speed': device['speed'] ?? 50,
                      'created_at': device['createdAt'] ?? device['created_at'],
                      'updated_at': device['updatedAt'] ?? device['updated_at'],
                    });
                  });
                }
              });
            }
          }
          
          return allDevices;
        });
  }

  /// Add new home
  Future<String> addHome({
    required String name,
    required String address,
  }) async {
    try {
      final uid = currentUser?.uid;
      if (uid == null) throw Exception('User tidak login');

      // Add to user's homes subcollection
      final docRef = await _firestore
          .collection('users')
          .doc(uid)
          .collection('homes')
          .add({
        'name': name,
        'address': address,
        'rooms': {},  // Initialize empty rooms map
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return docRef.id;
    } catch (e) {
      throw Exception('Gagal menambah rumah: ${e.toString()}');
    }
  }

  /// Add room to home
  Future<void> addRoom({
    required String homeId,
    required String roomName,
    required String roomType,
  }) async {
    try {
      final uid = currentUser?.uid;
      if (uid == null) throw Exception('User tidak login');
      
      // Add room as nested map field
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('homes')
          .doc(homeId)
          .update({
        'rooms.$roomName': {
          'name': roomName,
          'room_name': roomName,  // Some fields use room_name
          'type': roomType,
          'devices': {},  // Initialize empty devices map
          'createdAt': FieldValue.serverTimestamp(),
        },
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Gagal menambah ruangan: ${e.toString()}');
    }
  }

  /// Add device
  Future<String> addDevice({
    required String homeId,
    required String roomId,
    required String deviceName,
    required String chipId,
  }) async {
    try {
      final docRef = await _firestore.collection('devices').add({
        'homeId': homeId,
        'roomId': roomId,
        'deviceName': deviceName,
        'chipId': chipId,
        'power': false,
        'brightness': 255,
        'red': 255,
        'green': 255,
        'blue': 255,
        'preset': 0,
        'speed': 50,
        'status': 'offline',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return docRef.id;
    } catch (e) {
      throw Exception('Gagal menambah device: ${e.toString()}');
    }
  }

  /// Update device control (via API for MQTT + Firestore)
  Future<void> updateDeviceControl({
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
      // Check if cloud services are available
      if (ApiService.isApiAvailable) {
        print('🔄 Attempting MQTT Cloud command');
        try {
          // Try to call the API which will handle both MQTT and Firestore
          final apiResponse = await ApiService.controlDevice(
            deviceId: deviceId,
            power: power,
            brightness: brightness,
            red: red,
            green: green,
            blue: blue,
            preset: preset,
            speed: speed,
          );
          
          print('📡 API Response: $apiResponse');
          
          // Check if API call was successful
          // The backend might not return 'success' field, so we check for no error
          if (apiResponse['error'] == null && apiResponse['message'] != null) {
            print('✅ Device controlled via API (MQTT sent)');
            // Continue to update Firestore for web sync
          } else if (apiResponse['success'] == true) {
            print('✅ Device controlled via API (MQTT sent)');
            // Continue to update Firestore for web sync
          } else {
            print('⚠️ API call returned but with issues: ${apiResponse['error']}');
          }
        } catch (apiError) {
          print('❌ API call failed: $apiError');
        }
      }
      
      // Always update Firestore for web sync
      final uid = currentUser?.uid;
      if (uid == null) throw Exception('User tidak login');
      
      // If homeId and roomId not provided, we need to find them
      String? actualHomeId = homeId;
      String? actualRoomId = roomId;
      
      if (actualHomeId == null || actualRoomId == null) {
        // Search through all homes to find this device
        final homesSnapshot = await _firestore
            .collection('users')
            .doc(uid)
            .collection('homes')
            .get();
        
        for (var homeDoc in homesSnapshot.docs) {
          final homeData = homeDoc.data();
          final rooms = homeData['rooms'] as Map<String, dynamic>?;
          
          if (rooms != null) {
            for (var entry in rooms.entries) {
              final roomDevices = (entry.value as Map<String, dynamic>)['devices'] as Map<String, dynamic>?;
              if (roomDevices != null && roomDevices.containsKey(deviceId)) {
                actualHomeId = homeDoc.id;
                actualRoomId = entry.key;  // Room key/name
                break;
              }
            }
          }
          if (actualHomeId != null) break;
        }
      }
      
      if (actualHomeId == null || actualRoomId == null) {
        throw Exception('Device not found');
      }
      
      // Update device in nested map structure
      final Map<String, dynamic> updates = {};
      if (power != null) updates['rooms.$actualRoomId.devices.$deviceId.power'] = power;
      if (brightness != null) updates['rooms.$actualRoomId.devices.$deviceId.brightness'] = brightness;
      if (red != null) updates['rooms.$actualRoomId.devices.$deviceId.red'] = red;
      if (green != null) updates['rooms.$actualRoomId.devices.$deviceId.green'] = green;
      if (blue != null) updates['rooms.$actualRoomId.devices.$deviceId.blue'] = blue;
      if (preset != null) updates['rooms.$actualRoomId.devices.$deviceId.preset'] = preset;
      if (speed != null) updates['rooms.$actualRoomId.devices.$deviceId.speed'] = speed;
      updates['updatedAt'] = FieldValue.serverTimestamp();
      
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('homes')
          .doc(actualHomeId)
          .update(updates);
    } catch (e) {
      throw Exception('Gagal mengupdate device: ${e.toString()}');
    }
  }

  /// Get device data (from nested structure)
  Stream<Map<String, dynamic>> getDeviceData(String deviceId) {
    final uid = currentUser?.uid;
    if (uid == null) {
      return Stream.value({});
    }
    
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('homes')
        .snapshots()
        .map((homesSnapshot) {
          for (var homeDoc in homesSnapshot.docs) {
            final homeData = homeDoc.data();
            // Convert Map<dynamic, dynamic> to Map<String, dynamic>
            final roomsRaw = homeData['rooms'];
            final Map<String, dynamic>? rooms = roomsRaw != null ? Map<String, dynamic>.from(roomsRaw) : null;
            
            if (rooms != null) {
              for (var entry in rooms.entries) {
                final roomId = entry.key;
                if (entry.value == null || entry.value is! Map) continue;
                
                final roomData = Map<String, dynamic>.from(entry.value);
                // Web app uses 'room_name' field
                final roomName = roomData['room_name'] ?? roomData['name'] ?? 'Ruangan';
                final devicesRaw = roomData['devices'];
                final Map<String, dynamic>? devices = devicesRaw != null ? Map<String, dynamic>.from(devicesRaw) : null;
                
                if (devices != null && devices.containsKey(deviceId)) {
                  final deviceDataRaw = devices[deviceId];
                  if (deviceDataRaw == null || deviceDataRaw is! Map) continue;
                  
                  final deviceData = Map<String, dynamic>.from(deviceDataRaw);
                  // Get device name from various possible fields
                  final deviceName = deviceData['device_name'] ?? 
                                   deviceData['deviceName'] ?? 
                                   deviceData['lamp_name'] ?? 
                                   'LED Strip';
                  
                  return {
                    'id': deviceId,
                    'homeId': homeDoc.id,
                    'homeName': homeData['name'] ?? 'Unknown',
                    'roomId': roomId, // Keep room ID for updates
                    'roomName': roomName, // Actual room name for display
                    'deviceName': deviceName, // Ensure device has a name
                    ...deviceData,
                  };
                }
              }
            }
          }
          return {}; // Device not found
        });
  }

  // ========== SCHEDULES ==========
  
  /// Get schedules stream for specific device
  Stream<List<Map<String, dynamic>>> getSchedulesStream({String? deviceId}) {
    final uid = currentUser?.uid;
    if (uid == null) {
      return Stream.value([]);
    }
    
    print('🔍 Getting schedules for device: $deviceId');
    
    // TEMPORARY: Always use flat structure and filter by deviceId in memory
    return _firestore
        .collection('schedules')
        .where('uid', isEqualTo: uid)
        .snapshots()
        .map((snapshot) {
          print('📅 Raw schedules count: ${snapshot.docs.length}');
          final docs = snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id; // Add document ID
            return data;
          }).where((doc) => doc['isDeleted'] != true).toList(); // Filter deleted in memory
          
          // Filter by device if specified
          final filteredDocs = deviceId != null 
              ? docs.where((doc) => doc['deviceId'] == deviceId).toList()
              : docs;
          
          print('✅ Filtered schedules for device $deviceId: ${filteredDocs.length}');
          
          // Debug: Print first schedule structure
          if (filteredDocs.isNotEmpty) {
            print('📋 First schedule data: ${filteredDocs.first}');
          }
          
          // Remove duplicates by ID
          final uniqueDocs = <String, Map<String, dynamic>>{};
          for (final doc in filteredDocs) {
            final id = doc['id'] as String?;
            if (id != null && id.isNotEmpty) {
              uniqueDocs[id] = doc;
            }
          }
          
          final finalDocs = uniqueDocs.values.toList();
          
          // Sort by createdAt in memory (no index required)
          finalDocs.sort((a, b) {
            final aTime = a['createdAt'] as Timestamp?;
            final bTime = b['createdAt'] as Timestamp?;
            if (aTime == null && bTime == null) return 0;
            if (aTime == null) return 1;
            if (bTime == null) return -1;
            return bTime.compareTo(aTime); // Descending order
          });
          
          return finalDocs;
        });
  }
  
  /// Add schedule using nested structure
  Future<String> addSchedule(Map<String, dynamic> scheduleData) async {
    final uid = currentUser?.uid;
    if (uid == null) throw Exception('User tidak login');
    
    // TEMPORARY: Always use flat structure until Firestore rules are updated
    final docRef = await _firestore
        .collection('schedules')
        .add({
          ...scheduleData,
          'uid': uid,
          'isDeleted': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
    return docRef.id;
    
    /* NESTED STRUCTURE - Enable after Firestore rules update
    if (deviceId == null || homeId == null || roomId == null) {
      // Fallback to top-level collection for backward compatibility
      final docRef = await _firestore
          .collection('schedules')
          .add({
            ...scheduleData,
            'uid': uid,
            'isDeleted': false,
            'createdAt': FieldValue.serverTimestamp(),
          });
      return docRef.id;
    }
    
    // Transform data to match schema structure
    final schemaScheduleData = {
      'schedule_name': scheduleData['name'] ?? 'Unnamed Schedule',
      'enabled': scheduleData['isActive'] ?? true,
      'start_time': _formatTime(scheduleData['time']),
      'end_time': null, // Optional end time
      'days': _convertDaysToSchema(scheduleData['repeatDays'] ?? []),
      'action': _convertActionToSchema(scheduleData['actionData'] ?? {}),
      'createdAt': FieldValue.serverTimestamp(),
    };
    
    // Store in nested structure: users/{uid}/homes/{homeId}/rooms/{roomId}/devices/{deviceId}/schedules/{scheduleId}
    final docRef = await _firestore
        .collection('users')
        .doc(uid)
        .collection('homes')
        .doc(homeId)
        .collection('rooms')
        .doc(roomId)
        .collection('devices')
        .doc(deviceId)
        .collection('schedules')
        .add(schemaScheduleData);
    
    return docRef.id;
    */
  }
  
  /// Update schedule
  Future<void> updateSchedule(dynamic schedule) async {
    final uid = currentUser?.uid;
    if (uid == null) throw Exception('User tidak login');
    
    Map<String, dynamic> scheduleData;
    String scheduleId;
    
    if (schedule is Map<String, dynamic>) {
      scheduleData = schedule;
      scheduleId = schedule['id'] ?? '';
    } else {
      scheduleData = (schedule as dynamic).toJson();
      scheduleId = scheduleData['id'] ?? '';
    }
    
    if (scheduleId.isEmpty) throw Exception('Schedule ID is required');
    
    await _firestore
        .collection('schedules')
        .doc(scheduleId)
        .update({
          ...scheduleData,
          'uid': uid,
          'updatedAt': FieldValue.serverTimestamp(),
        });
  }
  
  /// Delete schedule (supports both nested and flat structure)
  Future<void> deleteSchedule(String scheduleId, {
    String? deviceId,
    String? homeId, 
    String? roomId,
  }) async {
    final uid = currentUser?.uid;
    if (uid == null) throw Exception('User tidak login');
    
    if (scheduleId.isEmpty) throw Exception('Schedule ID is required');
    
    try {
      // Try nested structure first if device info provided
      if (deviceId != null && homeId != null && roomId != null) {
        final docRef = _firestore
            .collection('users')
            .doc(uid)
            .collection('homes')
            .doc(homeId)
            .collection('rooms')
            .doc(roomId)
            .collection('devices')
            .doc(deviceId)
            .collection('schedules')
            .doc(scheduleId);
            
        final doc = await docRef.get();
        if (doc.exists) {
          // Set enabled to false (soft delete in schema)
          await docRef.update({
            'enabled': false,
            'deletedAt': FieldValue.serverTimestamp(),
          });
          print('✅ Schedule disabled successfully (nested): $scheduleId');
          return;
        }
      }
      
      // Fallback to flat structure
      final doc = await _firestore
          .collection('schedules')
          .doc(scheduleId)
          .get();
          
      if (!doc.exists) {
        throw Exception('Schedule not found');
      }
      
      final data = doc.data();
      if (data?['uid'] != uid) {
        throw Exception('Permission denied: Not your schedule');
      }
      
      // Soft delete: mark as deleted instead of actual delete
      await _firestore
          .collection('schedules')
          .doc(scheduleId)
          .update({
            'isDeleted': true,
            'deletedAt': FieldValue.serverTimestamp(),
            'deletedBy': uid,
          });
          
      print('✅ Schedule soft-deleted successfully (flat): $scheduleId');
    } catch (e) {
      print('❌ Delete schedule error: $e');
      rethrow;
    }
  }
  
  // ========== ERROR HANDLING ==========
  
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'Password terlalu lemah. Minimal 6 karakter dengan huruf besar, kecil, dan angka.';
      case 'email-already-in-use':
        return 'Email sudah terdaftar. Silakan gunakan email lain atau login.';
      case 'invalid-email':
        return 'Format email tidak valid.';
      case 'user-not-found':
        return 'User tidak ditemukan. Silakan daftar terlebih dahulu.';
      case 'wrong-password':
        return 'Password salah. Silakan coba lagi.';
      case 'user-disabled':
        return 'Akun ini telah dinonaktifkan.';
      case 'too-many-requests':
        return 'Terlalu banyak percobaan. Silakan coba lagi nanti.';
      case 'operation-not-allowed':
        return 'Operasi tidak diizinkan. Silakan hubungi administrator.';
      default:
        return 'Terjadi kesalahan: ${e.message}';
    }
  }
}
