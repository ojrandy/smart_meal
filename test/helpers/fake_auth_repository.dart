import 'dart:async';

import 'package:smart_meal/features/auth/data/auth_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

User testUser({
  String email = 'cook@example.com',
  Map<String, dynamic> metadata = const {},
}) => User(
  id: '00000000-0000-0000-0000-000000000001',
  appMetadata: const {},
  userMetadata: metadata,
  aud: 'authenticated',
  email: email,
  createdAt: '2026-10-21T00:00:00Z',
);

Session testSession(User user) =>
    Session(accessToken: 'test-token', tokenType: 'bearer', user: user);

/// Hand-written auth repository. Starts signed out (or as [currentUser]);
/// each action runs its `on…` handler, and an action without one fails the
/// test with [UnimplementedError]. [signInAs] / [signOutLocally] mimic the
/// session events Supabase emits.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this.currentUser});

  final _authEvents = StreamController<AuthState>.broadcast();

  @override
  User? currentUser;

  Future<AuthResponse> Function()? onSignIn;
  Future<AuthResponse> Function()? onSignUp;
  Future<AuthResponse> Function()? onSignInWithGoogle;
  Future<void> Function()? onSignOut;
  Future<void> Function()? onResetPassword;

  void signInAs(User user) {
    currentUser = user;
    _authEvents.add(AuthState(AuthChangeEvent.signedIn, testSession(user)));
  }

  void signOutLocally() {
    currentUser = null;
    _authEvents.add(const AuthState(AuthChangeEvent.signedOut, null));
  }

  @override
  Stream<AuthState> get authStateChanges => _authEvents.stream;

  @override
  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) => (onSignUp ?? (throw UnimplementedError()))();

  @override
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) => (onSignIn ?? (throw UnimplementedError()))();

  @override
  Future<AuthResponse> signInWithGoogle() =>
      (onSignInWithGoogle ?? (throw UnimplementedError()))();

  @override
  Future<void> signOut() => (onSignOut ?? (throw UnimplementedError()))();

  @override
  Future<void> resetPassword(String email) =>
      (onResetPassword ?? (throw UnimplementedError()))();

  Future<void> dispose() => _authEvents.close();
}
