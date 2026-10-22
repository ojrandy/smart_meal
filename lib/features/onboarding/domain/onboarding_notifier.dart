import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/app_logger.dart';
import '../data/onboarding_repository.dart';

/// Whether this device has seen onboarding. The router reads it to send
/// returning users from the splash straight to sign-in.
class OnboardingNotifier extends Notifier<bool> {
  @override
  bool build() => ref.watch(onboardingRepositoryProvider).isSeen;

  Future<void> markSeen() async {
    state = true;
    try {
      await ref.read(onboardingRepositoryProvider).markSeen();
    } catch (error, stackTrace) {
      // Not worth interrupting the user: worst case, onboarding shows again
      // on the next launch.
      AppLogger.log(
        'Could not persist onboarding seen',
        name: 'onboarding',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}

final onboardingSeenProvider = NotifierProvider<OnboardingNotifier, bool>(
  OnboardingNotifier.new,
);
