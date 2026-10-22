import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';

/// Minimal brand splash (owner-approved redesign, 2026-10-21): the logo
/// and wordmark on the deep brand green, one short entrance, then onward.
/// The native launch screens use the same green, so there is no flash
/// between them and this first Flutter frame.
///
/// It only animates: the router leaves it once `launchReadyProvider` says
/// the hold is over, choosing home, onboarding or sign-in.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.splashBackground,
      body: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: Column(
            children: [
              const Spacer(),
              Image.asset(
                    AppAssets.appLogo,
                    width: 112,
                    height: 112,
                    excludeFromSemantics: true,
                  )
                  .animate()
                  .fade(duration: 500.ms)
                  .scale(
                    begin: const Offset(0.9, 0.9),
                    duration: 500.ms,
                    curve: Curves.easeOutCubic,
                  ),
              const SizedBox(height: 20),
              Text.rich(
                    TextSpan(
                      style: GoogleFonts.inter(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -1.5,
                        height: 1.1,
                      ),
                      children: const [
                        TextSpan(
                          text: 'SmartMeal ',
                          style: TextStyle(color: AppColors.onDark),
                        ),
                        TextSpan(
                          text: 'AI',
                          style: TextStyle(color: AppColors.brandAccent),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  )
                  .animate()
                  .fade(delay: 200.ms, duration: 500.ms)
                  .slideY(begin: 0.2, end: 0, curve: Curves.easeOutCubic),
              const SizedBox(height: 10),
              Text(
                'Your AI food companion',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: AppColors.onDarkMuted,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ).animate().fade(delay: 400.ms, duration: 500.ms),
              const Spacer(),
              Text(
                'by OJ Tech',
                style: GoogleFonts.inter(
                  color: AppColors.onDarkMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ).animate().fade(delay: 400.ms, duration: 500.ms),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
