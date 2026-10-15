// Renders the image- and text-heavy screens with no network access: every
// bundled image must decode and every Inter variant the screens ask for must
// load from assets/fonts (runtime fetching is off, as in main()).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smart_meal/core/theme/app_fonts.dart';
import 'package:smart_meal/core/theme/app_theme.dart';
import 'package:smart_meal/features/auth/data/auth_repository.dart';
import 'package:smart_meal/features/auth/presentation/screens/login_screen.dart';
import 'package:smart_meal/features/auth/presentation/screens/signup_screen.dart';
import 'package:smart_meal/features/onboarding/presentation/onboarding_screen.dart';

import '../helpers/fake_auth_repository.dart';

void main() {
  setUpAll(AppFonts.configure);

  final screens = <String, Widget Function()>{
    'onboarding': () => const OnboardingScreen(),
    'login': () => const LoginScreen(),
    'signup': () => const SignupScreen(),
  };

  for (final MapEntry(key: name, value: build) in screens.entries) {
    testWidgets('$name renders offline with its images and Inter', (
      tester,
    ) async {
      // A typical phone: 1080 × 2400 px at 2.75×.
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.reset);

      final authRepository = FakeAuthRepository();
      addTearDown(authRepository.dispose);
      // The auth screens read GoRouter (back navigation), as in the app.
      final router = GoRouter(
        routes: [GoRoute(path: '/', builder: (_, _) => build())],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [authRepositoryProvider.overrideWithValue(authRepository)],
          child: MaterialApp.router(
            theme: AppTheme.lightTheme,
            routerConfig: router,
          ),
        ),
      );

      // Decode every image on screen for real; a failure throws here.
      final images = tester.widgetList<Image>(find.byType(Image)).toList();
      expect(images, isNotEmpty);
      await tester.runAsync(() async {
        for (final image in images) {
          await precacheImage(
            image.image,
            tester.element(find.byWidget(image)),
            onError: (error, _) => fail('$name: image failed to load: $error'),
          );
        }
        await GoogleFonts.pendingFonts();
      });
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.textContaining('missing'), findsNothing);
    });
  }
}
