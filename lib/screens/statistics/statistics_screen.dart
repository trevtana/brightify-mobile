import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../services/firebase_service.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/custom_bottom_nav.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({Key? key}) : super(key: key);

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  int _currentIndex = 2; // Statistics tab
  String _selectedPeriod = 'Hari Ini';

  // Calculate realistic LED power consumption (same as web)
  double _calculateLEDPower(Map<String, dynamic> device) {
    const double voltage = 5.0; // Volts
    const double maxSupplyCurrent = 2.0; // Amperes (from 5V 2A power supply)
    const int ledCount = 60; // LEDs in 1m strip
    const double maxCurrentPerLED = 0.06; // Amperes at full brightness white
    
    final int brightness = device['brightness'] ?? 128; // 0-255 range
    final double brightnessPercent = brightness / 255.0;
    
    // Check if device is on
    final bool isOn = device['power'] == true;
    if (!isOn) {
      // Standby power: ~5mA for the controller
      return 0.025; // 5V × 0.005A = 0.025W
    }
    
    // Get RGB values to calculate color factor
    final int r = device['red'] ?? 255;
    final int g = device['green'] ?? 255;
    final int b = device['blue'] ?? 255;
    
    // Color factor: each channel contributes to total current
    // White (255,255,255) = 3 channels = 100%
    // Single color (255,0,0) = 1 channel = 33%
    final double colorIntensity = (r + g + b) / (255.0 * 3);
    
    // Calculate current per LED based on brightness and color
    // I_LED = MAX_I × brightness% × color_intensity
    final double currentPerLED = maxCurrentPerLED * brightnessPercent * colorIntensity;
    
    // Total current for all LEDs
    double totalCurrent = currentPerLED * ledCount;
    
    // Safety limit: don't exceed power supply rating
    if (totalCurrent > maxSupplyCurrent) {
      totalCurrent = maxSupplyCurrent;
    }
    
    // Calculate power: P = V × I
    final double power = voltage * totalCurrent;
    
    // Return power in Watts, rounded to 2 decimals
    return (power * 100).round() / 100.0;
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    if (user == null) {
      print('⚠️ Statistics: User is NULL, redirecting to login');
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

            // Calculate statistics
            final activeDevices = devices.where((d) => d['power'] == true).length;
            final totalDevices = devices.length;
            final onlineDevices = devices.where((d) => d['status'] == 'online').length;
            
            // Realistic LED power calculation (same as web)
            double totalEnergyUsage = 0;
            for (var device in devices) {
              final power = _calculateLEDPower(device);
              totalEnergyUsage += power; // Power in Watts
            }
            // Realistic usage calculation (same as web)
            // Average daily usage: 6 hours (not 24 hours)
            const dailyHours = 6.0;
            final dailyUsage = (totalEnergyUsage * dailyHours) / 1000; // kWh per day
            final monthlyUsage = dailyUsage * 30; // kWh per month
            const electricityRate = 1500.0; // IDR per kWh (same as web)
            final dailyCost = dailyUsage * electricityRate;
            final monthlyCost = monthlyUsage * electricityRate;

            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    const Text(
                      'Statistik',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Period Selector
                    Row(
                      children: [
                        _buildPeriodChip('Hari Ini'),
                        const SizedBox(width: 8),
                        _buildPeriodChip('Minggu Ini'),
                        const SizedBox(width: 8),
                        _buildPeriodChip('Bulan Ini'),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Energy Usage Card
                    GlassCard(
                      gradient: true,
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Penggunaan Energi',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Icon(
                                Icons.bolt,
                                color: AppColors.primaryAccent,
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          
                          // Current Usage
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Saat Ini',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  Text(
                                    '${totalEnergyUsage.toStringAsFixed(1)} W',
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text(
                                    'Hari Ini',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  Text(
                                    '${dailyUsage.toStringAsFixed(2)} kWh',
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          
                          // Progress Bar
                          Container(
                            height: 8,
                            decoration: BoxDecoration(
                              color: AppColors.textSecondary.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: (activeDevices / (totalDevices == 0 ? 1 : totalDevices)).clamp(0.0, 1.0),
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: AppColors.primaryGradient,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '$activeDevices dari $totalDevices device aktif',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Cost Estimation
                    GlassCard(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Estimasi Biaya',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildCostItem(
                                'Hari Ini',
                                'Rp ${dailyCost.toStringAsFixed(0)}',
                                Icons.today,
                              ),
                              _buildCostItem(
                                'Bulan Ini',
                                'Rp ${monthlyCost.toStringAsFixed(0)}',
                                Icons.calendar_month,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Device Statistics
                    Row(
                      children: [
                        Expanded(
                          child: GlassCard(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.success.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.wifi,
                                    color: AppColors.success,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  '$onlineDevices',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const Text(
                                  'Online',
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
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.error.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.wifi_off,
                                    color: AppColors.error,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  '${totalDevices - onlineDevices}',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const Text(
                                  'Offline',
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
                    const SizedBox(height: 16),

                    // Usage by Room
                    GlassCard(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Penggunaan Per Ruangan',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ..._buildRoomUsageList(devices),
                        ],
                      ),
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            );
          },
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
  }

  Widget _buildPeriodChip(String label) {
    final isSelected = _selectedPeriod == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPeriod = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppColors.primaryAccent 
              : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected 
                ? AppColors.primaryBackground 
                : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildCostItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: AppColors.primaryAccent,
          size: 24,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildRoomUsageList(List<Map<String, dynamic>> devices) {
    // Group devices by room
    final Map<String, List<Map<String, dynamic>>> devicesByRoom = {};
    for (var device in devices) {
      final roomName = device['roomName'] ?? 'Lainnya';
      devicesByRoom.putIfAbsent(roomName, () => []);
      devicesByRoom[roomName]!.add(device);
    }

    return devicesByRoom.entries.map((entry) {
      final roomName = entry.key;
      final roomDevices = entry.value;
      final activeCount = roomDevices.where((d) => d['power'] == true).length;
      final percentage = (activeCount / roomDevices.length * 100).round();

      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Icon(
              _getRoomIcon(roomName),
              color: AppColors.primaryAccent,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        roomName,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '$percentage%',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.textSecondary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: percentage / 100,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.primaryAccent,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$activeCount/${roomDevices.length} device aktif',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }).toList();
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

  void _navigateToScreen(int index) {
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/dashboard');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/devices');
        break;
      case 2:
        // Already on statistics
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/settings');
        break;
    }
  }
}
