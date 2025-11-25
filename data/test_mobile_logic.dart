import 'dart:convert';
import 'dart:io';

// Simple test untuk mobile app logic tanpa Flutter
void main() async {
  print('🧪 Testing Mobile App Backend Discovery & API Logic...');
  
  // Test 1: Backend Discovery
  await testBackendDiscovery();
  
  // Test 2: Device Control API
  await testDeviceControl();
  
  print('\n✅ All tests completed!');
}

Future<void> testBackendDiscovery() async {
  print('\n📡 Testing Backend Discovery...');
  
  final endpoints = [
    'http://10.219.238.190:8080',
    'http://localhost:8080',
  ];
  
  for (final endpoint in endpoints) {
    try {
      final client = HttpClient();
      final request = await client.getUrl(Uri.parse('$endpoint/health'));
      request.headers.set('Content-Type', 'application/json');
      
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      
      if (response.statusCode == 200) {
        print('✅ Backend found: $endpoint');
        print('   Response: $body');
        client.close();
        return;
      }
    } catch (e) {
      print('❌ Failed to connect to $endpoint: $e');
    }
  }
  
  print('❌ No backend found!');
}

Future<void> testDeviceControl() async {
  print('\n🎮 Testing Device Control API...');
  
  final testCommands = [
    {'power': true},
    {'brightness': 128},
    {'red': 255, 'green': 0, 'blue': 0},
  ];
  
  for (final command in testCommands) {
    try {
      final client = HttpClient();
      final request = await client.postUrl(
        Uri.parse('http://localhost:8080/test/v1/devices/D92F2B14/test')
      );
      request.headers.set('Content-Type', 'application/json');
      request.write(jsonEncode(command));
      
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      
      if (response.statusCode == 200) {
        print('✅ Command sent: $command');
        final result = jsonDecode(body);
        print('   MQTT Success: ${result['success']}');
      } else {
        print('❌ Command failed: $command - Status: ${response.statusCode}');
      }
      
      client.close();
    } catch (e) {
      print('❌ Error sending command $command: $e');
    }
  }
}
