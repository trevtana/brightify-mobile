import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/schedule.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/firebase_service.dart';
import '../../services/notification_service.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/custom_bottom_nav.dart';
import 'add_schedule_dialog.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final NotificationService _notificationService = NotificationService();
  final int _currentIndex = 2; // Schedule tab
  
  Map<String, dynamic>? _selectedDevice;
  List<Map<String, dynamic>> _devices = [];
  StreamSubscription? _deviceSubscription;

  @override
  void initState() {
    super.initState();
    _loadDevices();
  }

  Future<void> _loadDevices() async {
    try {
      final uid = FirebaseService().currentUser?.uid;
      if (uid != null) {
        final devicesStream = _firebaseService.getUserDevices(uid);
        _deviceSubscription = devicesStream.listen((devices) {
          if (mounted) {
            setState(() {
              // Remove duplicates by device ID
              final uniqueDevices = <String, Map<String, dynamic>>{};
              for (final device in devices) {
                final deviceId = device['id'] as String?;
                if (deviceId != null && deviceId.isNotEmpty) {
                  uniqueDevices[deviceId] = device;
                }
              }
              
              _devices = uniqueDevices.values.toList();
              print('📱 Loaded ${_devices.length} unique devices: ${_devices.map((d) => d['id']).toList()}');
              if (_devices.isNotEmpty && _selectedDevice == null) {
                _selectedDevice = _devices.first;
              }
            });
          }
        });
      }
    } catch (e) {
      print('Error loading devices: $e');
    }
  }

  @override
  void dispose() {
    _deviceSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Scaffold(
      backgroundColor: themeProvider.getBackgroundColor(context),
      appBar: AppBar(
        title: Text(
          'Schedule',
          style: TextStyle(
            color: themeProvider.getTextPrimaryColor(context),
          ),
        ),
        backgroundColor: themeProvider.getCardColor(context),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              Icons.add,
              color: AppColors.primaryAccent,
            ),
            onPressed: _showAddScheduleDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Device Selector
          if (_devices.isNotEmpty) _buildDeviceSelector(themeProvider),
          
          // Schedules List
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _firebaseService.getSchedulesStream(
                deviceId: _selectedDevice?['id'],
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryAccent,
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return _buildEmptyState(themeProvider);
                }

                final schedules = snapshot.data!;
                
                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: schedules.length,
                  itemBuilder: (context, index) {
                    final scheduleData = schedules[index];
                    print('🎯 Building schedule card for: ${scheduleData['id']} - ${scheduleData['name']}');
                    
                    try {
                      final schedule = Schedule.fromJson(scheduleData);
                      return _buildScheduleCard(schedule, themeProvider);
                    } catch (e) {
                      print('❌ Error parsing schedule: $e');
                      print('📋 Schedule data: $scheduleData');
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red),
                        ),
                        child: Text(
                          'Error: ${scheduleData['name'] ?? 'Unknown'}\n$e',
                          style: const TextStyle(color: Colors.red),
                        ),
                      );
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddScheduleDialog,
        backgroundColor: AppColors.primaryAccent,
        child: const Icon(Icons.add, color: Colors.black),
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: _currentIndex,
        onTap: _navigateToScreen,
        onCenterTap: () {
          Navigator.pushNamed(context, '/add-home');
        },
      ),
    );
  }

  Widget _buildDeviceSelector(ThemeProvider themeProvider) {
    // Use device ID as value instead of full object to avoid duplicates
    final selectedDeviceId = _selectedDevice?['id'] as String?;
    
    // Ensure selected device ID exists in current devices list
    final deviceIds = _devices.map((device) => device['id'] as String).toSet();
    final validSelectedId = (selectedDeviceId != null && deviceIds.contains(selectedDeviceId)) 
        ? selectedDeviceId 
        : null;
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: themeProvider.getCardColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: themeProvider.getTextMutedColor(context).withValues(alpha: 0.2),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: validSelectedId,
          hint: Text(
            '🏠 Pilih Device',
            style: TextStyle(
              color: themeProvider.getTextSecondaryColor(context),
            ),
          ),
          dropdownColor: themeProvider.getCardColor(context),
          style: TextStyle(
            color: themeProvider.getTextPrimaryColor(context),
          ),
          items: _devices.map((device) {
            final deviceId = device['id'] as String;
            return DropdownMenuItem<String>(
              value: deviceId,
              child: Text(
                '${device['deviceName']} • ${device['roomName']}',
                style: TextStyle(
                  color: themeProvider.getTextPrimaryColor(context),
                ),
              ),
            );
          }).toList(),
          onChanged: (deviceId) {
            if (deviceId != null) {
              final selectedDevice = _devices.firstWhere(
                (device) => device['id'] == deviceId,
                orElse: () => {},
              );
              setState(() {
                _selectedDevice = selectedDevice.isNotEmpty ? selectedDevice : null;
              });
            }
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeProvider themeProvider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.schedule,
            size: 80,
            color: themeProvider.getTextMutedColor(context),
          ),
          const SizedBox(height: 16),
          Text(
            'Belum ada jadwal',
            style: TextStyle(
              fontSize: 18,
              color: themeProvider.getTextSecondaryColor(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + untuk menambah jadwal baru',
            style: TextStyle(
              fontSize: 14,
              color: themeProvider.getTextMutedColor(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleCard(Schedule schedule, ThemeProvider themeProvider) {
    final nextTime = schedule.getNextScheduledTime();
    final isToday = nextTime.day == DateTime.now().day;
    
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      schedule.name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: themeProvider.getTextPrimaryColor(context),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${schedule.deviceName} • ${schedule.roomName}',
                      style: TextStyle(
                        fontSize: 14,
                        color: themeProvider.getTextSecondaryColor(context),
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: schedule.isActive,
                onChanged: (value) {
                  _toggleSchedule(schedule, value);
                },
                activeThumbColor: AppColors.primaryAccent,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: themeProvider.isDarkMode
                  ? AppColors.primaryAccent.withValues(alpha: 0.1)
                  : AppColors.primaryAccent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: AppColors.primaryAccent,
                ),
                const SizedBox(width: 8),
                Text(
                  '${schedule.time.hour.toString().padLeft(2, '0')}:${schedule.time.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    color: AppColors.primaryAccent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (schedule.repeatDays.isNotEmpty) ...[
                  const SizedBox(width: 12),
                  Icon(
                    Icons.repeat,
                    size: 16,
                    color: AppColors.primaryAccent,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatRepeatDays(schedule.repeatDays),
                    style: TextStyle(
                      color: AppColors.primaryAccent,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildActionChip(schedule.action, themeProvider),
              const SizedBox(width: 8),
              if (schedule.action == 'preset')
                _buildPresetChip(schedule.actionData['preset'], themeProvider),
              const Spacer(),
              IconButton(
                icon: Icon(
                  Icons.edit_outlined,
                  color: themeProvider.getTextSecondaryColor(context),
                  size: 20,
                ),
                onPressed: () => _editSchedule(schedule),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 16),
              IconButton(
                icon: Icon(
                  Icons.delete_outline,
                  color: AppColors.error,
                  size: 20,
                ),
                onPressed: () => _deleteSchedule(schedule),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          if (isToday) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Hari ini',
                style: TextStyle(
                  color: AppColors.success,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionChip(String action, ThemeProvider themeProvider) {
    IconData icon;
    String label;
    
    switch (action) {
      case 'power_on':
        icon = Icons.power_settings_new;
        label = 'Nyalakan';
        break;
      case 'power_off':
        icon = Icons.power_off;
        label = 'Matikan';
        break;
      case 'preset':
        icon = Icons.palette;
        label = 'Mode';
        break;
      case 'brightness':
        icon = Icons.brightness_6;
        label = 'Brightness';
        break;
      default:
        icon = Icons.settings;
        label = action;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: themeProvider.getCardColor(context),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: themeProvider.getTextMutedColor(context).withValues(alpha: 0.7),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: themeProvider.getTextSecondaryColor(context)),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: themeProvider.getTextSecondaryColor(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetChip(int? presetId, ThemeProvider themeProvider) {
    final presets = ['Tidur', 'Belajar', 'Santai', 'Nonton', 'Makan', 'Pesta'];
    final preset = presetId != null && presetId < presets.length 
        ? presets[presetId] 
        : 'Custom';
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primaryAccent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        preset,
        style: const TextStyle(
          fontSize: 12,
          color: AppColors.primaryAccent,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _formatRepeatDays(List<String> days) {
    if (days.length == 7) return 'Setiap hari';
    if (days.length == 5 && !days.contains('saturday') && !days.contains('sunday')) {
      return 'Hari kerja';
    }
    if (days.length == 2 && days.contains('saturday') && days.contains('sunday')) {
      return 'Weekend';
    }
    
    final dayMap = {
      'monday': 'Sen',
      'tuesday': 'Sel',
      'wednesday': 'Rab',
      'thursday': 'Kam',
      'friday': 'Jum',
      'saturday': 'Sab',
      'sunday': 'Min',
    };
    
    return days.map((day) => dayMap[day.toLowerCase()] ?? day).join(', ');
  }

  void _showAddScheduleDialog() async {
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user == null) return;

    // Get user devices
    final devicesSnapshot = await _firebaseService.getUserDevices(user.uid).first;
    final devices = devicesSnapshot;

    if (devices.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Belum ada device. Tambahkan device terlebih dahulu.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    if (mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AddScheduleDialog(
            devices: devices,
            firebaseService: _firebaseService,
            notificationService: _notificationService,
          ),
        ),
      );
    }
  }

  void _toggleSchedule(Schedule schedule, bool value) async {
    await _firebaseService.updateSchedule(
      schedule.copyWith(isActive: value),
    );
    
    if (value) {
      // Schedule notifications
      await _notificationService.scheduleReminders(
        scheduleName: schedule.name,
        scheduleTime: schedule.getNextScheduledTime(),
        baseId: schedule.id.hashCode,
      );
    } else {
      // Cancel notifications
      await _notificationService.cancelScheduleNotifications(
        schedule.id.hashCode,
      );
    }
  }

  void _editSchedule(Schedule schedule) async {
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user == null) return;

    // Get user devices
    final devicesSnapshot = await _firebaseService.getUserDevices(user.uid).first;
    final devices = devicesSnapshot;

    if (mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AddScheduleDialog(
            devices: devices,
            firebaseService: _firebaseService,
            notificationService: _notificationService,
            existingSchedule: schedule,
          ),
        ),
      );
    }
  }

  void _deleteSchedule(Schedule schedule) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Jadwal'),
        content: Text('Hapus jadwal "${schedule.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      await _firebaseService.deleteSchedule(schedule.id);
      await _notificationService.cancelScheduleNotifications(
        schedule.id.hashCode,
      );
    }
  }

  void _navigateToScreen(int index) {
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/dashboard');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/devices');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/statistics');
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/settings');
        break;
    }
  }
}
