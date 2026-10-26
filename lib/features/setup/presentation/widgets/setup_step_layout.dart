import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../domain/setup_draft.dart';

/// The frame of every setup question: progress, title, the answers, and
/// Back / Continue pinned to the bottom so they never scroll away.
class SetupStepLayout extends StatelessWidget {
  const SetupStepLayout({
    super.key,
    required this.step,
    required this.title,
    this.subtitle,
    required this.body,
    required this.continueLabel,
    required this.onContinue,
    this.onBack,
    this.topAction,
    this.error,
  });

  final SetupStep step;
  final String title;
  final String? subtitle;
  final Widget body;
  final String continueLabel;

  /// Null disables Continue.
  final VoidCallback? onContinue;

  /// Null hides Back (first step).
  final VoidCallback? onBack;

  /// Optional action in the header's right corner (e.g. Sign out).
  final Widget? topAction;

  /// Shown above the buttons, e.g. "Please choose an option".
  final String? error;

  @override
  Widget build(BuildContext context) {
    final progress = step.number / SetupStep.total;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              child: SizedBox(
                height: 48,
                child: Row(
                  children: [
                    if (onBack != null)
                      IconButton(
                        onPressed: onBack,
                        tooltip: MaterialLocalizations.of(
                          context,
                        ).backButtonTooltip,
                        icon: const Icon(
                          Icons.arrow_back_ios_new,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      )
                    else
                      const SizedBox(width: 48),
                    Expanded(
                      child: Text(
                        'Step ${step.number} of ${SetupStep.total}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 96,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: topAction,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  color: AppColors.primary,
                  backgroundColor: AppColors.surfaceVariant,
                  semanticsLabel: 'Setup progress',
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                          height: 1.25,
                        ),
                      ),
                    ),
                    if (subtitle case final subtitle?) ...[
                      const SizedBox(height: 8),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    body,
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (error case final error?) ...[
                    Text(
                      error,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  CustomButton(text: continueLabel, onPressed: onContinue),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
