import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// The app's root [ScaffoldMessenger], given to `MaterialApp.router`. Lets
/// code without a screen of its own (e.g. a failed auth link) show a
/// snackbar that also survives the route change that follows.
final rootScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

/// Shows [message] as the app's floating snackbar, replacing any current
/// one. Errors are red; [isError] false gives the brand-green confirmation.
void showAppSnackBar(
  BuildContext context,
  String message, {
  bool isError = true,
  Duration duration = const Duration(seconds: 4),
}) {
  _show(ScaffoldMessenger.of(context), message, isError, duration);
}

/// [showAppSnackBar] on [rootScaffoldMessengerKey], for callers with no
/// [BuildContext] under the app. Does nothing before the app is built.
void showRootSnackBar(
  String message, {
  bool isError = true,
  Duration duration = const Duration(seconds: 4),
}) {
  final messenger = rootScaffoldMessengerKey.currentState;
  if (messenger != null) _show(messenger, message, isError, duration);
}

void _show(
  ScaffoldMessengerState messenger,
  String message,
  bool isError,
  Duration duration,
) {
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.primary,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        duration: duration,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
}
