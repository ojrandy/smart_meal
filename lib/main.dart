import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/config/app_config.dart';
import 'core/providers/app_config_provider.dart';
import 'core/router/app_router.dart';
import 'core/services/push_notification_service.dart';
import 'core/services/secure_session_storage.dart';
import 'core/theme/app_fonts.dart';
import 'core/theme/app_theme.dart';

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
  );

  // Not awaited: push is optional, so neither a missing Firebase config nor
  // a slow platform channel may hold back the first frame. initialize()
  // never throws and never prompts the user.
  unawaited(PushNotificationService().initialize());

  runApp(
    ProviderScope(
      overrides: [appConfigProvider.overrideWithValue(config)],
      child: const SmartMealApp(),
    ),
  );
}

class SmartMealApp extends ConsumerWidget {
  const SmartMealApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the router provider so it rebuilds when auth state changes.
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'Smart Meal',
      theme: AppTheme.lightTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
