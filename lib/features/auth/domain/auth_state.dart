/// The state of the auth *operation* a screen started (sign-in, sign-up,
/// sign-out, password reset). Whether someone is signed in is not here: that
/// comes from the Supabase session through `authSessionProvider`, which is
/// all the router reads.
///
/// ```dart
/// switch (authState) {
///   case AuthIdle()                       => ...
///   case AuthLoading()                    => disable buttons, show spinner
///   case AuthError()                      => show SnackBar with message
///   case AuthAwaitingEmailConfirmation()  => tell the user to check email
///   case AuthResetEmailSent()             => confirm the reset email
/// }
/// ```
sealed class SmartMealAuthState {}

/// Nothing in progress. Success also returns here; the session change
/// moves the router.
class AuthIdle extends SmartMealAuthState {}

/// An auth operation is in progress. Disable every auth action.
class AuthLoading extends SmartMealAuthState {}

/// An operation failed. [message] is user-safe; never raw server text.
class AuthError extends SmartMealAuthState {
  final String message;

  AuthError(this.message);
}

/// Sign-up succeeded without a session: email confirmation is on. Supabase
/// answers the same way for an already-registered email, so copy shown for
/// this state must be true in both cases.
class AuthAwaitingEmailConfirmation extends SmartMealAuthState {}

/// A password reset email was requested.
class AuthResetEmailSent extends SmartMealAuthState {}
