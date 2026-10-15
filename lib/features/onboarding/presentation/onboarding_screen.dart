import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';

class _OnboardingSlide {
  final String title;
  final String subtitle;
  final String image;

  const _OnboardingSlide({
    required this.title,
    required this.subtitle,
    required this.image,
  });
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const _slides = [
    _OnboardingSlide(
      title: 'Welcome to SmartMeal',
      subtitle:
          'Discover meals you will enjoy with AI-powered recommendations tailored to your taste.',
      image: AppAssets.onboardingDiscover,
    ),
    _OnboardingSlide(
      title: 'Plan Your Meals',
      subtitle:
          'Manage your budget and plan your weekly recipes efficiently with intelligent tracking.',
      image: AppAssets.onboardingPlan,
    ),
    _OnboardingSlide(
      title: 'Smarter Food Decisions',
      subtitle:
          'Get personalized recommendations and insights to make healthier food choices',
      image: AppAssets.onboardingDecide,
    ),
  ];

  // Translucent pill behind Skip: keeps the white label readable on light
  // artwork without darkening the whole top of the photo.
  static const _skipPillAlpha = 0.55;

  final PageController _pageController = PageController();
  int _currentIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onSkip() {
    context.go('/auth/login');
  }

  void _onNext() {
    if (_currentIndex == _slides.length - 1) {
      context.go('/auth/login');
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final insets = MediaQuery.paddingOf(context);
    // The design places Skip 60 dp from the top; keep that on typical phones
    // and move it below taller status bars and notches.
    final skipTop = math.max(60.0, insets.top + 8);
    // Room for the Skip button, which grows with the system text size.
    final skipHeight = MediaQuery.textScalerOf(context).scale(48);

    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemCount: _slides.length,
            itemBuilder: (context, index) => Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  _slides[index].image,
                  fit: BoxFit.cover,
                  excludeFromSemantics: true,
                  errorBuilder: (context, error, stackTrace) =>
                      const ColoredBox(color: AppColors.primaryDark),
                ),
                // Bottom-aligned as designed; scrolls instead of overflowing
                // on short screens or with large system text.
                Positioned(
                  top: skipTop + skipHeight,
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: LayoutBuilder(
                    builder: (context, constraints) => SingleChildScrollView(
                      reverse: true,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            _TextScrim(child: _buildSlideContent(index)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Skip Button at Top Right
          Positioned(
            top: skipTop,
            right: 24 + insets.right,
            child: TextButton(
              onPressed: _onSkip,
              style: TextButton.styleFrom(
                backgroundColor: AppColors.scrim.withValues(
                  alpha: _skipPillAlpha,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shape: const StadiumBorder(),
              ),
              child: const Text(
                'Skip',
                style: TextStyle(
                  color: AppColors.onDark,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlideContent(int index) {
    final slide = _slides[index];
    final isLastSlide = _currentIndex == _slides.length - 1;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
      child: Column(
        children: [
          Text(
            slide.title,
            style: textTheme.headlineMedium?.copyWith(
              color: AppColors.onDark,
              fontWeight: FontWeight.bold,
              fontSize: 36,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            slide.subtitle,
            style: textTheme.bodyLarge?.copyWith(
              color: AppColors.onDarkMuted,
              fontSize: 20,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 56),
          // Page Indicator
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
              _slides.length,
              (indicatorIndex) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                height: 8,
                width: _currentIndex == indicatorIndex ? 24 : 8,
                decoration: BoxDecoration(
                  color: _currentIndex == indicatorIndex
                      ? AppColors.primary
                      : AppColors.onDarkSubtle,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          // Next / Start Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _onNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isLastSlide ? 'Get started' : 'Next',
                    style: const TextStyle(
                      color: AppColors.onPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (isLastSlide) ...[
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.arrow_forward,
                      color: AppColors.onPrimary,
                      size: 20,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Darkens the photo behind the slide text wherever the text ends up (any
/// screen size or text scale), so the white text keeps WCAG AA contrast: a
/// soft fade above the title, then a scrim that deepens towards the bottom.
class _TextScrim extends StatelessWidget {
  final Widget child;

  const _TextScrim({required this.child});

  static const _fadeHeight = 120.0;
  static const _topAlpha = 0.6;
  static const _bottomAlpha = 0.85;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: _fadeHeight,
          width: double.infinity,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.scrim.withValues(alpha: 0),
                  AppColors.scrim.withValues(alpha: _topAlpha),
                ],
              ),
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.scrim.withValues(alpha: _topAlpha),
                AppColors.scrim.withValues(alpha: _bottomAlpha),
              ],
            ),
          ),
          child: child,
        ),
      ],
    );
  }
}
