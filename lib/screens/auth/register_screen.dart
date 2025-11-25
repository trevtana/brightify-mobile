import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_input.dart';
import '../../widgets/glass_card.dart';
import '../../providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> with SingleTickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _nameError;
  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;
  
  // Password strength indicators
  bool _hasUpperCase = false;
  bool _hasLowerCase = false;
  bool _hasNumber = false;
  bool _hasMinLength = false;
  
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
    
    // Listen to password changes for strength indicator
    _passwordController.addListener(_updatePasswordStrength);
  }
  
  void _updatePasswordStrength() {
    setState(() {
      _hasUpperCase = _passwordController.text.contains(RegExp(r'[A-Z]'));
      _hasLowerCase = _passwordController.text.contains(RegExp(r'[a-z]'));
      _hasNumber = _passwordController.text.contains(RegExp(r'[0-9]'));
      _hasMinLength = _passwordController.text.length >= 6;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _handleRegister() async {
    setState(() {
      _nameError = null;
      _emailError = null;
      _passwordError = null;
      _confirmPasswordError = null;
    });

    // Validation
    bool hasError = false;
    
    if (_nameController.text.isEmpty) {
      setState(() {
        _nameError = 'Nama lengkap wajib diisi';
      });
      hasError = true;
    }
    
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
    } else if (!(_hasUpperCase && _hasLowerCase && _hasNumber && _hasMinLength)) {
      setState(() {
        _passwordError = 'Password tidak memenuhi kriteria';
      });
      hasError = true;
    }
    
    if (_confirmPasswordController.text.isEmpty) {
      setState(() {
        _confirmPasswordError = 'Konfirmasi password wajib diisi';
      });
      hasError = true;
    } else if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _confirmPasswordError = 'Password tidak cocok';
      });
      hasError = true;
    }

    if (hasError) return;

    setState(() {
      _isLoading = true;
    });

    // Firebase register
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.register(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      name: _nameController.text.trim(),
    );

    setState(() {
      _isLoading = false;
    });

    if (success && mounted) {
      // AuthWrapper will automatically redirect to dashboard
      Navigator.pushReplacementNamed(context, '/');
    } else if (authProvider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage!),
          backgroundColor: AppColors.error,
        ),
      );
      authProvider.clearError();
    }
  }

  void _handleGoogleRegister() async {
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
      // AuthWrapper will automatically redirect to dashboard
      Navigator.pushReplacementNamed(context, '/');
    } else if (authProvider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage!),
          backgroundColor: AppColors.error,
        ),
      );
      authProvider.clearError();
    }
  }
  
  Widget _buildPasswordStrengthIndicator() {
    return Column(
      children: [
        Row(
          children: [
            _buildIndicatorItem('Min. 6 karakter', _hasMinLength),
            const SizedBox(width: 12),
            _buildIndicatorItem('Huruf besar', _hasUpperCase),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            _buildIndicatorItem('Huruf kecil', _hasLowerCase),
            const SizedBox(width: 12),
            _buildIndicatorItem('Angka', _hasNumber),
          ],
        ),
      ],
    );
  }
  
  Widget _buildIndicatorItem(String label, bool isValid) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: isValid ? AppColors.success : Colors.transparent,
            border: Border.all(
              color: isValid ? AppColors.success : AppColors.textMuted,
              width: 1.5,
            ),
            shape: BoxShape.circle,
          ),
          child: isValid
              ? const Icon(
                  Icons.check,
                  size: 8,
                  color: AppColors.primaryBackground,
                )
              : null,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isValid ? AppColors.success : AppColors.textMuted,
          ),
        ),
      ],
    );
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
                    const SizedBox(height: 20),
                    
                    // Back Button
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.arrow_back,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Logo and Brand
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primaryAccent.withOpacity(0.3),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.lightbulb_outline,
                              size: 32,
                              color: AppColors.primaryBackground,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Buat Akun Baru',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Bergabunglah untuk mengontrol pencahayaan rumah',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Register Form
                    GlassCard(
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            // Name Field
                            CustomInput(
                              label: 'Nama Lengkap',
                              hint: 'Masukkan nama lengkap Anda',
                              controller: _nameController,
                              keyboardType: TextInputType.name,
                              prefixIcon: Icons.person_outline,
                              error: _nameError,
                            ),
                            const SizedBox(height: 20),
                            
                            // Email Field
                            CustomInput(
                              label: 'Alamat Email',
                              hint: 'Masukkan email Anda',
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              prefixIcon: Icons.email_outlined,
                              error: _emailError,
                            ),
                            const SizedBox(height: 20),
                            
                            // Password Fields Side by Side
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: CustomInput(
                                    label: 'Buat Password',
                                    hint: 'Min. 6 karakter',
                                    controller: _passwordController,
                                    obscureText: true,
                                    prefixIcon: Icons.lock_outline,
                                    error: _passwordError,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: CustomInput(
                                    label: 'Konfirmasi Password',
                                    hint: 'Ulangi password',
                                    controller: _confirmPasswordController,
                                    obscureText: true,
                                    prefixIcon: Icons.lock_outline,
                                    error: _confirmPasswordError,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            
                            // Password Strength Indicator
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.glassMedium,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: _buildPasswordStrengthIndicator(),
                            ),
                            const SizedBox(height: 24),
                            
                            CustomButton(
                              text: 'Daftar Sekarang',
                              onPressed: _handleRegister,
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
                              text: 'Daftar dengan Google',
                              onPressed: _handleGoogleRegister,
                              variant: ButtonVariant.outline,
                              icon: Icons.g_mobiledata,
                              width: double.infinity,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Login Link
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Sudah punya akun? ',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.pop(context);
                            },
                            child: const Text(
                              'Masuk Sekarang',
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
