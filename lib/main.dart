import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/config/app_config.dart';
import 'core/l10n/l10n.dart';
import 'core/providers/app_config_provider.dart';
import 'core/providers/shared_preferences_provider.dart';
import 'core/router/app_router.dart';
import 'core/services/push_notification_service.dart';
import 'core/services/secure_session_storage.dart';
import 'core/services/timeout_http_client.dart';
import 'core/theme/app_fonts.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/app_snack_bar.dart';
import 'features/auth/domain/password_recovery.dart';
import 'features/language/domain/app_language.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Fail fast: a build without a valid env file must never reach Supabase.
  // Throws AppConfigException listing every missing or malformed define.
  final config = AppConfig.fromEnvironment();

  AppFonts.configure();

  // Initialize Supabase before the app starts. The session and the PKCE
  // verifier persist in platform secure storage (Keychain / Keystore),
  // never in plaintext SharedPreferences (S7).
  await Supabase.initialize(
    url: config.supabaseUrl,
    publishableKey: config.supabasePublishableKey,
    authOptions: FlutterAuthClientOptions(
      localStorage: SecureSessionStorage(
        persistSessionKey: SecureSessionStorage.sessionKeyFor(
          config.supabaseUrl,
        ),
      ),
      pkceAsyncStorage: const SecurePkceStorage(),
    ),
    // Every request gives up after a time limit, so a lost connection is
    // reported instead of leaving a screen waiting forever.
    httpClient: TimeoutHttpClient(),
  );

  // Not awaited: push is optional, so neither a missing Firebase config nor
  // a slow platform channel may hold back the first frame. initialize()
  // never throws and never prompts the user.
  unawaited(PushNotificationService().initialize());

  // Loaded before the first frame so the router knows, without waiting,
  // whether onboarding was already seen.
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        appConfigProvider.overrideWithValue(config),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const SmartMealApp(),
    ),
  );
}

class SmartMealApp extends ConsumerWidget {
  const SmartMealApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // A failed confirmation or recovery link can arrive on any screen, even
    // during the splash, so it is shown at the root.
    ref.listen<bool>(authLinkErrorProvider, (_, failed) {
      if (!failed) return;
      // The messenger sits inside MaterialApp, so its context has the
      // app's localizations.
      final messengerContext = rootScaffoldMessengerKey.currentContext;
      if (messengerContext != null) {
        showRootSnackBar(
          messengerContext.l10n.authLinkErrorNotice,
          duration: const Duration(seconds: 6),
        );
      }
      ref.read(authLinkErrorProvider.notifier).clear();
    });

    // Watch the router provider so it rebuilds when auth state changes.
    final router = ref.watch(routerProvider);
    // Null until the user picks a language: then the phone's language
    // decides (French phones get French, everything else English).
    final language = ref.watch(appLanguageProvider);
    return MaterialApp.router(
      onGenerateTitle: (context) => context.l10n.appName,
      theme: AppTheme.lightTheme,
      locale: language?.locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      localeListResolutionCallback: (deviceLocales, _) =>
          resolveAppLocale(deviceLocales),
      routerConfig: router,
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      debugShowCheckedModeBanner: false,
    );
  }
}
