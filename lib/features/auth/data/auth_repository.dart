import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/providers/app_config_provider.dart';
import '../../../core/providers/supabase_provider.dart';

/// Why the native Google step failed, typed so callers never match on
/// error text. Supabase failures after Google succeeds stay [AuthException].
sealed class GoogleSignInFailure implements Exception {
  const GoogleSignInFailure();
}

/// The user closed the account picker. Not an error.
class GoogleSignInCancelled extends GoogleSignInFailure {
  const GoogleSignInCancelled();
}

class GoogleSignInNetworkFailure extends GoogleSignInFailure {
  const GoogleSignInNetworkFailure();
}

/// Anything else, including a misconfigured OAuth client (no ID token).
class GoogleSignInFailed extends GoogleSignInFailure {
  const GoogleSignInFailed(this.reason);

  /// Developer-facing detail for the debug log only, never the UI.
  final String reason;
}

/// Auth Repository — Data Layer
///
/// Wraps all Supabase Auth SDK calls.
/// No UI logic, no Riverpod state — just clean data operations.
///
/// Responsibilities:
/// - Email & password sign-up / sign-in
/// - Google OAuth sign-in via Supabase
/// - Session management (sign-out, current user)
/// - Password recovery (reset email, new password)
/// - Auth state change stream
class AuthRepository {
  /// Where confirmation and recovery emails send the user back to. Must
  /// match the Android intent filter, the iOS `CFBundleURLTypes` entry and
  /// the Supabase redirect allow-list (`supabase/config.toml`) exactly.
  static const authRedirectUri = 'com.ojtech.smartmeal://auth-callback';

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
    return _client.auth.signUp(
      email: email,
      password: password,
      emailRedirectTo: authRedirectUri,
    );
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
  /// Throws a [GoogleSignInFailure] if the Google step fails or is
  /// cancelled, and [AuthException] if Supabase rejects the token.
  Future<AuthResponse> signInWithGoogle() async {
    final GoogleSignInAccount? googleUser;
    final GoogleSignInAuthentication googleAuth;
    try {
      googleUser = await _googleSignIn.signIn();
      if (googleUser == null) throw const GoogleSignInCancelled();
      googleAuth = await googleUser.authentication;
    } on PlatformException catch (e) {
      throw switch (e.code) {
        GoogleSignIn.kSignInCanceledError => const GoogleSignInCancelled(),
        GoogleSignIn.kNetworkError => const GoogleSignInNetworkFailure(),
        _ => GoogleSignInFailed('PlatformException ${e.code}'),
      };
    }

    final idToken = googleAuth.idToken;
    if (idToken == null) {
      throw const GoogleSignInFailed(
        'No Google ID token: check the OAuth client configuration.',
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

  /// Sends a password reset email to [email]. The link opens the app, and
  /// supabase_flutter exchanges its PKCE code for a recovery session, which
  /// emits [AuthChangeEvent.passwordRecovery]. The verifier stays on this
  /// device, so the link only works where it was requested.
  Future<void> resetPassword(String email) {
    return _client.auth.resetPasswordForEmail(
      email,
      redirectTo: authRedirectUri,
    );
  }

  /// Sets the signed-in (recovery) user's new password.
  Future<void> updatePassword(String password) {
    return _client.auth.updateUser(UserAttributes(password: password));
  }

  /// Revokes every session of this user except the current one.
  Future<void> signOutOtherSessions() {
    return _client.auth.signOut(scope: SignOutScope.others);
  }
}

// ── Riverpod Provider ──────────────────────────────────────────────────────

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final config = ref.watch(appConfigProvider);
  return AuthRepository(client, googleWebClientId: config.googleWebClientId);
});
