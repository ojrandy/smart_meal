/// Paths of every bundled image. Reference images only through these
/// constants so a rename or format change touches one file.
abstract final class AppAssets {
  static const String _images = 'assets/images';

  static const String appLogo = '$_images/app_logo.png';

  // Onboarding carousel, in page order.
  static const String onboardingDiscover = '$_images/onboarding_discover.png';
  static const String onboardingPlan = '$_images/onboarding_plan.png';
  static const String onboardingDecide = '$_images/onboarding_decide.png';

  // Auth screen heroes.
  static const String authLoginHero = '$_images/auth_login_hero.png';
  static const String authSignupHero = '$_images/auth_signup_hero.png';

  /// Every image above; a test checks each one is in the asset bundle.
  static const List<String> all = [
    appLogo,
    onboardingDiscover,
    onboardingPlan,
    onboardingDecide,
    authLoginHero,
    authSignupHero,
  ];
}
