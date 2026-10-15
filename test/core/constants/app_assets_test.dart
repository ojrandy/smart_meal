import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_meal/core/constants/app_assets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('every AppAssets path is in the asset bundle', () async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final bundled = manifest.listAssets();

    for (final path in AppAssets.all) {
      expect(bundled, contains(path), reason: '$path is not bundled');
    }
  });

  test('only AppAssets images are bundled', () async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final images = manifest.listAssets().where(
      (path) => path.startsWith('assets/images/'),
    );

    expect(images, unorderedEquals(AppAssets.all));
  });

  // Catches a corrupt or truncated file and an image wider than the 1440 px
  // budget (ui-context.md → Assets).
  testWidgets('every AppAssets image decodes within the size budget', (
    tester,
  ) async {
    await tester.runAsync(() async {
      for (final path in AppAssets.all) {
        final data = await rootBundle.load(path);
        final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
        final frame = await codec.getNextFrame();

        expect(frame.image.width, inInclusiveRange(1, 1440), reason: path);
        expect(frame.image.height, greaterThan(0), reason: path);
        frame.image.dispose();
        codec.dispose();
      }
    });
  });
}
