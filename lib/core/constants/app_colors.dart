import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors
  static const Color primaryBackground = Color(0xFF0A0A0A);
  static const Color cardBackground = Color(0xFF141414);
  static const Color inputBackground = Color(0xFF1C1C1C);
  
  // Accent Colors  
  static const Color primaryAccent = Color(0xFFFDB515);
  static const Color secondaryAccent = Color(0xFFFFD700);
  
  // Text Colors
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB8B8B8);
  static const Color textMuted = Color(0xFF808080);
  
  // Status Colors
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);
  
  // Border & Glass Effects
  static const Color glassBorder = Color(0x1AFFFFFF);
  static const Color glassLight = Color(0x0DFFFFFF);
  static const Color glassMedium = Color(0x1AFFFFFF);
  
  // Gradient Colors
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryAccent, secondaryAccent],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF1A1A1A), Color(0xFF141414)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // Shadow Colors
  static const Color shadowDark = Color(0x80000000);
  static const Color shadowLight = Color(0x1A000000);
  static const Color glowShadow = Color(0x40FDB515);
}
