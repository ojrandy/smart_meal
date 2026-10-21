// SmartMeal — App shell smoke test
//
// Pumps the real app (router, theme, auth notifier) with a hand-written fake
// auth repository, so no Supabase client or network is needed.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smart_meal/features/auth/data/auth_repository.dart';
import 'package:smart_meal/features/splash/presentation/splash_screen.dart';
import 'package:smart_meal/main.dart';

import 'helpers/fake_auth_repository.dart';

void main() {
  setUpAll(() {
    // Same as main(): Inter comes from assets/fonts, never the network.
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('app starts on the splash screen', (tester) async {
    final authRepository = FakeAuthRepository();
    addTearDown(authRepository.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(authRepository)],
        child: const SmartMealApp(),
      ),
    );
    await tester.pump();

    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.text('Your AI food companion'), findsOneWidget);

    // Unmount so the splash's delayed navigation is not left pending.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 6));
  });
}
