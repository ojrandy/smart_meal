import 'dart:async';

import 'package:smart_meal/features/auth/data/auth_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Signed-out user; every auth action is unused by the tests that need it.
class FakeAuthRepository implements AuthRepository {
  final _authEvents = StreamController<AuthState>.broadcast();

  @override
  User? get currentUser => null;

  @override
  Stream<AuthState> get authStateChanges => _authEvents.stream;

  @override
  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) => throw UnimplementedError();

  @override
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) => throw UnimplementedError();

  @override
  Future<AuthResponse> signInWithGoogle() => throw UnimplementedError();

  @override
  Future<void> signOut() => throw UnimplementedError();

  @override
  Future<void> resetPassword(String email) => throw UnimplementedError();

  Future<void> dispose() => _authEvents.close();
}
