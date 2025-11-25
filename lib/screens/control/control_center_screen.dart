import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../services/firebase_service.dart';
import '../../widgets/glass_card.dart';
import '../../models/preset_mode.dart';

class ControlCenterScreen extends StatefulWidget {
  const ControlCenterScreen({Key? key}) : super(key: key);

  @override
  State<ControlCenterScreen> createState() => _ControlCenterScreenState();
}

class _ControlCenterScreenState extends State<ControlCenterScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  bool _allDevicesPower = false;
  int _globalBrightness = 255;
  PresetMode? _selectedPreset;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    if (user == null) {
      print('⚠️ ControlCenter: User is NULL, redirecting to login');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/login');
        }
      });
      return const Scaffold(
        backgroundColor: AppColors.primaryBackground,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primaryAccent),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: SafeArea(
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: _firebaseService.getUserDevices(user.uid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primaryAccent),
              );
            }

            final devices = snapshot.data ?? [];

            final activeDevicesCount = devices.where((d) => d['power'] == true).length;
            final onlineDevicesCount = devices.where((d) => d['status'] == 'online').length;
            
            // Update global power state
            _allDevicesPower = activeDevicesCount == devices.length && devices.isNotEmpty;

            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.close, color: AppColors.textPrimary),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const Expanded(
                          child: Text(
                            'Control Center',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Quick Stats
                    Row(
                      children: [
                        Expanded(
                          child: GlassCard(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.lightbulb,
                                  color: AppColors.primaryAccent,
                                  size: 32,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '$activeDevicesCount/${devices.length}',
                                  style: const TextStyle(
                                    fontSize: 24,
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
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.wifi,
                                  color: AppColors.success,
                                  size: 32,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '$onlineDevicesCount/${devices.length}',
                                  style: const TextStyle(
                                    fontSize: 24,
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
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Master Control
                    const Text(
                      'Master Control',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    GlassCard(
                      gradient: true,
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          // All Devices Power
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Semua Device',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Kontrol semua lampu sekaligus',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                              Switch(
                                value: _allDevicesPower,
                                onChanged: (value) async {
                                  setState(() {
                                    _allDevicesPower = value;
                                  });
                                  // Update all devices
                                  for (var device in devices) {
                                    final chipId = device['chip_id'] ?? device['chipId'] ?? device['id'];
                                    await _firebaseService.updateDeviceControl(
                                      deviceId: chipId,
                                      power: value,
                                    );
                                  }
                                },
                                activeColor: AppColors.primaryAccent,
                              ),
                            ],
                          ),
                          
                          if (_allDevicesPower) ...[
                            const Divider(height: 32),
                            // Global Brightness
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Brightness',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    Text(
                                      '${(_globalBrightness / 255 * 100).round()}%',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                SliderTheme(
                                  data: SliderTheme.of(context).copyWith(
                                    activeTrackColor: AppColors.primaryAccent,
                                    inactiveTrackColor: AppColors.textSecondary.withOpacity(0.3),
                                    thumbColor: AppColors.primaryAccent,
                                    overlayColor: AppColors.primaryAccent.withOpacity(0.3),
                                  ),
                                  child: Slider(
                                    value: _globalBrightness.toDouble(),
                                    min: 0,
                                    max: 255,
                                    onChanged: (value) {
                                      setState(() {
                                        _globalBrightness = value.round();
                                      });
                                    },
                                    onChangeEnd: (value) async {
                                      // Update all active devices
                                      for (var device in devices) {
                                        if (device['power'] == true) {
                                          final chipId = device['chip_id'] ?? device['chipId'] ?? device['id'];
                                          await _firebaseService.updateDeviceControl(
                                            deviceId: chipId,
                                            brightness: value.round(),
                                          );
                                        }
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Quick Presets
                    const Text(
                      'Quick Presets',
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
                        crossAxisCount: 3,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.0,
                      ),
                      itemCount: 6,
                      itemBuilder: (context, index) {
                        final preset = PresetMode.allModes[index];
                        final isSelected = _selectedPreset?.id == preset.id;
                        
                        return GlassCard(
                          borderGlow: isSelected,
                          padding: const EdgeInsets.all(12),
                          onTap: () async {
                            setState(() {
                              _selectedPreset = preset;
                            });
                            
                            // Apply preset to all active devices
                            for (var device in devices) {
                              if (device['power'] == true) {
                                final chipId = device['chip_id'] ?? device['chipId'] ?? device['id'];
                                await _firebaseService.updateDeviceControl(
                                  deviceId: chipId,
                                  red: preset.red,
                                  green: preset.green,
                                  blue: preset.blue,
                                  brightness: preset.brightness,
                                );
                              }
                            }
                            
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Mode ${preset.name} diterapkan'),
                                  backgroundColor: AppColors.success,
                                ),
                              );
                            }
                          },
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: preset.colors,
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  preset.icon,
                                  color: AppColors.textPrimary,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                preset.name,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                  color: isSelected 
                                      ? AppColors.primaryAccent 
                                      : AppColors.textPrimary,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),

                    // Room Controls
                    const Text(
                      'Control Per Ruangan',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    _buildRoomControls(devices),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildRoomControls(List<Map<String, dynamic>> devices) {
    // Group devices by room
    final Map<String, List<Map<String, dynamic>>> devicesByRoom = {};
    for (var device in devices) {
      final roomName = device['room'] ?? 
          device['deviceName']?.toString().split(' ')[0] ?? 'Lainnya';
      devicesByRoom.putIfAbsent(roomName, () => []);
      devicesByRoom[roomName]!.add(device);
    }

    return Column(
      children: devicesByRoom.entries.map((entry) {
        final roomName = entry.key;
        final roomDevices = entry.value;
        final activeCount = roomDevices.where((d) => d['power'] == true).length;
        final allActive = activeCount == roomDevices.length;

        return GlassCard(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                _getRoomIcon(roomName),
                color: AppColors.primaryAccent,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      roomName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '$activeCount/${roomDevices.length} device aktif',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: allActive,
                onChanged: (value) async {
                  for (var device in roomDevices) {
                    final chipId = device['chip_id'] ?? device['chipId'] ?? device['id'];
                    await _firebaseService.updateDeviceControl(
                      deviceId: chipId,
                      power: value,
                    );
                  }
                },
                activeColor: AppColors.primaryAccent,
              ),
            ],
          ),
        );
      }).toList(),
    );
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
}
