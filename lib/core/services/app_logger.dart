import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

/// Debug-only logger. Every call is a no-op in profile and release builds,
/// so nothing logged here can ship. Never pass tokens, credentials or
/// personal data, even in debug.
class AppLogger {
  AppLogger._();

  static void log(
    String message, {
    required String name,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (!kDebugMode) return;
    developer.log(message, name: name, error: error, stackTrace: stackTrace);
  }
}
