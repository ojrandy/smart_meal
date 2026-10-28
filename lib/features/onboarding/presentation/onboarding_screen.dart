import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../language/presentation/widgets/language_switch.dart';
import '../domain/onboarding_notifier.dart';

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
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  static List<_OnboardingSlide> _slidesFor(AppLocalizations l10n) => [
    _OnboardingSlide(
      title: l10n.onboardingDiscoverTitle,
      subtitle: l10n.onboardingDiscoverBody,
      image: AppAssets.onboardingDiscover,
    ),
    _OnboardingSlide(
      title: l10n.onboardingPlanTitle,
      subtitle: l10n.onboardingPlanBody,
      image: AppAssets.onboardingPlan,
    ),
    _OnboardingSlide(
      title: l10n.onboardingDecideTitle,
      subtitle: l10n.onboardingDecideBody,
      image: AppAssets.onboardingDecide,
    ),
  ];

  static const _slideCount = 3;

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

  // Skip and Get started both count as seen: onboarding shows once.
  void _finish() {
    unawaited(ref.read(onboardingSeenProvider.notifier).markSeen());
    context.go('/auth/login');
  }

  void _onSkip() => _finish();

  void _onNext() {
    if (_currentIndex == _slideCount - 1) {
      _finish();
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
    final isLastSlide = _currentIndex == _slideCount - 1;
    final l10n = context.l10n;
    final slides = _slidesFor(l10n);

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
                  itemCount: slides.length,
                  itemBuilder: (context, index) => _SlidePage(
                    slide: slides[index],
                    isActive: index == _currentIndex,
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
                    _PageDots(count: slides.length, current: _currentIndex),
                    const SizedBox(height: 24),
                    CustomButton(
                      text: isLastSlide
                          ? l10n.getStartedButton
                          : l10n.nextButton,
                      onPressed: _onNext,
                    ),
                  ],
                ),
              ),
            ],
          ),
          // First chance to pick English or French (owner, 2026-10-26).
          Positioned(
            top: skipTop,
            left: 24 + insets.left,
            child: const LanguageSwitch(),
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
              child: Text(
                l10n.skipButton,
                style: const TextStyle(
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
  final bool isActive;
  final double minPhotoHeight;

  const _SlidePage({
    required this.slide,
    required this.isActive,
    required this.minPhotoHeight,
  });

  /// The shown photo settles from this zoom to its full frame (a slow
  /// "Ken Burns" ease); swiped-away photos drift back, ready for next time.
  static const _photoZoom = 1.08;
  static const _photoSettle = Duration(seconds: 7);

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final photoHeight = math.max(
          minPhotoHeight,
          math.min(
            constraints.maxHeight * _OnboardingScreenState._photoShare,
            constraints.maxWidth / _OnboardingScreenState._photoAspect,
          ),
        );

        final photo = Image.asset(
          slide.image,
          width: double.infinity,
          height: photoHeight,
          fit: BoxFit.cover,
          excludeFromSemantics: true,
          errorBuilder: (context, error, stackTrace) =>
              const ColoredBox(color: AppColors.primaryLight),
        );

        final message = Column(
          children: [
            Text(
              slide.title,
              // Large system text still grows the title, but stops at 1.8×
              // so a 3-line title fits on the smallest phones.
              textScaler: MediaQuery.textScalerOf(
                context,
              ).clamp(maxScaleFactor: 1.8),
              style: textTheme.headlineMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 30,
                height: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              slide.subtitle,
              style: textTheme.bodyLarge?.copyWith(
                color: AppColors.textSecondary,
                fontSize: 17,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
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
                child: reduceMotion
                    ? photo
                    : photo
                          .animate(target: isActive ? 1 : 0)
                          .scale(
                            begin: const Offset(_photoZoom, _photoZoom),
                            end: const Offset(1, 1),
                            duration: _photoSettle,
                            curve: Curves.easeOutCubic,
                          ),
              ),
            ),
            // Scrolls instead of overflowing on short screens or with
            // large system text.
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 8),
                child: reduceMotion
                    ? message
                    : message
                          .animate()
                          .fadeIn(duration: 450.ms)
                          .slideY(
                            begin: 0.15,
                            end: 0,
                            duration: 450.ms,
                            curve: Curves.easeOutCubic,
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
