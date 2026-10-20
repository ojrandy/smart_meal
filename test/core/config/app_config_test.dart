import 'package:flutter_test/flutter_test.dart';
import 'package:smart_meal/core/config/app_config.dart';

// Fake but well-formed values; none of them is a real project or client.
const _valid = {
  AppConfig.urlKey: 'https://example-ref.supabase.example',
  AppConfig.publishableKeyKey: 'sb_publishable_testOnlyNotARealKey',
  AppConfig.googleWebClientIdKey: '123456-abc123.apps.googleusercontent.com',
  AppConfig.googleIosClientIdKey: '',
  AppConfig.envKey: 'dev',
};

Map<String, String> _with(String key, String value) => {..._valid, key: value};

List<String> _problemsFor(Map<String, String> values) {
  try {
    AppConfig.parse(values);
  } on AppConfigException catch (e) {
    return e.problems;
  }
  fail('expected AppConfigException');
}

void main() {
  group('AppConfig.parse', () {
    test('accepts a complete, well-formed config', () {
      final config = AppConfig.parse(_valid);

      expect(config.env, AppEnv.dev);
      expect(config.supabaseUrl, _valid[AppConfig.urlKey]);
      expect(
        config.supabasePublishableKey,
        _valid[AppConfig.publishableKeyKey],
      );
      expect(config.googleWebClientId, _valid[AppConfig.googleWebClientIdKey]);
      expect(config.googleIosClientId, isEmpty);
    });

    test('accepts every APP_ENV value and a valid iOS client ID', () {
      for (final env in AppEnv.values) {
        final config = AppConfig.parse({
          ..._with(AppConfig.envKey, env.name),
          AppConfig.googleIosClientIdKey:
              '123456-ios.apps.googleusercontent.com',
        });
        expect(config.env, env);
      }
    });

    test('reports every missing required value at once', () {
      final problems = _problemsFor(const {});

      expect(problems, hasLength(4));
      expect(problems, contains('SUPABASE_URL is empty.'));
      expect(problems, contains('SUPABASE_PUBLISHABLE_KEY is empty.'));
      expect(problems, contains('GOOGLE_WEB_CLIENT_ID is empty.'));
      expect(problems.last, startsWith('APP_ENV must be one of: dev,'));
    });

    test('the exception message names the problems and the fix', () {
      expect(
        () => AppConfig.parse(const {}),
        throwsA(
          isA<AppConfigException>().having(
            (e) => e.toString(),
            'message',
            allOf(
              contains('SUPABASE_URL is empty.'),
              contains('--dart-define-from-file=env/<env>.json'),
            ),
          ),
        ),
      );
    });

    for (final url in [
      'http://example-ref.supabase.example',
      'example-ref.supabase.example',
      'https://',
      'https://user:pass@example-ref.supabase.example',
      'https://example-ref.supabase.example?x=1',
      'https://example-ref.supabase.example#x',
    ]) {
      test('rejects SUPABASE_URL "$url"', () {
        expect(_problemsFor(_with(AppConfig.urlKey, url)), [
          contains('SUPABASE_URL must be an https:// project URL'),
        ]);
      });
    }

    for (final key in ['sb_secret_abc', 'eyJhbGciOiJIUzI1NiJ9.x.y']) {
      test('rejects a secret-looking key "$key" with a rotate warning', () {
        expect(_problemsFor(_with(AppConfig.publishableKeyKey, key)), [
          allOf(contains('secret or legacy JWT'), contains('rotate')),
        ]);
      });
    }

    test('rejects a key without the publishable prefix', () {
      expect(_problemsFor(_with(AppConfig.publishableKeyKey, 'abc')), [
        contains('must be the Supabase publishable key'),
      ]);
    });

    test('rejects malformed Google client IDs, iOS included', () {
      final problems = _problemsFor({
        ..._with(AppConfig.googleWebClientIdKey, 'not-an-id'),
        AppConfig.googleIosClientIdKey: 'abc.apps.googleusercontent.com',
      });

      expect(problems, [
        startsWith('GOOGLE_WEB_CLIENT_ID is not a Google OAuth client ID'),
        startsWith('GOOGLE_IOS_CLIENT_ID is not a Google OAuth client ID'),
      ]);
    });

    test('rejects an unknown APP_ENV', () {
      expect(_problemsFor(_with(AppConfig.envKey, 'production')), [
        'APP_ENV must be one of: dev, staging, prod.',
      ]);
    });

    test('names each value still holding an env/example.json placeholder', () {
      final problems = _problemsFor({
        ..._with(AppConfig.urlKey, 'https://<your-project-ref>.supabase.co'),
        AppConfig.publishableKeyKey: '<sb_publishable_your_key>',
      });

      expect(problems, [
        'SUPABASE_URL still holds the env/example.json placeholder.',
        'SUPABASE_PUBLISHABLE_KEY still holds the env/example.json placeholder.',
      ]);
    });

    test('trims surrounding whitespace', () {
      final config = AppConfig.parse(_with(AppConfig.envKey, ' prod '));

      expect(config.env, AppEnv.prod);
    });
  });
}
