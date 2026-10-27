// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Smart Meal';

  @override
  String get languageSwitchLabel => 'Language';

  @override
  String get errorNoConnection =>
      'No connection. Check your internet and try again.';

  @override
  String get errorGeneric => 'Something went wrong. Please try again.';

  @override
  String get tryAgain => 'Try again';

  @override
  String get signOut => 'Sign out';

  @override
  String get authErrorInvalidCredentials =>
      'Incorrect email or password. Please try again.';

  @override
  String get authErrorEmailExists =>
      'An account with this email already exists. Try signing in.';

  @override
  String get authErrorWeakPassword =>
      'Choose a stronger password: at least 8 characters with upper- and lowercase letters, a number and a symbol.';

  @override
  String get authErrorEmailNotConfirmed =>
      'Please confirm your email before signing in.';

  @override
  String get authErrorTooManyAttempts =>
      'Too many attempts. Please wait a moment and try again.';

  @override
  String get authErrorSignupDisabled =>
      'New sign-ups are paused right now. Please try again later.';

  @override
  String get authErrorEmailAddressInvalid =>
      'That email address can\'t be used. Please check it and try again.';

  @override
  String get authErrorValidationFailed =>
      'Please check your details and try again.';

  @override
  String get authErrorSamePassword =>
      'Your new password must be different from your current one.';

  @override
  String get authErrorSessionExpired =>
      'Your session has expired. Please sign in again.';

  @override
  String get authErrorUserBanned => 'This account can\'t sign in right now.';

  @override
  String get authErrorGoogleSignInFailed =>
      'Google sign-in failed. Please try again.';

  @override
  String get authErrorSignOutFailed => 'Sign out failed. Please try again.';

  @override
  String get authErrorAccountDeletionFailed =>
      'We couldn\'t delete your account. Please try again.';

  @override
  String get fieldEmailMissing => 'Please enter your email';

  @override
  String get fieldEmailInvalid => 'Please enter a valid email';

  @override
  String get fieldPasswordMissing => 'Please enter your password';

  @override
  String fieldPasswordTooShort(int count) {
    return 'Password must be at least $count characters';
  }

  @override
  String get fieldPasswordTooLong => 'Password is too long';

  @override
  String get fieldPasswordTooSimple =>
      'Use upper- and lowercase letters, a number and a symbol';

  @override
  String get fieldConfirmationMissing => 'Please confirm your password';

  @override
  String get fieldConfirmationMismatch => 'Passwords don\'t match';

  @override
  String get loginTitleLead => 'Welcome back to';

  @override
  String get loginSubtitle =>
      'Sign in to get your personalized meal\nrecommendations ✨';

  @override
  String get emailLabel => 'Email';

  @override
  String get emailHint => 'user@email.com';

  @override
  String get passwordLabel => 'Password';

  @override
  String get forgotPasswordLink => 'Forgot password?';

  @override
  String get signInButton => 'Sign In ✨';

  @override
  String get orContinueWith => 'or continue with';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get noAccountPrompt => 'Don\'t have an account?';

  @override
  String get signUpLink => 'Sign up';

  @override
  String get signupConfirmationSent =>
      'Almost there! We\'ve sent a confirmation link to your email.';

  @override
  String get signupTitleLead => 'Create your';

  @override
  String get signupTitleAccent => 'Smart Meal account';

  @override
  String get signupSubtitle =>
      'Discover personalized meals made for your taste ✨';

  @override
  String get confirmPasswordLabel => 'Confirm Password';

  @override
  String get createAccountButton => 'Create Account ✨';

  @override
  String get haveAccountPrompt => 'Already have an account?';

  @override
  String get logInLink => 'Log in';

  @override
  String get forgotPasswordTitleLead => 'Forgot your';

  @override
  String get forgotPasswordTitleAccent => 'password?';

  @override
  String get forgotPasswordSubtitle =>
      'Enter your account email and we\'ll send you a link to set a new password.';

  @override
  String get sendResetLinkButton => 'Send reset link';

  @override
  String resendInSeconds(int seconds) {
    return 'Resend in ${seconds}s';
  }

  @override
  String get resendLinkButton => 'Resend link';

  @override
  String get resetEmailSentNotice =>
      'If an account exists for that email, we\'ve sent a link to reset your password.';

  @override
  String get passwordUpdatedNotice => 'Your password has been updated.';

  @override
  String get resetPasswordTitleLead => 'Set a new';

  @override
  String get resetPasswordTitleAccent => 'password';

  @override
  String get newPasswordLabel => 'New password';

  @override
  String get confirmNewPasswordLabel => 'Confirm password';

  @override
  String get savePasswordButton => 'Save password';

  @override
  String get aiChefHeading => 'YOUR AI CHEF RECOMMENDS';

  @override
  String get seeWhyButton => 'See why';

  @override
  String get showPasswordLabel => 'Show password';

  @override
  String get hidePasswordLabel => 'Hide password';

  @override
  String get addToFavoritesLabel => 'Add to favorites';

  @override
  String get removeFromFavoritesLabel => 'Remove from favorites';

  @override
  String get navHome => 'Home';

  @override
  String get navDiscover => 'Discover';

  @override
  String get navPlanner => 'Planner';

  @override
  String get navFavorites => 'Favorites';

  @override
  String get navProfile => 'Profile';

  @override
  String get homeWelcome => 'Welcome to Smart Meal';

  @override
  String homeWelcomeName(String name) {
    return 'Welcome, $name';
  }

  @override
  String homeSignedInAs(String email) {
    return 'Signed in as $email';
  }

  @override
  String get homeComingSoon =>
      'Your personalized meals will appear here soon ✨';

  @override
  String get splashTagline => 'Your AI food companion';

  @override
  String get splashByline => 'by OJ Tech';

  @override
  String get onboardingDiscoverTitle => 'Welcome to SmartMeal';

  @override
  String get onboardingDiscoverBody =>
      'Discover meals you will enjoy with AI-powered recommendations tailored to your taste.';

  @override
  String get onboardingPlanTitle => 'Plan Your Meals';

  @override
  String get onboardingPlanBody =>
      'Manage your budget and plan your weekly recipes efficiently with intelligent tracking.';

  @override
  String get onboardingDecideTitle => 'Smarter Food Decisions';

  @override
  String get onboardingDecideBody =>
      'Get personalized recommendations and insights to make healthier food choices.';

  @override
  String get getStartedButton => 'Get started';

  @override
  String get nextButton => 'Next';

  @override
  String get skipButton => 'Skip';

  @override
  String get authLinkErrorNotice =>
      'This link is invalid or has expired. Please request a new one.';

  @override
  String get setupLoadingMessage => 'Getting things ready…';

  @override
  String setupStepCounter(int number, int total) {
    return 'Step $number of $total';
  }

  @override
  String get setupProgressLabel => 'Setup progress';

  @override
  String get setupChooseOption => 'Please choose an option';

  @override
  String get continueButton => 'Continue';

  @override
  String get finishButton => 'Finish';

  @override
  String get setupLifestyleTitle => 'What best describes you?';

  @override
  String get lifestyleStudent => 'Student';

  @override
  String get lifestyleStudentHint => 'School or university';

  @override
  String get lifestyleWorking => 'Working';

  @override
  String get lifestyleWorkingHint => 'Job, business or trade';

  @override
  String get lifestyleFamily => 'Cooking for my family';

  @override
  String get lifestyleAthlete => 'Sports / very active';

  @override
  String get setupHouseholdTitle => 'How many people do you cook for?';

  @override
  String get setupHouseholdSubtitle => 'Count yourself too.';

  @override
  String get setupHouseholdFewer => 'Fewer people';

  @override
  String get setupHouseholdMore => 'More people';

  @override
  String peopleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count people',
      one: '1 person',
    );
    return '$_temp0';
  }

  @override
  String peopleUnit(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'people',
      one: 'person',
    );
    return '$_temp0';
  }

  @override
  String get setupBudgetTitle => 'How much do you spend on food?';

  @override
  String get setupBudgetSubtitle => 'We\'ll suggest meals that fit it.';

  @override
  String get setupBudgetAmountLabel => 'Amount in FCFA';

  @override
  String get setupBudgetInvalid =>
      'Enter an amount between 1 and 10 000 000 FCFA';

  @override
  String get budgetPerDay => 'Per day';

  @override
  String get budgetPerWeek => 'Per week';

  @override
  String get budgetPerMonth => 'Per month';

  @override
  String setupBudgetAdviceDaily(int count, String amount) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count people',
      one: '1 person',
    );
    return 'For $_temp0, we suggest at least $amount per day so we can find enough good meals. You can keep your amount — we\'ll do our best with it.';
  }

  @override
  String setupBudgetAdviceWeekly(int count, String amount) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count people',
      one: '1 person',
    );
    return 'For $_temp0, we suggest at least $amount per week so we can find enough good meals. You can keep your amount — we\'ll do our best with it.';
  }

  @override
  String setupBudgetAdviceMonthly(int count, String amount) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count people',
      one: '1 person',
    );
    return 'For $_temp0, we suggest at least $amount per month so we can find enough good meals. You can keep your amount — we\'ll do our best with it.';
  }

  @override
  String get setupCookingTitle => 'How do you like to cook?';

  @override
  String get cookingSkillBeginner => 'I\'m still learning';

  @override
  String get cookingSkillIntermediate => 'I cook often';

  @override
  String get cookingSkillAdvanced => 'I\'m a very good cook';

  @override
  String get setupCookTimeQuestion => 'How much time can you spend cooking?';

  @override
  String cookTimeMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String get cookTimeOneHour => '1 h';

  @override
  String get cookTimeOneHourThirty => '1 h 30';

  @override
  String get cookTimeTwoHours => '2 h';

  @override
  String get setupCuisinesTitle => 'What kinds of food do you like?';

  @override
  String get setupCuisinesSubtitle =>
      'Tap once if you like it, twice if you don\'t. You can skip this.';

  @override
  String get cuisineLike => 'Like';

  @override
  String get cuisineDislike => 'Don\'t like';

  @override
  String get cuisineCameroonian => 'Cameroonian food';

  @override
  String get cuisineCameroonianHint => 'Ndolé, eru, achu, koki';

  @override
  String get cuisineWestAfrican => 'West African food';

  @override
  String get cuisineWestAfricanHint => 'Jollof rice, puff-puff';

  @override
  String get cuisineItalian => 'Italian food';

  @override
  String get cuisineItalianHint => 'Spaghetti, pasta, pizza';

  @override
  String get cuisineFrench => 'French food';

  @override
  String get cuisineFrenchHint => 'Omelette, salads, gratin';

  @override
  String get cuisineIndian => 'Indian food';

  @override
  String get cuisineIndianHint => 'Curry, chapati';

  @override
  String get cuisineChinese => 'Chinese food';

  @override
  String get cuisineChineseHint => 'Fried rice, noodles';

  @override
  String get setupConsentTitle => 'Your health information, your choice';

  @override
  String get setupConsentWhy =>
      'Why we ask: knowing your allergies is how we keep every meal we suggest safe for you.';

  @override
  String get setupConsentText =>
      'I agree that Smart Meal stores my allergies, diet and health goals to personalise my meals. Only I can see them, and I can delete them anytime.';

  @override
  String get setupConsentAgree => 'I agree';

  @override
  String get setupDietTitle => 'Is there food you don\'t eat?';

  @override
  String get dietNone => 'I eat everything';

  @override
  String get dietVegetarian => 'No meat';

  @override
  String get dietVegetarianHint => 'Vegetarian';

  @override
  String get dietVegan => 'No food from animals';

  @override
  String get dietVeganHint => 'No meat, fish, eggs or milk (vegan)';

  @override
  String get dietPescatarian => 'Fish, but no meat';

  @override
  String get dietHalal => 'Halal only';

  @override
  String get dietGlutenFree => 'No wheat flour';

  @override
  String get dietGlutenFreeHint => 'No bread, puff-puff or pasta (gluten-free)';

  @override
  String get dietDairyFree => 'No milk products';

  @override
  String get dietDairyFreeHint => 'No milk, cheese or yoghurt';

  @override
  String get dietLowCarb => 'Less starch';

  @override
  String get dietLowCarbHint => 'Less rice, garri, bread and pasta (low-carb)';

  @override
  String get setupAllergiesTitle => 'Does any food make you sick?';

  @override
  String get setupAllergiesSubtitle =>
      'Food allergies. We\'ll never suggest a meal that contains these.';

  @override
  String get allergiesNone => 'No, none';

  @override
  String get allergenGluten => 'Wheat flour';

  @override
  String get allergenGlutenHint => 'Bread, puff-puff, pasta, beignets';

  @override
  String get allergenCrustaceans => 'Crayfish, prawns, crabs';

  @override
  String get allergenMolluscs => 'Snails, mussels, oysters';

  @override
  String get allergenFish => 'Fish';

  @override
  String get allergenFishHint => 'Fresh, smoked or dried';

  @override
  String get allergenEggs => 'Eggs';

  @override
  String get allergenMilk => 'Milk';

  @override
  String get allergenMilkHint => 'And cheese, yoghurt, butter';

  @override
  String get allergenPeanuts => 'Groundnuts';

  @override
  String get allergenPeanutsHint => 'Peanuts, groundnut paste';

  @override
  String get allergenTreeNuts => 'Cashew, almonds and other nuts';

  @override
  String get allergenSoy => 'Soya';

  @override
  String get allergenSoyHint => 'Soya beans, soy sauce';

  @override
  String get allergenSesame => 'Sesame (benne) seeds';

  @override
  String get allergenCelery => 'Celery';

  @override
  String get allergenMustard => 'Mustard';

  @override
  String get allergenSulphites => 'Sulphites';

  @override
  String get allergenSulphitesHint => 'In some wine, dried fruit, vinegar';

  @override
  String get allergenLupin => 'Lupin flour';

  @override
  String get allergenLupinHint => 'Rare; in some imported breads';

  @override
  String get setupGoalsTitle => 'What should your food help you with?';

  @override
  String get setupGoalsSubtitle => 'Optional — choose any.';

  @override
  String get goalLoseWeight => 'Lose weight';

  @override
  String get goalMaintainWeight => 'Keep my weight';

  @override
  String get goalGainMuscle => 'Get stronger';

  @override
  String get goalGainMuscleHint => 'Build muscle';

  @override
  String get goalEatHealthier => 'Eat healthier';

  @override
  String get goalManageBloodSugar => 'Control my blood sugar';

  @override
  String get goalManageBloodSugarHint => 'For example, with diabetes';

  @override
  String get setupProcessingTitle => 'Personalising your meals…';

  @override
  String get setupStageSaving => 'Saving your preferences';

  @override
  String get setupStageMatching => 'Matching recipes to your taste';

  @override
  String get setupStageChecking => 'Checking allergies and budget';

  @override
  String get setupSaveFailed =>
      'We couldn\'t save your answers. Please try again.';

  @override
  String recipeDetailsTitle(String id) {
    return 'Recipe $id';
  }

  @override
  String get fieldNewPasswordMissing => 'Please enter a password';
}
