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
          : AuthError(formatAuthError(null));
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
          : AuthError('Sign out failed. Please try again.');
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

  // ── Helper ─────────────────────────────────────────────────────────────────

  AuthError _failure(String operation, Object error, StackTrace stackTrace) {
    // The raw error goes to the debug log only; the UI gets a safe message.
    AppLogger.log(
      '$operation failed',
      name: 'auth',
      error: error,
      stackTrace: stackTrace,
    );
    return AuthError(formatAuthError(error));
  }
}

const _genericAuthError = 'Something went wrong. Please try again.';

/// Maps any auth failure to a user-safe message. The one error mapper for
/// auth: extend its switch when a new Supabase error code shows up, and
/// never return the error's own text.
///
/// Codes: https://supabase.com/docs/guides/auth/debugging/error-codes
@visibleForTesting
String formatAuthError(Object? error) {
  switch (error) {
    // Checked before the code switch: it carries no code.
    case sb.AuthRetryableFetchException():
    case SocketException():
    case TimeoutException():
    case GoogleSignInNetworkFailure():
      return 'No connection. Check your internet and try again.';
    case GoogleSignInFailed():
      return 'Google sign-in failed. Please try again.';
    case sb.AuthException(:final code):
      return switch (code) {
        'invalid_credentials' =>
          'Incorrect email or password. Please try again.',
        'email_exists' || 'user_already_exists' =>
          'An account with this email already exists. Try signing in.',
        'weak_password' =>
          'Choose a stronger password: at least 8 characters with upper- '
              'and lowercase letters, a number and a symbol.',
        'email_not_confirmed' => 'Please confirm your email before signing in.',
        'over_email_send_rate_limit' || 'over_request_rate_limit' =>
          'Too many attempts. Please wait a moment and try again.',
        'signup_disabled' =>
          'New sign-ups are paused right now. Please try again later.',
        'email_address_invalid' =>
          "That email address can't be used. Please check it and try again.",
        'validation_failed' => 'Please check your details and try again.',
        'same_password' =>
          'Your new password must be different from your current one.',
        'session_expired' || 'refresh_token_not_found' =>
          'Your session has expired. Please sign in again.',
        'user_banned' => "This account can't sign in right now.",
        _ => _genericAuthError,
      };
    default:
      return _genericAuthError;
  }
}

// ── Riverpod Provider ──────────────────────────────────────────────────────

final authNotifierProvider = NotifierProvider<AuthNotifier, SmartMealAuthState>(
  AuthNotifier.new,
);
