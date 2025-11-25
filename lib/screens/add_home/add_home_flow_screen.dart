import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_input.dart';

class AddHomeFlowScreen extends StatefulWidget {
  const AddHomeFlowScreen({Key? key}) : super(key: key);

  @override
  State<AddHomeFlowScreen> createState() => _AddHomeFlowScreenState();
}

class _AddHomeFlowScreenState extends State<AddHomeFlowScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  bool _isLoading = false;

  // Step 1: Home/Property
  final TextEditingController _homeNameController = TextEditingController();
  final TextEditingController _homeAddressController = TextEditingController();
  String? _selectedHomeId;
  String? _selectedHomeName;

  // Step 2: Room
  final TextEditingController _roomNameController = TextEditingController();
  String _selectedRoomType = 'Ruang Tamu';
  String? _selectedRoomName;

  // Step 3: Device
  final TextEditingController _deviceNameController = TextEditingController();
  final TextEditingController _chipIdController = TextEditingController();
  final TextEditingController _pairingCodeController = TextEditingController();

  final List<String> _roomTypes = [
    'Ruang Tamu',
    'Kamar Tidur',
    'Dapur',
    'Kamar Mandi',
    'Ruang Kerja',
    'Ruang Keluarga',
    'Taman',
    'Garasi',
    'Teras',
    'Gudang',
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _homeNameController.dispose();
    _homeAddressController.dispose();
    _roomNameController.dispose();
    _deviceNameController.dispose();
    _chipIdController.dispose();
    _pairingCodeController.dispose();
    super.dispose();
  }

  Future<void> _nextStep() async {
    if (_currentStep < 2) {
      setState(() {
        _currentStep++;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _previousStep() async {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _addHome() async {
    if (_homeNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nama rumah harus diisi'),
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

      // Add home to user's homes subcollection (match web structure)
      final docRef = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('homes')
          .add({
            'name': _homeNameController.text,
            'address': _homeAddressController.text,
            'rooms': {}, // Initialize empty rooms map
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });

      setState(() {
        _selectedHomeId = docRef.id;
        _selectedHomeName = _homeNameController.text;
      });

      _nextStep();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menambah rumah: $e'),
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

  Future<void> _addRoom() async {
    if (_roomNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nama ruangan harus diisi'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Add room to Firestore
      // Add room to home as nested field (match web structure)
      await FirebaseFirestore.instance
          .collection('users')
          .doc(Provider.of<AuthProvider>(context, listen: false).user!.uid)
          .collection('homes')
          .doc(_selectedHomeId)
          .update({
            'rooms.${_roomNameController.text}': {
              'name': _roomNameController.text,
              'room_name':
                  _roomNameController.text, // Added for Web App compatibility
              'location':
                  'Lantai 1', // Default location for Web App compatibility
              'type': _selectedRoomType,
              'devices': {}, // Initialize empty devices map
              'createdAt': FieldValue.serverTimestamp(),
            },
            'updatedAt': FieldValue.serverTimestamp(),
          });

      setState(() {
        _selectedRoomName = _roomNameController.text;
      });

      _nextStep();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menambah ruangan: $e'),
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

  Future<void> _addDevice() async {
    if (_deviceNameController.text.isEmpty ||
        _chipIdController.text.isEmpty ||
        _pairingCodeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Semua field harus diisi'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Validate pairing code (example: 6 digits)
    if (_pairingCodeController.text.length != 6 ||
        !RegExp(r'^\d{6}$').hasMatch(_pairingCodeController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pairing code harus 6 digit angka'),
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

      // Add device as nested field in room (match web structure)
      // Use Chip ID as device ID for consistency with backend
      final deviceId = _chipIdController.text.trim();

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('homes')
          .doc(_selectedHomeId)
          .update({
            'rooms.$_selectedRoomName.devices.$deviceId': {
              'device_name':
                  _deviceNameController.text, // snake_case for backend
              'deviceName':
                  _deviceNameController.text, // camelCase for mobile legacy
              'chip_id': _chipIdController.text, // snake_case for backend
              'chipId': _chipIdController.text, // camelCase for mobile legacy
              'pairing_code':
                  _pairingCodeController.text, // snake_case for backend
              'pairingCode':
                  _pairingCodeController.text, // camelCase for mobile legacy
              'device_type': 'LED_STRIP',
              'power': false,
              'brightness': 255,
              'red': 255,
              'green': 255,
              'blue': 255,
              'preset': 0,
              'status': 'offline',
              'speed': 50,
              'createdAt': FieldValue.serverTimestamp(),
            },
            'updatedAt': FieldValue.serverTimestamp(),
          });

      // Add delay for initialization (match web app behavior)
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Menginisialisasi device... mohon tunggu'),
            backgroundColor: AppColors.primaryAccent,
            duration: Duration(seconds: 2),
          ),
        );
      }

      // Wait for backend to process (3 seconds)
      await Future.delayed(const Duration(seconds: 3));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Device berhasil ditambahkan!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pushReplacementNamed(context, '/dashboard');
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
        child: Column(
          children: [
            // Header with progress
            Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    children: [
                      if (_currentStep > 0)
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back,
                            color: AppColors.textPrimary,
                          ),
                          onPressed: _previousStep,
                        )
                      else
                        IconButton(
                          icon: const Icon(
                            Icons.close,
                            color: AppColors.textPrimary,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      const Expanded(
                        child: Text(
                          'Setup Device',
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
                  const SizedBox(height: 20),
                  // Progress Steps
                  Row(
                    children: [
                      _buildStepIndicator(0, 'Rumah'),
                      Expanded(child: _buildStepLine(0)),
                      _buildStepIndicator(1, 'Ruangan'),
                      Expanded(child: _buildStepLine(1)),
                      _buildStepIndicator(2, 'Device'),
                    ],
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildHomeStep(),
                  _buildRoomStep(),
                  _buildDeviceStep(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator(int step, String label) {
    final isActive = _currentStep >= step;
    final isComplete = _currentStep > step;

    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isComplete
                ? AppColors.success
                : isActive
                ? AppColors.primaryAccent
                : AppColors.cardBackground,
            border: Border.all(
              color: isActive
                  ? AppColors.primaryAccent
                  : AppColors.cardBackground,
              width: 2,
            ),
          ),
          child: Center(
            child: isComplete
                ? const Icon(
                    Icons.check,
                    color: AppColors.primaryBackground,
                    size: 20,
                  )
                : Text(
                    '${step + 1}',
                    style: TextStyle(
                      color: isActive
                          ? AppColors.primaryBackground
                          : AppColors.textSecondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isActive ? AppColors.textPrimary : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine(int step) {
    final isActive = _currentStep > step;

    return Container(
      height: 2,
      margin: const EdgeInsets.only(bottom: 20),
      color: isActive ? AppColors.primaryAccent : AppColors.cardBackground,
    );
  }

  Widget _buildHomeStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Illustration
          GlassCard(
            gradient: true,
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primaryAccent.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.home_outlined,
                    size: 48,
                    color: AppColors.primaryAccent,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Tambah Rumah',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Mulai dengan menambahkan rumah atau property Anda',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Or select existing home
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(context.read<AuthProvider>().user?.uid ?? '')
                .collection('homes')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Atau pilih rumah yang sudah ada:',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...snapshot.data!.docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return GlassCard(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        onTap: () {
                          setState(() {
                            _selectedHomeId = doc.id;
                            _selectedHomeName = data['name'];
                          });
                          _nextStep();
                        },
                        child: Row(
                          children: [
                            Icon(Icons.home, color: AppColors.primaryAccent),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    data['name'] ?? 'Rumah',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  if (data['address'] != null &&
                                      data['address'].toString().isNotEmpty)
                                    Text(
                                      data['address'],
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios,
                              color: AppColors.textSecondary,
                              size: 16,
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    const SizedBox(height: 12),
                    const Divider(color: AppColors.cardBackground),
                    const SizedBox(height: 12),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),

          // Form for new home
          const Text(
            'Tambah Rumah Baru:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),

          CustomInput(
            controller: _homeNameController,
            label: 'Nama Rumah',
            hint: 'Contoh: Rumah Utama',
            prefixIcon: Icons.home,
          ),
          const SizedBox(height: 16),

          CustomInput(
            controller: _homeAddressController,
            label: 'Alamat (Opsional)',
            hint: 'Contoh: Jl. Sudirman No. 1',
            prefixIcon: Icons.location_on,
          ),
          const SizedBox(height: 24),

          CustomButton(
            onPressed: _isLoading ? null : _addHome,
            text: 'Lanjutkan',
            isLoading: _isLoading,
            icon: Icons.arrow_forward,
          ),
        ],
      ),
    );
  }

  Widget _buildRoomStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info Card
          GlassCard(
            gradient: true,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.home, color: AppColors.primaryAccent),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Rumah:',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        _selectedHomeName ?? 'Rumah',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          const Text(
            'Tambah Ruangan',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Pilih ruangan di mana device akan dipasang',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),

          // Room Name
          CustomInput(
            controller: _roomNameController,
            label: 'Nama Ruangan',
            hint: 'Contoh: Kamar Utama',
            prefixIcon: Icons.room_preferences,
          ),
          const SizedBox(height: 16),

          // Room Type
          const Text(
            'Tipe Ruangan',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
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
                value: _selectedRoomType,
                isExpanded: true,
                dropdownColor: AppColors.cardBackground,
                style: const TextStyle(color: AppColors.textPrimary),
                onChanged: (value) {
                  setState(() {
                    _selectedRoomType = value!;
                  });
                },
                items: _roomTypes.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Row(
                      children: [
                        Icon(
                          _getRoomIcon(type),
                          color: AppColors.primaryAccent,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(type),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 24),

          CustomButton(
            onPressed: _isLoading ? null : _addRoom,
            text: 'Lanjutkan',
            isLoading: _isLoading,
            icon: Icons.arrow_forward,
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info Cards
          GlassCard(
            gradient: true,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.home,
                          color: AppColors.primaryAccent,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _selectedHomeName ?? 'Rumah',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.room,
                          color: AppColors.primaryAccent,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _selectedRoomName ?? 'Ruangan',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          const Text(
            'Tambah Device',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Masukkan informasi device untuk melakukan pairing',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),

          // Device Name
          CustomInput(
            controller: _deviceNameController,
            label: 'Nama Device',
            hint: 'Contoh: Lampu Utama',
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

          // Pairing Code
          CustomInput(
            controller: _pairingCodeController,
            label: 'Pairing Code',
            hint: '6 digit code (123456)',
            prefixIcon: Icons.lock_outline,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 24),

          // Instructions
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppColors.warning,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Cara mendapatkan informasi device:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildInstruction('1', 'Nyalakan device ESP8266'),
                const SizedBox(height: 8),
                _buildInstruction(
                  '2',
                  'Tekan tombol reset 3x untuk mode pairing',
                ),
                const SizedBox(height: 8),
                _buildInstruction('3', 'LED akan berkedip biru (mode pairing)'),
                const SizedBox(height: 8),
                _buildInstruction(
                  '4',
                  'Lihat Chip ID dan Pairing Code di LCD/Serial',
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Scan QR dalam pengembangan'),
                      ),
                    );
                  },
                  text: 'Scan QR',
                  variant: ButtonVariant.secondary,
                  icon: Icons.qr_code_scanner,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomButton(
                  onPressed: _isLoading ? null : _addDevice,
                  text: 'Pairing',
                  isLoading: _isLoading,
                  icon: Icons.link,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInstruction(String number, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: AppColors.primaryAccent.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                fontSize: 11,
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

  IconData _getRoomIcon(String type) {
    switch (type) {
      case 'Ruang Tamu':
        return Icons.weekend;
      case 'Kamar Tidur':
        return Icons.bed;
      case 'Dapur':
        return Icons.kitchen;
      case 'Kamar Mandi':
        return Icons.bathtub_outlined;
      case 'Ruang Kerja':
        return Icons.work_outline;
      case 'Ruang Keluarga':
        return Icons.family_restroom;
      case 'Taman':
        return Icons.yard;
      case 'Garasi':
        return Icons.garage;
      case 'Teras':
        return Icons.deck;
      case 'Gudang':
        return Icons.storage;
      default:
        return Icons.room;
    }
  }
}
