import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/app_logger.dart';
import '../data/language_repository.dart';

/// The languages the app is written in (owner, 2026-10-26: Cameroon is
/// bilingual). Every key in `lib/core/l10n/app_en.arb` has a French twin in
/// `app_fr.arb`.
enum AppLanguage {
  english('en'),
  french('fr');

  const AppLanguage(this.code);

  final String code;

  Locale get locale => Locale(code);

  static AppLanguage? fromCode(String? code) {
    for (final language in values) {
      if (language.code == code) return language;
    }
    return null;
  }
}

/// The language the user chose in the app, or null to follow the phone.
/// `MaterialApp` passes null on as "resolve from the device", see
/// [resolveAppLocale].
class AppLanguageNotifier extends Notifier<AppLanguage?> {
  @override
  AppLanguage? build() =>
      AppLanguage.fromCode(ref.watch(languageRepositoryProvider).savedCode);

  Future<void> choose(AppLanguage language) async {
    state = language;
    try {
      await ref.read(languageRepositoryProvider).save(language.code);
    } catch (error, stackTrace) {
      // The switch still applies now; at worst the phone's language comes
      // back on the next launch.
      AppLogger.log(
        'Could not persist the language',
        name: 'language',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}

final appLanguageProvider = NotifierProvider<AppLanguageNotifier, AppLanguage?>(
  AppLanguageNotifier.new,
);

/// Without a choice in the app: French when the phone prefers French
/// (any region, e.g. fr_CM), otherwise English.
Locale resolveAppLocale(List<Locale>? deviceLocales) {
  for (final locale in deviceLocales ?? const <Locale>[]) {
    final language = AppLanguage.fromCode(locale.languageCode);
    if (language != null) return language.locale;
  }
  return AppLanguage.english.locale;
}
