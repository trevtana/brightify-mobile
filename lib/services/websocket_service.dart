import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:firebase_auth/firebase_auth.dart';
import 'backend_discovery.dart';

class WebSocketService {
  static WebSocketService? _instance;
  static WebSocketService get instance => _instance ??= WebSocketService._();
  
  WebSocketService._();
  
  WebSocketChannel? _channel;
  StreamController<Map<String, dynamic>>? _streamController;
  Timer? _reconnectTimer;
  bool _isConnected = false;
  String? _currentUserId;
  
  // WebSocket URL (dynamic discovery from backend)
  static Future<String?> get wsUrl async {
    final backendUrl = await BackendDiscovery.getBackendUrl();
    if (backendUrl == null) return null;
    
    // Convert HTTP to WebSocket protocol
    return backendUrl
        .replaceFirst('https://', 'wss://')
        .replaceFirst('http://', 'ws://') + '/ws';
  }
  
  // Get the stream for listening to device updates
  Stream<Map<String, dynamic>> get deviceUpdates {
    _streamController ??= StreamController<Map<String, dynamic>>.broadcast();
    return _streamController!.stream;
  }
  
  // Connect to WebSocket server
  Future<void> connect() async {
    try {
      // Get current user
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('❌ WebSocket: No user logged in');
        return;
      }
      
      _currentUserId = user.uid;
      
      // Close existing connection if any
      await disconnect();
      
      // Get WebSocket URL
      final wsUrlString = await wsUrl;
      if (wsUrlString == null) {
        print('❌ WebSocket: No backend URL available');
        return;
      }
      
      print('🔌 WebSocket: Connecting to $wsUrlString');
      
      // Create WebSocket connection
      _channel = WebSocketChannel.connect(Uri.parse(wsUrlString));
      
      // Send authentication
      final authMessage = {
        'type': 'auth',
        'userId': user.uid,
        'token': await user.getIdToken(),
      };
      _channel!.sink.add(jsonEncode(authMessage));
      
      // Listen to messages
      _channel!.stream.listen(
        (message) {
          _handleMessage(message);
        },
        onError: (error) {
          print('❌ WebSocket error: $error');
          _handleDisconnect();
        },
        onDone: () {
          print('⚠️ WebSocket connection closed');
          _handleDisconnect();
        },
      );
      
      _isConnected = true;
      print('✅ WebSocket connected');
      
    } catch (e) {
      print('❌ WebSocket connection failed: $e');
      _handleDisconnect();
    }
  }
  
  // Handle incoming messages
  void _handleMessage(dynamic message) {
    try {
      final data = jsonDecode(message);
      print('📨 WebSocket message: $data');
      
      // Handle different message types
      switch (data['type']) {
        case 'device_update':
          // Broadcast device update to listeners
          _streamController?.add(data['data']);
          break;
          
        case 'connection':
          print('✅ WebSocket authenticated: ${data['message']}');
          break;
          
        case 'error':
          print('❌ WebSocket error: ${data['message']}');
          break;
          
        default:
          print('❓ Unknown message type: ${data['type']}');
      }
    } catch (e) {
      print('❌ Error parsing WebSocket message: $e');
    }
  }
  
  // Handle disconnection
  void _handleDisconnect() {
    _isConnected = false;
    
    // Schedule reconnection after 5 seconds
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      if (!_isConnected && _currentUserId != null) {
        print('🔄 WebSocket: Attempting reconnection...');
        connect();
      }
    });
  }
  
  // Send message to server
  void sendMessage(Map<String, dynamic> message) {
    if (_isConnected && _channel != null) {
      _channel!.sink.add(jsonEncode(message));
    } else {
      print('⚠️ WebSocket not connected, cannot send message');
    }
  }
  
  // Send device control command
  void sendDeviceControl({
    required String deviceId,
    bool? power,
    int? brightness,
    int? red,
    int? green,
    int? blue,
    int? preset,
    int? speed,
  }) {
    final message = {
      'type': 'device_control',
      'deviceId': deviceId,
      'data': {
        if (power != null) 'power': power,
        if (brightness != null) 'brightness': brightness,
        if (red != null) 'red': red,
        if (green != null) 'green': green,
        if (blue != null) 'blue': blue,
        if (preset != null) 'preset': preset,
        if (speed != null) 'speed': speed,
      },
    };
    
    sendMessage(message);
  }
  
  // Disconnect from WebSocket
  Future<void> disconnect() async {
    _reconnectTimer?.cancel();
    _isConnected = false;
    
    if (_channel != null) {
      await _channel!.sink.close(status.goingAway);
      _channel = null;
    }
  }
  
  // Clean up resources
  void dispose() {
    _reconnectTimer?.cancel();
    _streamController?.close();
    disconnect();
  }
  
  bool get isConnected => _isConnected;
}
