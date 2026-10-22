import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Shows [message] as the app's floating snackbar, replacing any current
/// one. Errors are red; [isError] false gives the brand-green confirmation.
void showAppSnackBar(
  BuildContext context,
  String message, {
  bool isError = true,
  Duration duration = const Duration(seconds: 4),
}) {
  ScaffoldMessenger.of(context)
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
