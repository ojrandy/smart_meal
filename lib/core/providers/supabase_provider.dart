import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Exposes the Supabase client as a Riverpod provider.
///
/// Use this anywhere in the app that needs direct Supabase access,
/// ensuring a single source of truth for the client instance.
///
/// Example:
/// ```dart
/// final client = ref.watch(supabaseClientProvider);
/// ```
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});
