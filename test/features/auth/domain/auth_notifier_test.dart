import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_meal/features/auth/data/auth_repository.dart';
import 'package:smart_meal/features/auth/domain/auth_notifier.dart';
import 'package:smart_meal/features/auth/domain/auth_session.dart';
import 'package:smart_meal/features/auth/domain/auth_state.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../helpers/fake_auth_repository.dart';

const _generic = 'Something went wrong. Please try again.';
const _offline = 'No connection. Check your internet and try again.';

void main() {
  group('formatAuthError', () {
    for (final (code, message) in [
      ('invalid_credentials', 'Incorrect email or password. Please try again.'),
      (
        'email_exists',
        'An account with this email already exists. Try signing in.',
      ),
      (
        'user_already_exists',
        'An account with this email already exists. Try signing in.',
      ),
      (
        'weak_password',
        'Choose a stronger password: at least 8 characters with upper- and '
            'lowercase letters, a number and a symbol.',
      ),
      ('email_not_confirmed', 'Please confirm your email before signing in.'),
      (
        'over_email_send_rate_limit',
        'Too many attempts. Please wait a moment and try again.',
      ),
      (
        'over_request_rate_limit',
        'Too many attempts. Please wait a moment and try again.',
      ),
      (
        'signup_disabled',
        'New sign-ups are paused right now. Please try again later.',
      ),
      (
        'email_address_invalid',
        "That email address can't be used. Please check it and try again.",
      ),
      ('validation_failed', 'Please check your details and try again.'),
      (
        'same_password',
        'Your new password must be different from your current one.',
      ),
      ('session_expired', 'Your session has expired. Please sign in again.'),
      (
        'refresh_token_not_found',
        'Your session has expired. Please sign in again.',
      ),
      ('user_banned', "This account can't sign in right now."),
    ]) {
      test(code, () {
        expect(
          formatAuthError(AuthApiException('server text', code: code)),
          message,
        );
      });
    }

    test('an unknown code gets the generic message, not server text', () {
      expect(
        formatAuthError(const AuthException('raw server text', code: 'nope')),
        _generic,
      );
      expect(formatAuthError(const AuthException('raw server text')), _generic);
    });

    for (final (label, error) in [
      ('AuthRetryableFetchException', AuthRetryableFetchException()),
      ('SocketException', const SocketException('down')),
      ('TimeoutException', TimeoutException('slow')),
      ('Google network failure', const GoogleSignInNetworkFailure()),
    ]) {
      test('$label is a connection problem', () {
        expect(formatAuthError(error), _offline);
      });
    }

    test('a failed Google step hides the developer detail', () {
      expect(
        formatAuthError(const GoogleSignInFailed('check the OAuth client')),
        'Google sign-in failed. Please try again.',
      );
    });

    test('anything else is generic', () {
      expect(formatAuthError(StateError('bug')), _generic);
      expect(formatAuthError(null), _generic);
    });
  });

  group('AuthNotifier', () {
    late FakeAuthRepository repo;
    late ProviderContainer container;

    setUp(() {
      repo = FakeAuthRepository();
      container = ProviderContainer(
        overrides: [authRepositoryProvider.overrideWithValue(repo)],
      );
      // Keep the session provider alive, as the router does.
      container.listen(authSessionProvider, (_, _) {});
    });

    tearDown(() async {
      container.dispose();
      await repo.dispose();
    });

    AuthNotifier notifier() => container.read(authNotifierProvider.notifier);
    SmartMealAuthState state() => container.read(authNotifierProvider);

    test('starts idle', () => expect(state(), isA<AuthIdle>()));

    test(
      'sign-in success returns to idle; the session comes from Supabase',
      () async {
        final user = testUser();
        repo.onSignIn = () async {
          repo.signInAs(user);
          return AuthResponse(session: testSession(user));
        };

        final pending = notifier().signIn(email: 'a@b.co', password: 'x');
        expect(state(), isA<AuthLoading>());
        await pending;
        await Future<void>.delayed(Duration.zero);

        expect(state(), isA<AuthIdle>());
        expect(container.read(authSessionProvider), user);
      },
    );

    test('sign-in with wrong credentials shows the mapped message', () async {
      repo.onSignIn = () =>
          throw const AuthApiException('raw', code: 'invalid_credentials');

      await notifier().signIn(email: 'a@b.co', password: 'x');

      expect(
        (state() as AuthError).message,
        'Incorrect email or password. Please try again.',
      );
    });

    test('sign-in offline shows the connection message', () async {
      repo.onSignIn = () => throw AuthRetryableFetchException();

      await notifier().signIn(email: 'a@b.co', password: 'x');

      expect((state() as AuthError).message, _offline);
    });

    test('sign-up with a session returns to idle', () async {
      final user = testUser();
      repo.onSignUp = () async => AuthResponse(session: testSession(user));

      await notifier().signUp(email: 'a@b.co', password: 'Abcdef1!');

      expect(state(), isA<AuthIdle>());
    });

    test('sign-up without a session awaits email confirmation', () async {
      repo.onSignUp = () async => AuthResponse(user: testUser());

      await notifier().signUp(email: 'a@b.co', password: 'Abcdef1!');

      expect(state(), isA<AuthAwaitingEmailConfirmation>());
    });

    test('cancelling Google returns to idle with no error', () async {
      repo.onSignInWithGoogle = () => throw const GoogleSignInCancelled();

      await notifier().signInWithGoogle();

      expect(state(), isA<AuthIdle>());
    });

    test('Google offline shows the connection message', () async {
      repo.onSignInWithGoogle = () => throw const GoogleSignInNetworkFailure();

      await notifier().signInWithGoogle();

      expect((state() as AuthError).message, _offline);
    });

    test('a Supabase rejection after Google is mapped too', () async {
      repo.onSignInWithGoogle = () =>
          throw const AuthApiException('raw', code: 'user_banned');

      await notifier().signInWithGoogle();

      expect(
        (state() as AuthError).message,
        "This account can't sign in right now.",
      );
    });

    test('a failed sign-out with the session still here keeps the user in '
        'and says so', () async {
      final user = testUser();
      repo.signInAs(user);
      await Future<void>.delayed(Duration.zero);
      repo.onSignOut = () => throw const SocketException('down');

      await notifier().signOut();

      expect(
        (state() as AuthError).message,
        'Sign out failed. Please try again.',
      );
      expect(container.read(authSessionProvider), user);
    });

    test('a sign-out whose server revoke fails after the local session is '
        'gone is quiet', () async {
      repo.signInAs(testUser());
      await Future<void>.delayed(Duration.zero);
      repo.onSignOut = () async {
        repo.signOutLocally();
        throw AuthRetryableFetchException();
      };

      await notifier().signOut();
      await Future<void>.delayed(Duration.zero);

      expect(state(), isA<AuthIdle>());
      expect(container.read(authSessionProvider), isNull);
    });

    test('a reset request reports the email as sent', () async {
      repo.onResetPassword = () async {};

      await notifier().resetPassword('a@b.co');

      expect(state(), isA<AuthResetEmailSent>());
    });
  });
}
