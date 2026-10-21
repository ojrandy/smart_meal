import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_logger.dart';

const _logName = 'SecureSessionStorage';

/// The secure store both adapters share: Android Keystore-wrapped AES-GCM
/// (the package default) and an iOS Keychain item that stays on this
/// device (no iCloud sync) but is readable after the first unlock, so
/// background token refresh keeps working.
const appSecureStorage = FlutterSecureStorage(
  aOptions: AndroidOptions(),
  iOptions: IOSOptions(
    accessibility: KeychainAccessibility.first_unlock_this_device,
  ),
);

/// Supabase session persistence in platform secure storage (S7).
///
/// supabase_flutter's default keeps the access and refresh tokens in
/// SharedPreferences, i.e. plaintext XML / plist. This adapter replaces it
/// and, in [initialize]:
/// - moves a legacy plaintext session into secure storage, verifies the
///   read-back and deletes the plaintext copy, so nobody is signed out by
///   the upgrade (idempotent);
/// - on the first run of a fresh install with nothing to migrate, clears
///   secure storage, because iOS Keychain items survive an uninstall and
///   must not silently resume a previous install's session (S12).
///
/// Every storage failure is treated as "signed out": the store is cleared
/// and nothing throws, so a Keystore invalidated by a restore or a
/// device-credential change can never crash the app.
class SecureSessionStorage extends LocalStorage {
  SecureSessionStorage({
    required this.persistSessionKey,
    this.secureStorage = appSecureStorage,
  });

  /// Same key supabase_flutter uses, see [sessionKeyFor].
  final String persistSessionKey;
  final FlutterSecureStorage secureStorage;

  /// Non-sensitive SharedPreferences flag marking that this install has run
  /// before. SharedPreferences, unlike the Keychain, is removed on uninstall.
  static const installedMarkerKey = 'smartmeal.installed';

  /// The PKCE verifier key gotrue uses; removed from SharedPreferences if a
  /// pre-P09 build left one behind.
  static const legacyPkceVerifierKey = 'supabase.auth.token-code-verifier';

  /// supabase_flutter's session key for [supabaseUrl]
  /// (`sb-<project-ref>-auth-token`), so a legacy session can be found.
  static String sessionKeyFor(String supabaseUrl) =>
      'sb-${Uri.parse(supabaseUrl).host.split('.').first}-auth-token';

  @override
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isFirstRun = !(prefs.getBool(installedMarkerKey) ?? false);
      final legacySession = prefs.getString(persistSessionKey);

      if (legacySession != null) {
        await _migrate(prefs, legacySession);
      } else if (isFirstRun) {
        await secureStorage.deleteAll();
      }
      await prefs.remove(legacyPkceVerifierKey);
      if (isFirstRun) await prefs.setBool(installedMarkerKey, true);
    } catch (e, st) {
      AppLogger.log(
        'Session storage init failed; treating as signed out.',
        name: _logName,
        error: e,
        stackTrace: st,
      );
      await _clearQuietly();
    }
  }

  Future<void> _migrate(SharedPreferences prefs, String legacySession) async {
    await secureStorage.write(key: persistSessionKey, value: legacySession);
    final readBack = await secureStorage.read(key: persistSessionKey);
    if (readBack != legacySession) {
      // Keep the plaintext copy so the next launch can retry; this launch
      // reads secure storage only, so the user is signed out for now.
      await _clearQuietly();
      AppLogger.log('Session migration read-back mismatch.', name: _logName);
      return;
    }
    await prefs.remove(persistSessionKey);
    AppLogger.log('Migrated session to secure storage.', name: _logName);
  }

  @override
  Future<bool> hasAccessToken() async => await accessToken() != null;

  @override
  Future<String?> accessToken() async {
    try {
      return await secureStorage.read(key: persistSessionKey);
    } catch (e, st) {
      AppLogger.log(
        'Session read failed; treating as signed out.',
        name: _logName,
        error: e,
        stackTrace: st,
      );
      await _clearQuietly();
      return null;
    }
  }

  @override
  Future<void> persistSession(String persistSessionString) async {
    try {
      await secureStorage.write(
        key: persistSessionKey,
        value: persistSessionString,
      );
    } catch (e, st) {
      // Not persisted: the session lives in memory until the app closes.
      AppLogger.log(
        'Session write failed.',
        name: _logName,
        error: e,
        stackTrace: st,
      );
    }
  }

  @override
  Future<void> removePersistedSession() async {
    try {
      await secureStorage.delete(key: persistSessionKey);
    } catch (e, st) {
      AppLogger.log(
        'Session delete failed; clearing storage.',
        name: _logName,
        error: e,
        stackTrace: st,
      );
      await _clearQuietly();
    }
  }

  Future<void> _clearQuietly() async {
    try {
      await secureStorage.deleteAll();
    } catch (e) {
      AppLogger.log('Secure storage clear failed.', name: _logName, error: e);
    }
  }
}

/// PKCE code-verifier storage in secure storage instead of
/// SharedPreferences. Read failures return null, which makes the pending
/// auth flow fail cleanly instead of crashing.
class SecurePkceStorage extends GotrueAsyncStorage {
  const SecurePkceStorage({this.secureStorage = appSecureStorage});

  final FlutterSecureStorage secureStorage;

  @override
  Future<String?> getItem({required String key}) async {
    try {
      return await secureStorage.read(key: key);
    } catch (e) {
      AppLogger.log('PKCE verifier read failed.', name: _logName, error: e);
      return null;
    }
  }

  @override
  Future<void> setItem({required String key, required String value}) =>
      secureStorage.write(key: key, value: value);

  @override
  Future<void> removeItem({required String key}) async {
    try {
      await secureStorage.delete(key: key);
    } catch (e) {
      AppLogger.log('PKCE verifier delete failed.', name: _logName, error: e);
    }
  }
}
