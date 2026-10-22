// SmartMeal — App shell and launch-routing tests
//
// Pumps the real app (router, theme, auth notifier) with a hand-written fake
// auth repository and mock SharedPreferences, so no Supabase client or
// network is needed.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_meal/core/providers/shared_preferences_provider.dart';
import 'package:smart_meal/features/auth/data/auth_repository.dart';
import 'package:smart_meal/features/auth/presentation/screens/login_screen.dart';
import 'package:smart_meal/features/home/presentation/screens/home_screen.dart';
import 'package:smart_meal/features/onboarding/data/onboarding_repository.dart';
import 'package:smart_meal/features/onboarding/presentation/onboarding_screen.dart';
import 'package:smart_meal/features/splash/domain/launch_ready_notifier.dart';
import 'package:smart_meal/features/splash/presentation/splash_screen.dart';
import 'package:smart_meal/main.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show User;

import 'helpers/fake_auth_repository.dart';

Future<FakeAuthRepository> _pumpApp(
  WidgetTester tester, {
  User? signedInAs,
  bool onboardingSeen = false,
}) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.75;
  addTearDown(tester.view.reset);

  SharedPreferences.setMockInitialValues({
    if (onboardingSeen) OnboardingRepository.seenKey: true,
  });
  final prefs = await SharedPreferences.getInstance();
  final authRepository = FakeAuthRepository(currentUser: signedInAs);
  addTearDown(authRepository.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(authRepository),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const SmartMealApp(),
    ),
  );
  await tester.pump();
  return authRepository;
}

/// Lets the splash hold run out, then settles the route change.
Future<void> _finishSplash(WidgetTester tester) async {
  await tester.pump(LaunchReadyNotifier.splashHold);
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() {
    // Same as main(): Inter comes from assets/fonts, never the network.
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('the splash stays until the hold is over', (tester) async {
    await _pumpApp(tester);

    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.text('Your AI food companion'), findsOneWidget);

    await tester.pump(
      LaunchReadyNotifier.splashHold - const Duration(milliseconds: 100),
    );
    expect(find.byType(SplashScreen), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();
    expect(find.byType(SplashScreen), findsNothing);
  });

  testWidgets('a new device goes splash → onboarding', (tester) async {
    await _pumpApp(tester);
    await _finishSplash(tester);

    expect(find.byType(OnboardingScreen), findsOneWidget);
  });

  testWidgets('a returning signed-out user goes splash → sign-in', (
    tester,
  ) async {
    await _pumpApp(tester, onboardingSeen: true);
    await _finishSplash(tester);

    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('a signed-in user goes splash → home, greeted by name', (
    tester,
  ) async {
    await _pumpApp(
      tester,
      signedInAs: testUser(metadata: {'full_name': 'Ada Lovelace'}),
    );
    await _finishSplash(tester);

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('Welcome, Ada'), findsOneWidget);
    expect(find.text('Signed in as cook@example.com'), findsOneWidget);
  });

  testWidgets('signing in on the login screen lands on home', (tester) async {
    final repo = await _pumpApp(tester, onboardingSeen: true);
    await _finishSplash(tester);

    repo.signInAs(testUser());
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('signing out from home returns to sign-in', (tester) async {
    final repo = await _pumpApp(tester, signedInAs: testUser());
    await _finishSplash(tester);
    repo.onSignOut = () async => repo.signOutLocally();

    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('a failed sign-out keeps the user home with an error', (
    tester,
  ) async {
    final repo = await _pumpApp(tester, signedInAs: testUser());
    await _finishSplash(tester);
    repo.onSignOut = () => throw const SocketException('down');

    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('Sign out failed. Please try again.'), findsOneWidget);
  });
}
