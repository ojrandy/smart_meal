import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_meal/core/services/secure_session_storage.dart';

const _key = 'sb-testref-auth-token';
const _session = '{"access_token":"a","refresh_token":"r"}';
const _marker = SecureSessionStorage.installedMarkerKey;

/// Secure storage whose reads fail, like a Keystore invalidated after a
/// backup restore or a device-credential change.
class _BrokenStorage extends FlutterSecureStorage {
  _BrokenStorage();

  bool cleared = false;

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) => throw PlatformException(code: 'decrypt_failed');

  @override
  Future<void> deleteAll({
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => cleared = true;
}

SecureSessionStorage _storage() =>
    SecureSessionStorage(persistSessionKey: _key);

Future<String?> _secure(String key) =>
    appSecureStorage.read(key: key); // backed by the mock store in tests

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
  });

  test('sessionKeyFor matches supabase_flutter\'s key', () {
    expect(
      SecureSessionStorage.sessionKeyFor('https://abcref.supabase.co'),
      'sb-abcref-auth-token',
    );
  });

  test('round-trips a session and removes it on sign-out', () async {
    final storage = _storage();
    await storage.initialize();

    expect(await storage.hasAccessToken(), isFalse);

    await storage.persistSession(_session);
    expect(await storage.hasAccessToken(), isTrue);
    expect(await storage.accessToken(), _session);

    await storage.removePersistedSession();
    expect(await storage.hasAccessToken(), isFalse);
    expect(await _secure(_key), isNull);
  });

  group('migration from plaintext SharedPreferences', () {
    test('moves the legacy session and deletes the plaintext copy', () async {
      SharedPreferences.setMockInitialValues({_key: _session});

      final storage = _storage();
      await storage.initialize();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(_key), isNull);
      expect(await storage.accessToken(), _session);
      expect(prefs.getBool(_marker), isTrue);
    });

    test('upgrade keeps the user signed in even without the marker', () async {
      // Pre-P09 installs have a plaintext session but no marker; that must
      // count as an upgrade, not a fresh install.
      SharedPreferences.setMockInitialValues({_key: _session});

      await _storage().initialize();

      expect(await _storage().accessToken(), _session);
    });

    test('is a no-op when there is no legacy session', () async {
      FlutterSecureStorage.setMockInitialValues({_key: _session});
      SharedPreferences.setMockInitialValues({_marker: true});

      await _storage().initialize();

      expect(await _secure(_key), _session);
    });

    test('running twice changes nothing', () async {
      SharedPreferences.setMockInitialValues({_key: _session});

      await _storage().initialize();
      await _storage().initialize();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(_key), isNull);
      expect(await _secure(_key), _session);
    });

    test('removes a legacy plaintext PKCE verifier', () async {
      SharedPreferences.setMockInitialValues({
        _marker: true,
        SecureSessionStorage.legacyPkceVerifierKey: 'verifier',
      });

      await _storage().initialize();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(SecureSessionStorage.legacyPkceVerifierKey), null);
    });
  });

  test('first run of a fresh install clears a surviving session', () async {
    // iOS: the Keychain survives uninstall; SharedPreferences does not.
    FlutterSecureStorage.setMockInitialValues({_key: _session});

    final storage = _storage();
    await storage.initialize();

    expect(await storage.hasAccessToken(), isFalse);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(_marker), isTrue);
  });

  group('storage failures are treated as signed out', () {
    test(
      'a failed read returns no session, clears, and never throws',
      () async {
        final broken = _BrokenStorage();
        final storage = SecureSessionStorage(
          persistSessionKey: _key,
          secureStorage: broken,
        );

        expect(await storage.accessToken(), isNull);
        expect(await storage.hasAccessToken(), isFalse);
        expect(broken.cleared, isTrue);
      },
    );

    test(
      'a failed migration does not throw and keeps plaintext for retry',
      () async {
        SharedPreferences.setMockInitialValues({_key: _session});
        final broken = _BrokenStorage();

        await SecureSessionStorage(
          persistSessionKey: _key,
          secureStorage: broken,
        ).initialize();

        expect(broken.cleared, isTrue);
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString(_key), _session);
      },
    );
  });

  group('SecurePkceStorage', () {
    test('round-trips and removes a verifier', () async {
      const pkce = SecurePkceStorage();

      await pkce.setItem(key: 'v', value: 'secret');
      expect(await pkce.getItem(key: 'v'), 'secret');

      await pkce.removeItem(key: 'v');
      expect(await pkce.getItem(key: 'v'), isNull);
    });

    test('a failed read returns null instead of throwing', () async {
      final pkce = SecurePkceStorage(secureStorage: _BrokenStorage());

      expect(await pkce.getItem(key: 'v'), isNull);
    });
  });
}
