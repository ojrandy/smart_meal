import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/app_logger.dart';
import '../../../core/services/network_errors.dart';
import '../../auth/domain/auth_session.dart';
import '../data/setup_repository.dart';
import 'setup_draft.dart';
import 'setup_status.dart';

/// Where the setup flow is. Every state carries the in-memory [draft].
sealed class SetupFlowState {
  const SetupFlowState(this.draft);

  final SetupDraft draft;
}

/// Answering questions; [step] is on screen.
class SetupEditing extends SetupFlowState {
  const SetupEditing(super.draft, this.step);

  final SetupStep step;
}

/// Saving all answers in one call.
class SetupSubmitting extends SetupFlowState {
  const SetupSubmitting(super.draft);
}

/// Saved; the router leaves setup on its own.
class SetupCompleted extends SetupFlowState {
  const SetupCompleted(super.draft);
}

/// Saving failed; nothing was stored. The screen offers a retry.
class SetupFailed extends SetupFlowState {
  const SetupFailed(super.draft, {this.noConnection = false});

  /// The server could not be reached (offline or timed out), so the screen
  /// says so instead of a generic failure.
  final bool noConnection;
}

/// Runs the setup flow (P16). The draft holds sensitive answers, so it
/// lives only here, in memory (S6): closing the app or signing out starts
/// again from the first step, and another user never sees it (S12).
class SetupNotifier extends Notifier<SetupFlowState> {
  @override
  SetupFlowState build() {
    // A different (or no) user means a fresh, empty draft.
    ref.watch(authSessionProvider.select((user) => user?.id));
    return const SetupEditing(SetupDraft(), SetupStep.lifestyle);
  }

  SetupDraft get draft => state.draft;

  /// Changes the draft without moving between steps.
  void edit(SetupDraft Function(SetupDraft draft) change) {
    final current = state;
    if (current is SetupEditing) {
      state = SetupEditing(change(current.draft), current.step);
    }
  }

  /// Moves to the step after [SetupEditing.step] when it is answered.
  /// Returns the step now on screen.
  SetupStep next() {
    final current = state;
    if (current is! SetupEditing) return SetupStep.goals;
    final step = current.step;
    if (!current.draft.isAnswered(step) || step == SetupStep.goals) return step;
    final following = SetupStep.values[step.index + 1];
    state = SetupEditing(current.draft, following);
    return following;
  }

  /// Moves one step back. Returns the step now on screen.
  SetupStep back() {
    final current = state;
    if (current is! SetupEditing) return SetupStep.lifestyle;
    if (current.step == SetupStep.lifestyle) return current.step;
    final previous = SetupStep.values[current.step.index - 1];
    state = SetupEditing(current.draft, previous);
    return previous;
  }

  /// Opens [step] directly, used when a route shows a different section
  /// than the current step (e.g. after system back between sections).
  void show(SetupStep step) {
    state = SetupEditing(state.draft, step);
  }

  /// Saves everything. Does nothing unless every required answer is given.
  /// Completion waits at least [minimumDuration], so the processing screen
  /// is seen even on a fast connection before the router moves on.
  Future<void> submit({
    Duration minimumDuration = const Duration(milliseconds: 2100),
  }) async {
    final draft = state.draft;
    if (draft.firstIncompleteStep != null || state is SetupSubmitting) return;

    state = SetupSubmitting(draft);
    try {
      await Future.wait([
        ref.read(setupRepositoryProvider).completeSetup(draft),
        Future<void>.delayed(minimumDuration),
      ]);
    } catch (error, stackTrace) {
      // Logged in debug builds only; the answers themselves are never
      // logged (S4, S6).
      AppLogger.log(
        'complete_setup failed',
        name: 'setup',
        error: error.runtimeType,
        stackTrace: stackTrace,
      );
      state = SetupFailed(draft, noConnection: isConnectionError(error));
      return;
    }
    state = SetupCompleted(draft);
    await ref.read(setupStatusProvider.notifier).markComplete();
  }
}

final setupNotifierProvider = NotifierProvider<SetupNotifier, SetupFlowState>(
  SetupNotifier.new,
);
