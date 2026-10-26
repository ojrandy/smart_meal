import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../domain/setup_notifier.dart';

const _stages = [
  'Saving your preferences',
  'Matching recipes to your taste',
  'Checking allergies and budget',
];

/// The "AI processing" moment (`/setup/processing`): saves every answer in
/// one call and shows progress. On success the router leaves setup on its
/// own (P15); this screen never navigates home. Until P17 it completes
/// after the save; P17 adds fetching the first recommendations.
class SetupProcessingScreen extends ConsumerStatefulWidget {
  const SetupProcessingScreen({super.key});

  /// Time between the stage lines appearing.
  static const stageInterval = Duration(milliseconds: 700);

  @override
  ConsumerState<SetupProcessingScreen> createState() =>
      _SetupProcessingScreenState();
}

class _SetupProcessingScreenState extends ConsumerState<SetupProcessingScreen> {
  int _visibleStages = 1;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(SetupProcessingScreen.stageInterval, (timer) {
      if (_visibleStages >= _stages.length) return timer.cancel();
      setState(() => _visibleStages++);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _start() {
    if (!mounted) return;
    final draft = ref.read(setupNotifierProvider).draft;
    final missing = draft.firstIncompleteStep;
    if (missing != null) {
      // Opened without a finished draft (e.g. after a restart): go back to
      // the first question still unanswered.
      ref.read(setupNotifierProvider.notifier).show(missing);
      context.go(
        missing.isLifestyleSection ? '/setup/lifestyle' : '/setup/preferences',
      );
      return;
    }
    unawaited(ref.read(setupNotifierProvider.notifier).submit());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(setupNotifierProvider);
    final failure = state is SetupFailed ? state.message : null;

    return PopScope(
      // Leaving mid-save would only confuse; the router moves on after.
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    AppAssets.appLogo,
                    height: 64,
                    excludeFromSemantics: true,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.restaurant_menu,
                      color: AppColors.warning,
                      size: 64,
                    ),
                  ),
                  const SizedBox(height: 32),
                  if (failure == null) ...[
                    Semantics(
                      header: true,
                      child: const Text(
                        'Personalising your meals…',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const SizedBox(
                      width: 32,
                      height: 32,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    for (var i = 0; i < _visibleStages; i++)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              i < _visibleStages - 1
                                  ? Icons.check_circle_rounded
                                  : Icons.more_horiz_rounded,
                              color: AppColors.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _stages[i],
                              style: const TextStyle(
                                fontSize: 15,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ] else ...[
                    Text(
                      failure,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppColors.textPrimary,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    CustomButton(
                      text: 'Try again',
                      onPressed: () => unawaited(
                        ref.read(setupNotifierProvider.notifier).submit(),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
