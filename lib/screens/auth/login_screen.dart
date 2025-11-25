import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_input.dart';
import '../../widgets/glass_card.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _emailError;
  String? _passwordError;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _handleEmailLogin() async {
    setState(() {
      _emailError = null;
      _passwordError = null;
    });

    // Validation
    bool hasError = false;
    if (_emailController.text.isEmpty) {
      setState(() {
        _emailError = 'Email wajib diisi';
      });
      hasError = true;
    } else if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
        .hasMatch(_emailController.text)) {
      setState(() {
        _emailError = 'Email tidak valid';
      });
      hasError = true;
    }

    if (_passwordController.text.isEmpty) {
      setState(() {
        _passwordError = 'Password wajib diisi';
      });
      hasError = true;
    } else if (_passwordController.text.length < 6) {
      setState(() {
        _passwordError = 'Password minimal 6 karakter';
      });
      hasError = true;
    }

    if (hasError) return;

    setState(() {
      _isLoading = true;
    });

    // Firebase login
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.signIn(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    setState(() {
      _isLoading = false;
    });

    if (success && mounted) {
      print('✅ Email Login: Success! Going to dashboard');
      Navigator.pushReplacementNamed(context, '/dashboard');
    } else if (authProvider.errorMessage != null) {
      print('❌ Email Login: Error - ${authProvider.errorMessage}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage!),
          backgroundColor: AppColors.error,
        ),
      );
      authProvider.clearError();
    }
  }

  void _handleGoogleLogin() async {
    setState(() {
      _isLoading = true;
    });

    // Google Sign-In
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.signInWithGoogle();

    setState(() {
      _isLoading = false;
    });

    if (success && mounted) {
      print('✅ Google Login: Success! Going to dashboard');
      Navigator.pushReplacementNamed(context, '/dashboard');
    } else if (authProvider.errorMessage != null) {
      print('❌ Google Login: Error - ${authProvider.errorMessage}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage!),
          backgroundColor: AppColors.error,
        ),
      );
      authProvider.clearError();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 40),
                    // Logo and Brand
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primaryAccent.withOpacity(0.3),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.lightbulb_outline,
                              size: 40,
                              color: AppColors.primaryBackground,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Brightify',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Kendalikan Cahaya, Wujudkan Suasana',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary.withOpacity(0.8),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 48),

                    // Welcome Text
                    const Center(
                      child: Column(
                        children: [
                          Text(
                            'Selamat Datang',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Masuk untuk mengakses dashboard Anda',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Login Form
                    GlassCard(
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            CustomInput(
                              label: 'Alamat Email',
                              hint: 'Masukkan email Anda',
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              prefixIcon: Icons.email_outlined,
                              error: _emailError,
                            ),
                            const SizedBox(height: 20),
                            CustomInput(
                              label: 'Password',
                              hint: 'Masukkan password Anda',
                              controller: _passwordController,
                              obscureText: true,
                              prefixIcon: Icons.lock_outline,
                              error: _passwordError,
                            ),
                            const SizedBox(height: 16),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {
                                  // Navigate to forgot password
                                },
                                child: const Text(
                                  'Lupa Password?',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppColors.primaryAccent,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            CustomButton(
                              text: 'Masuk',
                              onPressed: _handleEmailLogin,
                              variant: ButtonVariant.gradient,
                              isLoading: _isLoading,
                              width: double.infinity,
                              glow: true,
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    height: 1,
                                    color: AppColors.glassBorder,
                                  ),
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 16),
                                  child: Text(
                                    'atau',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Container(
                                    height: 1,
                                    color: AppColors.glassBorder,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            CustomButton(
                              text: 'Masuk dengan Google',
                              onPressed: _handleGoogleLogin,
                              variant: ButtonVariant.outline,
                              icon: Icons.g_mobiledata,
                              width: double.infinity,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Register Link
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Belum punya akun? ',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.pushNamed(context, '/register');
                            },
                            child: const Text(
                              'Daftar Sekarang',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.primaryAccent,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
