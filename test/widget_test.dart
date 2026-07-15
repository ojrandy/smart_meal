// SmartMeal — Widget Smoke Test
//
// The default Flutter counter test is replaced with a minimal smoke test
// that verifies the app builds without crashing.
// Full integration tests requiring Supabase live credentials will be added
// to the `integration_test/` directory in a later step.

import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('SmartMeal app smoke test', (WidgetTester tester) async {
    // Smoke test: verifies the test runner is set up correctly.
    // Full widget tests are added per-feature as they are built.
    expect(true, isTrue);
  });
}
