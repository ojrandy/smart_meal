import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_meal/core/providers/shared_preferences_provider.dart';
import 'package:smart_meal/features/auth/data/auth_repository.dart';
import 'package:smart_meal/features/setup/data/setup_status_repository.dart';
import 'package:smart_meal/features/setup/domain/setup_status.dart';

import '../../../helpers/fake_auth_repository.dart';
import '../../../helpers/fake_setup_status_repository.dart';

const _userId = '00000000-0000-0000-0000-000000000001';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeAuthRepository auth;
  late FakeSetupStatusRepository setup;
  late ProviderContainer container;

  Future<void> start({bool signedIn = true}) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    auth = FakeAuthRepository(currentUser: signedIn ? testUser() : null);
    container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(auth),
        sharedPreferencesProvider.overrideWithValue(prefs),
        setupStatusRepositoryProvider.overrideWithValue(setup),
      ],
    );
    container.listen(setupStatusProvider, (_, _) {});
  }

  SetupStatus status() => container.read(setupStatusProvider);
  Future<void> settle() => Future<void>.delayed(Duration.zero);

  tearDown(() async {
    container.dispose();
    await auth.dispose();
  });

  test('signed out is signedOut and asks nothing', () async {
    setup = FakeSetupStatusRepository();
    await start(signedIn: false);
    await settle();

    expect(status(), SetupStatus.signedOut);
    expect(setup.fetchCount, 0);
  });

  test('a first launch checks, then reports the server answer and caches '
      'it for this user', () async {
    setup = FakeSetupStatusRepository(serverComplete: true);
    await start();

    expect(status(), SetupStatus.checking);
    await settle();

    expect(status(), SetupStatus.complete);
    expect(setup.cached[_userId], isTrue);
  });

  test(
    'a cached answer decides at once, then the server corrects it',
    () async {
      setup = FakeSetupStatusRepository(
        serverComplete: false,
        cached: {_userId: true},
      );
      await start();

      expect(status(), SetupStatus.complete);
      await settle();

      expect(status(), SetupStatus.incomplete);
      expect(setup.cached[_userId], isFalse);
    },
  );

  test('offline with a cached answer keeps it', () async {
    setup = FakeSetupStatusRepository(cached: {_userId: true})
      ..onFetch = (_) => throw const SocketException('down');
    await start();
    await settle();

    expect(status(), SetupStatus.complete);
  });

  test(
    'offline with nothing cached is unavailable; a retry recovers',
    () async {
      setup = FakeSetupStatusRepository()
        ..onFetch = (_) => throw const SocketException('down');
      await start();
      await settle();
      expect(status(), SetupStatus.unavailable);

      setup
        ..onFetch = null
        ..serverComplete = false;
      final retry = container.read(setupStatusProvider.notifier).refresh();
      expect(status(), SetupStatus.checking);
      await retry;

      expect(status(), SetupStatus.incomplete);
    },
  );

  test('signing in checks the new user', () async {
    setup = FakeSetupStatusRepository(serverComplete: true);
    await start(signedIn: false);

    auth.signInAs(testUser());
    await settle();
    await settle();

    expect(status(), SetupStatus.complete);
    expect(setup.fetchCount, 1);
  });

  test("signing out clears that user's cached answer (S12)", () async {
    setup = FakeSetupStatusRepository(serverComplete: true);
    await start();
    await settle();
    expect(setup.cached[_userId], isTrue);

    auth.signOutLocally();
    await settle();

    expect(status(), SetupStatus.signedOut);
    expect(setup.cached.containsKey(_userId), isFalse);
  });

  test('returning to the app checks again', () async {
    setup = FakeSetupStatusRepository(serverComplete: false);
    await start();
    await settle();
    expect(status(), SetupStatus.incomplete);

    setup.serverComplete = true;
    WidgetsBinding.instance.handleAppLifecycleStateChanged(
      AppLifecycleState.inactive,
    );
    WidgetsBinding.instance.handleAppLifecycleStateChanged(
      AppLifecycleState.resumed,
    );
    await settle();

    expect(status(), SetupStatus.complete);
  });

  test(
    'a check started before setup completed cannot undo it (race)',
    () async {
      setup = FakeSetupStatusRepository(serverComplete: false);
      final slowAnswer = Completer<bool>();
      setup.onFetch = (_) => slowAnswer.future;
      await start();
      await settle(); // The first check is now in flight.

      await container.read(setupStatusProvider.notifier).markComplete();
      slowAnswer.complete(
        false,
      ); // Stale: read before complete_setup committed.
      await settle();

      expect(status(), SetupStatus.complete);
      expect(setup.cached[_userId], isTrue);
    },
  );
}
