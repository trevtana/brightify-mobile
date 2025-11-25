import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/firebase_service.dart';
import '../../services/notification_service.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/custom_bottom_nav.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _currentIndex = 3;
  final NotificationService _notificationService = NotificationService();
  
  @override
  void initState() {
    super.initState();
    _notificationService.initialize();
  }
  bool _autoModeEnabled = false;
  
  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryAccent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: AppColors.primaryAccent,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

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
                const Text(
                  'Pengaturan',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 24),

                // User Profile Section
                GlassCard(
                  gradient: true,
                  padding: const EdgeInsets.all(16),
                  onTap: () => Navigator.pushNamed(context, '/profile'),
                  child: Row(
                    children: [
                      // Avatar
                      if (user?.photoURL != null && user!.photoURL!.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            user.photoURL!,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return _buildDefaultAvatar(user);
                            },
                          ),
                        )
                      else
                        _buildDefaultAvatar(user),
                      const SizedBox(width: 16),
                      // User Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.displayName ?? user?.email?.split('@')[0] ?? 'User',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user?.email ?? 'No email',
                              style: const TextStyle(
                                fontSize: 14,
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
                ),
                const SizedBox(height: 24),

                // Preferences Section
                const Text(
                  'Preferensi',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),

                _buildSettingItem(
                  icon: Icons.notifications_outlined,
                  title: 'Notifikasi',
                  subtitle: 'Terima pemberitahuan penting',
                  trailing: Switch(
                    value: _notificationService.isEnabled,
                    onChanged: (value) async {
                      await _notificationService.toggleNotifications(value);
                      setState(() {});
                      
                      if (value) {
                        // Show notification for devices that are currently on
                        Future.delayed(const Duration(seconds: 2), () async {
                          final user = FirebaseAuth.instance.currentUser;
                          if (user != null) {
                            // Get all devices
                            final devices = await FirebaseService().getUserDevices(user.uid).first;
                            
                            // Find devices that are powered on
                            final activeDevices = devices.where((d) => d['power'] == true).toList();
                            
                            if (activeDevices.isNotEmpty) {
                              // Show notification for first active device
                              final device = activeDevices.first;
                              
                              // Calculate real usage time (for now, show current status)
                              // In real app, you'd track actual on time
                              _notificationService.showUsageNotification(
                                deviceName: device['deviceName'] ?? device['roomName'] ?? 'Device',
                                minutes: 1, // Show just turned on notification
                              );
                            } else {
                              // Show test notification if no devices are on
                              await _notificationService.showNotification(
                                title: 'Brightify',
                                body: 'Notifikasi telah diaktifkan',
                                id: DateTime.now().millisecondsSinceEpoch,
                              );
                            }
                          }
                        });
                      }
                    },
                    activeColor: AppColors.primaryAccent,
                  ),
                  onTap: null,
                ),
                const SizedBox(height: 12),

                Consumer<ThemeProvider>(
                  builder: (context, themeProvider, child) {
                    return _buildSettingItem(
                      icon: themeProvider.isDarkMode 
                          ? Icons.dark_mode 
                          : Icons.light_mode,
                      title: 'Tema',
                      subtitle: themeProvider.isDarkMode 
                          ? 'Mode gelap aktif' 
                          : 'Mode terang aktif',
                      trailing: Switch(
                        value: themeProvider.isDarkMode,
                        onChanged: (value) {
                          themeProvider.toggleTheme();
                        },
                        activeColor: AppColors.primaryAccent,
                      ),
                      onTap: null,
                    );
                  },
                ),
                const SizedBox(height: 12),

                // Auto Mode
                GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryAccent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.auto_mode,
                          color: AppColors.primaryAccent,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Mode Otomatis',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              'Otomatis atur lampu',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _autoModeEnabled,
                        onChanged: (value) {
                          setState(() {
                            _autoModeEnabled = value;
                          });
                        },
                        activeColor: AppColors.primaryAccent,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Actions Section
                const Text(
                  'Lainnya',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),

                // About
                _buildMenuItem(
                  icon: Icons.info_outline,
                  title: 'Tentang',
                  subtitle: 'Informasi aplikasi',
                  onTap: () {
                    _showAboutDialog();
                  },
                ),
                const SizedBox(height: 12),

                // Help
                _buildMenuItem(
                  icon: Icons.help_outline,
                  title: 'Bantuan',
                  subtitle: 'FAQ dan dukungan',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Halaman bantuan dalam pengembangan')),
                    );
                  },
                ),
                const SizedBox(height: 12),

                // Privacy
                _buildMenuItem(
                  icon: Icons.privacy_tip_outlined,
                  title: 'Privasi',
                  subtitle: 'Kebijakan privasi',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Kebijakan privasi dalam pengembangan')),
                    );
                  },
                ),
                const SizedBox(height: 12),

                // Debug Info
                _buildMenuItem(
                  icon: Icons.bug_report,
                  title: 'Debug Info',
                  subtitle: 'Test Firestore connection',
                  onTap: () {
                    Navigator.pushNamed(context, '/debug');
                  },
                ),
                const SizedBox(height: 12),

                // Logout
                _buildMenuItem(
                  icon: Icons.logout,
                  title: 'Keluar',
                  subtitle: 'Keluar dari akun',
                  iconColor: AppColors.error,
                  onTap: () async {
                    _showLogoutDialog();
                  },
                ),
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
  }

  Widget _buildDefaultAvatar(User? user) {
    final userName = user?.displayName ?? user?.email?.split('@')[0] ?? 'U';
    final initial = userName[0].toUpperCase();
    
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryBackground,
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    Color? iconColor,
    required VoidCallback onTap,
  }) {
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (iconColor ?? AppColors.primaryAccent).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: iconColor ?? AppColors.primaryAccent,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
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
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: const Text(
          'Tentang Brightify',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Versi 1.0.0',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            SizedBox(height: 8),
            Text(
              'Brightify adalah aplikasi smart home untuk mengontrol pencahayaan rumah Anda dengan mudah.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            SizedBox(height: 8),
            Text(
              '© 2025 Arkan Ardiansyah',
              style: TextStyle(color: AppColors.textMuted),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'OK',
              style: TextStyle(color: AppColors.primaryAccent),
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: const Text(
          'Keluar',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: const Text(
          'Apakah Anda yakin ingin keluar?',
          style: TextStyle(color: AppColors.textSecondary),
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
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              await authProvider.signOut();
              if (mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (route) => false,
                );
              }
            },
            child: const Text(
              'Keluar',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
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
        // Already on settings
        break;
    }
  }
}
