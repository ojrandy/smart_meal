import 'package:flutter/material.dart';

class AppColors {
  // Primary Brand Colors
  static const Color primary = Color(0xFF0A7C36); // The main green used in buttons and highlights
  static const Color primaryDark = Color(0xFF065C27);
  static const Color primaryLight = Color(0xFFE6F4EA);

  // Background Colors
  static const Color background = Color(0xFFFCFAF5); // The off-white/cream background
  static const Color surface = Colors.white;
  static const Color surfaceVariant = Color(0xFFF3F4F6); // Light grey for cards/inputs

  // Text Colors
  static const Color textPrimary = Color(0xFF111827); // Dark slate/black
  static const Color textSecondary = Color(0xFF6B7280); // Grey text
  static const Color textHint = Color(0xFF9CA3AF);

  // Semantic Colors
  static const Color error = Color(0xFFEF4444);
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  
  // AI Chef Gradient Colors
  static const Color aiGradientStart = Color(0xFF1B5E20); // Dark Green
  static const Color aiGradientEnd = Color(0xFFF59E0B); // Golden/Orange
  
  static const LinearGradient aiChefGradient = LinearGradient(
    colors: [aiGradientStart, aiGradientEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
