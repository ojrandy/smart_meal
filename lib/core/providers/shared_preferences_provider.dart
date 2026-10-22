import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The app's [SharedPreferences], loaded once in `main()` so features can
/// read non-sensitive flags synchronously. Never store credentials here.
///
/// `main()` overrides this in the root `ProviderScope`; tests override it
/// after `SharedPreferences.setMockInitialValues`.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'sharedPreferencesProvider must be overridden in main()',
  );
});
