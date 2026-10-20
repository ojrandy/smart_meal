import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';

/// Exposes the validated [AppConfig] built once in `main()`.
///
/// `main()` overrides this in the root `ProviderScope`; tests override it
/// with their own value. Reading it without an override is a wiring bug.
final appConfigProvider = Provider<AppConfig>((ref) {
  throw UnimplementedError('appConfigProvider must be overridden in main()');
});
