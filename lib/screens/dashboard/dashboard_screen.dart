import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/preset_mode.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/custom_bottom_nav.dart';
import '../../providers/auth_provider.dart';
import '../../services/firebase_service.dart';
import '../rooms/room_details_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
  final FirebaseService _firebaseService = FirebaseService();

  void _handlePresetTap(PresetMode preset, List<Map<String, dynamic>> devices) async {
    final activeDevices = devices.where((d) => d['power'] == true).toList();
    
    if (activeDevices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Semua lampu dalam kondisi OFF! Nyalakan terlebih dahulu lampu Anda.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }
    
    // Apply preset RGB values to all active devices
    try {
      for (var device in activeDevices) {
        // Use chip_id or chipId as the deviceId for API calls
        final chipId = device['chip_id'] ?? device['chipId'] ?? device['id'];
        await _firebaseService.updateDeviceControl(
          deviceId: chipId,
          homeId: device['homeId'],
          roomId: device['roomId'],
          red: preset.red,
          green: preset.green,
          blue: preset.blue,
          brightness: preset.brightness,
        );
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Mode ${preset.name} diterapkan ke ${activeDevices.length} device'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menerapkan preset: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  IconData _getRoomIcon(String? roomName) {
    if (roomName == null) return Icons.devices;
    final name = roomName.toLowerCase();
    if (name.contains('tamu') || name.contains('keluarga')) return Icons.weekend;
    if (name.contains('tidur') || name.contains('kamar')) return Icons.bed;
    if (name.contains('dapur') || name.contains('kitchen')) return Icons.kitchen;
    if (name.contains('mandi') || name.contains('bathroom')) return Icons.bathtub_outlined;
    if (name.contains('kerja') || name.contains('office')) return Icons.work_outline;
    if (name.contains('taman') || name.contains('garden')) return Icons.yard;
    return Icons.room;
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    
    print('🏛️ Dashboard: User from provider: ${user?.email ?? "NULL"}');
    print('🏛️ Dashboard: Is authenticated: ${authProvider.isAuthenticated}');
    
    // Check if user is logged in
    if (user == null) {
      print('⚠️ Dashboard: USER IS NULL!');
      print('⚠️ Dashboard: Redirecting to login...');
      
      // Redirect to login
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/login');
        }
      });
      
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primaryAccent),
        ),
      );
    }

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _firebaseService.getUserDevices(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: Center(
              child: CircularProgressIndicator(color: AppColors.primaryAccent),
            ),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: AppColors.error),
              ),
            ),
          );
        }

        // Parse devices from Firestore
        final devices = snapshot.data ?? [];

        // Calculate stats
        final activeDevicesCount = devices.where((d) => d['power'] == true).length;
        final onlineDevicesCount = devices.where((d) => d['status'] == 'online').length;
        
        // Group devices by room/location using roomId as the key
        final Map<String, List<Map<String, dynamic>>> devicesByRoomId = {};
        final Map<String, String> roomIdToName = {};
        
        for (var device in devices) {
          final roomId = device['roomId'] ?? device['roomName'] ?? 'Lainnya';
          final roomName = device['roomName'] ?? roomId;
          
          // Store the mapping
          if (!roomIdToName.containsKey(roomId) || roomName != 'Lainnya') {
            roomIdToName[roomId] = roomName;
          }
          
          devicesByRoomId.putIfAbsent(roomId, () => []);
          devicesByRoomId[roomId]!.add(device);
        }

        final rooms = devicesByRoomId.entries.map((entry) {
          final roomDevices = entry.value;
          // Get home and room IDs from first device (all devices in same room should have same IDs)
          final firstDevice = roomDevices.isNotEmpty ? roomDevices.first : null;
          final roomName = roomIdToName[entry.key] ?? entry.key;
          
          return {
            'name': roomName,
            'id': entry.key, // Use the room key from Firebase
            'homeId': firstDevice?['homeId'] ?? '',
            'homeName': firstDevice?['homeName'] ?? 'Unknown Home',
            'icon': _getRoomIcon(roomName),
            'devicesCount': roomDevices.length,
            'activeDevices': roomDevices.where((d) => d['power'] == true).length,
          };
        }).toList();

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    _buildHeader(),
                    const SizedBox(height: 24),
                    
                    // Status Cards
                    _buildStatusCards(activeDevicesCount, onlineDevicesCount, devices.length),
                    const SizedBox(height: 24),
                    
                    // Quick Actions
                    _buildQuickActions(),
                    const SizedBox(height: 24),
                    
                    // Warning Banner if no active devices
                    if (activeDevicesCount == 0) _buildWarningBanner(),
                    
                    // Quick Preset Modes
                    _buildQuickPresets(devices, activeDevicesCount),
                    const SizedBox(height: 24),
                    
                    // Rooms Grid or No Data Message
                    if (devices.isEmpty)
                      _buildNoDevices()
                    else
                      _buildRoomsSection(rooms, devices),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ),
          bottomNavigationBar: CustomBottomNav(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
              _navigateToScreen(index);
            },
            onCenterTap: () {
              Navigator.pushNamed(context, '/add-home');
            },
          ),
        );
      },
    );
  }
  
  Widget _buildHeader() {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final userName = user?.displayName ?? user?.email?.split('@')[0] ?? 'User';
    final userInitial = userName[0].toUpperCase();
    final photoURL = user?.photoURL;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Selamat Datang',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              userName,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        Row(
          children: [
            IconButton(
              onPressed: () {
                // TODO: Show notifications
              },
              icon: const Icon(
                Icons.notifications_outlined,
                color: AppColors.textPrimary,
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, '/profile');
              },
              child: photoURL != null && photoURL.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        photoURL,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildDefaultAvatar(userInitial);
                        },
                      ),
                    )
                  : _buildDefaultAvatar(userInitial),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildStatusCards(int activeCount, int onlineCount, int totalDevices) {
    // Simplified energy calculation based on active devices
    final energyUsage = (activeCount * 0.01 * 24).toStringAsFixed(1); // kWh estimate
    
    return Row(
      children: [
        Expanded(
          child: GlassCard(
            gradient: true,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryAccent.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.lightbulb,
                    color: AppColors.primaryAccent,
                    size: 20,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '$activeCount',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Text(
                  'Lampu Aktif',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GlassCard(
            gradient: true,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.wifi,
                    color: AppColors.success,
                    size: 20,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '$onlineCount',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Text(
                  'Device Online',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GlassCard(
            gradient: true,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.info.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.bolt,
                    color: AppColors.info,
                    size: 20,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  energyUsage,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Text(
                  'kWh Hari Ini',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: GlassCard(
            padding: const EdgeInsets.all(16),
            borderGlow: false,
            onTap: () {
              Navigator.pushNamed(context, '/schedule');
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.schedule,
                    color: AppColors.primaryAccent,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Schedule',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Atur jadwal otomatis',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GlassCard(
            padding: const EdgeInsets.all(16),
            borderGlow: false,
            onTap: () {
              Navigator.pushNamed(context, '/statistics');
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.bar_chart,
                    color: AppColors.success,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Statistik',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Lihat penggunaan',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildWarningBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.warning.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: AppColors.warning,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Semua lampu dalam kondisi OFF',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.warning,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Nyalakan lampu untuk menggunakan preset mode',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildQuickPresets(List<Map<String, dynamic>> devices, int activeCount) {
    final quickPresets = PresetMode.allModes.take(4).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Mode Preset',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            IconButton(
              onPressed: () {
                Navigator.pushNamed(context, '/add-home');
              },
              icon: const Icon(
                Icons.add_circle_outline,
                color: AppColors.primaryAccent,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.5,
          ),
          itemCount: quickPresets.length,
          itemBuilder: (context, index) {
            final preset = quickPresets[index];
            final isDisabled = activeCount == 0;
            
            return GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              borderGlow: !isDisabled,
              onTap: isDisabled ? null : () => _handlePresetTap(preset, devices),
              child: Opacity(
                opacity: isDisabled ? 0.5 : 1.0,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: preset.colors,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        preset.icon,
                        color: AppColors.textPrimary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      preset.name,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      preset.description,
                      style: const TextStyle(
                        fontSize: 9,
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
  
  Widget _buildRoomsSection(List<Map<String, dynamic>> rooms, List<Map<String, dynamic>> devices) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ruangan',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.3,
          ),
          itemCount: rooms.length,
          itemBuilder: (context, index) {
            final room = rooms[index];
            
            return GlassCard(
              padding: const EdgeInsets.all(16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RoomDetailsScreen(
                      homeId: room['homeId'],
                      homeName: room['homeName'],
                      roomId: room['id'],
                      roomName: room['name'],
                    ),
                  ),
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primaryAccent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          room['icon'],
                          color: AppColors.primaryAccent,
                          size: 24,
                        ),
                      ),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: room['activeDevices'] > 0
                              ? AppColors.success
                              : AppColors.textMuted,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        room['name'],
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${room['activeDevices']}/${room['devicesCount']} device aktif',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
  
  Widget _buildDefaultAvatar(String initial) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryBackground,
          ),
        ),
      ),
    );
  }

  Widget _buildNoDevices() {
    return GlassCard(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.lightbulb_outline,
            size: 64,
            color: AppColors.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'Belum Ada Device',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tambahkan device pertama Anda untuk\nmulai mengontrol pencahayaan',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, '/add-home');
            },
            icon: const Icon(Icons.add),
            label: const Text('Tambah Device'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryAccent,
              foregroundColor: AppColors.primaryBackground,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
  
  void _navigateToScreen(int index) {
    switch (index) {
      case 0:
        // Already on dashboard
        break;
      case 1:
        Navigator.pushNamed(context, '/devices');
        break;
      case 2:
        Navigator.pushNamed(context, '/statistics');
        break;
      case 3:
        Navigator.pushNamed(context, '/settings');
        break;
    }
  }
}
