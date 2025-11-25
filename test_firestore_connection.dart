import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'lib/firebase_options.dart';

void main() async {
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Get current user
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    print('❌ No user logged in');
    return;
  }
  
  print('✅ Logged in as: ${user.email} (${user.uid})');
  print('Display Name: ${user.displayName}');
  
  // Test direct Firestore query to users/{uid}/homes
  print('\n📊 Testing Firestore Query...');
  
  try {
    // Query 1: Get homes from subcollection (correct structure)
    print('\n1️⃣ Querying users/${user.uid}/homes/...');
    final homesSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('homes')
        .get();
    
    print('✅ Found ${homesSnapshot.docs.length} homes');
    
    for (var home in homesSnapshot.docs) {
      print('\nHome ID: ${home.id}');
      final data = home.data();
      print('Name: ${data['name']}');
      print('Address: ${data['address'] ?? 'N/A'}');
      
      // Check rooms
      final rooms = data['rooms'] as Map<String, dynamic>?;
      if (rooms != null) {
        print('Rooms: ${rooms.keys.join(', ')}');
        
        // Check devices in each room
        rooms.forEach((roomName, roomData) {
          final devices = (roomData as Map<String, dynamic>)['devices'] as Map<String, dynamic>?;
          if (devices != null) {
            print('  Room "$roomName" has ${devices.length} devices');
            devices.forEach((deviceId, deviceData) {
              final device = deviceData as Map<String, dynamic>;
              print('    - ${device['deviceName'] ?? deviceId}: ${device['status'] ?? 'offline'}');
            });
          }
        });
      }
    }
    
  } catch (e) {
    print('❌ Error querying subcollection: $e');
  }
  
  // Test if any top-level homes collection exists (shouldn't)
  print('\n2️⃣ Checking if top-level /homes collection exists...');
  try {
    final topLevelHomes = await FirebaseFirestore.instance
        .collection('homes')
        .limit(1)
        .get();
    
    if (topLevelHomes.docs.isNotEmpty) {
      print('⚠️ WARNING: Found top-level homes collection (shouldn\'t exist!)');
    } else {
      print('✅ No top-level homes collection (correct)');
    }
  } catch (e) {
    print('❌ Error checking top-level collection: $e');
  }
}
