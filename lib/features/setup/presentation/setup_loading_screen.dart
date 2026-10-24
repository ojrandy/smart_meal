import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../auth/domain/auth_notifier.dart';
import '../../auth/domain/auth_state.dart';
import '../domain/setup_status.dart';

/// The entry to setup (`/setup/loading`). The router sends every signed-in
/// user here until setup is known to be complete; this screen resolves
/// "not known yet": it waits for the check, offers a retry when offline,
/// and moves into the flow when setup is unfinished. A finished setup
/// needs nothing here — the router goes home.
class SetupLoadingScreen extends ConsumerStatefulWidget {
  const SetupLoadingScreen({super.key});

  /// First step of the setup flow (P16 builds it).
  static const firstStepRoute = '/setup/lifestyle';

  @override
  ConsumerState<SetupLoadingScreen> createState() => _SetupLoadingScreenState();
}

class _SetupLoadingScreenState extends ConsumerState<SetupLoadingScreen> {
  @override
  void initState() {
    super.initState();
    // The answer may already be known (cached) when the screen opens.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _continueIfIncomplete(ref.read(setupStatusProvider)),
    );
  }

  void _continueIfIncomplete(SetupStatus status) {
    if (mounted && status == SetupStatus.incomplete) {
      context.go(SetupLoadingScreen.firstStepRoute);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<SetupStatus>(
      setupStatusProvider,
      (_, next) => _continueIfIncomplete(next),
    );

    final isOffline = ref.watch(setupStatusProvider) == SetupStatus.unavailable;
    final isSigningOut = ref.watch(authNotifierProvider) is AuthLoading;

    return Scaffold(
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
                  height: 56,
                  excludeFromSemantics: true,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.restaurant_menu,
                    color: AppColors.warning,
                    size: 56,
                  ),
                ),
                const SizedBox(height: 32),
                if (isOffline) ...[
                  const Icon(
                    Icons.wifi_off_rounded,
                    color: AppColors.textSecondary,
                    size: 32,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No connection. Check your internet and try again.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: AppColors.textPrimary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  CustomButton(
                    text: 'Try again',
                    onPressed: () =>
                        ref.read(setupStatusProvider.notifier).refresh(),
                  ),
                  const SizedBox(height: 8),
                  // Offline with nothing cached is a dead end without this.
                  TextButton(
                    onPressed: isSigningOut
                        ? null
                        : () =>
                              ref.read(authNotifierProvider.notifier).signOut(),
                    child: const Text(
                      'Sign out',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ] else ...[
                  const SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Getting things ready…',
                    style: TextStyle(
                      fontSize: 15,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
