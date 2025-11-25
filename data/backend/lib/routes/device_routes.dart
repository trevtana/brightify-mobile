import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../services/mqtt_service.dart';
import '../services/firebase_service.dart';

Router deviceRoutes() {
  final router = Router();

  // POST /devices/{chipId}/test - Test device control (no auth required)
  router.post('/<chipId>/test', (Request request, String chipId) async {
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;

      print('🧪 TEST Device control request for $chipId');
      print('📋 Control data: $data');

      // Validate chip_id
      if (chipId.isEmpty) {
        return Response.badRequest(
          body: jsonEncode({
            'success': false,
            'message': 'Device chip_id is required',
          }),
          headers: {'Content-Type': 'application/json'},
        );
      }

      bool mqttSuccess = false;
      String mqttError = '';

      // Send MQTT commands
      if (MqttService.isConnected) {
        // Send individual control commands
        if (data.containsKey('power')) {
          await MqttService.publishPower(chipId, data['power']);
        }
        if (data.containsKey('brightness')) {
          await MqttService.publishBrightness(chipId, data['brightness']);
        }
        if (data.containsKey('red') || data.containsKey('green') || data.containsKey('blue')) {
          await MqttService.publishColor(
            chipId, 
            data['red'] ?? 255, 
            data['green'] ?? 255, 
            data['blue'] ?? 255
          );
        }
        if (data.containsKey('preset')) {
          await MqttService.publishPreset(chipId, data['preset']);
        }
        if (data.containsKey('speed')) {
          await MqttService.publishSpeed(chipId, data['speed']);
        }

        // Send general control command
        mqttSuccess = await MqttService.publishDeviceControl(chipId, data);
        
        if (mqttSuccess) {
          print('✅ MQTT commands sent successfully');
        } else {
          mqttError = 'Failed to publish MQTT message';
          print('❌ MQTT publish failed');
        }
      } else {
        mqttError = 'MQTT broker not connected';
        print('❌ MQTT is not connected!');
      }

      return Response.ok(
        jsonEncode({
          'success': mqttSuccess,
          'message': mqttSuccess ? 'Device control commands sent successfully' : 'MQTT command failed',
          'data': {
            'device_id': chipId,
            'chip_id': chipId,
            'mqtt_success': mqttSuccess,
            'mqtt_error': mqttError.isNotEmpty ? mqttError : null,
            'commands_sent': data,
          }
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ Error in device control: $e');
      return Response.internalServerError(
        body: jsonEncode({
          'success': false,
          'message': 'Internal server error: $e',
        }),
        headers: {'Content-Type': 'application/json'},
      );
    }
  });

  // POST /devices/{chipId}/control - Control device
  router.post('/<chipId>/control', (Request request, String chipId) async {
    try {
      final userId = request.context['userId'] as String;
      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;

      print('🎮 Device control request for $chipId from user $userId');
      print('📋 Control data: $data');

      // Validate chip_id
      if (chipId.isEmpty) {
        return Response.badRequest(
          body: jsonEncode({
            'success': false,
            'message': 'Device chip_id is required',
          }),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Prepare MQTT commands
      final List<Future<bool>> mqttPromises = [];
      final Map<String, dynamic> controlCommand = {};

      // Build control command and individual MQTT messages
      if (data.containsKey('power')) {
        final power = data['power'] as bool;
        controlCommand['power'] = power;
        mqttPromises.add(MqttService.publishPower(chipId, power));
      }

      if (data.containsKey('brightness')) {
        final brightness = data['brightness'] as int;
        controlCommand['brightness'] = brightness;
        mqttPromises.add(MqttService.publishBrightness(chipId, brightness));
      }

      if (data.containsKey('red') && data.containsKey('green') && data.containsKey('blue')) {
        final red = data['red'] as int;
        final green = data['green'] as int;
        final blue = data['blue'] as int;
        controlCommand['red'] = red;
        controlCommand['green'] = green;
        controlCommand['blue'] = blue;
        mqttPromises.add(MqttService.publishColor(chipId, red, green, blue));
      }

      if (data.containsKey('preset')) {
        final preset = data['preset'] as int;
        controlCommand['preset'] = preset;
        mqttPromises.add(MqttService.publishPreset(chipId, preset));
      }

      if (data.containsKey('speed')) {
        final speed = data['speed'] as int;
        controlCommand['speed'] = speed;
        mqttPromises.add(MqttService.publishSpeed(chipId, speed));
      }

      // Publish full control command
      mqttPromises.add(MqttService.publishDeviceControl(chipId, controlCommand));

      // Execute all MQTT publishes
      bool mqttSuccess = false;
      String? mqttError;

      try {
        if (!MqttService.isConnected) {
          mqttError = 'MQTT broker not connected';
          print('❌ MQTT is not connected!');
        } else {
          print('📡 Publishing MQTT commands to device $chipId...');
          final results = await Future.wait(mqttPromises);
          mqttSuccess = results.every((result) => result);
          
          if (mqttSuccess) {
            print('✅ All MQTT commands sent successfully to $chipId');
          } else {
            mqttError = 'Some MQTT commands failed';
            print('⚠️ Some MQTT commands failed for $chipId');
          }
        }
      } catch (e) {
        mqttError = e.toString();
        print('❌ MQTT publish error: $mqttError');
      }

      // Find and update device in Firebase (for web sync)
      bool firestoreSuccess = false;
      try {
        // This is a simplified approach - in production you'd want to search for the device
        // For now, we'll assume the mobile app provides homeId and roomId in the request
        final homeId = data['homeId'] as String?;
        final roomId = data['roomId'] as String?;
        
        if (homeId != null && roomId != null) {
          firestoreSuccess = await FirebaseService.updateDeviceInHome(
            userId, 
            homeId, 
            roomId, 
            chipId, 
            controlCommand
          );
        } else {
          print('⚠️ No homeId/roomId provided, skipping Firestore update');
        }
      } catch (e) {
        print('❌ Firestore update error: $e');
      }

      // Return response
      if (mqttSuccess) {
        return Response.ok(
          jsonEncode({
            'success': true,
            'message': 'Device control command sent successfully',
            'data': {
              'device_id': chipId,
              'chip_id': chipId,
              'command_sent': controlCommand,
              'timestamp': DateTime.now().toIso8601String(),
              'mqtt_success': mqttSuccess,
              'firestore_success': firestoreSuccess,
            },
          }),
          headers: {'Content-Type': 'application/json'},
        );
      } else {
        return Response.badRequest(
          body: jsonEncode({
            'success': false,
            'message': mqttError ?? 'Device chip_id not found. Device may not be properly paired.',
            'data': {
              'device_id': chipId,
              'chip_id': chipId,
              'mqtt_error': mqttError,
              'firestore_success': firestoreSuccess,
            },
          }),
          headers: {'Content-Type': 'application/json'},
        );
      }
    } catch (e) {
      print('❌ Device control error: $e');
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

  // GET /devices/{chipId}/status - Get device status
  router.get('/<chipId>/status', (Request request, String chipId) async {
    try {
      
      // In a real implementation, you'd query the device status from Firebase
      // For now, return a simple response
      return Response.ok(
        jsonEncode({
          'success': true,
          'data': {
            'chip_id': chipId,
            'status': 'online', // This would come from actual device status
            'last_seen': DateTime.now().toIso8601String(),
          },
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({
          'success': false,
          'message': 'Failed to get device status',
          'error': e.toString(),
        }),
        headers: {'Content-Type': 'application/json'},
      );
    }
  });

  return router;
}
