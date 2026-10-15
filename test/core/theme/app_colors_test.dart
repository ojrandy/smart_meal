import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_meal/core/theme/app_colors.dart';

// P05 moved inline colors into tokens; the rendered values must not change.
void main() {
  test('tokens keep the values they replaced', () {
    final replaced = <(Color, Color)>[
      (AppColors.onPrimary, Colors.white),
      (AppColors.onDark, Colors.white),
      (AppColors.onDarkMuted, Colors.white70),
      (AppColors.onDarkSubtle, Colors.white54),
      (AppColors.scrim, Colors.black),
      (AppColors.shadow, Colors.black),
      (AppColors.favorite, Colors.red),
      (AppColors.placeholderIcon, Colors.grey),
      (AppColors.socialGoogle, Colors.red),
      (AppColors.socialApple, Colors.black),
      (AppColors.socialFacebook, Colors.blue),
      (AppColors.splashGradientStart, const Color(0xFF188241)),
      (AppColors.splashGradientMid, const Color(0xFF289A45)),
      (AppColors.splashGradientEnd, const Color(0xFF86B93F)),
      (AppColors.splashGlow, const Color(0xFFF59E0B)),
      (AppColors.brandAccent, const Color(0xFFFF6B00)),
    ];
    for (final (token, original) in replaced) {
      expect(token.toARGB32(), original.toARGB32());
    }
  });

  test('splash gradient keeps its stops and direction', () {
    const gradient = AppColors.splashGradient;
    expect(gradient.stops, [0.0, 0.4, 1.0]);
    expect(gradient.begin, Alignment.topLeft);
    expect(gradient.end, Alignment.bottomRight);
  });
}
