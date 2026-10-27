import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_meal/core/l10n/l10n.dart';
import 'package:smart_meal/core/providers/shared_preferences_provider.dart';
import 'package:smart_meal/core/theme/app_fonts.dart';
import 'package:smart_meal/core/theme/app_theme.dart';
import 'package:smart_meal/core/widgets/custom_button.dart';
import 'package:smart_meal/features/auth/data/auth_repository.dart';
import 'package:smart_meal/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:smart_meal/features/auth/presentation/screens/reset_password_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show AuthApiException, AuthRetryableFetchException;

import '../../../../helpers/fake_auth_repository.dart';

const _sentCopy =
    "If an account exists for that email, we've sent a link to reset your "
    'password.';

Future<FakeAuthRepository> _pump(WidgetTester tester, String location) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.75;
  addTearDown(tester.view.reset);

  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final repository = FakeAuthRepository();
  addTearDown(repository.dispose);
  final router = GoRouter(
    initialLocation: location,
    routes: [
      GoRoute(
        path: '/auth/forgot-password',
        builder: (_, _) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/auth/reset-password',
        builder: (_, _) => const ResetPasswordScreen(),
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(repository),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: MaterialApp.router(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: AppTheme.lightTheme,
        routerConfig: router,
      ),
    ),
  );
  await tester.pump();
  return repository;
}

Finder _field(int index) => find.byType(TextFormField).at(index);

CustomButton _button(WidgetTester tester) =>
    tester.widget<CustomButton>(find.byType(CustomButton));

Future<void> _tapButton(WidgetTester tester) async {
  await tester.ensureVisible(find.byType(CustomButton));
  await tester.tap(find.byType(CustomButton));
  await tester.pump();
}

/// Runs the resend cooldown out so no timer outlives the test.
Future<void> _finishCooldown(WidgetTester tester) async {
  await tester.pump(ForgotPasswordScreen.resendCooldown);
  await tester.pump();
}

void main() {
  setUpAll(AppFonts.configure);

  group('forgot password', () {
    testWidgets('asks for a valid email', (tester) async {
      await _pump(tester, '/auth/forgot-password');

      await _tapButton(tester);
      expect(find.text('Please enter your email'), findsOneWidget);

      await tester.enterText(_field(0), 'a@b');
      await _tapButton(tester);
      expect(find.text('Please enter a valid email'), findsOneWidget);
    });

    testWidgets('shows loading, then the neutral confirmation and a '
        'cooldown before resending', (tester) async {
      final repo = await _pump(tester, '/auth/forgot-password');
      final response = Completer<void>();
      repo.onResetPassword = () => response.future;
      await tester.enterText(_field(0), 'cook@example.com');

      await _tapButton(tester);
      expect(_button(tester).isLoading, isTrue);

      response.complete();
      await tester.pump();

      expect(find.text(_sentCopy), findsOneWidget);
      expect(find.text('Resend in 60s'), findsOneWidget);
      expect(_button(tester).onPressed, isNull);

      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Resend in 59s'), findsOneWidget);

      await _finishCooldown(tester);
      expect(find.text('Resend link'), findsOneWidget);
      expect(_button(tester).onPressed, isNotNull);
    });

    testWidgets('a rate-limited request looks exactly like a sent one', (
      tester,
    ) async {
      final repo = await _pump(tester, '/auth/forgot-password');
      repo.onResetPassword = () => throw const AuthApiException(
        'raw',
        code: 'over_email_send_rate_limit',
      );
      await tester.enterText(_field(0), 'cook@example.com');

      await _tapButton(tester);
      await tester.pump();

      expect(find.text(_sentCopy), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
      expect(find.textContaining('raw'), findsNothing);
      await _finishCooldown(tester);
    });

    testWidgets('offline shows the connection message and no confirmation', (
      tester,
    ) async {
      final repo = await _pump(tester, '/auth/forgot-password');
      repo.onResetPassword = () => throw AuthRetryableFetchException();
      await tester.enterText(_field(0), 'cook@example.com');

      await _tapButton(tester);
      await tester.pump();

      expect(
        find.text('No connection. Check your internet and try again.'),
        findsOneWidget,
      );
      expect(find.text(_sentCopy), findsNothing);
      expect(_button(tester).onPressed, isNotNull);
    });
  });

  group('reset password', () {
    testWidgets('applies the new-password policy and the confirmation', (
      tester,
    ) async {
      await _pump(tester, '/auth/reset-password');

      await tester.enterText(_field(0), 'password1');
      await tester.enterText(_field(1), 'password2');
      await _tapButton(tester);

      expect(
        find.text('Use upper- and lowercase letters, a number and a symbol'),
        findsOneWidget,
      );
      expect(find.text("Passwords don't match"), findsOneWidget);
    });

    testWidgets('saves the password with loading, then confirms', (
      tester,
    ) async {
      final repo = await _pump(tester, '/auth/reset-password');
      final response = Completer<void>();
      String? saved;
      repo.onUpdatePassword = (password) {
        saved = password;
        return response.future;
      };
      repo.onSignOutOtherSessions = () async {};
      await tester.enterText(_field(0), 'N3w-password');
      await tester.enterText(_field(1), 'N3w-password');

      await _tapButton(tester);
      expect(_button(tester).isLoading, isTrue);

      response.complete();
      await tester.pumpAndSettle();

      expect(saved, 'N3w-password');
      expect(find.text('Your password has been updated.'), findsOneWidget);
    });

    testWidgets('same_password shows the mapped message', (tester) async {
      final repo = await _pump(tester, '/auth/reset-password');
      repo.onUpdatePassword = (_) =>
          throw const AuthApiException('raw', code: 'same_password');
      await tester.enterText(_field(0), 'N3w-password');
      await tester.enterText(_field(1), 'N3w-password');

      await _tapButton(tester);
      await tester.pump();

      expect(
        find.text('Your new password must be different from your current one.'),
        findsOneWidget,
      );
    });

    testWidgets('going back signs out instead of keeping the recovery '
        'session', (tester) async {
      final repo = await _pump(tester, '/auth/reset-password');
      var signedOut = false;
      repo.onSignOut = () async => signedOut = true;

      await tester.tap(find.byTooltip('Back'));
      await tester.pump();

      expect(signedOut, isTrue);
    });
  });
}
