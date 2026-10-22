import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_snack_bar.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../auth/domain/auth_notifier.dart';
import '../../../auth/domain/auth_session.dart';
import '../../../auth/domain/auth_state.dart';

/// Interim Home: greets the signed-in user and offers sign-out, so the
/// whole auth flow can be exercised end to end. P18 replaces the body with
/// live recommendations.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<SmartMealAuthState>(authNotifierProvider, (_, next) {
      if (next is AuthError) showAppSnackBar(context, next.message);
    });

    final user = ref.watch(authSessionProvider);
    final isLoading = ref.watch(authNotifierProvider) is AuthLoading;
    final metadata = user?.userMetadata ?? const {};
    final fullName = (metadata['full_name'] ?? metadata['name']) as String?;
    final firstName = fullName?.trim().split(' ').first;
    final email = user?.email;

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
                    ? 'Welcome to Smart Meal'
                    : 'Welcome, $firstName',
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
                  'Signed in as $email',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              const Text(
                'Your personalized meals will appear here soon ✨',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const Spacer(),
              CustomButton(
                text: 'Sign out',
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
