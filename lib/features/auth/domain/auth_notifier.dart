import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../data/auth_repository.dart';
import 'auth_state.dart';

/// Auth Notifier — Domain Layer
///
/// Manages the global authentication state for SmartMeal.
/// Listens to Supabase auth state changes via a stream subscription
/// so the state stays in sync even when sessions expire or are refreshed.
///
/// Exposed methods:
/// - [signIn]            — email & password sign-in
/// - [signUp]            — email & password account creation
/// - [signInWithGoogle]  — Google OAuth via Supabase
/// - [signOut]           — sign out from all providers
class AuthNotifier extends Notifier<SmartMealAuthState> {
  late StreamSubscription<sb.AuthState> _authSubscription;

  @override
  SmartMealAuthState build() {
    final repo = ref.watch(authRepositoryProvider);

    // ── Subscribe to real-time Supabase auth state changes ────────────────
    // This keeps our state in sync with the Supabase session automatically,
    // including token refreshes and session expiration.
    _authSubscription = repo.authStateChanges.listen((supabaseAuthState) {
      final session = supabaseAuthState.session;
      if (session != null) {
        state = AuthAuthenticated(session.user);
      } else {
        state = AuthUnauthenticated();
      }
    });

    ref.onDispose(() => _authSubscription.cancel());

    // ── Resolve the initial state synchronously ────────────────────────────
    // If a persisted session exists (user previously logged in), we start
    // in AuthAuthenticated to avoid a flash of the login screen.
    final currentUser = repo.currentUser;
    if (currentUser != null) {
      return AuthAuthenticated(currentUser);
    }
    return AuthUnauthenticated();
  }

  // ── Email & Password Sign-In ───────────────────────────────────────────────

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = AuthLoading();
    try {
      final response = await ref.read(authRepositoryProvider).signIn(
            email: email,
            password: password,
          );
      if (response.user != null) {
        state = AuthAuthenticated(response.user!);
      } else {
        state = AuthError('Sign in failed. Please check your credentials.');
      }
    } on sb.AuthException catch (e) {
      state = AuthError(_formatAuthError(e));
    } catch (_) {
      state = AuthError('An unexpected error occurred. Please try again.');
    }
  }

  // ── Email & Password Sign-Up ───────────────────────────────────────────────

  Future<void> signUp({
    required String email,
    required String password,
  }) async {
    state = AuthLoading();
    try {
      final response = await ref.read(authRepositoryProvider).signUp(
            email: email,
            password: password,
          );

      if (response.user == null) {
        state = AuthError('Account creation failed. Please try again.');
        return;
      }

      if (response.session != null) {
        // Email confirmation is OFF in Supabase — user is immediately active.
        state = AuthAuthenticated(response.user!);
      } else {
        // Email confirmation is ON — user must verify their email first.
        state = AuthUnauthenticated();
      }
    } on sb.AuthException catch (e) {
      state = AuthError(_formatAuthError(e));
    } catch (_) {
      state = AuthError('An unexpected error occurred. Please try again.');
    }
  }

  // ── Google Sign-In ─────────────────────────────────────────────────────────

  Future<void> signInWithGoogle() async {
    state = AuthLoading();
    try {
      final response =
          await ref.read(authRepositoryProvider).signInWithGoogle();
      if (response.user != null) {
        state = AuthAuthenticated(response.user!);
      } else {
        state = AuthError('Google sign-in failed. Please try again.');
      }
    } on sb.AuthException catch (e) {
      state = AuthError(_formatAuthError(e));
    } catch (e) {
      // Handles user-cancelled Google picker and unexpected failures.
      final message = e.toString().contains('cancelled')
          ? 'Sign-in cancelled.'
          : 'Google sign-in failed. Please try again.';
      state = AuthError(message);
    }
  }

  // ── Sign Out ───────────────────────────────────────────────────────────────

  Future<void> signOut() async {
    state = AuthLoading();
    try {
      await ref.read(authRepositoryProvider).signOut();
      state = AuthUnauthenticated();
    } catch (_) {
      state = AuthError('Sign out failed. Please try again.');
    }
  }

  // ── Password Reset ─────────────────────────────────────────────────────────

  Future<void> resetPassword(String email) async {
    state = AuthLoading();
    try {
      await ref.read(authRepositoryProvider).resetPassword(email);
      // Return to unauthenticated — let the UI show a success message.
      state = AuthUnauthenticated();
    } on sb.AuthException catch (e) {
      state = AuthError(_formatAuthError(e));
    } catch (_) {
      state = AuthError('Failed to send reset email. Please try again.');
    }
  }

  // ── Helper ─────────────────────────────────────────────────────────────────

  /// Maps Supabase [AuthException] codes to user-friendly messages.
  String _formatAuthError(sb.AuthException e) {
    switch (e.code) {
      case 'invalid_credentials':
        return 'Incorrect email or password. Please try again.';
      case 'user_already_exists':
        return 'An account with this email already exists.';
      case 'weak_password':
        return 'Password is too weak. Use at least 8 characters.';
      case 'email_not_confirmed':
        return 'Please confirm your email before signing in.';
      case 'over_email_send_rate_limit':
        return 'Too many requests. Please wait a moment and try again.';
      default:
        return e.message.isNotEmpty
            ? e.message
            : 'Authentication failed. Please try again.';
    }
  }
}

// ── Riverpod Provider ──────────────────────────────────────────────────────

final authNotifierProvider =
    NotifierProvider<AuthNotifier, SmartMealAuthState>(AuthNotifier.new);
