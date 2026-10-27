import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_meal/core/l10n/l10n.dart';
import 'package:smart_meal/core/providers/shared_preferences_provider.dart';
import 'package:smart_meal/core/theme/app_fonts.dart';
import 'package:smart_meal/core/theme/app_theme.dart';
import 'package:smart_meal/features/auth/data/auth_repository.dart';
import 'package:smart_meal/features/setup/data/setup_repository.dart';
import 'package:smart_meal/features/setup/data/setup_status_repository.dart';
import 'package:smart_meal/features/setup/domain/setup_draft.dart';
import 'package:smart_meal/features/setup/domain/setup_notifier.dart';
import 'package:smart_meal/features/setup/domain/setup_status.dart';
import 'package:smart_meal/features/setup/domain/setup_vocabulary.dart';
import 'package:smart_meal/features/setup/presentation/setup_processing_screen.dart';
import 'package:smart_meal/features/setup/presentation/setup_questions_screen.dart';

import '../../../helpers/fake_auth_repository.dart';
import '../../../helpers/fake_setup_repository.dart';
import '../../../helpers/fake_setup_status_repository.dart';
import '../../../helpers/setup_fixtures.dart';

class _Harness {
  _Harness(this.container, this.router, this.setup);

  final ProviderContainer container;
  final GoRouter router;
  final FakeSetupRepository setup;

  SetupNotifier get notifier => container.read(setupNotifierProvider.notifier);
  String get location => router.state.matchedLocation;
}

Future<_Harness> _pump(
  WidgetTester tester, {
  String location = '/setup/lifestyle',
  SetupDraft? draft,
  SetupStep? step,
  Locale? locale,
}) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.75;
  addTearDown(tester.view.reset);

  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final auth = FakeAuthRepository(currentUser: testUser());
  addTearDown(auth.dispose);
  final status = FakeSetupStatusRepository(serverComplete: false);
  final setup = FakeSetupRepository(
    onSaved: () => status.serverComplete = true,
  );

  final container = ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWithValue(auth),
      sharedPreferencesProvider.overrideWithValue(prefs),
      setupRepositoryProvider.overrideWithValue(setup),
      setupStatusRepositoryProvider.overrideWithValue(status),
    ],
  );
  addTearDown(container.dispose);
  if (draft != null) {
    container.read(setupNotifierProvider.notifier)
      ..edit((_) => draft)
      ..show(step ?? SetupStep.lifestyle);
  }

  final router = GoRouter(
    initialLocation: location,
    routes: [
      GoRoute(
        path: '/setup/lifestyle',
        builder: (_, _) => const SetupQuestionsScreen(lifestyleSection: true),
      ),
      GoRoute(
        path: '/setup/preferences',
        builder: (_, _) => const SetupQuestionsScreen(lifestyleSection: false),
      ),
      GoRoute(
        path: '/setup/processing',
        builder: (_, _) => const SetupProcessingScreen(),
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: AppTheme.lightTheme,
        locale: locale,
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return _Harness(container, router, setup);
}

Future<void> _tap(WidgetTester tester, String text) async {
  await tester.ensureVisible(find.text(text).first);
  await tester.tap(find.text(text).first);
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(AppFonts.configure);

  testWidgets('a required question asks for an answer before moving on', (
    tester,
  ) async {
    await _pump(tester);

    expect(find.text('What best describes you?'), findsOneWidget);
    expect(find.text('Step 1 of 9'), findsOneWidget);
    await _tap(tester, 'Continue');
    expect(find.text('Please choose an option'), findsOneWidget);

    await _tap(tester, 'Student');
    await _tap(tester, 'Continue');
    expect(find.text('How many people do you cook for?'), findsOneWidget);
    expect(find.text('Please choose an option'), findsNothing);
  });

  testWidgets('the household counter stays within 1–20', (tester) async {
    final h = await _pump(
      tester,
      draft: const SetupDraft().withLifestyle(Lifestyle.family),
      step: SetupStep.household,
    );

    expect(
      tester
          .widget<IconButton>(
            find.widgetWithIcon(IconButton, Icons.remove_rounded),
          )
          .onPressed,
      isNull,
    );
    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.pump();
    expect(h.notifier.draft.householdSize, 3);
  });

  testWidgets('a low budget gets friendly advice but is never blocked', (
    tester,
  ) async {
    final h = await _pump(
      tester,
      draft: const SetupDraft()
          .withLifestyle(Lifestyle.family)
          .withHouseholdSize(4),
      step: SetupStep.budget,
    );

    await tester.enterText(find.byType(TextField), '2000');
    await _tap(tester, 'Per day');

    expect(
      find.textContaining(
        'For 4 people, we suggest at least 3\xA0100\xA0FCFA per day',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('You can keep your amount'), findsOneWidget);

    await _tap(tester, 'Continue');
    expect(find.text('How do you like to cook?'), findsOneWidget);
    expect(h.notifier.draft.budgetAmount, 2000);
  });

  testWidgets('in French, questions and budget advice read naturally', (
    tester,
  ) async {
    await _pump(
      tester,
      draft: const SetupDraft()
          .withLifestyle(Lifestyle.family)
          .withHouseholdSize(4),
      step: SetupStep.budget,
      locale: const Locale('fr'),
    );

    expect(
      find.text('Combien dépensez-vous pour la nourriture\xA0?'),
      findsOneWidget,
    );
    expect(find.text('Étape 3 sur 9'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '2000');
    await _tap(tester, 'Par jour');

    expect(
      find.textContaining(
        'Pour 4 personnes, nous conseillons au moins 3\xA0100\xA0FCFA par jour',
      ),
      findsOneWidget,
    );
    await _tap(tester, 'Continuer');
    expect(find.text('Comment aimez-vous cuisiner\xA0?'), findsOneWidget);
  });

  testWidgets('a budget above the suggestion shows no advice', (tester) async {
    await _pump(
      tester,
      draft: const SetupDraft().withLifestyle(Lifestyle.student),
      step: SetupStep.budget,
    );

    await tester.enterText(find.byType(TextField), '15000');
    await _tap(tester, 'Per week');

    expect(find.textContaining('we suggest at least'), findsNothing);
  });

  testWidgets('the budget field groups thousands as the user types', (
    tester,
  ) async {
    await _pump(
      tester,
      draft: const SetupDraft().withLifestyle(Lifestyle.student),
      step: SetupStep.budget,
    );

    await tester.enterText(find.byType(TextField), '25000');
    expect(find.text('25\xA0000'), findsOneWidget);
  });

  testWidgets('finishing the lifestyle section moves to the preferences '
      'route; Back returns', (tester) async {
    final h = await _pump(
      tester,
      draft: completeDraft(),
      step: SetupStep.cooking,
    );

    await _tap(tester, 'Continue');
    expect(h.location, '/setup/preferences');
    expect(find.text('What kinds of food do you like?'), findsOneWidget);
    expect(find.text('Cameroonian food'), findsOneWidget);
    expect(find.text('Ndolé, eru, achu, koki'), findsOneWidget);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(h.location, '/setup/lifestyle');
    expect(find.text('How do you like to cook?'), findsOneWidget);
  });

  testWidgets('a cuisine taps through like, don\'t like, no opinion', (
    tester,
  ) async {
    final h = await _pump(
      tester,
      location: '/setup/preferences',
      draft: completeDraft(),
      step: SetupStep.cuisines,
    );

    await _tap(tester, 'Italian food');
    expect(find.text('Like'), findsOneWidget);
    await _tap(tester, 'Italian food');
    expect(find.text("Don't like"), findsOneWidget);
    await _tap(tester, 'Italian food');
    expect(h.notifier.draft.cuisines, isEmpty);
  });

  testWidgets('consent is required before the health questions', (
    tester,
  ) async {
    await _pump(
      tester,
      location: '/setup/preferences',
      draft: completeDraft().withConsent(false),
      step: SetupStep.consent,
    );

    expect(find.text('Your health information, your choice'), findsOneWidget);
    expect(find.text('Sign out'), findsOneWidget);
    await _tap(tester, 'Continue');
    expect(find.text('Please choose an option'), findsOneWidget);

    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    await _tap(tester, 'Continue');
    expect(find.text("Is there food you don't eat?"), findsOneWidget);
  });

  testWidgets('allergies: "No, none" and an allergen exclude each other', (
    tester,
  ) async {
    final h = await _pump(
      tester,
      location: '/setup/preferences',
      draft: completeDraft(),
      step: SetupStep.allergies,
    );

    expect(find.text('Groundnuts'), findsOneWidget);
    expect(find.text('Snails, mussels, oysters'), findsOneWidget);
    await _tap(tester, 'No, none');
    expect(h.notifier.draft.allergies, isEmpty);
    expect(h.notifier.draft.allergiesNone, isTrue);

    await _tap(tester, 'Crayfish, prawns, crabs');
    expect(h.notifier.draft.allergiesNone, isFalse);
    expect(h.notifier.draft.allergies, {Allergen.crustaceans});
  });

  testWidgets('the last step saves everything and opens the gate', (
    tester,
  ) async {
    final h = await _pump(
      tester,
      location: '/setup/preferences',
      draft: completeDraft(),
      step: SetupStep.goals,
    );

    expect(find.text('Skip'), findsOneWidget);
    await _tap(tester, 'Eat healthier');
    await tester.ensureVisible(find.text('Finish'));
    await tester.tap(find.text('Finish'));
    await tester.pump();
    await tester.pump();

    expect(h.location, '/setup/processing');
    expect(find.text('Personalising your meals…'), findsOneWidget);

    // Past the minimum display time; no redirect in this harness, so the
    // spinner keeps turning and pumpAndSettle would never return.
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
    expect(h.setup.saved.single.goals, {HealthGoal.eatHealthier});
    expect(h.container.read(setupStatusProvider), SetupStatus.complete);
  });

  testWidgets('a failed save offers a retry that works', (tester) async {
    final h = await _pump(
      tester,
      location: '/setup/preferences',
      draft: completeDraft(),
      step: SetupStep.goals,
    );
    h.setup.onComplete = (_) => throw const SocketException('down');

    await _tap(tester, 'Skip');
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    expect(
      find.text("We couldn't save your answers. Please try again."),
      findsOneWidget,
    );
    expect(h.container.read(setupStatusProvider), isNot(SetupStatus.complete));

    h.setup.onComplete = null;
    await tester.tap(find.text('Try again'));
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
    expect(h.container.read(setupStatusProvider), SetupStatus.complete);
  });

  testWidgets('opening processing without a finished draft goes back to the '
      'first unanswered question', (tester) async {
    final h = await _pump(tester, location: '/setup/processing');

    expect(h.location, '/setup/lifestyle');
    expect(find.text('What best describes you?'), findsOneWidget);
    expect(h.setup.saved, isEmpty);
  });
}
