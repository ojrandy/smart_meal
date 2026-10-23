import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_meal/core/theme/app_fonts.dart';
import 'package:smart_meal/core/theme/app_theme.dart';
import 'package:smart_meal/core/widgets/custom_button.dart';
import 'package:smart_meal/core/widgets/social_auth_button.dart';
import 'package:smart_meal/features/auth/data/auth_repository.dart';
import 'package:smart_meal/features/auth/presentation/screens/login_screen.dart';
import 'package:smart_meal/features/auth/presentation/screens/signup_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthResponse;

import '../../../../helpers/fake_auth_repository.dart';

Future<FakeAuthRepository> _pump(WidgetTester tester, String location) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.75;
  addTearDown(tester.view.reset);

  final repository = FakeAuthRepository();
  addTearDown(repository.dispose);
  final router = GoRouter(
    initialLocation: location,
    routes: [
      GoRoute(path: '/auth/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/auth/signup', builder: (_, _) => const SignupScreen()),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
      child: MaterialApp.router(
        theme: AppTheme.lightTheme,
        routerConfig: router,
      ),
    ),
  );
  await tester.pump();
  return repository;
}

Finder _field(int index) => find.byType(TextFormField).at(index);

Future<void> _tapText(WidgetTester tester, String text) async {
  await tester.ensureVisible(find.text(text));
  await tester.tap(find.text(text));
  await tester.pump();
}

void main() {
  setUpAll(AppFonts.configure);

  for (final location in ['/auth/login', '/auth/signup']) {
    testWidgets('$location offers Google as the only social sign-in', (
      tester,
    ) async {
      await _pump(tester, location);

      expect(find.byType(SocialAuthButton), findsOneWidget);
      expect(find.text('Continue with Google'), findsOneWidget);
      expect(find.textContaining('Apple'), findsNothing);
      expect(find.textContaining('Facebook'), findsNothing);
      expect(find.textContaining('coming soon'), findsNothing);
    });

    testWidgets('$location: cancelling Google shows nothing', (tester) async {
      final repo = await _pump(tester, location);
      repo.onSignInWithGoogle = () => throw const GoogleSignInCancelled();

      await _tapText(tester, 'Continue with Google');
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsNothing);
    });
  }

  group('login', () {
    testWidgets('asks for both fields when empty', (tester) async {
      await _pump(tester, '/auth/login');

      await _tapText(tester, 'Sign In ✨');

      expect(find.text('Please enter your email'), findsOneWidget);
      expect(find.text('Please enter your password'), findsOneWidget);
    });

    testWidgets('rejects an invalid email but not a short password', (
      tester,
    ) async {
      await _pump(tester, '/auth/login');
      await tester.enterText(_field(0), 'a@b');
      await tester.enterText(_field(1), 'short');

      await _tapText(tester, 'Sign In ✨');

      expect(find.text('Please enter a valid email'), findsOneWidget);
      expect(find.textContaining('characters'), findsNothing);
    });

    testWidgets('loading disables every action', (tester) async {
      final repo = await _pump(tester, '/auth/login');
      final response = Completer<AuthResponse>();
      repo.onSignIn = () => response.future;
      await tester.enterText(_field(0), 'a+b@x.company');
      await tester.enterText(_field(1), 'whatever');

      await _tapText(tester, 'Sign In ✨');

      expect(
        tester.widget<CustomButton>(find.byType(CustomButton)).isLoading,
        isTrue,
      );
      expect(
        tester
            .widget<SocialAuthButton>(find.byType(SocialAuthButton))
            .onPressed,
        isNull,
      );
      expect(
        tester
            .widget<TextButton>(
              find.widgetWithText(TextButton, 'Forgot password?'),
            )
            .onPressed,
        isNull,
      );

      response.complete(AuthResponse(session: testSession(testUser())));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<SocialAuthButton>(find.byType(SocialAuthButton))
            .onPressed,
        isNotNull,
      );
    });

    testWidgets('a failure shows the mapped message', (tester) async {
      final repo = await _pump(tester, '/auth/login');
      repo.onSignInWithGoogle = () => throw const GoogleSignInNetworkFailure();

      await _tapText(tester, 'Continue with Google');
      await tester.pump();

      expect(
        find.text('No connection. Check your internet and try again.'),
        findsOneWidget,
      );
    });
  });

  group('signup', () {
    testWidgets('enforces the password policy and the confirmation', (
      tester,
    ) async {
      await _pump(tester, '/auth/signup');
      await tester.enterText(_field(0), 'cook@example.com');
      await tester.enterText(_field(1), 'password1');
      await tester.enterText(_field(2), 'password2');

      await _tapText(tester, 'Create Account ✨');

      expect(
        find.text('Use upper- and lowercase letters, a number and a symbol'),
        findsOneWidget,
      );
      expect(find.text("Passwords don't match"), findsOneWidget);
    });

    testWidgets('without a session, confirms by email and goes to sign-in', (
      tester,
    ) async {
      final repo = await _pump(tester, '/auth/signup');
      repo.onSignUp = () async => AuthResponse(user: testUser());
      await tester.enterText(_field(0), 'cook@example.com');
      await tester.enterText(_field(1), 'Abcdef1!');
      await tester.enterText(_field(2), 'Abcdef1!');

      await _tapText(tester, 'Create Account ✨');
      await tester.pumpAndSettle();

      expect(
        find.text(
          "Almost there! We've sent a confirmation link to your email.",
        ),
        findsOneWidget,
      );
      expect(find.byType(LoginScreen), findsOneWidget);
    });
  });
}
