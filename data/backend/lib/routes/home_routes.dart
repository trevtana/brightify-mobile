import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../services/firebase_service.dart';

Router homeRoutes() {
  final router = Router();

  // POST /homes - Create new home
  router.post('/', (Request request) async {
    try {
      final userId = request.context['userId'] as String;
      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;

      print('🏠 Creating home for user $userId');
      print('📋 Home data: $data');

      final homeName = data['name'] as String?;
      final address = data['address'] as String?;
      
      if (homeName == null || homeName.isEmpty) {
        return Response.badRequest(
          body: jsonEncode({
            'success': false,
            'message': 'Home name is required',
          }),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Create home document
      final homeId = DateTime.now().millisecondsSinceEpoch.toString();
      final homeData = {
        'name': homeName,
        'address': address ?? '',
        'country': data['country'] ?? 'Indonesia',
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
        'rooms': <String, dynamic>{}, // Empty rooms initially
      };

      // Save to Firebase
      final success = await FirebaseService.setDocument(
        'users/$userId/homes',
        homeId,
        homeData,
      );

      if (success) {
        return Response.ok(
          jsonEncode({
            'success': true,
            'message': 'Home created successfully',
            'data': {
              'homeId': homeId,
              'home': homeData,
            },
          }),
          headers: {'Content-Type': 'application/json'},
        );
      } else {
        return Response.internalServerError(
          body: jsonEncode({
            'success': false,
            'message': 'Failed to create home',
          }),
          headers: {'Content-Type': 'application/json'},
        );
      }
    } catch (e) {
      print('❌ Create home error: $e');
      return Response.internalServerError(
        body: jsonEncode({
          'success': false,
          'message': 'Internal server error',
          'error': e.toString(),
        }),
        headers: {'Content-Type': 'application/json'},
      );
    }
  });

  // POST /homes/{homeId}/rooms - Create new room
  router.post('/<homeId>/rooms', (Request request, String homeId) async {
    try {
      final userId = request.context['userId'] as String;
      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;

      print('🏠 Creating room in home $homeId for user $userId');
      print('📋 Room data: $data');

      final roomName = data['room_name'] as String?;
      final roomType = data['room_type'] as String?;
      
      if (roomName == null || roomName.isEmpty) {
        return Response.badRequest(
          body: jsonEncode({
            'success': false,
            'message': 'Room name is required',
          }),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Get existing home
      final home = await FirebaseService.getUserHome(userId, homeId);
      if (home == null) {
        return Response.notFound(
          jsonEncode({
            'success': false,
            'message': 'Home not found',
          }),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Add room to home
      final rooms = Map<String, dynamic>.from(home['rooms'] ?? {});
      rooms[roomName] = {
        'room_name': roomName,
        'type': roomType ?? 'general',
        'createdAt': DateTime.now().toIso8601String(),
        'devices': <String, dynamic>{}, // Empty devices initially
      };

      // Update home with new room
      final success = await FirebaseService.updateDocument(
        'users/$userId/homes',
        homeId,
        {'rooms': rooms, 'updatedAt': DateTime.now().toIso8601String()},
      );

      if (success) {
        return Response.ok(
          jsonEncode({
            'success': true,
            'message': 'Room created successfully',
            'data': {
              'homeId': homeId,
              'roomName': roomName,
              'room': rooms[roomName],
            },
          }),
          headers: {'Content-Type': 'application/json'},
        );
      } else {
        return Response.internalServerError(
          body: jsonEncode({
            'success': false,
            'message': 'Failed to create room',
          }),
          headers: {'Content-Type': 'application/json'},
        );
      }
    } catch (e) {
      print('❌ Create room error: $e');
      return Response.internalServerError(
        body: jsonEncode({
          'success': false,
          'message': 'Internal server error',
          'error': e.toString(),
        }),
        headers: {'Content-Type': 'application/json'},
      );
    }
  });

  // POST /homes/{homeId}/rooms/{roomId}/devices - Add device to room
  router.post('/<homeId>/rooms/<roomId>/devices', (Request request, String homeId, String roomId) async {
    try {
      final userId = request.context['userId'] as String;
      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;

      print('💡 Adding device to room $roomId in home $homeId for user $userId');
      print('📋 Device data: $data');

      final deviceName = data['device_name'] as String?;
      final chipId = data['chip_id'] as String?;
      final pairingCode = data['pairing_code'] as String?;
      
      if (deviceName == null || chipId == null) {
        return Response.badRequest(
          body: jsonEncode({
            'success': false,
            'message': 'Device name and chip_id are required',
          }),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Get existing home
      final home = await FirebaseService.getUserHome(userId, homeId);
      if (home == null) {
        return Response.notFound(
          jsonEncode({
            'success': false,
            'message': 'Home not found',
          }),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final rooms = Map<String, dynamic>.from(home['rooms'] ?? {});
      if (!rooms.containsKey(roomId)) {
        return Response.notFound(
          jsonEncode({
            'success': false,
            'message': 'Room not found',
          }),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Add device to room
      final roomData = Map<String, dynamic>.from(rooms[roomId]);
      final devices = Map<String, dynamic>.from(roomData['devices'] ?? {});
      
      devices[chipId] = {
        'device_name': deviceName,
        'deviceName': deviceName, // For compatibility
        'chip_id': chipId,
        'chipId': chipId, // For compatibility
        'pairing_code': pairingCode ?? '',
        'device_type': data['device_type'] ?? 'LED_STRIP',
        'power': false,
        'brightness': 255,
        'red': 255,
        'green': 255,
        'blue': 255,
        'preset': 0,
        'speed': 50,
        'status': 'offline',
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      };

      roomData['devices'] = devices;
      rooms[roomId] = roomData;

      // Update home with new device
      final success = await FirebaseService.updateDocument(
        'users/$userId/homes',
        homeId,
        {'rooms': rooms, 'updatedAt': DateTime.now().toIso8601String()},
      );

      if (success) {
        return Response.ok(
          jsonEncode({
            'success': true,
            'message': 'Device added successfully',
            'data': {
              'homeId': homeId,
              'roomId': roomId,
              'chipId': chipId,
              'device': devices[chipId],
            },
          }),
          headers: {'Content-Type': 'application/json'},
        );
      } else {
        return Response.internalServerError(
          body: jsonEncode({
            'success': false,
            'message': 'Failed to add device',
          }),
          headers: {'Content-Type': 'application/json'},
        );
      }
    } catch (e) {
      print('❌ Add device error: $e');
      return Response.internalServerError(
        body: jsonEncode({
          'success': false,
          'message': 'Internal server error',
          'error': e.toString(),
        }),
        headers: {'Content-Type': 'application/json'},
      );
    }
  });

  return router;
}
