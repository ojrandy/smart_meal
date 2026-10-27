import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_snack_bar.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../auth/domain/auth_notifier.dart';
import '../../../auth/domain/auth_session.dart';
import '../../../auth/domain/auth_state.dart';
import '../../../auth/presentation/auth_error_text.dart';

/// Interim Home: greets the signed-in user and offers sign-out, so the
/// whole auth flow can be exercised end to end. P18 replaces the body with
/// live recommendations.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<SmartMealAuthState>(authNotifierProvider, (_, next) {
      if (next is AuthError) {
        showAppSnackBar(context, authErrorText(context.l10n, next.reason));
      }
    });

    final user = ref.watch(authSessionProvider);
    final isLoading = ref.watch(authNotifierProvider) is AuthLoading;
    final metadata = user?.userMetadata ?? const {};
    final fullName = (metadata['full_name'] ?? metadata['name']) as String?;
    final firstName = fullName?.trim().split(' ').first;
    final email = user?.email;
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.asset(
                AppAssets.appLogo,
                height: 40,
                excludeFromSemantics: true,
              ),
              const SizedBox(height: 32),
              Text(
                firstName == null || firstName.isEmpty
                    ? l10n.homeWelcome
                    : l10n.homeWelcomeName(firstName),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  height: 1.2,
                ),
              ),
              if (email != null) ...[
                const SizedBox(height: 8),
                Text(
                  l10n.homeSignedInAs(email),
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Text(
                l10n.homeComingSoon,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const Spacer(),
              CustomButton(
                text: l10n.signOut,
                isOutline: true,
                isLoading: isLoading,
                onPressed: () =>
                    ref.read(authNotifierProvider.notifier).signOut(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
