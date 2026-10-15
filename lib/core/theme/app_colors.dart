import 'package:flutter/material.dart';

class AppColors {
  // Primary Brand Colors
  static const Color primary = Color(
    0xFF0A7C36,
  ); // The main green used in buttons and highlights
  static const Color primaryDark = Color(0xFF065C27);
  static const Color primaryLight = Color(0xFFE6F4EA);
  static const Color onPrimary = Color(0xFFFFFFFF);

  // Orange of the logo; the "AI" / "TECH" highlight on the splash.
  static const Color brandAccent = Color(0xFFFF6B00);

  // Background Colors
  static const Color background = Color(
    0xFFFCFAF5,
  ); // The off-white/cream background
  static const Color surface = Colors.white;
  static const Color surfaceVariant = Color(
    0xFFF3F4F6,
  ); // Light grey for cards/inputs

  // Text Colors
  static const Color textPrimary = Color(0xFF111827); // Dark slate/black
  static const Color textSecondary = Color(0xFF6B7280); // Grey text
  static const Color textHint = Color(0xFF9CA3AF);

  // Content on photos, gradients and other dark backgrounds
  static const Color onDark = Color(0xFFFFFFFF);
  static const Color onDarkMuted = Color(0xB3FFFFFF); // white 70 %
  static const Color onDarkSubtle = Color(0x8AFFFFFF); // white 54 %

  // Base colors for overlays; apply alpha at the call site.
  static const Color scrim = Color(0xFF000000);
  static const Color shadow = Color(0xFF000000);

  // Semantic Colors
  static const Color error = Color(0xFFEF4444);
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color favorite = Color(0xFFF44336);
  static const Color placeholderIcon = Color(0xFF9E9E9E);

  // Third-party brand marks on the social sign-in buttons
  static const Color socialGoogle = Color(0xFFF44336);
  static const Color socialApple = Color(0xFF000000);
  static const Color socialFacebook = Color(0xFF2196F3);

  // AI Chef Gradient Colors
  static const Color aiGradientStart = Color(0xFF1B5E20); // Dark Green
  static const Color aiGradientEnd = Color(0xFFF59E0B); // Golden/Orange

  static const LinearGradient aiChefGradient = LinearGradient(
    colors: [aiGradientStart, aiGradientEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Splash
  static const Color splashGradientStart = Color(0xFF188241);
  static const Color splashGradientMid = Color(0xFF289A45);
  static const Color splashGradientEnd = Color(0xFF86B93F);
  static const Color splashGlow = Color(0xFFF59E0B);

  static const LinearGradient splashGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [splashGradientStart, splashGradientMid, splashGradientEnd],
    stops: [0.0, 0.4, 1.0],
  );
}
