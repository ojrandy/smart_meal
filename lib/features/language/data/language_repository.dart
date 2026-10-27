import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/providers/shared_preferences_provider.dart';

/// Remembers on this device the language the user picked in the app. No
/// stored value means "follow the phone".
class LanguageRepository {
  LanguageRepository(this._prefs);

  final SharedPreferences _prefs;

  static const languageKey = 'smartmeal.language';

  /// The stored language code ('en', 'fr'), or null.
  String? get savedCode => _prefs.getString(languageKey);

  Future<void> save(String code) => _prefs.setString(languageKey, code);
}

final languageRepositoryProvider = Provider<LanguageRepository>((ref) {
  return LanguageRepository(ref.watch(sharedPreferencesProvider));
});
