import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/providers/shared_preferences_provider.dart';

/// Remembers on this device that a recovery link was opened and no new
/// password has been set yet, so a recovery session that survives an app
/// restart still lands on the reset screen instead of Home.
///
/// Only a flag: the recovery session itself lives in secure storage with
/// every other session (S7).
class PasswordRecoveryRepository {
  PasswordRecoveryRepository(this._prefs);

  final SharedPreferences _prefs;

  static const pendingKey = 'smartmeal.auth.recovery_pending';

  bool get isPending => _prefs.getBool(pendingKey) ?? false;

  Future<void> setPending(bool pending) =>
      pending ? _prefs.setBool(pendingKey, true) : _prefs.remove(pendingKey);
}

final passwordRecoveryRepositoryProvider = Provider<PasswordRecoveryRepository>(
  (ref) => PasswordRecoveryRepository(ref.watch(sharedPreferencesProvider)),
);
