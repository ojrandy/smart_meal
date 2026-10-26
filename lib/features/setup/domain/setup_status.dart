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

  // Bumped by every newer fact (a user change, a completed setup). A server
  // answer is applied only if nothing newer arrived while it was in flight,
  // so a check started before `complete_setup` committed cannot undo it.
  int _generation = 0;

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
    _generation++;
    if (userId == null) return SetupStatus.signedOut;

    scheduleMicrotask(() => unawaited(refresh()));
    return switch (_repo.cachedIsComplete(userId)) {
      true => SetupStatus.complete,
      false => SetupStatus.incomplete,
      null => SetupStatus.checking,
    };
  }

  /// Records a setup just saved on the server (P16), so the router leaves
  /// setup at once without another round trip.
  Future<void> markComplete() async {
    final userId = _userId;
    if (userId == null) return;
    _generation++;
    state = SetupStatus.complete;
    await _repo.cache(userId, isComplete: true);
  }

  /// Asks the server again. Without a connection the cached answer stands;
  /// with no cached answer the status becomes [SetupStatus.unavailable].
  Future<void> refresh() async {
    final userId = _userId;
    if (userId == null) return;
    final generation = _generation;
    if (state == SetupStatus.unavailable) state = SetupStatus.checking;

    try {
      final isComplete = await _repo.fetchIsComplete(userId);
      // Signed out, switched user, or setup completed meanwhile: stale.
      if (generation != _generation) return;
      state = isComplete ? SetupStatus.complete : SetupStatus.incomplete;
      await _repo.cache(userId, isComplete: isComplete);
    } catch (error, stackTrace) {
      AppLogger.log(
        'Setup status check failed',
        name: 'setup',
        error: error,
        stackTrace: stackTrace,
      );
      if (generation == _generation && state == SetupStatus.checking) {
        state = SetupStatus.unavailable;
      }
    }
  }
}

final setupStatusProvider = NotifierProvider<SetupStatusNotifier, SetupStatus>(
  SetupStatusNotifier.new,
);
