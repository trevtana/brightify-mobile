import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../services/firebase_service.dart';
import '../../widgets/custom_bottom_nav.dart';

class DevicesScreen extends StatefulWidget {
  const DevicesScreen({Key? key}) : super(key: key);

  @override
  State<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends State<DevicesScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  int _currentIndex = 1; // Devices tab

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    if (user == null) {
      print('⚠️ Devices: User is NULL, redirecting to login');
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
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const Expanded(
                    child: Text(
                      'Semua Device',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add, color: AppColors.primaryAccent),
                    onPressed: () => _showAddDeviceDialog(),
                  ),
                ],
              ),
            ),
            // Device List
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: _firebaseService.getUserDevices(user.uid),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppColors.primaryAccent),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error: ${snapshot.error}',
                        style: const TextStyle(color: AppColors.error),
                      ),
                    );
                  }

                  final allDevices = snapshot.data ?? [];
                  
                  // Filter unique devices by chip_id to avoid duplicates
                  final Map<String, Map<String, dynamic>> uniqueDevicesMap = {};
                  for (var device in allDevices) {
                    final chipId = device['chip_id'] ?? device['chipId'] ?? device['id'];
                    // Keep the device with device_name field (not generic names)
                    if (!uniqueDevicesMap.containsKey(chipId) || 
                        (device['deviceName'] != null && device['deviceName'] != 'LED Strip')) {
                      uniqueDevicesMap[chipId] = device;
                    }
                  }
                  
                  final devices = uniqueDevicesMap.values.toList();

                  if (devices.isEmpty) {
                    return _buildEmptyState();
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: devices.length,
                    itemBuilder: (context, index) {
                      final device = devices[index];
                      return _buildDeviceCard(device);
                    },
                  );
                },
              ),
            ),
          ],
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
          Navigator.pushNamed(context, '/add-home').then((result) {
            if (result == true) {
              setState(() {});
            }
          });
        },
      ),
    );
  }

  Widget _buildDeviceCard(Map<String, dynamic> device) {
    final isOnline = device['status'] == 'online';
    final isPowerOn = device['power'] == true || device['power'] == 'on';
    final deviceName = device['deviceName'] ?? 'Unknown Device';
    final roomName = device['roomName'] ?? 'Unknown';
    final chipId = device['chip_id'] ?? device['chipId'] ?? 'N/A';
    // Get RGB from separate fields
    final red = device['red'] ?? 255;
    final green = device['green'] ?? 255;
    final blue = device['blue'] ?? 255;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: isPowerOn 
          ? LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.cardBackground,
                AppColors.cardBackground.withOpacity(0.95),
              ],
            )
          : null,
        color: !isPowerOn ? AppColors.cardBackground : null,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isPowerOn 
            ? AppColors.primaryAccent.withOpacity(0.3)
            : AppColors.cardBackground.withOpacity(0.5),
          width: 1,
        ),
        boxShadow: isPowerOn
          ? [
              BoxShadow(
                color: Color.fromRGBO(red, green, blue, 0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ]
          : [],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.pushNamed(
              context,
              '/device/${device['id']}/$roomName',
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Modern Device Icon
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: isPowerOn
                      ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.primaryAccent.withOpacity(0.2),
                            AppColors.primaryAccent.withOpacity(0.1),
                          ],
                        )
                      : null,
                    color: !isPowerOn 
                      ? AppColors.textSecondary.withOpacity(0.1)
                      : null,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isPowerOn
                        ? AppColors.primaryAccent.withOpacity(0.3)
                        : AppColors.textSecondary.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 600),
                        tween: Tween<double>(
                          begin: isPowerOn ? 0.8 : 1.0,
                          end: isPowerOn ? 1.0 : 0.8,
                        ),
                        builder: (context, scale, child) {
                          return Transform.scale(
                            scale: scale,
                            child: Icon(
                              Icons.lightbulb_rounded,
                              color: isPowerOn
                                ? AppColors.primaryAccent
                                : AppColors.textSecondary,
                              size: 30,
                            ),
                          );
                        },
                      ),
                      // Status indicator
                      Positioned(
                        right: 2,
                        top: 2,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isOnline ? AppColors.success : AppColors.error,
                            border: Border.all(
                              color: AppColors.cardBackground,
                              width: 2,
                            ),
                            boxShadow: isOnline
                              ? [
                                  BoxShadow(
                                    color: AppColors.success.withOpacity(0.4),
                                    blurRadius: 4,
                                  ),
                                ]
                              : [],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // Device Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        deviceName,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              roomName,
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        chipId,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
                // RGB Color & Power
                Column(
                  children: [
                    // RGB Color Display
                    if (isPowerOn)
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color.fromRGBO(red, green, blue, 1.0),
                          border: Border.all(
                            color: AppColors.textSecondary.withOpacity(0.3),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Color.fromRGBO(red, green, blue, 0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    if (!isPowerOn)
                      Icon(
                        Icons.power_settings_new,
                        color: AppColors.textSecondary,
                        size: 28,
                      ),
                  ],
                ),
                const SizedBox(width: 8),
                // Power Toggle
                Transform.scale(
                  scale: 1.1,
                  child: Switch.adaptive(
                    value: isPowerOn,
                    onChanged: (value) async {
                      HapticFeedback.lightImpact();
                      // Use chip_id or chipId as the deviceId for API calls
                      final chipId = device['chip_id'] ?? device['chipId'] ?? device['id'];
                      await _firebaseService.updateDeviceControl(
                        deviceId: chipId,
                        homeId: device['homeId'],
                        roomId: device['roomName'] ?? device['roomId'],
                        power: value,
                      );
                    },
                    activeColor: AppColors.primaryAccent,
                    activeTrackColor: AppColors.primaryAccent.withOpacity(0.3),
                    inactiveThumbColor: AppColors.textSecondary,
                    inactiveTrackColor: AppColors.textSecondary.withOpacity(0.2),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.devices_other,
            size: 80,
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
            'Tambahkan device untuk mulai',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showAddDeviceDialog,
            icon: const Icon(Icons.add),
            label: const Text('Tambah Device'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryAccent,
              foregroundColor: AppColors.primaryBackground,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddDeviceDialog() {
    Navigator.pushNamed(context, '/add-home').then((result) {
      // Refresh devices after adding
      if (result == true) {
        setState(() {});
      }
    });
  }

  void _navigateToScreen(int index) {
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/dashboard');
        break;
      case 1:
        // Already on devices
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
