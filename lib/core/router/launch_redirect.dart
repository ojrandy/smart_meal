/// Everything the router guard decides on, captured at one moment.
class LaunchSnapshot {
  const LaunchSnapshot({
    required this.location,
    required this.isReady,
    required this.isSignedIn,
    required this.isOnboardingSeen,
  });

  /// The matched location being navigated to, e.g. `/auth/login`.
  final String location;

  /// The splash hold has elapsed.
  final bool isReady;
  final bool isSignedIn;
  final bool isOnboardingSeen;
}

/// The router guard as a pure function: where to send the user instead of
/// [LaunchSnapshot.location], or null to let them through.
///
/// | From      | Signed in | Onboarding seen | Goes to        |
/// |-----------|-----------|-----------------|----------------|
/// | splash    | (not ready yet)             | stays          |
/// | splash    | yes       | –               | /home          |
/// | splash    | no        | no              | /onboarding    |
/// | splash    | no        | yes             | /auth/login    |
/// | public    | yes       | –               | /home          |
/// | protected | no        | –               | /auth/login    |
///
/// Public routes are `/onboarding` and `/auth/*`. P15 adds the setup gate
/// once profiles exist (P13).
String? resolveRedirect(LaunchSnapshot snapshot) {
  final location = snapshot.location;

  if (location == '/splash') {
    if (!snapshot.isReady) return null;
    if (snapshot.isSignedIn) return '/home';
    return snapshot.isOnboardingSeen ? '/auth/login' : '/onboarding';
  }

  final isPublic =
      location == '/onboarding' ||
      location == '/auth' ||
      location.startsWith('/auth/');

  if (snapshot.isSignedIn) return isPublic ? '/home' : null;
  return isPublic ? null : '/auth/login';
}
