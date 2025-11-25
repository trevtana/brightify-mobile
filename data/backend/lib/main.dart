import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_cors_headers/shelf_cors_headers.dart';
import 'package:dotenv/dotenv.dart';

import 'services/mqtt_service.dart';
import 'services/firebase_service.dart';
import 'routes/device_routes.dart';
import 'routes/home_routes.dart';
import 'middleware/auth_middleware.dart';

Future<void> main() async {
  // Load environment variables
  final env = DotEnv(includePlatformEnvironment: true)..load();
  
  // Initialize services
  print('🔥 Initializing Firebase Admin...');
  await FirebaseService.initialize();
  
  print('📡 Initializing MQTT Service...');
  await MqttService.initialize();
  
  // Create router
  final router = Router();
  
  // Health check
  router.get('/health', (Request request) {
    return Response.ok('{"status": "healthy", "service": "Brightify Dart Backend"}', 
        headers: {'Content-Type': 'application/json'});
  });
  
  // API routes with authentication for mobile app
  router.mount('/api/v1/devices', 
      Pipeline().addMiddleware(authMiddleware).addHandler(deviceRoutes()));
  router.mount('/api/v1/homes', 
      Pipeline().addMiddleware(authMiddleware).addHandler(homeRoutes()));
  
  // Test routes without authentication (for web testing)
  router.mount('/test/v1/devices', deviceRoutes());
  
  // Create handler with CORS and logging
  final handler = Pipeline()
      .addMiddleware(corsHeaders())
      .addMiddleware(logRequests())
      .addHandler(router);
  
  // Start server
  final port = int.parse(env['SERVER_PORT'] ?? '8080');
  final host = env['SERVER_HOST'] ?? '0.0.0.0';
  
  final server = await serve(handler, host, port);
  
  print('🚀 Brightify Dart Backend running on http://${server.address.host}:${server.port}');
  print('📱 Mobile apps can connect to: http://localhost:$port');
  print('🌐 External access: http://YOUR_IP:$port');
  print('');
  print('📋 Available endpoints:');
  print('  GET  /health - Health check');
  print('  POST /api/v1/devices/{chipId}/control - Control device');
  print('  POST /api/v1/homes - Create home');
  print('  POST /api/v1/homes/{homeId}/rooms - Create room');
  print('');
  print('Press Ctrl+C to stop the server');
}
