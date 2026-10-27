import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../../../core/services/app_logger.dart';
import '../data/password_recovery_repository.dart';

/// True while the session comes from a password-recovery link and no new
/// password has been set. The router then allows only the reset screen, so
/// a recovery session never reaches Home.
///
/// `AuthSessionNotifier` sets it from the Supabase auth events *before* it
/// publishes the session, so the router never sees a recovery session
/// without the flag.
class PasswordRecoveryNotifier extends Notifier<bool> {
  @override
  bool build() => ref.watch(passwordRecoveryRepositoryProvider).isPending;

  Future<void> begin() => _set(true);

  Future<void> end() => _set(false);

  Future<void> _set(bool pending) async {
    if (state == pending) return;
    state = pending;
    try {
      await ref.read(passwordRecoveryRepositoryProvider).setPending(pending);
    } catch (error, stackTrace) {
      // The in-memory flag still guards this run; only a restart could
      // miss it.
      AppLogger.log(
        'Could not persist password recovery flag',
        name: 'auth',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}

final passwordRecoveryProvider =
    NotifierProvider<PasswordRecoveryNotifier, bool>(
      PasswordRecoveryNotifier.new,
    );

/// True from an auth-link failure until the app has shown it and called
/// [clear]: an emailed link (confirmation or recovery) was invalid,
/// expired, already used, or opened on another device. Set by
/// `AuthSessionNotifier`; the app words it (`authLinkErrorNotice`).
class AuthLinkErrorNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void report() => state = true;

  void clear() => state = false;
}

final authLinkErrorProvider = NotifierProvider<AuthLinkErrorNotifier, bool>(
  AuthLinkErrorNotifier.new,
);

/// Whether an error on the Supabase auth stream came from opening an auth
/// link. supabase_flutter reports a failed link (an `error=` redirect, a
/// missing PKCE verifier, a rejected code) as an [sb.AuthException] there.
/// The other errors on that stream are a lost connection during a token
/// refresh and a corrupt stored session, which are not the user's link.
bool isAuthLinkError(Object error) =>
    error is sb.AuthException &&
    error is! sb.AuthRetryableFetchException &&
    error.code != sb.ErrorCode.sessionMissing.code &&
    error.code != sb.ErrorCode.sessionExpired.code;
