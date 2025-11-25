import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_service.dart';

class HomeProvider with ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  
  List<Map<String, dynamic>> _homes = [];
  List<Map<String, dynamic>> _devices = [];
  String? _selectedHomeId;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<Map<String, dynamic>> get homes => _homes;
  List<Map<String, dynamic>> get devices => _devices;
  String? get selectedHomeId => _selectedHomeId;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Get devices for current home
  List<Map<String, dynamic>> get currentHomeDevices {
    if (_selectedHomeId == null) return [];
    return _devices.where((device) => device['homeId'] == _selectedHomeId).toList();
  }

  // Get active devices count
  int get activeDevicesCount {
    return currentHomeDevices.where((device) => device['power'] == true).length;
  }

  // Get online devices count
  int get onlineDevicesCount {
    return currentHomeDevices.where((device) => device['status'] == 'online').length;
  }

  /// Load user homes
  Future<void> loadHomes(String uid) async {
    try {
      _setLoading(true);
      _clearError();

      _firebaseService.getUserHomes(uid).listen((snapshot) {
        _homes = snapshot.docs.map((doc) {
          return {
            'id': doc.id,
            ...doc.data() as Map<String, dynamic>,
          };
        }).toList();

        // Set first home as selected if not set
        if (_selectedHomeId == null && _homes.isNotEmpty) {
          _selectedHomeId = _homes.first['id'];
          loadDevices(_selectedHomeId!);
        }

        _setLoading(false);
        notifyListeners();
      });
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
    }
  }

  /// Load devices for a home (from nested structure)
  Future<void> loadDevices(String homeId) async {
    try {
      final userId = _firebaseService.currentUser?.uid;
      if (userId == null) return;
      
      _firebaseService.getHomeData(userId, homeId).listen((snapshot) {
        if (!snapshot.exists) {
          _devices = [];
          notifyListeners();
          return;
        }
        
        final homeData = snapshot.data() as Map<String, dynamic>;
        final rooms = homeData['rooms'] as Map<String, dynamic>? ?? {};
        List<Map<String, dynamic>> allDevices = [];
        
        rooms.forEach((roomName, roomData) {
          final devices = (roomData as Map<String, dynamic>)['devices'] as Map<String, dynamic>? ?? {};
          devices.forEach((deviceId, deviceData) {
            allDevices.add({
              'id': deviceId,
              'roomName': roomName,
              ...deviceData as Map<String, dynamic>,
            });
          });
        });
        
        _devices = allDevices;
        notifyListeners();
      });
    } catch (e) {
      _setError(e.toString());
    }
  }

  /// Select home
  void selectHome(String homeId) {
    _selectedHomeId = homeId;
    loadDevices(homeId);
    notifyListeners();
  }

  /// Add new home
  Future<bool> addHome({
    required String name,
    required String address,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final homeId = await _firebaseService.addHome(
        name: name,
        address: address,
      );

      _selectedHomeId = homeId;
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  /// Add room to home
  Future<bool> addRoom({
    required String homeId,
    required String roomName,
    required String roomType,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      await _firebaseService.addRoom(
        homeId: homeId,
        roomName: roomName,
        roomType: roomType,
      );

      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  /// Add device
  Future<bool> addDevice({
    required String homeId,
    required String roomId,
    required String deviceName,
    required String chipId,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      await _firebaseService.addDevice(
        homeId: homeId,
        roomId: roomId,
        deviceName: deviceName,
        chipId: chipId,
      );

      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  /// Control device
  Future<bool> controlDevice({
    required String deviceId,
    bool? power,
    int? brightness,
    int? red,
    int? green,
    int? blue,
    int? preset,
    int? speed,
  }) async {
    try {
      await _firebaseService.updateDeviceControl(
        deviceId: deviceId,
        power: power,
        brightness: brightness,
        red: red,
        green: green,
        blue: blue,
        preset: preset,
        speed: speed,
      );

      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  /// Apply preset to all active devices
  Future<bool> applyPresetToAll(int presetId) async {
    try {
      final activeDevices = currentHomeDevices.where((device) => device['power'] == true);
      
      for (var device in activeDevices) {
        await controlDevice(
          deviceId: device['id'],
          preset: presetId,
        );
      }
      
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  /// Get device by ID
  Map<String, dynamic>? getDeviceById(String deviceId) {
    try {
      return _devices.firstWhere((device) => device['id'] == deviceId);
    } catch (e) {
      return null;
    }
  }

  /// Get devices by room
  List<Map<String, dynamic>> getDevicesByRoom(String roomId) {
    return _devices.where((device) => device['roomId'] == roomId).toList();
  }

  // Helper methods
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  void clearError() {
    _clearError();
    notifyListeners();
  }
}
