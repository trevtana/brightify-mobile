import 'dart:convert';
import 'package:shelf/shelf.dart';
import '../services/firebase_service.dart';

Middleware authMiddleware = (Handler innerHandler) {
  return (Request request) async {
    // Skip auth for health check
    if (request.url.path == 'health') {
      return innerHandler(request);
    }

    // Get Authorization header
    final authHeader = request.headers['authorization'];
    if (authHeader == null || !authHeader.startsWith('Bearer ')) {
      return Response.unauthorized(
        jsonEncode({'error': 'Missing or invalid authorization header'}),
        headers: {'Content-Type': 'application/json'},
      );
    }

    // Extract token
    final token = authHeader.substring(7); // Remove 'Bearer ' prefix

    try {
      // Verify token with Firebase
      final userId = await FirebaseService.verifyIdToken(token);
      if (userId == null) {
        return Response.unauthorized(
          jsonEncode({'error': 'Invalid or expired token'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Add userId to request context
      final updatedRequest = request.change(context: {
        ...request.context,
        'userId': userId,
      });

      return innerHandler(updatedRequest);
    } catch (e) {
      print('❌ Auth middleware error: $e');
      return Response.unauthorized(
        jsonEncode({'error': 'Authentication failed'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  };
};
