import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/schedule.dart';
import '../../models/preset_mode.dart';
import '../../providers/theme_provider.dart';
import '../../services/firebase_service.dart';
import '../../services/notification_service.dart';
import '../../widgets/glass_card.dart';

class AddScheduleDialog extends StatefulWidget {
  final List<Map<String, dynamic>> devices;
  final FirebaseService firebaseService;
  final NotificationService notificationService;
  final Schedule? existingSchedule;

  const AddScheduleDialog({super.key,
    required this.devices,
    required this.firebaseService,
    required this.notificationService,
    this.existingSchedule,
  });

  @override
  State<AddScheduleDialog> createState() => _AddScheduleDialogState();
}

class _AddScheduleDialogState extends State<AddScheduleDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  
  Map<String, dynamic>? _selectedDevice;
  String _selectedAction = 'power_on';
  TimeOfDay _selectedTime = TimeOfDay.now();
  List<String> _selectedDays = [];
  bool _isActive = true;
  
  // For preset action
  String _selectedPreset = 'Tidur';
  
  // For brightness action
  double _selectedBrightness = 255;

  @override
  void initState() {
    super.initState();
    
    if (widget.existingSchedule != null) {
      final schedule = widget.existingSchedule!;
      _nameController.text = schedule.name;
      _selectedAction = schedule.action;
      _selectedTime = TimeOfDay(hour: schedule.time.hour, minute: schedule.time.minute);
      _selectedDays = List.from(schedule.repeatDays);
      _isActive = schedule.isActive;
      
      // Find device
      _selectedDevice = widget.devices.firstWhere(
        (d) => d['id'] == schedule.deviceId,
        orElse: () => widget.devices.first,
      );
      
      // Load action data
      if (schedule.action == 'preset' && schedule.actionData['preset'] != null) {
        _selectedPreset = schedule.actionData['preset'];
      }
      if (schedule.action == 'brightness' && schedule.actionData['brightness'] != null) {
        _selectedBrightness = schedule.actionData['brightness'].toDouble();
      }
    } else {
      _selectedDevice = widget.devices.first;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Scaffold(
      backgroundColor: themeProvider.getBackgroundColor(context),
      appBar: AppBar(
        title: Text(
          widget.existingSchedule != null ? 'Edit Jadwal' : 'Tambah Jadwal',
          style: TextStyle(
            color: themeProvider.getTextPrimaryColor(context),
          ),
        ),
        backgroundColor: themeProvider.getCardColor(context),
        elevation: 0,
        iconTheme: IconThemeData(
          color: themeProvider.getTextPrimaryColor(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Name
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nama Jadwal',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: themeProvider.getTextSecondaryColor(context),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _nameController,
                    style: TextStyle(
                      color: themeProvider.getTextPrimaryColor(context),
                    ),
                    decoration: InputDecoration(
                      hintText: 'Contoh: Lampu Pagi',
                      hintStyle: TextStyle(
                        color: themeProvider.getTextMutedColor(context),
                      ),
                      filled: true,
                      fillColor: themeProvider.isDarkMode
                          ? AppColors.inputBackground
                          : Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Nama jadwal tidak boleh kosong';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Device Selection
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Device',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: themeProvider.getTextSecondaryColor(context),
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<Map<String, dynamic>>(
                    initialValue: _selectedDevice,
                    dropdownColor: themeProvider.getCardColor(context),
                    style: TextStyle(
                      color: themeProvider.getTextPrimaryColor(context),
                    ),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: themeProvider.isDarkMode
                          ? AppColors.inputBackground
                          : Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    items: widget.devices.map((device) {
                      return DropdownMenuItem(
                        value: device,
                        child: Text(
                          '${device['deviceName']} • ${device['roomName']}',
                          style: TextStyle(
                            color: themeProvider.getTextPrimaryColor(context),
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedDevice = value;
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Time Selection
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Waktu',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: themeProvider.getTextSecondaryColor(context),
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: _selectedTime,
                        builder: (context, child) {
                          return Theme(
                            data: ThemeData.dark().copyWith(
                              colorScheme: const ColorScheme.dark(
                                primary: AppColors.primaryAccent,
                                onSurface: AppColors.textPrimary,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (time != null) {
                        setState(() {
                          _selectedTime = time;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: themeProvider.isDarkMode
                            ? AppColors.inputBackground
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryAccent,
                            ),
                          ),
                          const Icon(
                            Icons.access_time,
                            color: AppColors.primaryAccent,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Repeat Days
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ulangi',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: themeProvider.getTextSecondaryColor(context),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildDayChip('Sen', 'monday', themeProvider),
                      _buildDayChip('Sel', 'tuesday', themeProvider),
                      _buildDayChip('Rab', 'wednesday', themeProvider),
                      _buildDayChip('Kam', 'thursday', themeProvider),
                      _buildDayChip('Jum', 'friday', themeProvider),
                      _buildDayChip('Sab', 'saturday', themeProvider),
                      _buildDayChip('Min', 'sunday', themeProvider),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Action Selection
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Aksi',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: themeProvider.getTextSecondaryColor(context),
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedAction,
                    dropdownColor: themeProvider.getCardColor(context),
                    style: TextStyle(
                      color: themeProvider.getTextPrimaryColor(context),
                    ),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: themeProvider.isDarkMode
                          ? AppColors.inputBackground
                          : Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'power_on', child: Text('Nyalakan')),
                      DropdownMenuItem(value: 'power_off', child: Text('Matikan')),
                      DropdownMenuItem(value: 'preset', child: Text('Mode Preset')),
                      DropdownMenuItem(value: 'brightness', child: Text('Atur Brightness')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedAction = value!;
                      });
                    },
                  ),
                  
                  // Additional options based on action
                  if (_selectedAction == 'preset') ...[
                    const SizedBox(height: 12),
                    Text(
                      'Pilih Preset',
                      style: TextStyle(
                        fontSize: 14,
                        color: themeProvider.getTextSecondaryColor(context),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: PresetMode.allModes.map((preset) {
                        final isSelected = _selectedPreset == preset.name;
                        return InkWell(
                          onTap: () {
                            setState(() {
                              _selectedPreset = preset.name;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              gradient: isSelected ? LinearGradient(
                                colors: preset.colors,
                              ) : null,
                              color: !isSelected
                                  ? themeProvider.getCardColor(context)
                                  : null,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.transparent
                                    : themeProvider.getTextMutedColor(context).withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              preset.name,
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : themeProvider.getTextPrimaryColor(context),
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                  
                  if (_selectedAction == 'brightness') ...[
                    const SizedBox(height: 12),
                    Text(
                      'Brightness: ${_selectedBrightness.round()}',
                      style: TextStyle(
                        fontSize: 14,
                        color: themeProvider.getTextSecondaryColor(context),
                      ),
                    ),
                    Slider(
                      value: _selectedBrightness,
                      min: 0,
                      max: 255,
                      divisions: 255,
                      activeColor: AppColors.primaryAccent,
                      onChanged: (value) {
                        setState(() {
                          _selectedBrightness = value;
                        });
                      },
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Save Button
            ElevatedButton(
              onPressed: _saveSchedule,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryAccent,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                widget.existingSchedule != null ? 'Simpan Perubahan' : 'Tambah Jadwal',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayChip(String label, String value, ThemeProvider themeProvider) {
    final isSelected = _selectedDays.contains(value);
    
    return InkWell(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedDays.remove(value);
          } else {
            _selectedDays.add(value);
          }
        });
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryAccent
              : themeProvider.getCardColor(context),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryAccent
                : themeProvider.getTextMutedColor(context).withValues(alpha: 0.3),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? Colors.black
                  : themeProvider.getTextPrimaryColor(context),
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  void _saveSchedule() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedDevice == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih device terlebih dahulu'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Build action data
    Map<String, dynamic> actionData = {};
    if (_selectedAction == 'preset') {
      final preset = PresetMode.allModes.firstWhere(
        (p) => p.name == _selectedPreset,
        orElse: () => PresetMode.allModes.first,
      );
      actionData = {
        'preset': preset.name,
        'red': preset.red,
        'green': preset.green,
        'blue': preset.blue,
        'brightness': preset.brightness,
      };
    } else if (_selectedAction == 'brightness') {
      actionData = {
        'brightness': _selectedBrightness.round(),
      };
    } else if (_selectedAction == 'power_on') {
      actionData = {'power': true};
    } else if (_selectedAction == 'power_off') {
      actionData = {'power': false};
    }

    final now = DateTime.now();
    final scheduleTime = DateTime(
      now.year,
      now.month,
      now.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    try {
      if (widget.existingSchedule != null) {
        // Update existing schedule
        final updatedSchedule = widget.existingSchedule!.copyWith(
          name: _nameController.text,
          deviceId: _selectedDevice!['id'],
          deviceName: _selectedDevice!['deviceName'],
          homeId: _selectedDevice!['homeId'],
          homeName: _selectedDevice!['homeName'], // Add homeName
          roomId: _selectedDevice!['roomId'],
          roomName: _selectedDevice!['roomName'],
          action: _selectedAction,
          actionData: actionData,
          time: scheduleTime,
          repeatDays: _selectedDays,
          isActive: _isActive,
          updatedAt: DateTime.now(),
        );
        
        await widget.firebaseService.updateSchedule(updatedSchedule);
        
        // Update notifications
        if (_isActive) {
          await widget.notificationService.scheduleReminders(
            scheduleName: updatedSchedule.name,
            scheduleTime: updatedSchedule.getNextScheduledTime(),
            baseId: updatedSchedule.id.hashCode,
          );
        }
      } else {
        // Create new schedule
        final schedule = Schedule(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: _nameController.text,
          deviceId: _selectedDevice!['id'],
          deviceName: _selectedDevice!['deviceName'],
          homeId: _selectedDevice!['homeId'],
          homeName: _selectedDevice!['homeName'], // Add homeName
          roomId: _selectedDevice!['roomId'],
          roomName: _selectedDevice!['roomName'],
          action: _selectedAction,
          actionData: actionData,
          time: scheduleTime,
          repeatDays: _selectedDays,
          isActive: true,
          createdAt: DateTime.now(),
        );
        
        await widget.firebaseService.addSchedule(schedule.toJson());
        
        // Schedule notifications
        await widget.notificationService.scheduleReminders(
          scheduleName: schedule.name,
          scheduleTime: schedule.getNextScheduledTime(),
          baseId: schedule.id.hashCode,
        );
      }
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.existingSchedule != null
                  ? 'Jadwal berhasil diperbarui'
                  : 'Jadwal berhasil ditambahkan',
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan jadwal: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
