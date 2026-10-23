import 'package:flutter/material.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_colors.dart';

/// The back button, logo and two-tone title the auth screens open with:
/// [title] in the text color, [highlight] on the next line in brand green.
class AuthScreenHeader extends StatelessWidget {
  const AuthScreenHeader({
    super.key,
    required this.onBack,
    required this.title,
    required this.highlight,
    this.subtitle,
  });

  final VoidCallback? onBack;
  final String title;
  final String highlight;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: onBack,
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
              icon: const Icon(
                Icons.arrow_back_ios_new,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            Image.asset(
              AppAssets.appLogo,
              height: 40,
              excludeFromSemantics: true,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.restaurant_menu,
                color: AppColors.warning,
                size: 40,
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        Text.rich(
          TextSpan(
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              height: 1.2,
            ),
            children: [
              TextSpan(text: '$title\n'),
              TextSpan(
                text: highlight,
                style: const TextStyle(color: AppColors.primary),
              ),
            ],
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
      ],
    );
  }
}
