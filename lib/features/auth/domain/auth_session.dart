import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../../../core/services/app_logger.dart';
import '../data/auth_repository.dart';
import 'password_recovery.dart';

/// The signed-in Supabase user, or null when signed out.
///
/// The only source of session truth: the router guard reads this and
/// nothing else, so an operation that is loading or failed (e.g. a sign-out
/// that could not complete) never moves the user.
class AuthSessionNotifier extends Notifier<sb.User?> {
  @override
  sb.User? build() {
    final repo = ref.watch(authRepositoryProvider);

    final subscription = repo.authStateChanges.listen(
      (event) {
        // The recovery flag moves first, so the router never sees a
        // recovery session without it.
        _trackRecovery(event);
        state = event.session?.user;
      },
      // A failed background token refresh or a bad auth link arrives here;
      // the session event that follows (if any) decides the state.
      onError: (Object error, StackTrace stackTrace) {
        AppLogger.log(
          'Auth state stream error',
          name: 'auth',
          error: error,
          stackTrace: stackTrace,
        );
        if (isAuthLinkError(error)) {
          ref.read(authLinkErrorProvider.notifier).report();
        }
      },
    );
    ref.onDispose(subscription.cancel);

    // Supabase.initialize has already restored any persisted session, so the
    // first frame knows whether the user is signed in.
    return repo.currentUser;
  }

  void _trackRecovery(sb.AuthState event) {
    final recovery = ref.read(passwordRecoveryProvider.notifier);
    switch (event.event) {
      case sb.AuthChangeEvent.passwordRecovery:
        unawaited(recovery.begin());
      // A normal sign-in, a sign-out (S12) or starting without a session
      // all end any recovery left on this device.
      case sb.AuthChangeEvent.signedIn:
      case sb.AuthChangeEvent.signedOut:
        unawaited(recovery.end());
      case sb.AuthChangeEvent.initialSession when event.session == null:
        unawaited(recovery.end());
      default:
        break;
    }
  }
}

final authSessionProvider = NotifierProvider<AuthSessionNotifier, sb.User?>(
  AuthSessionNotifier.new,
);
