import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../../../core/services/app_logger.dart';
import '../data/auth_repository.dart';
import 'auth_state.dart';
import 'password_recovery.dart';

/// Auth Notifier — Domain Layer
///
/// Runs the auth operations screens start and reports their progress as a
/// [SmartMealAuthState]. It never decides where the user is: a successful
/// operation changes the Supabase session, `authSessionProvider` picks that
/// up, and the router redirects.
///
/// Exposed methods:
/// - [signIn]            — email & password sign-in
/// - [signUp]            — email & password account creation
/// - [signInWithGoogle]  — Google OAuth via Supabase
/// - [signOut]           — sign out from all providers
/// - [resetPassword]     — request a password reset email
/// - [updatePassword]    — set a new password from a recovery link
/// - [deleteAccount]     — delete the account and all its data
class AuthNotifier extends Notifier<SmartMealAuthState> {
  @override
  SmartMealAuthState build() => AuthIdle();

  AuthRepository get _repo => ref.read(authRepositoryProvider);

  // ── Email & Password Sign-In ───────────────────────────────────────────────

  Future<void> signIn({required String email, required String password}) async {
    state = AuthLoading();
    try {
      final response = await _repo.signIn(email: email, password: password);
      state = response.session != null
          ? AuthIdle()
          : AuthError(AuthErrorReason.generic);
    } catch (error, stackTrace) {
      state = _failure('signIn', error, stackTrace);
    }
  }

  // ── Email & Password Sign-Up ───────────────────────────────────────────────

  Future<void> signUp({required String email, required String password}) async {
    state = AuthLoading();
    try {
      final response = await _repo.signUp(email: email, password: password);
      // With a session, email confirmation is off and the user is in. Without
      // one, confirmation is on — or the email was already registered, which
      // Supabase deliberately reports the same way.
      state = response.session != null
          ? AuthIdle()
          : AuthAwaitingEmailConfirmation();
    } catch (error, stackTrace) {
      state = _failure('signUp', error, stackTrace);
    }
  }

  // ── Google Sign-In ─────────────────────────────────────────────────────────

  Future<void> signInWithGoogle() async {
    state = AuthLoading();
    try {
      await _repo.signInWithGoogle();
      state = AuthIdle();
    } on GoogleSignInCancelled {
      // Closing the picker is a choice, not an error: no message.
      state = AuthIdle();
    } catch (error, stackTrace) {
      state = _failure('signInWithGoogle', error, stackTrace);
    }
  }

  // ── Sign Out ───────────────────────────────────────────────────────────────

  Future<void> signOut() async {
    state = AuthLoading();
    try {
      await _repo.signOut();
      state = AuthIdle();
    } catch (error, stackTrace) {
      // Supabase drops the local session before revoking it on the server,
      // so a failed revoke has still signed this device out: nothing to show.
      // Only a session that is still here (e.g. the Google step failed)
      // means the user is still signed in and should hear about it.
      state = _repo.currentUser == null
          ? AuthIdle()
          : AuthError(AuthErrorReason.signOutFailed);
      AppLogger.log(
        'signOut failed',
        name: 'auth',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  // ── Password Reset ─────────────────────────────────────────────────────────

  Future<void> resetPassword(String email) async {
    state = AuthLoading();
    try {
      await _repo.resetPassword(email);
      state = AuthResetEmailSent();
    } catch (error, stackTrace) {
      if (error is sb.AuthException &&
          error.code == 'over_email_send_rate_limit') {
        // Supabase limits emails per *existing* account, so this error
        // alone would reveal that the account exists. Answer exactly as for
        // a sent email; the screen's resend cooldown stops quick retries.
        AppLogger.log(
          'resetPassword rate limited',
          name: 'auth',
          error: error,
          stackTrace: stackTrace,
        );
        state = AuthResetEmailSent();
      } else {
        state = _failure('resetPassword', error, stackTrace);
      }
    }
  }

  // ── New Password (recovery) ────────────────────────────────────────────────

  /// Sets the new password for a recovery session, revokes the user's other
  /// sessions, and ends recovery so the router continues as usual.
  Future<void> updatePassword(String password) async {
    state = AuthLoading();
    try {
      await _repo.updatePassword(password);
    } catch (error, stackTrace) {
      state = _failure('updatePassword', error, stackTrace);
      return;
    }

    try {
      await _repo.signOutOtherSessions();
    } catch (error, stackTrace) {
      // The password is changed, which is what the user asked for, so this
      // still succeeds. Other devices keep their sessions until they sign
      // out (known issue: no retry yet).
      AppLogger.log(
        'Revoking other sessions failed',
        name: 'auth',
        error: error,
        stackTrace: stackTrace,
      );
    }
    state = AuthPasswordUpdated();
    await ref.read(passwordRecoveryProvider.notifier).end();
  }

  // ── Account Deletion ───────────────────────────────────────────────────────

  /// Deletes the account and all its data, then signs this device out. The
  /// session change sends the router to sign-in; the UI entry point is the
  /// Profile screen (T1-Profile).
  Future<void> deleteAccount() async {
    state = AuthLoading();
    try {
      await _repo.deleteAccount();
      state = AuthAccountDeleted();
    } on AccountDeletionReauthRequired {
      state = AuthReauthenticationRequired();
    } catch (error, stackTrace) {
      state = _failure('deleteAccount', error, stackTrace);
    }
  }

  // ── Helper ─────────────────────────────────────────────────────────────────

  AuthError _failure(String operation, Object error, StackTrace stackTrace) {
    // The raw error goes to the debug log only; the UI gets a reason.
    AppLogger.log(
      '$operation failed',
      name: 'auth',
      error: error,
      stackTrace: stackTrace,
    );
    return AuthError(authErrorReason(error));
  }
}

/// Maps any auth failure to the reason the user is told. The one error
/// mapper for auth: extend its switch when a new Supabase error code shows
/// up. The screen turns the reason into words (`authErrorText`), so the
/// error's own text never reaches the user.
///
/// Codes: https://supabase.com/docs/guides/auth/debugging/error-codes
@visibleForTesting
AuthErrorReason authErrorReason(Object? error) {
  switch (error) {
    // Checked before the code switch: it carries no code.
    case sb.AuthRetryableFetchException():
    case SocketException():
    case TimeoutException():
    case GoogleSignInNetworkFailure():
      return AuthErrorReason.noConnection;
    case GoogleSignInFailed():
      return AuthErrorReason.googleSignInFailed;
    case AccountDeletionRateLimited():
      return AuthErrorReason.tooManyAttempts;
    case AccountDeletionFailed():
      return AuthErrorReason.accountDeletionFailed;
    case sb.AuthException(:final code):
      return switch (code) {
        'invalid_credentials' => AuthErrorReason.invalidCredentials,
        'email_exists' || 'user_already_exists' => AuthErrorReason.emailExists,
        'weak_password' => AuthErrorReason.weakPassword,
        'email_not_confirmed' => AuthErrorReason.emailNotConfirmed,
        'over_email_send_rate_limit' ||
        'over_request_rate_limit' => AuthErrorReason.tooManyAttempts,
        'signup_disabled' => AuthErrorReason.signupDisabled,
        'email_address_invalid' => AuthErrorReason.emailAddressInvalid,
        'validation_failed' => AuthErrorReason.validationFailed,
        'same_password' => AuthErrorReason.samePassword,
        'session_expired' ||
        'refresh_token_not_found' => AuthErrorReason.sessionExpired,
        'user_banned' => AuthErrorReason.userBanned,
        _ => AuthErrorReason.generic,
      };
    default:
      return AuthErrorReason.generic;
  }
}

// ── Riverpod Provider ──────────────────────────────────────────────────────

final authNotifierProvider = NotifierProvider<AuthNotifier, SmartMealAuthState>(
  AuthNotifier.new,
);
