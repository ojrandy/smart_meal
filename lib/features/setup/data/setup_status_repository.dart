import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/providers/shared_preferences_provider.dart';
import '../../../core/providers/supabase_provider.dart';

/// Whether a user has finished setup. The server is the truth
/// (`profiles.setup_completed_at`); this device keeps the last known answer
/// per user so a cold start without a connection still routes correctly.
///
/// The cache is one non-sensitive boolean per user ID, removed on sign-out
/// (S12). No setup answers are ever stored here.
class SetupStatusRepository {
  SetupStatusRepository(this._client, this._prefs);

  final SupabaseClient _client;
  final SharedPreferences _prefs;

  static String cacheKeyFor(String userId) =>
      'smartmeal.setup_complete.$userId';

  /// Reads the signed-in user's profile. RLS limits it to their own row.
  Future<bool> fetchIsComplete(String userId) async {
    final row = await _client
        .from('profiles')
        .select('setup_completed_at')
        .eq('id', userId)
        .maybeSingle();
    return row?['setup_completed_at'] != null;
  }

  /// The last answer seen on this device, or null if never checked.
  bool? cachedIsComplete(String userId) => _prefs.getBool(cacheKeyFor(userId));

  Future<void> cache(String userId, {required bool isComplete}) =>
      _prefs.setBool(cacheKeyFor(userId), isComplete);

  Future<void> clearCache(String userId) => _prefs.remove(cacheKeyFor(userId));
}

final setupStatusRepositoryProvider = Provider<SetupStatusRepository>((ref) {
  return SetupStatusRepository(
    ref.watch(supabaseClientProvider),
    ref.watch(sharedPreferencesProvider),
  );
});
