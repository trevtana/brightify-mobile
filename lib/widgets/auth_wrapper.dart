import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    // Wait a bit for providers to initialize
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get auth provider
    final authProvider = Provider.of<AuthProvider>(context);
    
    debugPrint('🔸 AuthWrapper: Initialized: $_isInitialized');
    debugPrint('🔸 AuthWrapper: User from Provider: ${authProvider.user?.email ?? "null"}');
    debugPrint('🔸 AuthWrapper: Is authenticated: ${authProvider.isAuthenticated}');

    // Show loading while initializing
    if (!_isInitialized) {
      return const Scaffold(
        backgroundColor: AppColors.primaryBackground,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: AppColors.primaryAccent,
              ),
              SizedBox(height: 16),
              Text(
                'Memuat...',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Check user from AuthProvider (not directly from Firebase)
    if (authProvider.isAuthenticated && authProvider.user != null) {
      debugPrint('✅ AuthWrapper: User authenticated, showing Dashboard');
      return const DashboardScreen();
    }

    // If not logged in, show login screen
    debugPrint('❌ AuthWrapper: No user, showing Login');
    return const LoginScreen();
  }
}
