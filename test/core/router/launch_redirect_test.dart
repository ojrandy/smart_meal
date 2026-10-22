import 'package:flutter_test/flutter_test.dart';
import 'package:smart_meal/core/router/launch_redirect.dart';

String? _redirect(
  String location, {
  bool ready = true,
  bool signedIn = false,
  bool onboardingSeen = false,
}) => resolveRedirect(
  LaunchSnapshot(
    location: location,
    isReady: ready,
    isSignedIn: signedIn,
    isOnboardingSeen: onboardingSeen,
  ),
);

void main() {
  group('from the splash', () {
    test('stays until ready, whatever the session', () {
      expect(_redirect('/splash', ready: false), isNull);
      expect(_redirect('/splash', ready: false, signedIn: true), isNull);
    });

    test('a new device goes to onboarding', () {
      expect(_redirect('/splash'), '/onboarding');
    });

    test('a returning signed-out user skips onboarding', () {
      expect(_redirect('/splash', onboardingSeen: true), '/auth/login');
    });

    test('a signed-in user goes home, seen or not', () {
      expect(_redirect('/splash', signedIn: true), '/home');
      expect(
        _redirect('/splash', signedIn: true, onboardingSeen: true),
        '/home',
      );
    });
  });

  group('signed out', () {
    for (final location in [
      '/onboarding',
      '/auth/login',
      '/auth/signup',
      '/auth/forgot-password',
    ]) {
      test('may open public $location', () {
        expect(_redirect(location), isNull);
      });
    }

    for (final location in [
      '/home',
      '/home/recipe/1',
      '/profile',
      '/setup/loading',
      // Only /auth and /auth/* are public, not anything starting with it.
      '/authors',
    ]) {
      test('is sent from protected $location to sign-in', () {
        expect(_redirect(location), '/auth/login');
      });
    }
  });

  group('signed in', () {
    for (final location in ['/onboarding', '/auth/login', '/auth/signup']) {
      test('is sent from $location home', () {
        expect(_redirect(location, signedIn: true), '/home');
      });
    }

    for (final location in ['/home', '/discover', '/profile']) {
      test('may open $location', () {
        expect(_redirect(location, signedIn: true), isNull);
      });
    }
  });
}
