import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../services/firebase_service.dart';
import '../../widgets/glass_card.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseService _firebaseService = FirebaseService();

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    if (user == null) {
      print('⚠️ Profile: User is NULL, redirecting to login');
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
            final devices = snapshot.data ?? [];

            final totalDevices = devices.length;
            final activeDevices = devices.where((d) => d['power'] == true).length;
            final onlineDevices = devices.where((d) => d['status'] == 'online').length;

            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Header with back button
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const Expanded(
                          child: Text(
                            'Profil',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit, color: AppColors.primaryAccent),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Edit profil dalam pengembangan')),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Profile Picture
                    Stack(
                      children: [
                        if (user.photoURL != null && user.photoURL!.isNotEmpty)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(60),
                            child: Image.network(
                              user.photoURL!,
                              width: 120,
                              height: 120,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return _buildDefaultAvatar(user, size: 120);
                              },
                            ),
                          )
                        else
                          _buildDefaultAvatar(user, size: 120),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primaryAccent,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: AppColors.primaryBackground,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // User Name
                    Text(
                      user.displayName ?? user.email?.split('@')[0] ?? 'User',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // User Email
                    Text(
                      user.email ?? 'No email',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Statistics Cards
                    Row(
                      children: [
                        Expanded(
                          child: GlassCard(
                            gradient: true,
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.devices,
                                  color: AppColors.primaryAccent,
                                  size: 24,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '$totalDevices',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const Text(
                                  'Total Device',
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
                            gradient: true,
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.lightbulb,
                                  color: AppColors.success,
                                  size: 24,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '$activeDevices',
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
                            gradient: true,
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.wifi,
                                  color: AppColors.info,
                                  size: 24,
                                ),
                                const SizedBox(height: 8),
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
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Account Info Section
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Informasi Akun',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        // Provider
                        _buildInfoItem(
                          icon: Icons.login,
                          title: 'Login Method',
                          value: user.providerData.isNotEmpty 
                              ? (user.providerData[0].providerId == 'google.com' ? 'Google' : 'Email')
                              : 'Unknown',
                        ),
                        const SizedBox(height: 12),

                        // Member Since
                        _buildInfoItem(
                          icon: Icons.calendar_today,
                          title: 'Member Sejak',
                          value: _formatDate(user.metadata.creationTime),
                        ),
                        const SizedBox(height: 12),

                        // Last Login
                        _buildInfoItem(
                          icon: Icons.access_time,
                          title: 'Login Terakhir',
                          value: _formatDate(user.metadata.lastSignInTime),
                        ),
                        const SizedBox(height: 12),

                        // UID
                        _buildInfoItem(
                          icon: Icons.fingerprint,
                          title: 'User ID',
                          value: user.uid.substring(0, 12) + '...',
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Actions
                    GlassCard(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Ganti password dalam pengembangan')),
                        );
                      },
                      padding: const EdgeInsets.all(16),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.lock_outline,
                            color: AppColors.primaryAccent,
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Ganti Password',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Spacer(),
                          Icon(
                            Icons.arrow_forward_ios,
                            color: AppColors.textSecondary,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    GlassCard(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Hapus akun dalam pengembangan')),
                        );
                      },
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_outline,
                            color: AppColors.error,
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Hapus Akun',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.error,
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            Icons.arrow_forward_ios,
                            color: AppColors.textSecondary,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDefaultAvatar(User? user, {double size = 60}) {
    final userName = user?.displayName ?? user?.email?.split('@')[0] ?? 'U';
    final initial = userName[0].toUpperCase();
    
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            fontSize: size / 2.5,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryBackground,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(
            icon,
            color: AppColors.primaryAccent,
            size: 20,
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Unknown';
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
