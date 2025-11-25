import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/constants/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    // Wait a bit for Firebase to initialize
    await Future.delayed(const Duration(seconds: 1));
    
    if (!mounted) return;
    
    // Check if user is logged in
    final user = FirebaseAuth.instance.currentUser;
    
    print('🔥 SPLASH: Current user: ${user?.email ?? "NONE"}');
    
    if (user != null) {
      print('✅ SPLASH: User found, going to dashboard');
      Navigator.pushReplacementNamed(context, '/dashboard');
    } else {
      print('❌ SPLASH: No user, going to login');
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lightbulb,
              size: 80,
              color: AppColors.primaryAccent,
            ),
            SizedBox(height: 24),
            Text(
              'Brightify',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 16),
            CircularProgressIndicator(
              color: AppColors.primaryAccent,
            ),
          ],
        ),
      ),
    );
  }
}
