import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smart_meal/core/theme/app_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(AppFonts.configure);

  for (final (weight, style) in AppFonts.bundledInterVariants) {
    test('Inter $weight ${style.name} loads from assets', () async {
      GoogleFonts.inter(fontWeight: weight, fontStyle: style);

      await expectLater(GoogleFonts.pendingFonts(), completes);
    });
  }

  test('an unbundled weight fails instead of downloading', () async {
    // google_fonts also surfaces the failure as an uncaught async error, so
    // capture it in a guarded zone rather than letting it fail the test.
    final error = Completer<Object>();
    runZonedGuarded(() => GoogleFonts.inter(fontWeight: FontWeight.w800), (
      Object e,
      StackTrace _,
    ) {
      if (!error.isCompleted) error.complete(e);
    });

    expect(
      (await error.future).toString(),
      contains('Inter-ExtraBold was not found in the application assets'),
    );
  });

  test('the Inter OFL licence is registered', () async {
    final entries = await LicenseRegistry.licenses.toList();

    expect(
      entries.where((entry) => entry.packages.contains('Inter')),
      isNotEmpty,
    );
  });
}
