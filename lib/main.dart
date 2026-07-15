import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/config/supabase_config.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase before the app starts.
  // Session persistence is handled automatically by supabase_flutter.
  await Supabase.initialize(
    url: SupabaseConfig.projectUrl,
    anonKey: SupabaseConfig.anonKey, // ignore: deprecated_member_use
  );

  runApp(
    const ProviderScope(
      child: SmartMealApp(),
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
