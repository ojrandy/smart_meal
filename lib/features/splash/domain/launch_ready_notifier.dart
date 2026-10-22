import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// True once the splash has been on screen for [splashHold]. The session
/// and the onboarding flag are already known at startup, so this is the
/// only thing the router waits for before leaving the splash.
class LaunchReadyNotifier extends Notifier<bool> {
  /// Long enough for the entrance to finish and register, short enough
  /// that the splash never feels like a wait (owner-approved, 2026-10-21).
  static const splashHold = Duration(milliseconds: 1600);

  @override
  bool build() {
    final timer = Timer(splashHold, () => state = true);
    ref.onDispose(timer.cancel);
    return false;
  }
}

final launchReadyProvider = NotifierProvider<LaunchReadyNotifier, bool>(
  LaunchReadyNotifier.new,
);
