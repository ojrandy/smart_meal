/// The state of the auth *operation* a screen started (sign-in, sign-up,
/// sign-out, password reset). Whether someone is signed in is not here: that
/// comes from the Supabase session through `authSessionProvider`, which is
/// all the router reads.
///
/// ```dart
/// switch (authState) {
///   case AuthIdle()                       => ...
///   case AuthLoading()                    => disable buttons, show spinner
///   case AuthError()                      => show SnackBar for the reason
///   case AuthAwaitingEmailConfirmation()  => tell the user to check email
///   case AuthResetEmailSent()             => confirm the reset email
///   case AuthPasswordUpdated()            => confirm the new password
///   case AuthReauthenticationRequired()   => ask to sign in again, retry
///   case AuthAccountDeleted()             => confirm; the router signs out
/// }
/// ```
sealed class SmartMealAuthState {}

/// Nothing in progress. Success also returns here; the session change
/// moves the router.
class AuthIdle extends SmartMealAuthState {}

/// An auth operation is in progress. Disable every auth action.
class AuthLoading extends SmartMealAuthState {}

/// An operation failed. The screen words [reason] in the user's language
/// (`authErrorText`); raw server text never reaches the user.
class AuthError extends SmartMealAuthState {
  final AuthErrorReason reason;

  AuthError(this.reason);
}

/// Why an auth operation failed, as far as the user needs to know.
enum AuthErrorReason {
  noConnection,
  invalidCredentials,
  emailExists,
  weakPassword,
  emailNotConfirmed,
  tooManyAttempts,
  signupDisabled,
  emailAddressInvalid,
  validationFailed,
  samePassword,
  sessionExpired,
  userBanned,
  googleSignInFailed,
  signOutFailed,
  accountDeletionFailed,
  generic,
}

/// Sign-up succeeded without a session: email confirmation is on. Supabase
/// answers the same way for an already-registered email, so copy shown for
/// this state must be true in both cases.
class AuthAwaitingEmailConfirmation extends SmartMealAuthState {}

/// A password reset email was requested. Also the answer when Supabase
/// rate-limits the request, so it never reveals whether the account exists.
class AuthResetEmailSent extends SmartMealAuthState {}

/// A recovery session set its new password; recovery has ended.
class AuthPasswordUpdated extends SmartMealAuthState {}

/// Account deletion needs a fresh sign-in first (server window: 10 min).
/// Nothing was deleted.
class AuthReauthenticationRequired extends SmartMealAuthState {}

/// The account and all its data are deleted and this device is signed out.
class AuthAccountDeleted extends SmartMealAuthState {}
