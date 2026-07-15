import 'package:supabase_flutter/supabase_flutter.dart';

/// Sealed class representing all possible authentication states
/// in the SmartMeal application.
///
/// Use pattern matching to handle each case in the UI:
/// ```dart
/// switch (authState) {
///   case AuthInitial()       => ...
///   case AuthLoading()       => show CircularProgressIndicator
///   case AuthAuthenticated() => navigate to /home
///   case AuthUnauthenticated() => navigate to /auth/login
///   case AuthError()         => show SnackBar with message
/// }
/// ```
sealed class SmartMealAuthState {}

/// The initial state before any auth check has been resolved.
class AuthInitial extends SmartMealAuthState {}

/// An auth operation is in progress (sign-in, sign-up, sign-out).
/// Show a loading indicator while in this state.
class AuthLoading extends SmartMealAuthState {}

/// The user is authenticated and the session is active.
class AuthAuthenticated extends SmartMealAuthState {
  /// The authenticated Supabase user.
  final User user;

  AuthAuthenticated(this.user);
}

/// The user is not authenticated. Redirect to the login screen.
class AuthUnauthenticated extends SmartMealAuthState {}

/// An error occurred during an auth operation.
/// [message] is a user-friendly string safe to display in the UI.
class AuthError extends SmartMealAuthState {
  final String message;

  AuthError(this.message);
}
