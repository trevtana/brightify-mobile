import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/glass_card.dart';

class DebugScreen extends StatefulWidget {
  const DebugScreen({Key? key}) : super(key: key);

  @override
  State<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends State<DebugScreen> {
  String _debugInfo = 'Loading...';

  @override
  void initState() {
    super.initState();
    _runDebugTests();
  }

  Future<void> _runDebugTests() async {
    String info = '';
    
    try {
      // Get current user
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _debugInfo = '❌ No user logged in';
        });
        return;
      }
      
      info += '✅ User: ${user.email}\n';
      info += '📝 UID: ${user.uid}\n';
      info += '👤 Name: ${user.displayName}\n\n';
      
      // Test 1: Query subcollection (correct)
      info += '🔍 Testing users/{uid}/homes query...\n';
      try {
        final homesSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('homes')
            .get();
        
        info += '✅ Query successful!\n';
        info += '📊 Found ${homesSnapshot.docs.length} homes\n\n';
        
        for (var home in homesSnapshot.docs) {
          info += '🏠 Home: ${home.data()['name']}\n';
          info += '  ID: ${home.id}\n';
          
          final rooms = home.data()['rooms'] as Map<String, dynamic>?;
          if (rooms != null) {
            info += '  Rooms: ${rooms.keys.join(', ')}\n';
            
            rooms.forEach((roomName, roomData) {
              final devices = (roomData as Map<String, dynamic>)['devices'] as Map<String, dynamic>?;
              if (devices != null) {
                info += '    📦 $roomName: ${devices.length} devices\n';
                devices.forEach((deviceId, deviceData) {
                  final device = deviceData as Map<String, dynamic>;
                  info += '      • ${device['deviceName'] ?? deviceId}\n';
                });
              }
            });
          }
          info += '\n';
        }
      } catch (e) {
        info += '❌ Query error: $e\n\n';
      }
      
      // Test 2: Check if user document exists
      info += '🔍 Checking user document...\n';
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        
        if (userDoc.exists) {
          info += '✅ User document exists\n';
          info += '  Data: ${userDoc.data()}\n\n';
        } else {
          info += '⚠️ User document does NOT exist\n\n';
        }
      } catch (e) {
        info += '❌ Error checking user doc: $e\n\n';
      }
      
      // Test 3: Try to add a test home
      info += '🔍 Testing write permission...\n';
      try {
        // Try to add a test document
        final testDocRef = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('homes')
            .add({
          'name': 'Test Home ${DateTime.now().millisecondsSinceEpoch}',
          'address': 'Test Address',
          'rooms': {},
          'createdAt': FieldValue.serverTimestamp(),
          'test': true,
        });
        
        info += '✅ Write successful! Doc ID: ${testDocRef.id}\n';
        
        // Delete the test document
        await testDocRef.delete();
        info += '🗑️ Test document deleted\n\n';
      } catch (e) {
        info += '❌ Write error: $e\n\n';
      }
      
    } catch (e) {
      info += '\n❌ General Error: $e';
    }
    
    setState(() {
      _debugInfo = info;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBackground,
        elevation: 0,
        title: const Text(
          'Debug Info',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: GlassCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _debugInfo,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _runDebugTests,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryAccent,
                    ),
                    child: const Text('Run Tests Again'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
