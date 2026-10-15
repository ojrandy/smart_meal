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
}
