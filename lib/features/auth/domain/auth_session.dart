import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../../../core/services/app_logger.dart';
import '../data/auth_repository.dart';

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
      (event) => state = event.session?.user,
      // A failed background token refresh arrives here; the session event
      // that follows (if any) decides the state.
      onError: (Object error, StackTrace stackTrace) => AppLogger.log(
        'Auth state stream error',
        name: 'auth',
        error: error,
        stackTrace: stackTrace,
      ),
    );
    ref.onDispose(subscription.cancel);

    // Supabase.initialize has already restored any persisted session, so the
    // first frame knows whether the user is signed in.
    return repo.currentUser;
  }
}

final authSessionProvider = NotifierProvider<AuthSessionNotifier, sb.User?>(
  AuthSessionNotifier.new,
);
