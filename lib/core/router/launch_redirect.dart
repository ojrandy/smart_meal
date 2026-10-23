/// Everything the router guard decides on, captured at one moment.
class LaunchSnapshot {
  const LaunchSnapshot({
    required this.location,
    required this.isReady,
    required this.isSignedIn,
    required this.isOnboardingSeen,
    this.isRecovering = false,
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
}

const resetPasswordRoute = '/auth/reset-password';

/// The router guard as a pure function: where to send the user instead of
/// [LaunchSnapshot.location], or null to let them through.
///
/// | From      | Signed in       | Onboarding seen | Goes to              |
/// |-----------|-----------------|-----------------|----------------------|
/// | splash    | (not ready yet)                   | stays                |
/// | anywhere  | yes, recovering | –               | /auth/reset-password |
/// | splash    | yes             | –               | /home                |
/// | splash    | no              | no              | /onboarding          |
/// | splash    | no              | yes             | /auth/login          |
/// | public    | yes             | –               | /home                |
/// | protected | no              | –               | /auth/login          |
///
/// Public routes are `/onboarding` and `/auth/*`; the reset screen is only
/// reachable with a recovery session. P15 adds the setup gate once profiles
/// exist (P13).
String? resolveRedirect(LaunchSnapshot snapshot) {
  final location = snapshot.location;

  if (location == '/splash' && !snapshot.isReady) return null;

  // A recovery session is good for one thing only: setting a new password.
  if (snapshot.isSignedIn && snapshot.isRecovering) {
    return location == resetPasswordRoute ? null : resetPasswordRoute;
  }

  if (location == '/splash') {
    if (snapshot.isSignedIn) return '/home';
    return snapshot.isOnboardingSeen ? '/auth/login' : '/onboarding';
  }

  if (location == resetPasswordRoute) {
    return snapshot.isSignedIn ? '/home' : '/auth/login';
  }

  final isPublic =
      location == '/onboarding' ||
      location == '/auth' ||
      location.startsWith('/auth/');

  if (snapshot.isSignedIn) return isPublic ? '/home' : null;
  return isPublic ? null : '/auth/login';
}
