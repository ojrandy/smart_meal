// SmartMeal — App shell smoke test
//
// Pumps the real app (router, theme, auth notifier) with a hand-written fake
// auth repository, so no Supabase client or network is needed.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smart_meal/features/auth/data/auth_repository.dart';
import 'package:smart_meal/features/splash/presentation/splash_screen.dart';
import 'package:smart_meal/main.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Signed-out user; every auth action is unused by the smoke test.
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

void main() {
  setUpAll(() {
    // Tests have no network; fall back to the default font instead of
    // fetching Inter.
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('app starts on the splash screen', (tester) async {
    final authRepository = FakeAuthRepository();
    addTearDown(authRepository.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(authRepository)],
        child: const SmartMealApp(),
      ),
    );
    await tester.pump();

    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.text('AI POWERED FOOD COMPANION'), findsOneWidget);

    // Unmount so the splash's delayed navigation is not left pending.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 6));
  });
}
