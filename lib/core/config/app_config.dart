// SmartMeal — Environment Configuration
//
// Every value comes from a build-time define, supplied per environment with
//   flutter run --dart-define-from-file=env/<env>.json
// (copy env/example.json to env/dev.json; README → "Run locally").
//
// SECURITY: dart-define values are compiled into the app binary and anyone
// holding the APK/IPA can extract them. Only PUBLIC identifiers may go here:
// the Supabase project URL and publishable key, and OAuth client IDs. Access
// control comes from Row Level Security, not from hiding these values.
// Secrets (Supabase secret / service-role keys, the FCM service account,
// payment-provider keys) never enter the client: they live only in Supabase
// Edge Function secrets or the CI secret store. See docs/SECURITY.md.

/// Deployment environment, from `APP_ENV`.
enum AppEnv { dev, staging, prod }

/// Thrown at startup when the build defines are missing or malformed.
/// The message names every bad key and how to fix it.
class AppConfigException implements Exception {
  const AppConfigException(this.problems);

  final List<String> problems;

  @override
  String toString() => [
    'AppConfigException: SmartMeal build configuration is invalid.',
    for (final problem in problems) '  - $problem',
    'Run with --dart-define-from-file=env/<env>.json: copy env/example.json '
        'to env/dev.json and fill in real values (README → "Run locally").',
  ].join('\n');
}

/// Typed, validated build configuration. Create it once in `main()` with
/// [AppConfig.fromEnvironment] and read it through `appConfigProvider`.
class AppConfig {
  const AppConfig._({
    required this.env,
    required this.supabaseUrl,
    required this.supabasePublishableKey,
    required this.googleWebClientId,
    required this.googleIosClientId,
  });

  final AppEnv env;

  /// Supabase project URL — always `https://`.
  final String supabaseUrl;

  /// Supabase publishable (client) key. Never a secret key.
  final String supabasePublishableKey;

  /// Google OAuth Web Client ID, used as `serverClientId` so Google issues
  /// an ID token whose audience Supabase accepts.
  final String googleWebClientId;

  /// Google OAuth iOS Client ID. Empty until P12 registers the iOS client.
  final String googleIosClientId;

  static const urlKey = 'SUPABASE_URL';
  static const publishableKeyKey = 'SUPABASE_PUBLISHABLE_KEY';
  static const googleWebClientIdKey = 'GOOGLE_WEB_CLIENT_ID';
  static const googleIosClientIdKey = 'GOOGLE_IOS_CLIENT_ID';
  static const envKey = 'APP_ENV';

  // Prefix checks, not values: they reject a secret key pasted by mistake.
  static const _publishableKeyPrefix = 'sb_publishable_';
  static const _secretKeyPrefix = 'sb_secret_';
  static final _googleClientId = RegExp(
    r'^[0-9]+-[a-z0-9]+\.apps\.googleusercontent\.com$',
  );

  /// Reads and validates the compile-time defines. Throws
  /// [AppConfigException] if any value is missing or malformed.
  factory AppConfig.fromEnvironment() => AppConfig.parse(const {
    urlKey: String.fromEnvironment(urlKey),
    publishableKeyKey: String.fromEnvironment(publishableKeyKey),
    googleWebClientIdKey: String.fromEnvironment(googleWebClientIdKey),
    googleIosClientIdKey: String.fromEnvironment(googleIosClientIdKey),
    envKey: String.fromEnvironment(envKey),
  });

  /// Validates [values] (keyed by define name) and collects every problem
  /// before throwing, so one run shows the whole fix list.
  factory AppConfig.parse(Map<String, String> values) {
    final problems = <String>[];
    String check(String key, String? Function(String key, String value) rule) {
      final value = (values[key] ?? '').trim();
      final problem = value.contains('<')
          ? '$key still holds the env/example.json placeholder.'
          : rule(key, value);
      if (problem != null) problems.add(problem);
      return value;
    }

    final url = check(urlKey, _urlProblem);
    final key = check(publishableKeyKey, _publishableKeyProblem);
    final webClientId = check(googleWebClientIdKey, _requiredClientIdProblem);
    final iosClientId = check(googleIosClientIdKey, _optionalClientIdProblem);
    final envName = check(envKey, _envProblem);

    if (problems.isNotEmpty) throw AppConfigException(problems);

    return AppConfig._(
      env: AppEnv.values.byName(envName),
      supabaseUrl: url,
      supabasePublishableKey: key,
      googleWebClientId: webClientId,
      googleIosClientId: iosClientId,
    );
  }

  static String? _urlProblem(String key, String value) {
    if (value.isEmpty) return '$key is empty.';
    final uri = Uri.tryParse(value);
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment) {
      return '$key must be an https:// project URL with no credentials, '
          'query or fragment.';
    }
    return null;
  }

  static String? _publishableKeyProblem(String key, String value) {
    if (value.isEmpty) return '$key is empty.';
    if (value.startsWith(_secretKeyPrefix) || value.startsWith('eyJ')) {
      // A secret or legacy JWT key in a client build is an incident: it
      // can bypass RLS and is extractable from the binary.
      return '$key looks like a secret or legacy JWT key. Never ship it in '
          'the app; use the publishable key, and rotate this one if it was '
          'ever in a build or in git.';
    }
    if (!value.startsWith(_publishableKeyPrefix)) {
      return '$key must be the Supabase publishable key '
          '(Dashboard → Settings → API Keys).';
    }
    return null;
  }

  static String? _requiredClientIdProblem(String key, String value) {
    if (value.isEmpty) return '$key is empty.';
    return _optionalClientIdProblem(key, value);
  }

  // GOOGLE_IOS_CLIENT_ID may stay empty until P12 registers the iOS client.
  static String? _optionalClientIdProblem(String key, String value) {
    if (value.isEmpty || _googleClientId.hasMatch(value)) return null;
    return '$key is not a Google OAuth client ID '
        '(<number>-<id>.apps.googleusercontent.com).';
  }

  static String? _envProblem(String key, String value) {
    if (AppEnv.values.any((e) => e.name == value)) return null;
    return '$key must be one of: '
        '${AppEnv.values.map((e) => e.name).join(', ')}.';
  }
}
