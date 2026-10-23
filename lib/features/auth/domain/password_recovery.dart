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

/// Shown when an emailed auth link (confirmation or recovery) is invalid,
/// expired, already used, or was opened on another device.
const authLinkErrorMessage =
    'This link is invalid or has expired. Please request a new one.';

/// The latest auth-link failure, as a user-safe message, until the app has
/// shown it and called [clear]. Set by `AuthSessionNotifier`.
class AuthLinkErrorNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void report() => state = authLinkErrorMessage;

  void clear() => state = null;
}

final authLinkErrorProvider = NotifierProvider<AuthLinkErrorNotifier, String?>(
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
