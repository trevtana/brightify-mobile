import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_input.dart';

class AddHomeScreen extends StatefulWidget {
  const AddHomeScreen({Key? key}) : super(key: key);

  @override
  State<AddHomeScreen> createState() => _AddHomeScreenState();
}

class _AddHomeScreenState extends State<AddHomeScreen> {
  final TextEditingController _deviceNameController = TextEditingController();
  final TextEditingController _chipIdController = TextEditingController();
  final TextEditingController _roomController = TextEditingController();
  
  bool _isLoading = false;
  String _selectedRoom = 'Ruang Tamu';
  
  final List<String> _roomOptions = [
    'Ruang Tamu',
    'Kamar Tidur',
    'Dapur',
    'Kamar Mandi',
    'Ruang Kerja',
    'Ruang Keluarga',
    'Taman',
    'Garasi',
    'Lainnya',
  ];

  @override
  void dispose() {
    _deviceNameController.dispose();
    _chipIdController.dispose();
    _roomController.dispose();
    super.dispose();
  }

  Future<void> _addDevice() async {
    if (_deviceNameController.text.isEmpty || _chipIdController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Semua field harus diisi'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.user;
      
      if (user == null) {
        throw Exception('User tidak login');
      }

      final roomName = _selectedRoom == 'Lainnya' 
          ? _roomController.text 
          : _selectedRoom;

      // Add device to Firestore
      await FirebaseFirestore.instance.collection('devices').add({
        'deviceName': _deviceNameController.text,
        'chipId': _chipIdController.text,
        'room': roomName,
        'userId': user.uid,
        'power': false,
        'brightness': 255,
        'rgb': {'r': 255, 'g': 255, 'b': 255},
        'status': 'offline',
        'speed': 50,
        'createdAt': FieldValue.serverTimestamp(),
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
            content: Text('Gagal menambah device: $e'),
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
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: SafeArea(
        child: SingleChildScrollView(
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
                    const Expanded(
                      child: Text(
                        'Tambah Device',
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

                // Instruction
                GlassCard(
                  gradient: true,
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primaryAccent.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.info_outline,
                          color: AppColors.primaryAccent,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Setup Device',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Pastikan device sudah terhubung ke WiFi dan mendapatkan Chip ID',
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
                ),
                const SizedBox(height: 24),

                // Form
                const Text(
                  'Informasi Device',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),

                // Device Name
                CustomInput(
                  controller: _deviceNameController,
                  label: 'Nama Device',
                  hint: 'Contoh: Lampu Ruang Tamu',
                  prefixIcon: Icons.lightbulb_outline,
                ),
                const SizedBox(height: 16),

                // Chip ID
                CustomInput(
                  controller: _chipIdController,
                  label: 'Chip ID',
                  hint: 'ESP8266_XXXXXX',
                  prefixIcon: Icons.memory,
                ),
                const SizedBox(height: 16),

                // Room Selection
                const Text(
                  'Lokasi/Ruangan',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.cardBackground.withOpacity(0.5),
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedRoom,
                      isExpanded: true,
                      dropdownColor: AppColors.cardBackground,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                      ),
                      onChanged: (value) {
                        setState(() {
                          _selectedRoom = value!;
                        });
                      },
                      items: _roomOptions.map((room) {
                        return DropdownMenuItem(
                          value: room,
                          child: Text(room),
                        );
                      }).toList(),
                    ),
                  ),
                ),

                if (_selectedRoom == 'Lainnya') ...[
                  const SizedBox(height: 16),
                  CustomInput(
                    controller: _roomController,
                    label: 'Nama Ruangan',
                    hint: 'Masukkan nama ruangan',
                    prefixIcon: Icons.room,
                  ),
                ],
                const SizedBox(height: 24),

                // Instructions
                GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Cara mendapatkan Chip ID:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildStep('1', 'Nyalakan device ESP8266'),
                      const SizedBox(height: 8),
                      _buildStep('2', 'Hubungkan ke WiFi "Brightify_Setup"'),
                      const SizedBox(height: 8),
                      _buildStep('3', 'Buka browser, akses 192.168.4.1'),
                      const SizedBox(height: 8),
                      _buildStep('4', 'Setup WiFi dan catat Chip ID'),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Submit Button
                CustomButton(
                  onPressed: _isLoading ? null : _addDevice,
                  text: 'Tambah Device',
                  isLoading: _isLoading,
                  icon: Icons.add,
                ),
                const SizedBox(height: 16),

                // Scan QR Button
                CustomButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Scan QR Code dalam pengembangan'),
                      ),
                    );
                  },
                  text: 'Scan QR Code',
                  variant: ButtonVariant.secondary,
                  icon: Icons.qr_code_scanner,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep(String number, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: AppColors.primaryAccent.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryAccent,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
