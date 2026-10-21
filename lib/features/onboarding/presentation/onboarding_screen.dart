import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_button.dart';

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

/// First-run carousel: a real food photo on top (rounded bottom corners),
/// the message below on the cream background, and fixed page dots + CTA at
/// the bottom. Owner-approved redesign (2026-10-21) replacing the AI
/// full-bleed artwork; photo credits in design-assets/source/PHOTO-CREDITS.md.
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
          'Get personalized recommendations and insights to make healthier food choices.',
      image: AppAssets.onboardingDecide,
    ),
  ];

  // Translucent pill behind Skip: keeps the white label readable on any
  // photo without darkening the photo itself.
  static const _skipPillAlpha = 0.55;

  /// The photo takes this share of the swipeable area, but never gets
  /// taller than width / 0.72, so the 4:5 crops are upscaled at most ~11 %.
  static const _photoShare = 0.72;
  static const _photoAspect = 0.72;

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
    // Skip sits 60 dp from the top on typical phones and moves below
    // taller status bars and notches.
    final skipTop = math.max(60.0, insets.top + 8);
    // Room for the Skip button, which grows with the system text size.
    final skipHeight = MediaQuery.textScalerOf(context).scale(48);
    final isLastSlide = _currentIndex == _slides.length - 1;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) =>
                      setState(() => _currentIndex = index),
                  itemCount: _slides.length,
                  itemBuilder: (context, index) => _SlidePage(
                    slide: _slides[index],
                    // The title never starts under Skip, even when the
                    // photo is short (small screens, large text).
                    minPhotoHeight: skipTop + skipHeight,
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(24, 8, 24, 24 + insets.bottom),
                child: Column(
                  children: [
                    _PageDots(count: _slides.length, current: _currentIndex),
                    const SizedBox(height: 24),
                    CustomButton(
                      text: isLastSlide ? 'Get started' : 'Next',
                      onPressed: _onNext,
                    ),
                  ],
                ),
              ),
            ],
          ),
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
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SlidePage extends StatelessWidget {
  final _OnboardingSlide slide;
  final double minPhotoHeight;

  const _SlidePage({required this.slide, required this.minPhotoHeight});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final photoHeight = math.max(
          minPhotoHeight,
          math.min(
            constraints.maxHeight * _OnboardingScreenState._photoShare,
            constraints.maxWidth / _OnboardingScreenState._photoAspect,
          ),
        );

        return Column(
          children: [
            SizedBox(
              height: photoHeight,
              width: double.infinity,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(32),
                ),
                child: Image.asset(
                  slide.image,
                  fit: BoxFit.cover,
                  excludeFromSemantics: true,
                  errorBuilder: (context, error, stackTrace) =>
                      const ColoredBox(color: AppColors.primaryLight),
                ),
              ),
            ),
            // Scrolls instead of overflowing on short screens or with
            // large system text.
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 8),
                child: Column(
                  children: [
                    Text(
                      slide.title,
                      style: textTheme.headlineMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 28,
                        height: 1.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      slide.subtitle,
                      style: textTheme.bodyLarge?.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 16,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PageDots extends StatelessWidget {
  final int count;
  final int current;

  const _PageDots({required this.count, required this.current});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        count,
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 8,
          width: current == index ? 24 : 8,
          decoration: BoxDecoration(
            color: current == index ? AppColors.primary : AppColors.textHint,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }
}
