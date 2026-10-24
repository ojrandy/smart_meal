/// Everything the router guard decides on, captured at one moment.
class LaunchSnapshot {
  const LaunchSnapshot({
    required this.location,
    required this.isReady,
    required this.isSignedIn,
    required this.isOnboardingSeen,
    this.isRecovering = false,
    this.isSetupComplete = false,
  });

  /// The matched location being navigated to, e.g. `/auth/login`.
  final String location;

  /// The splash hold has elapsed.
  final bool isReady;
  final bool isSignedIn;
  final bool isOnboardingSeen;

  /// The session comes from a password-recovery link and no new password
  /// has been set yet.
  final bool isRecovering;

  /// The signed-in user has finished setup, as far as this device knows.
  /// "Not finished" and "not known yet" are both false: the setup loading
  /// screen resolves which.
  final bool isSetupComplete;
}

const resetPasswordRoute = '/auth/reset-password';
const setupEntryRoute = '/setup/loading';
const homeRoute = '/home';

/// The router guard as a pure function: where to send the user instead of
/// [LaunchSnapshot.location], or null to let them through.
///
/// | Ready | Session | Recovery | Onboarding seen | Setup complete | From splash          | Guard elsewhere                          |
/// |-------|---------|----------|-----------------|----------------|----------------------|------------------------------------------|
/// | no    | –       | –        | –               | –              | stay                 | stay                                     |
/// | yes   | none    | –        | no              | –              | /onboarding          | protected → /auth/login                  |
/// | yes   | none    | –        | yes             | –              | /auth/login          | protected → /auth/login                  |
/// | yes   | yes     | yes      | –               | –              | /auth/reset-password | everything → /auth/reset-password        |
/// | yes   | yes     | no       | –               | no / unknown   | /setup/loading       | public and main routes → /setup/loading  |
/// | yes   | yes     | no       | –               | yes            | /home                | /setup/* and public routes → /home       |
///
/// Public routes are `/onboarding` and `/auth/*`; the reset screen is only
/// reachable with a recovery session.
String? resolveRedirect(LaunchSnapshot snapshot) {
  final location = snapshot.location;

  if (location == '/splash' && !snapshot.isReady) return null;

  // A recovery session is good for one thing only: setting a new password.
  if (snapshot.isSignedIn && snapshot.isRecovering) {
    return location == resetPasswordRoute ? null : resetPasswordRoute;
  }

  final isPublic =
      location == '/onboarding' ||
      location == '/auth' ||
      location.startsWith('/auth/');
  final isSetup = location == '/setup' || location.startsWith('/setup/');

  if (!snapshot.isSignedIn) {
    if (location == '/splash') {
      return snapshot.isOnboardingSeen ? '/auth/login' : '/onboarding';
    }
    if (location == resetPasswordRoute) return '/auth/login';
    return isPublic ? null : '/auth/login';
  }

  // Signed in, not recovering: setup decides between the flow and the app.
  if (!snapshot.isSetupComplete) {
    return isSetup ? null : setupEntryRoute;
  }
  if (location == '/splash' || isPublic || isSetup) return homeRoute;
  return null;
}
