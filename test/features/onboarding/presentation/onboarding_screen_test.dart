import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smart_meal/core/theme/app_fonts.dart';
import 'package:smart_meal/core/theme/app_theme.dart';
import 'package:smart_meal/features/onboarding/presentation/onboarding_screen.dart';

const _titles = [
  'Welcome to SmartMeal',
  'Plan Your Meals',
  'Smarter Food Decisions',
];

Future<void> _pump(
  WidgetTester tester, {
  Size size = const Size(393, 873),
  double textScale = 1.0,
  EdgeInsets padding = EdgeInsets.zero,
}) async {
  tester.view.physicalSize = size * 2;
  tester.view.devicePixelRatio = 2;
  tester.view.padding = FakeViewPadding(
    top: padding.top * 2,
    right: padding.right * 2,
  );
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, _) => const OnboardingScreen()),
      GoRoute(
        path: '/auth/login',
        builder: (_, _) => const Scaffold(body: Text('login')),
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    MaterialApp.router(theme: AppTheme.lightTheme, routerConfig: router),
  );
  await tester.runAsync(GoogleFonts.pendingFonts);
  await tester.pump();
}

void main() {
  setUpAll(AppFonts.configure);

  testWidgets('shows 3 slides; Next becomes Get started on the last', (
    tester,
  ) async {
    await _pump(tester);

    for (var i = 0; i < _titles.length; i++) {
      expect(find.text(_titles[i]), findsOneWidget);
      final isLast = i == _titles.length - 1;
      expect(find.text('Next'), isLast ? findsNothing : findsOneWidget);
      expect(find.text('Get started'), isLast ? findsOneWidget : findsNothing);
      if (!isLast) {
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();
      }
    }

    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();
    expect(find.text('login'), findsOneWidget);
  });

  for (final (size, scale) in [
    (const Size(360, 640), 1.3),
    (const Size(320, 568), 1.3),
    (const Size(360, 640), 2.0),
  ]) {
    testWidgets('every slide stays readable on ${size.width.toInt()}×'
        '${size.height.toInt()} at text scale $scale', (tester) async {
      await _pump(
        tester,
        size: size,
        textScale: scale,
        padding: const EdgeInsets.only(top: 24),
      );

      for (var i = 0; i < _titles.length; i++) {
        await _expectReadable(tester, size, _titles[i], slide: i + 1);
        if (i < _titles.length - 1) {
          await tester.tap(find.text('Next'));
          await tester.pumpAndSettle();
        }
      }
    });
  }

  testWidgets('Skip stays below a tall status bar', (tester) async {
    await _pump(tester, padding: const EdgeInsets.only(top: 72));

    expect(
      tester.getRect(find.byType(TextButton)).top,
      greaterThanOrEqualTo(72),
    );
  });

  testWidgets('Skip keeps its designed offset on a standard status bar', (
    tester,
  ) async {
    await _pump(tester, padding: const EdgeInsets.only(top: 24));

    expect(tester.getRect(find.byType(TextButton)).top, 60);
  });

  testWidgets('background images are hidden from screen readers', (
    tester,
  ) async {
    await _pump(tester);

    for (final image in tester.widgetList<Image>(find.byType(Image))) {
      expect(image.excludeFromSemantics, isTrue);
    }
  });
}

/// The CTA is fully on screen, and the title is fully visible below Skip,
/// scrolling the text block into view if it is taller than the space.
Future<void> _expectReadable(
  WidgetTester tester,
  Size screen,
  String title, {
  required int slide,
}) async {
  expect(tester.takeException(), isNull);
  expect(
    Offset.zero & screen,
    _contains(tester.getRect(find.byType(ElevatedButton))),
    reason: 'slide $slide: CTA is off screen',
  );

  final scrollable = find.ancestor(
    of: find.text(title),
    matching: find.byType(Scrollable),
  );
  final titleFinder = find.text(title);
  if (tester.any(scrollable)) {
    await tester.ensureVisible(titleFinder);
    await tester.pumpAndSettle();
  }
  final skip = tester.getRect(find.byType(TextButton));
  final titleRect = tester.getRect(titleFinder);
  expect(
    titleRect.top,
    greaterThanOrEqualTo(skip.bottom),
    reason: 'slide $slide: title is under Skip or off screen',
  );
  expect(titleRect.bottom, lessThanOrEqualTo(screen.height));

  // Back to the resting position, with the CTA in view.
  if (tester.any(scrollable)) {
    await tester.drag(scrollable.first, const Offset(0, -2000));
    await tester.pumpAndSettle();
  }
}

Matcher _contains(Rect inner) => predicate<Rect>(
  (outer) =>
      outer.left <= inner.left &&
      outer.top <= inner.top &&
      outer.right >= inner.right &&
      outer.bottom >= inner.bottom,
  'contains $inner',
);
