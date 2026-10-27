// WCAG AA contrast of the white onboarding text over the real artwork and
// overlays: the screen is rendered once with transparent glyphs (same
// layout), and every background pixel under each visible text box is checked.

import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smart_meal/core/l10n/l10n.dart';
import 'package:smart_meal/core/theme/app_fonts.dart';
import 'package:smart_meal/core/theme/app_theme.dart';
import 'package:smart_meal/features/onboarding/presentation/onboarding_screen.dart';

double _linear(double c) =>
    c <= 0.04045 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();

double _luminance(double r, double g, double b) =>
    0.2126 * _linear(r) + 0.7152 * _linear(g) + 0.0722 * _linear(b);

double _contrast(double a, double b) =>
    (math.max(a, b) + 0.05) / (math.min(a, b) + 0.05);

InlineSpan _transparent(InlineSpan span) {
  if (span is! TextSpan) return span;
  return TextSpan(
    text: span.text,
    style: (span.style ?? const TextStyle()).copyWith(
      color: const Color(0x00000000),
    ),
    children: span.children?.map(_transparent).toList(),
  );
}

/// Lowest contrast of [foreground] (alpha-blended) over any pixel in [area].
double _worstContrast(Uint8List rgba, int width, Rect area, Color foreground) {
  var worst = double.infinity;
  for (var y = area.top.floor(); y < area.bottom.ceil(); y++) {
    for (var x = area.left.floor(); x < area.right.ceil(); x++) {
      final i = (y * width + x) * 4;
      final r = rgba[i] / 255, g = rgba[i + 1] / 255, b = rgba[i + 2] / 255;
      final a = foreground.a;
      final text = _luminance(
        foreground.r * a + r * (1 - a),
        foreground.g * a + g * (1 - a),
        foreground.b * a + b * (1 - a),
      );
      worst = math.min(worst, _contrast(text, _luminance(r, g, b)));
    }
  }
  return worst;
}

void main() {
  setUpAll(AppFonts.configure);

  for (final (size, scale) in [
    (const Size(393, 873), 1.0),
    (const Size(360, 640), 1.3),
    (const Size(320, 568), 1.3),
  ]) {
    testWidgets('text meets WCAG AA on every slide at '
        '${size.width.toInt()}×${size.height.toInt()} ×$scale', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      tester.view.padding = const FakeViewPadding(top: 24);
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      final boundary = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: boundary,
          child: ProviderScope(
            child: MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              theme: AppTheme.lightTheme,
              home: const OnboardingScreen(),
            ),
          ),
        ),
      );
      await tester.runAsync(GoogleFonts.pendingFonts);

      for (var slide = 1; slide <= 3; slide++) {
        await tester.runAsync(() async {
          for (final image in tester.widgetList<Image>(find.byType(Image))) {
            await precacheImage(
              image.image,
              tester.element(find.byWidget(image)),
            );
          }
        });
        await tester.pump();

        // Body text needs 4.5:1; the 36 px bold title is large text (3:1).
        final checks = [
          ('title', find.byType(Text).at(0), 3.0),
          ('subtitle', find.byType(Text).at(1), 4.5),
          ('Skip', find.text('Skip'), 4.5),
        ];
        final measured =
            <(String, RenderParagraph, InlineSpan, Rect, double)>[];
        for (final (name, finder, minimum) in checks) {
          final paragraph = tester.renderObject<RenderParagraph>(
            find.descendant(of: finder, matching: find.byType(RichText)),
          );
          final scrollable = find.ancestor(
            of: finder,
            matching: find.byType(Scrollable),
          );
          // Only the part of the text that is on screen.
          final visible = tester.any(scrollable)
              ? tester.getRect(scrollable.first)
              : Offset.zero & size;
          measured.add((
            name,
            paragraph,
            paragraph.text,
            tester.getRect(finder).intersect(visible),
            minimum,
          ));
        }

        final colors = [
          for (final (_, paragraph, _, _, _) in measured)
            (paragraph.text as TextSpan).style!.color!,
        ];
        for (final (_, paragraph, _, _, _) in measured) {
          paragraph.text = _transparent(paragraph.text);
        }
        await tester.pump();

        late Uint8List rgba;
        await tester.runAsync(() async {
          final image =
              await (boundary.currentContext!.findRenderObject()!
                      as RenderRepaintBoundary)
                  .toImage();
          rgba = (await image.toByteData(
            format: ui.ImageByteFormat.rawRgba,
          ))!.buffer.asUint8List();
        });

        for (var i = 0; i < measured.length; i++) {
          final (name, paragraph, original, area, minimum) = measured[i];
          expect(
            _worstContrast(rgba, size.width.toInt(), area, colors[i]),
            greaterThanOrEqualTo(minimum),
            reason: 'slide $slide: $name',
          );
          paragraph.text = original;
        }

        if (slide < 3) {
          await tester.tap(find.text('Next'));
          await tester.pumpAndSettle();
        }
      }
    });
  }
}
