import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/theme_provider.dart';

class AddDeviceDialog extends StatefulWidget {
  final String homeId;
  final String homeName;
  final String roomId;
  final String roomName;

  const AddDeviceDialog({
    Key? key,
    required this.homeId,
    required this.homeName,
    required this.roomId,
    required this.roomName,
  }) : super(key: key);

  @override
  State<AddDeviceDialog> createState() => _AddDeviceDialogState();
}

class _AddDeviceDialogState extends State<AddDeviceDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _chipIdController = TextEditingController();
  final _pairingCodeController = TextEditingController();
  String _deviceType = 'LED_STRIP';
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _chipIdController.dispose();
    _pairingCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: themeProvider.getBackgroundColor(context),
      appBar: AppBar(
        title: const Text('Tambah Device'),
        backgroundColor: themeProvider.getCardColor(context),
        elevation: 0,
        iconTheme: IconThemeData(
          color: themeProvider.getTextPrimaryColor(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Room Info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primaryAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: AppColors.primaryAccent,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Menambah device ke:',
                            style: TextStyle(
                              fontSize: 12,
                              color: themeProvider.getTextMutedColor(context),
                            ),
                          ),
                          Text(
                            widget.roomName,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: themeProvider.getTextPrimaryColor(context),
                            ),
                          ),
                          Text(
                            widget.homeName,
                            style: TextStyle(
                              fontSize: 12,
                              color: themeProvider.getTextSecondaryColor(
                                context,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Device Name
              Text(
                'Nama Device',
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
                  hintText: 'Contoh: Lampu kamar',
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
                  prefixIcon: const Icon(Icons.lightbulb_outline),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Nama device tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Device Type
              Text(
                'Tipe Device',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: themeProvider.getTextSecondaryColor(context),
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _deviceType,
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
                  prefixIcon: const Icon(Icons.category_outlined),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'LED_STRIP',
                    child: Text('LED Strip'),
                  ),
                  DropdownMenuItem(
                    value: 'SMART_BULB',
                    child: Text('Smart Bulb'),
                  ),
                  DropdownMenuItem(
                    value: 'RGB_LIGHT',
                    child: Text('RGB Light'),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _deviceType = value!;
                  });
                },
              ),
              const SizedBox(height: 20),

              // Chip ID
              Text(
                'Chip ID',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: themeProvider.getTextSecondaryColor(context),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _chipIdController,
                style: TextStyle(
                  color: themeProvider.getTextPrimaryColor(context),
                ),
                decoration: InputDecoration(
                  hintText: 'Contoh: D92F2B14',
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
                  prefixIcon: const Icon(Icons.memory),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Chip ID tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Pairing Code
              Text(
                'Pairing Code',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: themeProvider.getTextSecondaryColor(context),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _pairingCodeController,
                style: TextStyle(
                  color: themeProvider.getTextPrimaryColor(context),
                ),
                decoration: InputDecoration(
                  hintText: 'Contoh: 195368',
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
                  prefixIcon: const Icon(Icons.lock_outline),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Pairing code tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitDevice,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryAccent,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.black,
                            ),
                          ),
                        )
                      : const Text(
                          'Tambah Device',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submitDevice() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Use chip ID as device ID (like web app does)
      final deviceId = _chipIdController.text.toUpperCase();

      // Get current user ID
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not logged in');

      // Add device to nested map structure
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('homes')
          .doc(widget.homeId)
          .update({
            'rooms.${widget.roomName}.devices.$deviceId': {
              // Use room name as key
              'device_name': _nameController.text,
              'deviceName': _nameController.text, // Web uses both fields
              'type': _deviceType,
              'chip_id': deviceId, // snake_case for backend
              'chipId': deviceId, // camelCase for mobile legacy
              'pairing_code':
                  _pairingCodeController.text, // snake_case for backend
              'pairingCode':
                  _pairingCodeController.text, // camelCase for mobile legacy
              'power': false,
              'brightness': 255,
              'red': 255,
              'green': 255,
              'blue': 255,
              'preset': 0,
              'status': 'offline',
              'speed': 50,
              'createdAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            },
            'updatedAt': FieldValue.serverTimestamp(),
          });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Device berhasil ditambahkan'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
