import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../../core/constants/app_colors.dart';
import '../../services/firebase_service.dart';
import '../../widgets/glass_card.dart';
import '../../models/preset_mode.dart';

class DeviceScreen extends StatefulWidget {
  final String deviceId;
  final String roomName;

  const DeviceScreen({
    Key? key,
    this.deviceId = '',
    this.roomName = 'Device',
  }) : super(key: key);

  @override
  State<DeviceScreen> createState() => _DeviceScreenState();
}

class _DeviceScreenState extends State<DeviceScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  bool _isLoading = false;
  Color _selectedColor = Colors.white;
  double _brightness = 255;
  int _speed = 50;
  bool _isSliding = false; // Track if user is actively sliding
  Timer? _brightnessDebounce;

  void _applyPreset(PresetMode preset, Map<String, dynamic> device) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get device data first to have homeId and roomName
      final deviceStream = await _firebaseService.getDeviceData(widget.deviceId).first;
      
      // Use chip_id for API calls
      final chipId = deviceStream['chip_id'] ?? deviceStream['chipId'] ?? widget.deviceId;
      await _firebaseService.updateDeviceControl(
        deviceId: chipId,
        homeId: deviceStream['homeId'],
        roomId: deviceStream['roomId'],
        red: preset.red,
        green: preset.green,
        blue: preset.blue,
        brightness: preset.brightness,
      );

      setState(() {
        _selectedColor = Color.fromRGBO(preset.red, preset.green, preset.blue, 1);
        _brightness = preset.brightness.toDouble();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Mode ${preset.name} diterapkan'),
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
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get deviceId from route arguments if not provided
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final deviceId = widget.deviceId.isNotEmpty ? widget.deviceId : (args?['id'] ?? '');
    final roomName = widget.roomName != 'Device' ? widget.roomName : (args?['room'] ?? 'Device');

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: SafeArea(
        child: StreamBuilder<Map<String, dynamic>>(
          stream: _firebaseService.getDeviceData(deviceId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primaryAccent),
              );
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                child: Text(
                  'Device tidak ditemukan',
                  style: TextStyle(color: AppColors.textPrimary),
                ),
              );
            }

            final device = snapshot.data!;

            final isPowerOn = device['power'] == true || device['power'] == 'on';
            final isOnline = device['status'] == 'online';
            final deviceName = device['deviceName'] ?? 'Unknown Device';
            // Get RGB values from separate fields (match web structure)
            final red = device['red'] ?? 255;
            final green = device['green'] ?? 255;
            final blue = device['blue'] ?? 255;
            
            // Update state with current values
            if (_selectedColor == Colors.white) {
              _selectedColor = Color.fromRGBO(
                red,
                green,
                blue,
                1,
              );
            }
            // Only update brightness if user is not actively sliding
            if (!_isSliding) {
              _brightness = (device['brightness'] ?? 255).toDouble();
            }
            _speed = device['speed'] ?? 50;

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
                          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                deviceName,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                roomName,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isOnline 
                                ? AppColors.success.withOpacity(0.2)
                                : AppColors.error.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            isOnline ? 'Online' : 'Offline',
                            style: TextStyle(
                              fontSize: 12,
                              color: isOnline ? AppColors.success : AppColors.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Power Control
                    GlassCard(
                      gradient: true,
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Power',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isPowerOn ? 'Device Menyala' : 'Device Mati',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            child: Transform.scale(
                              scale: 1.2,
                              child: Switch.adaptive(
                                value: isPowerOn,
                                onChanged: isOnline ? (value) async {
                                  // Add haptic feedback
                                  HapticFeedback.lightImpact();
                                  setState(() {
                                    // Optimistic UI update
                                  });
                                  // Use chip_id for API calls
                                  final chipId = device['chip_id'] ?? device['chipId'] ?? deviceId;
                                  await _firebaseService.updateDeviceControl(
                                    deviceId: chipId,
                                    homeId: device['homeId'],
                                    roomId: device['roomId'],
                                    power: value,
                                  );
                                } : null,
                                activeColor: AppColors.primaryAccent,
                                activeTrackColor: AppColors.primaryAccent.withOpacity(0.3),
                                inactiveThumbColor: AppColors.textMuted,
                                inactiveTrackColor: AppColors.cardBackground.withOpacity(0.5),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (!isPowerOn) ...[
                      const SizedBox(height: 16),
                      GlassCard(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: AppColors.warning,
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Nyalakan device untuk mengatur warna dan brightness',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    if (isPowerOn) ...[
                      const SizedBox(height: 20),
                      
                      // Brightness Control
                      GlassCard(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Brightness',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  '${(_brightness / 255 * 100).round()}%',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryAccent,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                activeTrackColor: AppColors.primaryAccent,
                                inactiveTrackColor: AppColors.textSecondary.withOpacity(0.3),
                                thumbColor: AppColors.primaryAccent,
                                overlayColor: AppColors.primaryAccent.withOpacity(0.3),
                              ),
                              child: Slider(
                                value: _brightness,
                                min: 0,
                                max: 255,
                                onChangeStart: (value) {
                                  setState(() {
                                    _isSliding = true;
                                  });
                                },
                                onChanged: (value) {
                                  setState(() {
                                    _brightness = value;
                                  });
                                },
                                onChangeEnd: (value) async {
                                  setState(() {
                                    _isSliding = false;
                                  });
                                  // Debounce API call
                                  _brightnessDebounce?.cancel();
                                  _brightnessDebounce = Timer(const Duration(milliseconds: 300), () async {
                                    // Use chip_id for API calls
                                    final chipId = device['chip_id'] ?? device['chipId'] ?? deviceId;
                                    await _firebaseService.updateDeviceControl(
                                      deviceId: chipId,
                                      homeId: device['homeId'],
                                      roomId: device['roomId'],
                                      brightness: value.round(),
                                    );
                                    print('✅ Device brightness updated to ${value.round()}');
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Color Control
                      GlassCard(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Warna',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            GestureDetector(
                              onTap: _isLoading ? null : () => _showColorPicker(deviceId, device),
                              child: Container(
                                height: 100,
                                decoration: BoxDecoration(
                                  color: _selectedColor,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppColors.textSecondary,
                                    width: 2,
                                  ),
                                ),
                                child: Center(
                                  child: Icon(
                                    Icons.palette,
                                    color: _selectedColor.computeLuminance() > 0.5 
                                        ? Colors.black 
                                        : Colors.white,
                                    size: 32,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Speed Control
                      GlassCard(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Speed Motion',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  '$_speed%',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryAccent,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                activeTrackColor: AppColors.primaryAccent,
                                inactiveTrackColor: AppColors.textSecondary.withOpacity(0.3),
                                thumbColor: AppColors.primaryAccent,
                                overlayColor: AppColors.primaryAccent.withOpacity(0.3),
                              ),
                              child: Slider(
                                value: _speed.toDouble(),
                                min: 0,
                                max: 100,
                                onChanged: (value) {
                                  setState(() {
                                    _speed = value.round();
                                  });
                                },
                                onChangeEnd: (value) async {
                                  // Use chip_id for API calls
                                  final chipId = device['chip_id'] ?? device['chipId'] ?? deviceId;
                                  await _firebaseService.updateDeviceControl(
                                    deviceId: chipId,
                                    homeId: device['homeId'],
                                    roomId: device['roomId'],
                                    speed: value.round(),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Preset Modes
                      const Text(
                        'Mode Preset',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.0,
                        ),
                        itemCount: PresetMode.allModes.length,
                        itemBuilder: (context, index) {
                          final preset = PresetMode.allModes[index];
                          return GlassCard(
                            padding: const EdgeInsets.all(8),
                            onTap: _isLoading ? null : () => _applyPreset(preset, device),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: preset.colors,
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Icon(
                                    preset.icon,
                                    color: AppColors.textPrimary,
                                    size: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  preset.name,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: AppColors.textPrimary,
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
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _showColorPicker(String deviceId, Map<String, dynamic> device) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: const Text(
          'Pilih Warna',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: _selectedColor,
            onColorChanged: (Color color) {
              setState(() {
                _selectedColor = color;
              });
            },
            showLabel: false,
            pickerAreaHeightPercent: 0.8,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Batal',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              // Use chip_id for API calls
              final chipId = device['chip_id'] ?? device['chipId'] ?? deviceId;
              await _firebaseService.updateDeviceControl(
                deviceId: chipId,
                homeId: device['homeId'],
                roomId: device['roomId'],
                red: _selectedColor.red,
                green: _selectedColor.green,
                blue: _selectedColor.blue,
              );
            },
            child: const Text(
              'Simpan',
              style: TextStyle(color: AppColors.primaryAccent),
            ),
          ),
        ],
      ),
    );
  }
}
