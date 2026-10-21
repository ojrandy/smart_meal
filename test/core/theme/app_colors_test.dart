import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_meal/core/theme/app_colors.dart';

// P05 moved inline colors into tokens; the rendered values must not change.
void main() {
  test('social brand marks use the official brand colors', () {
    expect(AppColors.socialFacebook.toARGB32(), 0xFF0866FF);
    expect(AppColors.socialApple.toARGB32(), 0xFF000000);
  });

  test('tokens keep the values they replaced', () {
    final replaced = <(Color, Color)>[
      (AppColors.onPrimary, Colors.white),
      (AppColors.onDark, Colors.white),
      (AppColors.onDarkMuted, Colors.white70),
      (AppColors.scrim, Colors.black),
      (AppColors.shadow, Colors.black),
      (AppColors.favorite, Colors.red),
      (AppColors.placeholderIcon, Colors.grey),
      (AppColors.socialApple, Colors.black),
      (AppColors.brandAccent, const Color(0xFFFF6B00)),
    ];
    for (final (token, original) in replaced) {
      expect(token.toARGB32(), original.toARGB32());
    }
  });

  test('splash text meets WCAG AA on the splash background', () {
    double ratio(Color a, Color b) {
      final (la, lb) = (a.computeLuminance(), b.computeLuminance());
      return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
    }

    const bg = AppColors.splashBackground;
    // "AI" in the 40 px bold wordmark is large text: 3:1.
    expect(ratio(AppColors.brandAccent, bg), greaterThanOrEqualTo(3.0));
    // White wordmark and the muted small text: 4.5:1.
    expect(ratio(AppColors.onDark, bg), greaterThanOrEqualTo(4.5));
    expect(
      ratio(Color.alphaBlend(AppColors.onDarkMuted, bg), bg),
      greaterThanOrEqualTo(4.5),
    );
  });
}
