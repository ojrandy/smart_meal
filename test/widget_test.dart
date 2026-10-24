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
import 'package:smart_meal/features/auth/data/password_recovery_repository.dart';
import 'package:smart_meal/features/auth/domain/password_recovery.dart';
import 'package:smart_meal/features/auth/presentation/screens/reset_password_screen.dart';
import 'package:smart_meal/features/auth/presentation/screens/login_screen.dart';
import 'package:smart_meal/features/home/presentation/screens/home_screen.dart';
import 'package:smart_meal/features/onboarding/data/onboarding_repository.dart';
import 'package:smart_meal/features/onboarding/presentation/onboarding_screen.dart';
import 'package:smart_meal/features/splash/domain/launch_ready_notifier.dart';
import 'package:smart_meal/features/splash/presentation/splash_screen.dart';
import 'package:smart_meal/features/setup/data/setup_status_repository.dart';
import 'package:smart_meal/features/setup/presentation/setup_loading_screen.dart';
import 'package:smart_meal/main.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show AuthException, User;

import 'helpers/fake_auth_repository.dart';
import 'helpers/fake_setup_status_repository.dart';

Future<FakeAuthRepository> _pumpApp(
  WidgetTester tester, {
  User? signedInAs,
  bool onboardingSeen = false,
  bool recoveryPending = false,
  FakeSetupStatusRepository? setup,
}) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.75;
  addTearDown(tester.view.reset);

  SharedPreferences.setMockInitialValues({
    if (onboardingSeen) OnboardingRepository.seenKey: true,
    if (recoveryPending) PasswordRecoveryRepository.pendingKey: true,
  });
  final prefs = await SharedPreferences.getInstance();
  final authRepository = FakeAuthRepository(currentUser: signedInAs);
  addTearDown(authRepository.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(authRepository),
        sharedPreferencesProvider.overrideWithValue(prefs),
        setupStatusRepositoryProvider.overrideWithValue(
          setup ?? FakeSetupStatusRepository(serverComplete: true),
        ),
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

  testWidgets('a recovery link opens the reset screen, never home', (
    tester,
  ) async {
    final repo = await _pumpApp(tester, onboardingSeen: true);
    await _finishSplash(tester);

    repo.openRecoveryLinkAs(testUser());
    await tester.pumpAndSettle();

    expect(find.byType(ResetPasswordScreen), findsOneWidget);
    expect(find.byType(HomeScreen), findsNothing);
  });

  testWidgets('a recovery session restored at launch still lands on the '
      'reset screen', (tester) async {
    await _pumpApp(tester, signedInAs: testUser(), recoveryPending: true);
    await _finishSplash(tester);

    expect(find.byType(ResetPasswordScreen), findsOneWidget);
  });

  testWidgets('setting the new password continues home', (tester) async {
    final repo = await _pumpApp(
      tester,
      signedInAs: testUser(),
      recoveryPending: true,
    );
    await _finishSplash(tester);
    repo.onUpdatePassword = (_) async {};
    repo.onSignOutOtherSessions = () async {};

    await tester.enterText(find.byType(TextFormField).at(0), 'N3w-password');
    await tester.enterText(find.byType(TextFormField).at(1), 'N3w-password');
    await tester.ensureVisible(find.text('Save password'));
    await tester.tap(find.text('Save password'));
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('Your password has been updated.'), findsOneWidget);
  });

  testWidgets('a bad auth link shows the safe message, even during the '
      'splash, and keeps it across the route change', (tester) async {
    final repo = await _pumpApp(tester, onboardingSeen: true);

    repo.failAuthLink(
      const AuthException('raw server text', code: 'access_denied'),
    );
    await tester.pump();
    await _finishSplash(tester);

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text(authLinkErrorMessage), findsOneWidget);
    expect(find.textContaining('raw server text'), findsNothing);
  });

  testWidgets('a signed-in user without setup goes splash → setup, never '
      'home', (tester) async {
    await _pumpApp(
      tester,
      signedInAs: testUser(),
      setup: FakeSetupStatusRepository(serverComplete: false),
    );
    await _finishSplash(tester);

    expect(find.byType(HomeScreen), findsNothing);
    // The loading screen hands over to the first setup step.
    expect(find.widgetWithText(AppBar, 'Lifestyle Setup'), findsOneWidget);
  });

  testWidgets('signing in a new user leads into setup', (tester) async {
    final repo = await _pumpApp(
      tester,
      onboardingSeen: true,
      setup: FakeSetupStatusRepository(serverComplete: false),
    );
    await _finishSplash(tester);

    repo.signInAs(testUser());
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsNothing);
    expect(find.widgetWithText(AppBar, 'Lifestyle Setup'), findsOneWidget);
  });

  testWidgets('offline with no cached answer offers a retry, which '
      'recovers', (tester) async {
    final setup = FakeSetupStatusRepository(serverComplete: true)
      ..onFetch = (_) => throw const SocketException('down');
    await _pumpApp(tester, signedInAs: testUser(), setup: setup);
    await _finishSplash(tester);

    expect(find.byType(SetupLoadingScreen), findsOneWidget);
    expect(
      find.text('No connection. Check your internet and try again.'),
      findsOneWidget,
    );

    setup.onFetch = null;
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('a returning user with setup cached goes straight home, even '
      'offline', (tester) async {
    final user = testUser();
    final setup = FakeSetupStatusRepository(cached: {user.id: true})
      ..onFetch = (_) => throw const SocketException('down');
    await _pumpApp(tester, signedInAs: user, setup: setup);
    await _finishSplash(tester);

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(SetupLoadingScreen), findsNothing);
  });
}
