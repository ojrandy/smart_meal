import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_meal/core/providers/shared_preferences_provider.dart';
import 'package:smart_meal/features/auth/data/auth_repository.dart';
import 'package:smart_meal/features/auth/data/password_recovery_repository.dart';
import 'package:smart_meal/features/auth/domain/auth_notifier.dart';
import 'package:smart_meal/features/auth/domain/auth_session.dart';
import 'package:smart_meal/features/auth/domain/auth_state.dart';
import 'package:smart_meal/features/auth/domain/password_recovery.dart';
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

    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      repo = FakeAuthRepository();
      container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(repo),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
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

    test('a rate-limited reset answers exactly like a sent one', () async {
      repo.onResetPassword = () => throw const AuthApiException(
        'raw',
        code: 'over_email_send_rate_limit',
      );

      await notifier().resetPassword('a@b.co');

      expect(state(), isA<AuthResetEmailSent>());
    });

    test('a reset that fails otherwise shows the mapped message', () async {
      repo.onResetPassword = () => throw AuthRetryableFetchException();

      await notifier().resetPassword('a@b.co');

      expect((state() as AuthError).message, _offline);
    });
  });

  group('password recovery', () {
    late FakeAuthRepository repo;
    late ProviderContainer container;
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      repo = FakeAuthRepository();
      container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(repo),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      container.listen(authSessionProvider, (_, _) {});
    });

    tearDown(() async {
      container.dispose();
      await repo.dispose();
    });

    AuthNotifier notifier() => container.read(authNotifierProvider.notifier);
    SmartMealAuthState state() => container.read(authNotifierProvider);
    bool recovering() => container.read(passwordRecoveryProvider);
    bool persisted() =>
        prefs.getBool(PasswordRecoveryRepository.pendingKey) ?? false;

    Future<void> openRecoveryLink() async {
      repo.openRecoveryLinkAs(testUser());
      await Future<void>.delayed(Duration.zero);
    }

    test('a recovery link starts recovery and remembers it', () async {
      await openRecoveryLink();

      expect(recovering(), isTrue);
      expect(persisted(), isTrue);
      expect(container.read(authSessionProvider), isNotNull);
    });

    test('a pending recovery survives a restart', () async {
      await prefs.setBool(PasswordRecoveryRepository.pendingKey, true);

      expect(recovering(), isTrue);
    });

    test('a new password revokes other sessions and ends recovery', () async {
      await openRecoveryLink();
      String? saved;
      var othersRevoked = false;
      repo.onUpdatePassword = (password) async => saved = password;
      repo.onSignOutOtherSessions = () async => othersRevoked = true;

      final pending = notifier().updatePassword('N3w-password');
      expect(state(), isA<AuthLoading>());
      await pending;

      expect(saved, 'N3w-password');
      expect(othersRevoked, isTrue);
      expect(state(), isA<AuthPasswordUpdated>());
      expect(recovering(), isFalse);
      expect(persisted(), isFalse);
    });

    for (final (code, message) in [
      (
        'same_password',
        'Your new password must be different from your current one.',
      ),
      (
        'weak_password',
        'Choose a stronger password: at least 8 characters with upper- and '
            'lowercase letters, a number and a symbol.',
      ),
    ]) {
      test(
        '$code keeps the user in recovery with the mapped message',
        () async {
          await openRecoveryLink();
          repo.onUpdatePassword = (_) =>
              throw AuthApiException('raw', code: code);

          await notifier().updatePassword('N3w-password');

          expect((state() as AuthError).message, message);
          expect(recovering(), isTrue);
        },
      );
    }

    test(
      'a failed revoke of other sessions still completes the change',
      () async {
        await openRecoveryLink();
        repo.onUpdatePassword = (_) async {};
        repo.onSignOutOtherSessions = () => throw AuthRetryableFetchException();

        await notifier().updatePassword('N3w-password');

        expect(state(), isA<AuthPasswordUpdated>());
        expect(recovering(), isFalse);
      },
    );

    test('signing out ends recovery (S12)', () async {
      await openRecoveryLink();

      repo.signOutLocally();
      await Future<void>.delayed(Duration.zero);

      expect(recovering(), isFalse);
      expect(persisted(), isFalse);
    });

    test('a normal sign-in ends a leftover recovery', () async {
      await prefs.setBool(PasswordRecoveryRepository.pendingKey, true);
      expect(recovering(), isTrue);

      repo.signInAs(testUser());
      await Future<void>.delayed(Duration.zero);

      expect(recovering(), isFalse);
    });

    test('a failed auth link is reported once, as safe copy', () async {
      repo.failAuthLink(
        const AuthException(
          'Email link is invalid or has expired',
          statusCode: 'otp_expired',
          code: 'access_denied',
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(container.read(authLinkErrorProvider), authLinkErrorMessage);
      expect(container.read(authSessionProvider), isNull);
    });

    test('a token refresh that fails offline is not a link error', () async {
      repo.failAuthLink(AuthRetryableFetchException());
      await Future<void>.delayed(Duration.zero);

      expect(container.read(authLinkErrorProvider), isNull);
    });
  });

  group('isAuthLinkError', () {
    for (final (label, error, expected) in <(String, Object, bool)>[
      (
        'an error= redirect',
        const AuthException(
          'x',
          statusCode: 'otp_expired',
          code: 'access_denied',
        ),
        true,
      ),
      (
        'a missing PKCE verifier',
        const AuthException(
          'Code verifier could not be found in local storage.',
        ),
        true,
      ),
      (
        'a rejected code',
        const AuthApiException('x', code: 'bad_code_verifier'),
        true,
      ),
      ('no code in the link', const AuthPKCEGrantCodeExchangeError('x'), true),
      ('a refresh while offline', AuthRetryableFetchException(), false),
      (
        'a corrupt stored session',
        AuthException('x', code: ErrorCode.sessionMissing.code),
        false,
      ),
      (
        'an expired stored session',
        AuthException('x', code: ErrorCode.sessionExpired.code),
        false,
      ),
      ('a non-auth error', StateError('bug'), false),
    ]) {
      test('$label → $expected', () {
        expect(isAuthLinkError(error), expected);
      });
    }
  });
}
