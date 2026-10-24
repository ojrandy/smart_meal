import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/app_logger.dart';
import '../../auth/domain/auth_session.dart';
import '../data/setup_status_repository.dart';

/// Where the signed-in user stands with setup.
enum SetupStatus {
  /// No one is signed in.
  signedOut,

  /// First check for this user on this device, still running.
  checking,

  /// Setup not finished: the router keeps the user in `/setup/*`.
  incomplete,

  /// Setup finished: the main tabs are open.
  complete,

  /// No cached answer and the server could not be reached. The loading
  /// screen offers a retry.
  unavailable,
}

/// The setup gate the router reads (P15). Starts from this device's last
/// known answer for the user, so a cold start decides at once, then
/// confirms with the server on sign-in, on app resume and on [refresh].
class SetupStatusNotifier extends Notifier<SetupStatus> {
  String? _userId;

  SetupStatusRepository get _repo => ref.read(setupStatusRepositoryProvider);

  @override
  SetupStatus build() {
    ref.listen<String?>(authSessionProvider.select((user) => user?.id), (
      previous,
      next,
    ) {
      if (previous == next) return;
      // S12: the next person on this device starts from nothing.
      if (previous != null && next == null) {
        unawaited(_repo.clearCache(previous));
      }
      state = _startFor(next);
    });

    final lifecycle = AppLifecycleListener(
      onResume: () => unawaited(refresh()),
    );
    ref.onDispose(lifecycle.dispose);

    return _startFor(ref.read(authSessionProvider)?.id);
  }

  SetupStatus _startFor(String? userId) {
    _userId = userId;
    if (userId == null) return SetupStatus.signedOut;

    scheduleMicrotask(() => unawaited(refresh()));
    return switch (_repo.cachedIsComplete(userId)) {
      true => SetupStatus.complete,
      false => SetupStatus.incomplete,
      null => SetupStatus.checking,
    };
  }

  /// Asks the server again. Without a connection the cached answer stands;
  /// with no cached answer the status becomes [SetupStatus.unavailable].
  Future<void> refresh() async {
    final userId = _userId;
    if (userId == null) return;
    if (state == SetupStatus.unavailable) state = SetupStatus.checking;

    try {
      final isComplete = await _repo.fetchIsComplete(userId);
      if (_userId != userId) return; // Signed out or switched meanwhile.
      state = isComplete ? SetupStatus.complete : SetupStatus.incomplete;
      await _repo.cache(userId, isComplete: isComplete);
    } catch (error, stackTrace) {
      AppLogger.log(
        'Setup status check failed',
        name: 'setup',
        error: error,
        stackTrace: stackTrace,
      );
      if (_userId == userId && state == SetupStatus.checking) {
        state = SetupStatus.unavailable;
      }
    }
  }
}

final setupStatusProvider = NotifierProvider<SetupStatusNotifier, SetupStatus>(
  SetupStatusNotifier.new,
);
