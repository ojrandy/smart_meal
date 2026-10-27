import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_meal/core/providers/shared_preferences_provider.dart';
import 'package:smart_meal/features/auth/data/auth_repository.dart';
import 'package:smart_meal/features/setup/data/setup_repository.dart';
import 'package:smart_meal/features/setup/data/setup_status_repository.dart';
import 'package:smart_meal/features/setup/domain/setup_draft.dart';
import 'package:smart_meal/features/setup/domain/setup_notifier.dart';
import 'package:smart_meal/features/setup/domain/setup_status.dart';
import 'package:smart_meal/features/setup/domain/setup_vocabulary.dart';

import '../../../helpers/fake_auth_repository.dart';
import '../../../helpers/fake_setup_repository.dart';
import '../../../helpers/fake_setup_status_repository.dart';
import '../../../helpers/setup_fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeAuthRepository auth;
  late FakeSetupRepository setup;
  late FakeSetupStatusRepository status;
  late ProviderContainer container;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    auth = FakeAuthRepository(currentUser: testUser());
    setup = FakeSetupRepository();
    status = FakeSetupStatusRepository(serverComplete: false);
    container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(auth),
        sharedPreferencesProvider.overrideWithValue(prefs),
        setupRepositoryProvider.overrideWithValue(setup),
        setupStatusRepositoryProvider.overrideWithValue(status),
      ],
    );
    container.listen(setupNotifierProvider, (_, _) {});
    container.listen(setupStatusProvider, (_, _) {});
    await Future<void>.delayed(Duration.zero);
  });

  tearDown(() async {
    container.dispose();
    await auth.dispose();
  });

  SetupNotifier notifier() => container.read(setupNotifierProvider.notifier);
  SetupFlowState state() => container.read(setupNotifierProvider);
  SetupStep step() => (state() as SetupEditing).step;

  void fill(SetupDraft draft) => notifier().edit((_) => draft);

  test('starts at the first question with an empty draft', () {
    expect(step(), SetupStep.lifestyle);
    expect(state().draft.lifestyle, isNull);
  });

  test('Continue does not move past an unanswered question', () {
    expect(notifier().next(), SetupStep.lifestyle);
    notifier().edit((d) => d.withLifestyle(Lifestyle.student));
    expect(notifier().next(), SetupStep.household);
  });

  test('Back goes one step back and stops at the first', () {
    notifier().edit((d) => d.withLifestyle(Lifestyle.student));
    notifier().next();
    expect(notifier().back(), SetupStep.lifestyle);
    expect(notifier().back(), SetupStep.lifestyle);
  });

  test('answers survive moving between steps', () {
    notifier().edit((d) => d.withLifestyle(Lifestyle.athlete));
    notifier()
      ..next()
      ..back();
    expect(state().draft.lifestyle, Lifestyle.athlete);
  });

  test('submit refuses an incomplete draft and saves nothing', () async {
    await notifier().submit(minimumDuration: Duration.zero);
    expect(state(), isA<SetupEditing>());
    expect(setup.saved, isEmpty);
  });

  test('submit saves once, completes, and opens the gate', () async {
    fill(completeDraft());

    final pending = notifier().submit(minimumDuration: Duration.zero);
    expect(state(), isA<SetupSubmitting>());
    await pending;

    expect(state(), isA<SetupCompleted>());
    expect(setup.saved.single.allergies, {Allergen.peanuts});
    expect(container.read(setupStatusProvider), SetupStatus.complete);
  });

  test('a failed save keeps the answers and can be '
      'retried', () async {
    fill(completeDraft());
    setup.onComplete = (_) => throw const SocketException('down');

    await notifier().submit(minimumDuration: Duration.zero);

    final failed = state() as SetupFailed;
    expect(failed.draft.householdSize, 4);
    expect(container.read(setupStatusProvider), isNot(SetupStatus.complete));

    setup.onComplete = null;
    await notifier().submit(minimumDuration: Duration.zero);
    expect(state(), isA<SetupCompleted>());
  });

  test('a second submit while saving is ignored', () async {
    fill(completeDraft());
    final release = Completer<void>();
    setup.onComplete = (_) => release.future;

    final first = notifier().submit(minimumDuration: Duration.zero);
    await notifier().submit(minimumDuration: Duration.zero);
    release.complete();
    await first;

    expect(setup.saved, hasLength(1));
  });

  test('the save waits for the minimum display time', () async {
    fill(completeDraft());
    var done = false;
    final pending = notifier()
        .submit(minimumDuration: const Duration(milliseconds: 50))
        .then((_) => done = true);

    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(done, isFalse);
    await pending;
    expect(done, isTrue);
  });

  test('signing out discards the draft (S12)', () async {
    fill(completeDraft());

    auth.signOutLocally();
    await Future<void>.delayed(Duration.zero);

    expect(state().draft.lifestyle, isNull);
    expect(step(), SetupStep.lifestyle);
  });
}
