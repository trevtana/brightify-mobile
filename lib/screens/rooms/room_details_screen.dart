import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/glass_card.dart';
import '../../services/firebase_service.dart';
import 'add_device_dialog.dart';

class RoomDetailsScreen extends StatefulWidget {
  final String homeId;
  final String homeName;
  final String roomId;
  final String roomName;

  const RoomDetailsScreen({
    Key? key,
    required this.homeId,
    required this.homeName,
    required this.roomId,
    required this.roomName,
  }) : super(key: key);

  @override
  State<RoomDetailsScreen> createState() => _RoomDetailsScreenState();
}

class _RoomDetailsScreenState extends State<RoomDetailsScreen> {
  Timer? _brightnessDebounceTimer;

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: themeProvider.getBackgroundColor(context),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.roomName,
              style: TextStyle(
                color: themeProvider.getTextPrimaryColor(context),
                fontSize: 18,
              ),
            ),
            Text(
              widget.homeName,
              style: TextStyle(
                color: themeProvider.getTextMutedColor(context),
                fontSize: 12,
              ),
            ),
          ],
        ),
        backgroundColor: themeProvider.getCardColor(context),
        elevation: 0,
        iconTheme: IconThemeData(
          color: themeProvider.getTextPrimaryColor(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _editRoom,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _deleteRoom,
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(FirebaseAuth.instance.currentUser?.uid ?? '')
            .collection('homes')
            .doc(widget.homeId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppColors.primaryAccent,
              ),
            );
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return _buildEmptyState(themeProvider);
          }

          // Get devices from nested map structure
          final homeData = snapshot.data!.data() as Map<String, dynamic>;
          final rooms = homeData['rooms'] as Map<String, dynamic>? ?? {};
          
          
          // Try both roomId and roomName as keys
          var roomData = rooms[widget.roomId] as Map<String, dynamic>?;
          if (roomData == null) {
            roomData = rooms[widget.roomName] as Map<String, dynamic>?;
          }
          roomData ??= {};
          
          final devicesMap = roomData['devices'] as Map<String, dynamic>? ?? {};
          
          if (devicesMap.isEmpty) {
            return _buildEmptyState(themeProvider);
          }
          
          // Convert devices map to list
          final devices = devicesMap.entries.map((entry) => {
            'id': entry.key,
            ...entry.value as Map<String, dynamic>,
          }).toList();

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Room Info Card
              GlassCard(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primaryAccent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.meeting_room,
                        color: AppColors.primaryAccent,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Devices',
                            style: TextStyle(
                              fontSize: 14,
                              color: themeProvider.getTextMutedColor(context),
                            ),
                          ),
                          Text(
                            '${devices.length} Device${devices.length != 1 ? 's' : ''}',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: themeProvider.getTextPrimaryColor(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              
              // Devices List
              Text(
                'Devices',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: themeProvider.getTextPrimaryColor(context),
                ),
              ),
              const SizedBox(height: 12),
              ...devices.map((device) {
                final bool isOnline = device['status'] == 'online';
                final bool isPowerOn = device['power'] == true;
                
                return GlassCard(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          // Device Icon
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              gradient: isPowerOn 
                                  ? const LinearGradient(
                                      colors: [AppColors.primaryAccent, AppColors.secondaryAccent],
                                    )
                                  : null,
                              color: isPowerOn ? null : themeProvider.getCardColor(context),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.lightbulb,
                              color: isPowerOn ? Colors.black : themeProvider.getTextMutedColor(context),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          
                          // Device Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  device['device_name'] ?? 'Unknown Device',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: themeProvider.getTextPrimaryColor(context),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isOnline 
                                            ? AppColors.success.withOpacity(0.1)
                                            : AppColors.error.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        isOnline ? 'Online' : 'Offline',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: isOnline ? AppColors.success : AppColors.error,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      device['chip_id'] ?? '',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: themeProvider.getTextMutedColor(context),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          
                          // Power Switch
                          Switch.adaptive(
                            value: isPowerOn,
                            onChanged: isOnline ? (value) {
                              _toggleDevice(device['id'], value);
                            } : null,
                            activeColor: AppColors.primaryAccent,
                          ),
                        ],
                      ),
                      
                      // Brightness & Color Controls (if power is on)
                      if (isPowerOn && isOnline) ...[
                        const SizedBox(height: 16),
                        // Brightness Slider
                        Row(
                          children: [
                            Icon(
                              Icons.brightness_6,
                              size: 20,
                              color: themeProvider.getTextSecondaryColor(context),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Slider(
                                value: (device['brightness'] ?? 255).toDouble(),
                                min: 0,
                                max: 255,
                                activeColor: AppColors.primaryAccent,
                                onChanged: (value) {
                                  _updateBrightness(device['id'], value.round());
                                },
                              ),
                            ),
                            Text(
                              '${((device['brightness'] ?? 255) * 100 / 255).round()}%',
                              style: TextStyle(
                                fontSize: 12,
                                color: themeProvider.getTextSecondaryColor(context),
                              ),
                            ),
                          ],
                        ),
                        
                        // Color Display
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.color_lens,
                              size: 20,
                              color: themeProvider.getTextSecondaryColor(context),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: Color.fromRGBO(
                                  device['red'] ?? 255,
                                  device['green'] ?? 255,
                                  device['blue'] ?? 255,
                                  1,
                                ),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: themeProvider.getTextMutedColor(context).withOpacity(0.3),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'RGB(${device['red'] ?? 255}, ${device['green'] ?? 255}, ${device['blue'] ?? 255})',
                              style: TextStyle(
                                fontSize: 12,
                                color: themeProvider.getTextSecondaryColor(context),
                              ),
                            ),
                          ],
                        ),
                      ],
                      
                      // Actions
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => _editDevice(device['id'], device),
                            child: const Text(
                              'Edit',
                              style: TextStyle(color: AppColors.primaryAccent),
                            ),
                          ),
                          TextButton(
                            onPressed: () => _deleteDevice(device['id']),
                            child: const Text(
                              'Hapus',
                              style: TextStyle(color: AppColors.error),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addDevice,
        backgroundColor: AppColors.primaryAccent,
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }

  Widget _buildEmptyState(ThemeProvider themeProvider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.devices_other,
            size: 80,
            color: themeProvider.getTextMutedColor(context),
          ),
          const SizedBox(height: 16),
          Text(
            'Belum ada device',
            style: TextStyle(
              fontSize: 18,
              color: themeProvider.getTextSecondaryColor(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + untuk menambah device baru',
            style: TextStyle(
              fontSize: 14,
              color: themeProvider.getTextMutedColor(context),
            ),
          ),
        ],
      ),
    );
  }

  void _toggleDevice(String deviceId, bool value) async {
    try {
      // Use Firebase service which handles API + Firestore
      final firebaseService = FirebaseService();
      // Get device data to extract chip_id
      final deviceData = await _getDeviceData(deviceId);
      final chipId = deviceData?['chip_id'] ?? deviceData?['chipId'] ?? deviceId;
      
      // Use chip_id for API calls
      await firebaseService.updateDeviceControl(
        deviceId: chipId,
        homeId: widget.homeId,
        roomId: widget.roomName,  // Use room name as key
        power: value,
      );
      print('✅ Device power updated to $value');
    } catch (e) {
      print('❌ Error updating device power: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _updateBrightness(String deviceId, int brightness) async {
    // Cancel previous timer if exists
    _brightnessDebounceTimer?.cancel();
    
    // Start new timer with 500ms delay
    _brightnessDebounceTimer = Timer(const Duration(milliseconds: 500), () async {
      try {
        // Use Firebase service which handles API + Firestore
        final firebaseService = FirebaseService();
        // Get device data to extract chip_id
        final deviceData = await _getDeviceData(deviceId);
        final chipId = deviceData?['chip_id'] ?? deviceData?['chipId'] ?? deviceId;
        
        // Use chip_id for API calls
        await firebaseService.updateDeviceControl(
          deviceId: chipId,
          homeId: widget.homeId,
          roomId: widget.roomName,  // Use room name as key
          brightness: brightness,
        );
        print('✅ Device brightness updated to $brightness');
      } catch (e) {
        print('❌ Error updating brightness: $e');
      }
    });
  }
  
  Future<Map<String, dynamic>?> _getDeviceData(String deviceId) async {
    try {
      final homeDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser?.uid ?? '')
          .collection('homes')
          .doc(widget.homeId)
          .get();
          
      if (!homeDoc.exists) return null;
      
      final homeData = homeDoc.data() as Map<String, dynamic>;
      final rooms = homeData['rooms'] as Map<String, dynamic>? ?? {};
      
      // Try both roomId and roomName as keys
      var roomData = rooms[widget.roomId] as Map<String, dynamic>?;
      if (roomData == null) {
        roomData = rooms[widget.roomName] as Map<String, dynamic>?;
      }
      
      if (roomData == null) return null;
      
      final devicesMap = roomData['devices'] as Map<String, dynamic>? ?? {};
      return devicesMap[deviceId] as Map<String, dynamic>?;
    } catch (e) {
      print('Error getting device data: $e');
      return null;
    }
  }
  
  @override
  void dispose() {
    _brightnessDebounceTimer?.cancel();
    super.dispose();
  }

  void _addDevice() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddDeviceDialog(
          homeId: widget.homeId,
          homeName: widget.homeName,
          roomId: widget.roomId,
          roomName: widget.roomName,
        ),
      ),
    );
  }

  void _editDevice(String deviceId, Map<String, dynamic> device) async {
    // TODO: Implement edit device dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Edit device - Coming soon'),
      ),
    );
  }

  void _deleteDevice(String deviceId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Device'),
        content: const Text('Yakin ingin menghapus device ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Hapus',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('homes')
          .doc(widget.homeId)
          .update({
        'rooms.${widget.roomName}.devices.$deviceId': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Device berhasil dihapus'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  void _editRoom() async {
    final nameController = TextEditingController(text: widget.roomName);
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Ruangan'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Nama Ruangan',
            hintText: 'Contoh: Kamar Tidur',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, nameController.text),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty && result != widget.roomName) {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      
      // Since room ID is the room name, we need to copy to new name and delete old
      final homeRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('homes')
          .doc(widget.homeId);
      
      // Get current room data
      final homeDoc = await homeRef.get();
      final homeData = homeDoc.data() as Map<String, dynamic>;
      final rooms = homeData['rooms'] as Map<String, dynamic>? ?? {};
      final roomData = rooms[widget.roomId] ?? {};
      
      // Add new room with new name
      await homeRef.update({
        'rooms.$result': roomData,
        'rooms.$result.name': result,
        'rooms.$result.room_name': result,
        'rooms.${widget.roomName}': FieldValue.delete(),  // Use room name as key
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // Navigate back
      Navigator.pop(context);
    }
  }

  void _deleteRoom() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Ruangan'),
        content: Text('Yakin ingin menghapus ${widget.roomName}? Semua device di ruangan ini akan ikut terhapus.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Hapus',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      
      // Delete the room from nested map
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('homes')
          .doc(widget.homeId)
          .update({
        'rooms.${widget.roomName}': FieldValue.delete(),  // Use room name as key
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // Navigate back
      Navigator.pop(context);
    }
  }
}
