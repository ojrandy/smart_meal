/// Paths of every bundled image. Reference images only through these
/// constants so a rename or format change touches one file.
abstract final class AppAssets {
  static const String _images = 'assets/images';

  static const String appLogo = '$_images/app_logo.png';

  // Onboarding carousel, in page order.
  static const String onboardingDiscover = '$_images/onboarding_discover.webp';
  static const String onboardingPlan = '$_images/onboarding_plan.webp';
  static const String onboardingDecide = '$_images/onboarding_decide.webp';

  // Auth screen heroes.
  static const String authLoginHero = '$_images/auth_login_hero.webp';
  static const String authSignupHero = '$_images/auth_signup_hero.webp';

  // Official Google "G", cropped unmodified from Google's sign-in branding
  // assets (design-assets/source/google-signin-assets.zip, Light theme,
  // icon-only, 4x). White background: use it on white surfaces only.
  static const String googleLogo = '$_images/google_g.png';

  // Setup step illustrations (unDraw, recoloured to the app green), one per
  // question, in step order.
  static const String setupLifestyle = '$_images/setup_lifestyle.webp';
  static const String setupHousehold = '$_images/setup_household.webp';
  static const String setupBudget = '$_images/setup_budget.webp';
  static const String setupCooking = '$_images/setup_cooking.webp';
  static const String setupCuisines = '$_images/setup_cuisines.webp';
  static const String setupConsent = '$_images/setup_consent.webp';
  static const String setupDiet = '$_images/setup_diet.webp';
  static const String setupAllergies = '$_images/setup_allergies.webp';
  static const String setupGoals = '$_images/setup_goals.webp';

  /// Every image above; a test checks each one is in the asset bundle.
  static const List<String> all = [
    appLogo,
    onboardingDiscover,
    onboardingPlan,
    onboardingDecide,
    authLoginHero,
    authSignupHero,
    googleLogo,
    setupLifestyle,
    setupHousehold,
    setupBudget,
    setupCooking,
    setupCuisines,
    setupConsent,
    setupDiet,
    setupAllergies,
    setupGoals,
  ];
}
