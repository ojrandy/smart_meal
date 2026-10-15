import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Inter is bundled in `assets/fonts/`, so text renders the same offline and
/// startup makes no font request.
abstract final class AppFonts {
  static const String licenseAsset = 'assets/fonts/OFL.txt';

  /// Every Inter weight/style the app uses. Each must have a matching
  /// `assets/fonts/Inter-<Weight><Style>.ttf`; app_fonts_test enforces this.
  static const List<(FontWeight, FontStyle)> bundledInterVariants = [
    (FontWeight.w400, FontStyle.normal),
    (FontWeight.w500, FontStyle.normal),
    (FontWeight.w600, FontStyle.normal),
    (FontWeight.w700, FontStyle.normal),
    (FontWeight.w900, FontStyle.italic),
  ];

  /// Call once in `main()` before `runApp`.
  static void configure() {
    // A missing weight must fail loudly in development instead of being
    // fetched silently over the network.
    GoogleFonts.config.allowRuntimeFetching = false;
    LicenseRegistry.addLicense(_interLicense);
  }

  static Stream<LicenseEntry> _interLicense() async* {
    final license = await rootBundle.loadString(licenseAsset);
    yield LicenseEntryWithLineBreaks(const ['Inter'], license);
  }
}
