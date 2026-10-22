import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/providers/shared_preferences_provider.dart';

/// Remembers on this device that onboarding was seen, so it shows once.
class OnboardingRepository {
  OnboardingRepository(this._prefs);

  final SharedPreferences _prefs;

  static const seenKey = 'smartmeal.onboarding.seen';

  bool get isSeen => _prefs.getBool(seenKey) ?? false;

  Future<void> markSeen() => _prefs.setBool(seenKey, true);
}

final onboardingRepositoryProvider = Provider<OnboardingRepository>((ref) {
  return OnboardingRepository(ref.watch(sharedPreferencesProvider));
});
