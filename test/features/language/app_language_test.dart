import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_meal/core/l10n/l10n.dart';
import 'package:smart_meal/core/providers/shared_preferences_provider.dart';
import 'package:smart_meal/features/language/data/language_repository.dart';
import 'package:smart_meal/features/language/domain/app_language.dart';
import 'package:smart_meal/features/language/presentation/widgets/language_switch.dart';

Future<ProviderContainer> _container([
  Map<String, Object> saved = const {},
]) async {
  SharedPreferences.setMockInitialValues(saved);
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('resolveAppLocale (no choice made in the app)', () {
    for (final (device, expected) in [
      (const [Locale('fr', 'CM')], 'fr'),
      (const [Locale('fr')], 'fr'),
      (const [Locale('en', 'CM')], 'en'),
      (const [Locale('de'), Locale('fr', 'FR')], 'fr'),
      (const [Locale('de')], 'en'),
      (const <Locale>[], 'en'),
      (null, 'en'),
    ]) {
      test('$device → $expected', () {
        expect(resolveAppLocale(device).languageCode, expected);
      });
    }
  });

  group('AppLanguageNotifier', () {
    test('follows the phone until the user picks a language', () async {
      final container = await _container();
      expect(container.read(appLanguageProvider), isNull);
    });

    test('a pick applies at once and is remembered', () async {
      final container = await _container();
      await container
          .read(appLanguageProvider.notifier)
          .choose(AppLanguage.french);

      expect(container.read(appLanguageProvider), AppLanguage.french);
      final prefs = container.read(sharedPreferencesProvider);
      expect(prefs.getString(LanguageRepository.languageKey), 'fr');
    });

    test('restores the saved pick on the next launch', () async {
      final container = await _container({
        LanguageRepository.languageKey: 'fr',
      });
      expect(container.read(appLanguageProvider), AppLanguage.french);
    });

    test('ignores an unknown saved value', () async {
      final container = await _container({
        LanguageRepository.languageKey: 'de',
      });
      expect(container.read(appLanguageProvider), isNull);
    });
  });

  testWidgets('the switch changes the app language and marks the current one', (
    tester,
  ) async {
    final container = await _container();
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: Consumer(
          builder: (context, ref, _) => MaterialApp(
            locale: ref.watch(appLanguageProvider)?.locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: Builder(
                builder: (context) => Column(
                  children: [
                    const LanguageSwitch(),
                    Text(context.l10n.signInButton),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Sign In ✨'), findsOneWidget);
    expect(
      tester.getSemantics(find.bySemanticsLabel('English')),
      containsSemantics(isButton: true, isSelected: true),
    );

    await tester.tap(find.text('FR'));
    await tester.pumpAndSettle();

    expect(find.text('Se connecter ✨'), findsOneWidget);
    expect(container.read(appLanguageProvider), AppLanguage.french);
    expect(
      tester.getSemantics(find.bySemanticsLabel('Français')),
      containsSemantics(isButton: true, isSelected: true),
    );
  });
}
