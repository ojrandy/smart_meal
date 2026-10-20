import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/providers/app_config_provider.dart';
import '../../../core/providers/supabase_provider.dart';

/// Auth Repository — Data Layer
///
/// Wraps all Supabase Auth SDK calls.
/// No UI logic, no Riverpod state — just clean data operations.
///
/// Responsibilities:
/// - Email & password sign-up / sign-in
/// - Google OAuth sign-in via Supabase
/// - Session management (sign-out, current user)
/// - Auth state change stream
class AuthRepository {
  final SupabaseClient _client;

  // ── Google Sign-In Configuration ──────────────────────────────────────────
  // serverClientId is required to receive the server auth code on Android,
  // which is then exchanged with Supabase via signInWithIdToken.
  final GoogleSignIn _googleSignIn;

  AuthRepository(this._client, {required String googleWebClientId})
    : _googleSignIn = GoogleSignIn(serverClientId: googleWebClientId);

  // ── Current Session ────────────────────────────────────────────────────────

  /// Returns the currently authenticated Supabase user, or null.
  User? get currentUser => _client.auth.currentUser;

  // ── Auth State Stream ──────────────────────────────────────────────────────

  /// Emits an [AuthState] event whenever the session changes.
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  // ── Email & Password ───────────────────────────────────────────────────────

  /// Creates a new account with [email] and [password].
  ///
  /// Throws [AuthException] on failure (e.g. email already in use,
  /// weak password, network error).
  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) {
    return _client.auth.signUp(email: email, password: password);
  }

  /// Signs in an existing user with [email] and [password].
  ///
  /// Throws [AuthException] on failure (e.g. invalid credentials).
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) {
    return _client.auth.signInWithPassword(email: email, password: password);
  }

  // ── Google OAuth ───────────────────────────────────────────────────────────

  /// Initiates the native Google Sign-In flow, then exchanges the Google
  /// ID token with Supabase to create or sign in the Supabase user.
  ///
  /// Throws [AuthException] if Google token retrieval fails.
  /// Throws a general [Exception] if the user cancels the Google picker.
  Future<AuthResponse> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();

    if (googleUser == null) {
      // The user closed the Google sign-in picker without selecting an account.
      throw Exception('Google sign-in was cancelled.');
    }

    final googleAuth = await googleUser.authentication;
    final idToken = googleAuth.idToken;

    if (idToken == null) {
      throw const AuthException(
        'Failed to retrieve a Google ID token. '
        'Ensure your Google Cloud OAuth client is configured correctly.',
      );
    }

    return _client.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: googleAuth.accessToken,
    );
  }

  // ── Sign Out ───────────────────────────────────────────────────────────────

  /// Signs out from both Google and Supabase.
  Future<void> signOut() async {
    // Sign out from Google first so the picker reappears next time.
    await _googleSignIn.signOut();
    await _client.auth.signOut();
  }

  // ── Password Reset ─────────────────────────────────────────────────────────

  /// Sends a password reset email to [email].
  Future<void> resetPassword(String email) {
    return _client.auth.resetPasswordForEmail(email);
  }
}

// ── Riverpod Provider ──────────────────────────────────────────────────────

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final config = ref.watch(appConfigProvider);
  return AuthRepository(client, googleWebClientId: config.googleWebClientId);
});
