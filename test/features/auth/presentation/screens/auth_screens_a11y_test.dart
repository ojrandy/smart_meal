import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_meal/core/theme/app_fonts.dart';
import 'package:smart_meal/core/theme/app_theme.dart';
import 'package:smart_meal/features/auth/data/auth_repository.dart';
import 'package:smart_meal/features/auth/presentation/screens/login_screen.dart';
import 'package:smart_meal/features/auth/presentation/screens/signup_screen.dart';

import '../../../../helpers/fake_auth_repository.dart';

Future<GoRouter> _pump(WidgetTester tester, String initialLocation) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.75;
  addTearDown(tester.view.reset);

  final repository = FakeAuthRepository();
  addTearDown(repository.dispose);
  final router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (_, _) => const Scaffold(body: Text('onboarding')),
      ),
      GoRoute(path: '/auth/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/auth/signup', builder: (_, _) => const SignupScreen()),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
      child: MaterialApp.router(
        theme: AppTheme.lightTheme,
        routerConfig: router,
      ),
    ),
  );
  await tester.pump();
  return router;
}

Finder get _back => find.byTooltip('Back');

/// What Android sends for the system back button or gesture.
Future<void> _systemBack(WidgetTester tester) async {
  await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
    'flutter/navigation',
    const JSONMethodCodec().encodeMethodCall(const MethodCall('popRoute')),
    (_) {},
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(AppFonts.configure);

  testWidgets('login back goes to onboarding when nothing to pop', (
    tester,
  ) async {
    await _pump(tester, '/auth/login');

    await tester.tap(_back);
    await tester.pumpAndSettle();
    expect(find.text('onboarding'), findsOneWidget);
  });

  testWidgets('signup back goes to login when nothing to pop', (tester) async {
    await _pump(tester, '/auth/signup');

    await tester.tap(_back);
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('system back on login goes to onboarding', (tester) async {
    await _pump(tester, '/auth/login');

    await _systemBack(tester);
    expect(find.text('onboarding'), findsOneWidget);
  });

  testWidgets('system back on signup goes to login', (tester) async {
    await _pump(tester, '/auth/signup');

    await _systemBack(tester);
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('system back pops signup when pushed from login', (tester) async {
    final router = await _pump(tester, '/auth/login');
    unawaited(router.push('/auth/signup'));
    await tester.pumpAndSettle();

    await _systemBack(tester);
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(SignupScreen), findsNothing);
  });

  testWidgets('signup back pops to login when pushed from it', (tester) async {
    final router = await _pump(tester, '/auth/login');
    unawaited(router.push('/auth/signup'));
    await tester.pumpAndSettle();

    await tester.tap(_back);
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(SignupScreen), findsNothing);
  });

  for (final (name, location, title) in [
    ('login', '/auth/login', 'Smart Meal'),
    ('signup', '/auth/signup', 'Smart Meal account'),
  ]) {
    testWidgets('$name: icon-only controls are labelled 48 dp targets', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await _pump(tester, location);

      expect(
        tester.getSemantics(_back),
        containsSemantics(tooltip: 'Back', isButton: true, hasTapAction: true),
      );
      expect(find.bySemanticsLabel('Show password'), findsWidgets);
      for (final button in tester.widgetList(find.byType(IconButton))) {
        final size = tester.getSize(find.byWidget(button));
        expect(size.width, greaterThanOrEqualTo(48));
        expect(size.height, greaterThanOrEqualTo(48));
      }
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));

      semantics.dispose();
    });

    testWidgets('$name: title follows the system text scale', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await _pump(tester, location);

      final titleText = tester.widget<RichText>(
        find.byWidgetPredicate(
          (w) => w is RichText && w.text.toPlainText().endsWith('\n$title'),
        ),
      );
      expect(titleText.textScaler.scale(10), closeTo(13, 0.001));
    });

    testWidgets('$name: decorative images are hidden from screen readers', (
      tester,
    ) async {
      await _pump(tester, location);

      final images = tester.widgetList<Image>(find.byType(Image));
      expect(images, isNotEmpty);
      for (final image in images) {
        expect(image.excludeFromSemantics, isTrue);
      }
    });
  }
}
