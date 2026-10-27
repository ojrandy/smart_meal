import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr'),
  ];

  /// The app's name; a brand, never translated
  ///
  /// In en, this message translates to:
  /// **'Smart Meal'**
  String get appName;

  /// Screen-reader label of the EN | FR switch
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageSwitchLabel;

  /// Shown when the server cannot be reached
  ///
  /// In en, this message translates to:
  /// **'No connection. Check your internet and try again.'**
  String get errorNoConnection;

  /// Fallback error for anything unexpected
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errorGeneric;

  /// Retry button
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// Sign-out link or button
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// Sign-in failed: wrong email or password
  ///
  /// In en, this message translates to:
  /// **'Incorrect email or password. Please try again.'**
  String get authErrorInvalidCredentials;

  /// Sign-up with an email that is taken
  ///
  /// In en, this message translates to:
  /// **'An account with this email already exists. Try signing in.'**
  String get authErrorEmailExists;

  /// Server rejected the password as weak
  ///
  /// In en, this message translates to:
  /// **'Choose a stronger password: at least 8 characters with upper- and lowercase letters, a number and a symbol.'**
  String get authErrorWeakPassword;

  /// Sign-in before the confirmation link was opened
  ///
  /// In en, this message translates to:
  /// **'Please confirm your email before signing in.'**
  String get authErrorEmailNotConfirmed;

  /// Rate limited
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Please wait a moment and try again.'**
  String get authErrorTooManyAttempts;

  /// Sign-ups turned off on the server
  ///
  /// In en, this message translates to:
  /// **'New sign-ups are paused right now. Please try again later.'**
  String get authErrorSignupDisabled;

  /// Server refused the email address
  ///
  /// In en, this message translates to:
  /// **'That email address can\'t be used. Please check it and try again.'**
  String get authErrorEmailAddressInvalid;

  /// Server-side validation failed
  ///
  /// In en, this message translates to:
  /// **'Please check your details and try again.'**
  String get authErrorValidationFailed;

  /// New password equals the old one
  ///
  /// In en, this message translates to:
  /// **'Your new password must be different from your current one.'**
  String get authErrorSamePassword;

  /// Session no longer valid
  ///
  /// In en, this message translates to:
  /// **'Your session has expired. Please sign in again.'**
  String get authErrorSessionExpired;

  /// Account blocked
  ///
  /// In en, this message translates to:
  /// **'This account can\'t sign in right now.'**
  String get authErrorUserBanned;

  /// Google sign-in error
  ///
  /// In en, this message translates to:
  /// **'Google sign-in failed. Please try again.'**
  String get authErrorGoogleSignInFailed;

  /// Sign-out failed while still signed in
  ///
  /// In en, this message translates to:
  /// **'Sign out failed. Please try again.'**
  String get authErrorSignOutFailed;

  /// Account deletion failed
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t delete your account. Please try again.'**
  String get authErrorAccountDeletionFailed;

  /// Form error: email empty
  ///
  /// In en, this message translates to:
  /// **'Please enter your email'**
  String get fieldEmailMissing;

  /// Form error: email malformed
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email'**
  String get fieldEmailInvalid;

  /// Form error: password empty
  ///
  /// In en, this message translates to:
  /// **'Please enter your password'**
  String get fieldPasswordMissing;

  /// Form error: password shorter than the minimum
  ///
  /// In en, this message translates to:
  /// **'Password must be at least {count} characters'**
  String fieldPasswordTooShort(int count);

  /// Form error: password over 72 bytes
  ///
  /// In en, this message translates to:
  /// **'Password is too long'**
  String get fieldPasswordTooLong;

  /// Form error: password misses a character class
  ///
  /// In en, this message translates to:
  /// **'Use upper- and lowercase letters, a number and a symbol'**
  String get fieldPasswordTooSimple;

  /// Form error: confirmation empty
  ///
  /// In en, this message translates to:
  /// **'Please confirm your password'**
  String get fieldConfirmationMissing;

  /// Form error: confirmation differs
  ///
  /// In en, this message translates to:
  /// **'Passwords don\'t match'**
  String get fieldConfirmationMismatch;

  /// Sign-in title, followed by the app name on the next line
  ///
  /// In en, this message translates to:
  /// **'Welcome back to'**
  String get loginTitleLead;

  /// Sign-in subtitle
  ///
  /// In en, this message translates to:
  /// **'Sign in to get your personalized meal\nrecommendations ✨'**
  String get loginSubtitle;

  /// Email field label
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// Email field example
  ///
  /// In en, this message translates to:
  /// **'user@email.com'**
  String get emailHint;

  /// Password field label
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// Link to password recovery
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPasswordLink;

  /// Sign-in button
  ///
  /// In en, this message translates to:
  /// **'Sign In ✨'**
  String get signInButton;

  /// Divider above social sign-in
  ///
  /// In en, this message translates to:
  /// **'or continue with'**
  String get orContinueWith;

  /// Google sign-in button
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// Before the sign-up link
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get noAccountPrompt;

  /// Link to sign-up
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get signUpLink;

  /// After sign-up when email confirmation is on (also shown for an email already registered)
  ///
  /// In en, this message translates to:
  /// **'Almost there! We\'ve sent a confirmation link to your email.'**
  String get signupConfirmationSent;

  /// Sign-up title, first line
  ///
  /// In en, this message translates to:
  /// **'Create your'**
  String get signupTitleLead;

  /// Sign-up title, second line in brand colour
  ///
  /// In en, this message translates to:
  /// **'Smart Meal account'**
  String get signupTitleAccent;

  /// Sign-up subtitle
  ///
  /// In en, this message translates to:
  /// **'Discover personalized meals made for your taste ✨'**
  String get signupSubtitle;

  /// Sign-up: confirmation field label
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPasswordLabel;

  /// Sign-up button
  ///
  /// In en, this message translates to:
  /// **'Create Account ✨'**
  String get createAccountButton;

  /// Before the sign-in link
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get haveAccountPrompt;

  /// Link to sign-in
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get logInLink;

  /// Forgot-password title, first line
  ///
  /// In en, this message translates to:
  /// **'Forgot your'**
  String get forgotPasswordTitleLead;

  /// Forgot-password title, second line in brand colour
  ///
  /// In en, this message translates to:
  /// **'password?'**
  String get forgotPasswordTitleAccent;

  /// Forgot-password explanation
  ///
  /// In en, this message translates to:
  /// **'Enter your account email and we\'ll send you a link to set a new password.'**
  String get forgotPasswordSubtitle;

  /// Forgot-password button before sending
  ///
  /// In en, this message translates to:
  /// **'Send reset link'**
  String get sendResetLinkButton;

  /// Button while the resend cooldown runs
  ///
  /// In en, this message translates to:
  /// **'Resend in {seconds}s'**
  String resendInSeconds(int seconds);

  /// Button after the cooldown
  ///
  /// In en, this message translates to:
  /// **'Resend link'**
  String get resendLinkButton;

  /// Neutral confirmation; must not reveal whether the account exists
  ///
  /// In en, this message translates to:
  /// **'If an account exists for that email, we\'ve sent a link to reset your password.'**
  String get resetEmailSentNotice;

  /// After setting a new password
  ///
  /// In en, this message translates to:
  /// **'Your password has been updated.'**
  String get passwordUpdatedNotice;

  /// Reset-password title, first line
  ///
  /// In en, this message translates to:
  /// **'Set a new'**
  String get resetPasswordTitleLead;

  /// Reset-password title, second line in brand colour
  ///
  /// In en, this message translates to:
  /// **'password'**
  String get resetPasswordTitleAccent;

  /// Reset-password: new password field
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get newPasswordLabel;

  /// Reset-password: confirmation field
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get confirmNewPasswordLabel;

  /// Reset-password button
  ///
  /// In en, this message translates to:
  /// **'Save password'**
  String get savePasswordButton;

  /// Recommendation card heading (all caps)
  ///
  /// In en, this message translates to:
  /// **'YOUR AI CHEF RECOMMENDS'**
  String get aiChefHeading;

  /// Opens the reasons for a recommendation
  ///
  /// In en, this message translates to:
  /// **'See why'**
  String get seeWhyButton;

  /// Screen-reader label of the eye icon
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get showPasswordLabel;

  /// Screen-reader label of the eye icon
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get hidePasswordLabel;

  /// Screen-reader label of the heart icon
  ///
  /// In en, this message translates to:
  /// **'Add to favorites'**
  String get addToFavoritesLabel;

  /// Screen-reader label of the heart icon
  ///
  /// In en, this message translates to:
  /// **'Remove from favorites'**
  String get removeFromFavoritesLabel;

  /// Bottom tab
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// Bottom tab
  ///
  /// In en, this message translates to:
  /// **'Discover'**
  String get navDiscover;

  /// Bottom tab: meal planner
  ///
  /// In en, this message translates to:
  /// **'Planner'**
  String get navPlanner;

  /// Bottom tab
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get navFavorites;

  /// Bottom tab
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// Interim Home title when the name is unknown
  ///
  /// In en, this message translates to:
  /// **'Welcome to Smart Meal'**
  String get homeWelcome;

  /// Interim Home title with the user's first name
  ///
  /// In en, this message translates to:
  /// **'Welcome, {name}'**
  String homeWelcomeName(String name);

  /// Interim Home: which account is signed in
  ///
  /// In en, this message translates to:
  /// **'Signed in as {email}'**
  String homeSignedInAs(String email);

  /// Interim Home body until recommendations ship
  ///
  /// In en, this message translates to:
  /// **'Your personalized meals will appear here soon ✨'**
  String get homeComingSoon;

  /// Splash line under the wordmark
  ///
  /// In en, this message translates to:
  /// **'Your AI food companion'**
  String get splashTagline;

  /// Splash credit; OJ Tech is a brand
  ///
  /// In en, this message translates to:
  /// **'by OJ Tech'**
  String get splashByline;

  /// Onboarding slide 1 title
  ///
  /// In en, this message translates to:
  /// **'Welcome to SmartMeal'**
  String get onboardingDiscoverTitle;

  /// Onboarding slide 1 text
  ///
  /// In en, this message translates to:
  /// **'Discover meals you will enjoy with AI-powered recommendations tailored to your taste.'**
  String get onboardingDiscoverBody;

  /// Onboarding slide 2 title
  ///
  /// In en, this message translates to:
  /// **'Plan Your Meals'**
  String get onboardingPlanTitle;

  /// Onboarding slide 2 text
  ///
  /// In en, this message translates to:
  /// **'Manage your budget and plan your weekly recipes efficiently with intelligent tracking.'**
  String get onboardingPlanBody;

  /// Onboarding slide 3 title
  ///
  /// In en, this message translates to:
  /// **'Smarter Food Decisions'**
  String get onboardingDecideTitle;

  /// Onboarding slide 3 text
  ///
  /// In en, this message translates to:
  /// **'Get personalized recommendations and insights to make healthier food choices.'**
  String get onboardingDecideBody;

  /// Last onboarding slide button
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get getStartedButton;

  /// Onboarding button to the next slide
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get nextButton;

  /// Skips onboarding, or an optional setup question
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skipButton;

  /// A confirmation or recovery link failed
  ///
  /// In en, this message translates to:
  /// **'This link is invalid or has expired. Please request a new one.'**
  String get authLinkErrorNotice;

  /// Setup loading screen while the status is checked
  ///
  /// In en, this message translates to:
  /// **'Getting things ready…'**
  String get setupLoadingMessage;

  /// Setup progress text
  ///
  /// In en, this message translates to:
  /// **'Step {number} of {total}'**
  String setupStepCounter(int number, int total);

  /// Screen-reader label of the setup progress bar
  ///
  /// In en, this message translates to:
  /// **'Setup progress'**
  String get setupProgressLabel;

  /// Setup: Continue tapped without an answer
  ///
  /// In en, this message translates to:
  /// **'Please choose an option'**
  String get setupChooseOption;

  /// Setup: next step button
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueButton;

  /// Setup: last step button when goals are chosen
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get finishButton;

  /// Setup step 1 question
  ///
  /// In en, this message translates to:
  /// **'What best describes you?'**
  String get setupLifestyleTitle;

  /// Lifestyle answer
  ///
  /// In en, this message translates to:
  /// **'Student'**
  String get lifestyleStudent;

  /// Lifestyle answer hint
  ///
  /// In en, this message translates to:
  /// **'School or university'**
  String get lifestyleStudentHint;

  /// Lifestyle answer
  ///
  /// In en, this message translates to:
  /// **'Working'**
  String get lifestyleWorking;

  /// Lifestyle answer hint
  ///
  /// In en, this message translates to:
  /// **'Job, business or trade'**
  String get lifestyleWorkingHint;

  /// Lifestyle answer
  ///
  /// In en, this message translates to:
  /// **'Cooking for my family'**
  String get lifestyleFamily;

  /// Lifestyle answer
  ///
  /// In en, this message translates to:
  /// **'Sports / very active'**
  String get lifestyleAthlete;

  /// Setup step 2 question
  ///
  /// In en, this message translates to:
  /// **'How many people do you cook for?'**
  String get setupHouseholdTitle;

  /// Setup step 2 hint
  ///
  /// In en, this message translates to:
  /// **'Count yourself too.'**
  String get setupHouseholdSubtitle;

  /// Tooltip of the minus button
  ///
  /// In en, this message translates to:
  /// **'Fewer people'**
  String get setupHouseholdFewer;

  /// Tooltip of the plus button
  ///
  /// In en, this message translates to:
  /// **'More people'**
  String get setupHouseholdMore;

  /// A number of people
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 person} other{{count} people}}'**
  String peopleCount(int count);

  /// Word under the household number
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{person} other{people}}'**
  String peopleUnit(int count);

  /// Setup step 3 question
  ///
  /// In en, this message translates to:
  /// **'How much do you spend on food?'**
  String get setupBudgetTitle;

  /// Setup step 3 hint
  ///
  /// In en, this message translates to:
  /// **'We\'ll suggest meals that fit it.'**
  String get setupBudgetSubtitle;

  /// Budget field label
  ///
  /// In en, this message translates to:
  /// **'Amount in FCFA'**
  String get setupBudgetAmountLabel;

  /// Budget missing or out of range
  ///
  /// In en, this message translates to:
  /// **'Enter an amount between 1 and 10 000 000 FCFA'**
  String get setupBudgetInvalid;

  /// Budget period chip
  ///
  /// In en, this message translates to:
  /// **'Per day'**
  String get budgetPerDay;

  /// Budget period chip
  ///
  /// In en, this message translates to:
  /// **'Per week'**
  String get budgetPerWeek;

  /// Budget period chip
  ///
  /// In en, this message translates to:
  /// **'Per month'**
  String get budgetPerMonth;

  /// Advice, never a block, when a daily budget is below the suggestion
  ///
  /// In en, this message translates to:
  /// **'For {count, plural, =1{1 person} other{{count} people}}, we suggest at least {amount} per day so we can find enough good meals. You can keep your amount — we\'ll do our best with it.'**
  String setupBudgetAdviceDaily(int count, String amount);

  /// Advice, never a block, when a weekly budget is below the suggestion
  ///
  /// In en, this message translates to:
  /// **'For {count, plural, =1{1 person} other{{count} people}}, we suggest at least {amount} per week so we can find enough good meals. You can keep your amount — we\'ll do our best with it.'**
  String setupBudgetAdviceWeekly(int count, String amount);

  /// Advice, never a block, when a monthly budget is below the suggestion
  ///
  /// In en, this message translates to:
  /// **'For {count, plural, =1{1 person} other{{count} people}}, we suggest at least {amount} per month so we can find enough good meals. You can keep your amount — we\'ll do our best with it.'**
  String setupBudgetAdviceMonthly(int count, String amount);

  /// Setup step 4 question
  ///
  /// In en, this message translates to:
  /// **'How do you like to cook?'**
  String get setupCookingTitle;

  /// Cooking skill answer
  ///
  /// In en, this message translates to:
  /// **'I\'m still learning'**
  String get cookingSkillBeginner;

  /// Cooking skill answer
  ///
  /// In en, this message translates to:
  /// **'I cook often'**
  String get cookingSkillIntermediate;

  /// Cooking skill answer
  ///
  /// In en, this message translates to:
  /// **'I\'m a very good cook'**
  String get cookingSkillAdvanced;

  /// Setup step 4 second question
  ///
  /// In en, this message translates to:
  /// **'How much time can you spend cooking?'**
  String get setupCookTimeQuestion;

  /// Cooking time chip
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String cookTimeMinutes(int minutes);

  /// Cooking time chip
  ///
  /// In en, this message translates to:
  /// **'1 h'**
  String get cookTimeOneHour;

  /// Cooking time chip
  ///
  /// In en, this message translates to:
  /// **'1 h 30'**
  String get cookTimeOneHourThirty;

  /// Cooking time chip
  ///
  /// In en, this message translates to:
  /// **'2 h'**
  String get cookTimeTwoHours;

  /// Setup step 5 question
  ///
  /// In en, this message translates to:
  /// **'What kinds of food do you like?'**
  String get setupCuisinesTitle;

  /// Setup step 5 hint
  ///
  /// In en, this message translates to:
  /// **'Tap once if you like it, twice if you don\'t. You can skip this.'**
  String get setupCuisinesSubtitle;

  /// Mark on a liked kind of food
  ///
  /// In en, this message translates to:
  /// **'Like'**
  String get cuisineLike;

  /// Mark on a disliked kind of food
  ///
  /// In en, this message translates to:
  /// **'Don\'t like'**
  String get cuisineDislike;

  /// Kind of food
  ///
  /// In en, this message translates to:
  /// **'Cameroonian food'**
  String get cuisineCameroonian;

  /// Familiar dishes; names stay as people say them
  ///
  /// In en, this message translates to:
  /// **'Ndolé, eru, achu, koki'**
  String get cuisineCameroonianHint;

  /// Kind of food
  ///
  /// In en, this message translates to:
  /// **'West African food'**
  String get cuisineWestAfrican;

  /// Familiar dishes
  ///
  /// In en, this message translates to:
  /// **'Jollof rice, puff-puff'**
  String get cuisineWestAfricanHint;

  /// Kind of food
  ///
  /// In en, this message translates to:
  /// **'Italian food'**
  String get cuisineItalian;

  /// Familiar dishes
  ///
  /// In en, this message translates to:
  /// **'Spaghetti, pasta, pizza'**
  String get cuisineItalianHint;

  /// Kind of food
  ///
  /// In en, this message translates to:
  /// **'French food'**
  String get cuisineFrench;

  /// Familiar dishes
  ///
  /// In en, this message translates to:
  /// **'Omelette, salads, gratin'**
  String get cuisineFrenchHint;

  /// Kind of food
  ///
  /// In en, this message translates to:
  /// **'Indian food'**
  String get cuisineIndian;

  /// Familiar dishes
  ///
  /// In en, this message translates to:
  /// **'Curry, chapati'**
  String get cuisineIndianHint;

  /// Kind of food
  ///
  /// In en, this message translates to:
  /// **'Chinese food'**
  String get cuisineChinese;

  /// Familiar dishes
  ///
  /// In en, this message translates to:
  /// **'Fried rice, noodles'**
  String get cuisineChineseHint;

  /// Setup step 6 title
  ///
  /// In en, this message translates to:
  /// **'Your health information, your choice'**
  String get setupConsentTitle;

  /// Why consent is needed
  ///
  /// In en, this message translates to:
  /// **'Why we ask: knowing your allergies is how we keep every meal we suggest safe for you.'**
  String get setupConsentWhy;

  /// Consent text (owner-approved English, CONSENT_COPY)
  ///
  /// In en, this message translates to:
  /// **'I agree that Smart Meal stores my allergies, diet and health goals to personalise my meals. Only I can see them, and I can delete them anytime.'**
  String get setupConsentText;

  /// Under the consent text
  ///
  /// In en, this message translates to:
  /// **'I agree'**
  String get setupConsentAgree;

  /// Setup step 7 question
  ///
  /// In en, this message translates to:
  /// **'Is there food you don\'t eat?'**
  String get setupDietTitle;

  /// Diet answer: no restriction
  ///
  /// In en, this message translates to:
  /// **'I eat everything'**
  String get dietNone;

  /// Diet answer
  ///
  /// In en, this message translates to:
  /// **'No meat'**
  String get dietVegetarian;

  /// Diet answer hint
  ///
  /// In en, this message translates to:
  /// **'Vegetarian'**
  String get dietVegetarianHint;

  /// Diet answer
  ///
  /// In en, this message translates to:
  /// **'No food from animals'**
  String get dietVegan;

  /// Diet answer hint
  ///
  /// In en, this message translates to:
  /// **'No meat, fish, eggs or milk (vegan)'**
  String get dietVeganHint;

  /// Diet answer
  ///
  /// In en, this message translates to:
  /// **'Fish, but no meat'**
  String get dietPescatarian;

  /// Diet answer
  ///
  /// In en, this message translates to:
  /// **'Halal only'**
  String get dietHalal;

  /// Diet answer
  ///
  /// In en, this message translates to:
  /// **'No wheat flour'**
  String get dietGlutenFree;

  /// Diet answer hint
  ///
  /// In en, this message translates to:
  /// **'No bread, puff-puff or pasta (gluten-free)'**
  String get dietGlutenFreeHint;

  /// Diet answer
  ///
  /// In en, this message translates to:
  /// **'No milk products'**
  String get dietDairyFree;

  /// Diet answer hint
  ///
  /// In en, this message translates to:
  /// **'No milk, cheese or yoghurt'**
  String get dietDairyFreeHint;

  /// Diet answer
  ///
  /// In en, this message translates to:
  /// **'Less starch'**
  String get dietLowCarb;

  /// Diet answer hint
  ///
  /// In en, this message translates to:
  /// **'Less rice, garri, bread and pasta (low-carb)'**
  String get dietLowCarbHint;

  /// Setup step 8 question
  ///
  /// In en, this message translates to:
  /// **'Does any food make you sick?'**
  String get setupAllergiesTitle;

  /// Setup step 8 hint
  ///
  /// In en, this message translates to:
  /// **'Food allergies. We\'ll never suggest a meal that contains these.'**
  String get setupAllergiesSubtitle;

  /// Allergy answer: none
  ///
  /// In en, this message translates to:
  /// **'No, none'**
  String get allergiesNone;

  /// Allergen
  ///
  /// In en, this message translates to:
  /// **'Wheat flour'**
  String get allergenGluten;

  /// Allergen hint
  ///
  /// In en, this message translates to:
  /// **'Bread, puff-puff, pasta, beignets'**
  String get allergenGlutenHint;

  /// Allergen
  ///
  /// In en, this message translates to:
  /// **'Crayfish, prawns, crabs'**
  String get allergenCrustaceans;

  /// Allergen
  ///
  /// In en, this message translates to:
  /// **'Snails, mussels, oysters'**
  String get allergenMolluscs;

  /// Allergen
  ///
  /// In en, this message translates to:
  /// **'Fish'**
  String get allergenFish;

  /// Allergen hint
  ///
  /// In en, this message translates to:
  /// **'Fresh, smoked or dried'**
  String get allergenFishHint;

  /// Allergen
  ///
  /// In en, this message translates to:
  /// **'Eggs'**
  String get allergenEggs;

  /// Allergen
  ///
  /// In en, this message translates to:
  /// **'Milk'**
  String get allergenMilk;

  /// Allergen hint
  ///
  /// In en, this message translates to:
  /// **'And cheese, yoghurt, butter'**
  String get allergenMilkHint;

  /// Allergen
  ///
  /// In en, this message translates to:
  /// **'Groundnuts'**
  String get allergenPeanuts;

  /// Allergen hint
  ///
  /// In en, this message translates to:
  /// **'Peanuts, groundnut paste'**
  String get allergenPeanutsHint;

  /// Allergen
  ///
  /// In en, this message translates to:
  /// **'Cashew, almonds and other nuts'**
  String get allergenTreeNuts;

  /// Allergen
  ///
  /// In en, this message translates to:
  /// **'Soya'**
  String get allergenSoy;

  /// Allergen hint
  ///
  /// In en, this message translates to:
  /// **'Soya beans, soy sauce'**
  String get allergenSoyHint;

  /// Allergen
  ///
  /// In en, this message translates to:
  /// **'Sesame (benne) seeds'**
  String get allergenSesame;

  /// Allergen
  ///
  /// In en, this message translates to:
  /// **'Celery'**
  String get allergenCelery;

  /// Allergen
  ///
  /// In en, this message translates to:
  /// **'Mustard'**
  String get allergenMustard;

  /// Allergen
  ///
  /// In en, this message translates to:
  /// **'Sulphites'**
  String get allergenSulphites;

  /// Allergen hint
  ///
  /// In en, this message translates to:
  /// **'In some wine, dried fruit, vinegar'**
  String get allergenSulphitesHint;

  /// Allergen
  ///
  /// In en, this message translates to:
  /// **'Lupin flour'**
  String get allergenLupin;

  /// Allergen hint
  ///
  /// In en, this message translates to:
  /// **'Rare; in some imported breads'**
  String get allergenLupinHint;

  /// Setup step 9 question
  ///
  /// In en, this message translates to:
  /// **'What should your food help you with?'**
  String get setupGoalsTitle;

  /// Setup step 9 hint
  ///
  /// In en, this message translates to:
  /// **'Optional — choose any.'**
  String get setupGoalsSubtitle;

  /// Health goal
  ///
  /// In en, this message translates to:
  /// **'Lose weight'**
  String get goalLoseWeight;

  /// Health goal
  ///
  /// In en, this message translates to:
  /// **'Keep my weight'**
  String get goalMaintainWeight;

  /// Health goal
  ///
  /// In en, this message translates to:
  /// **'Get stronger'**
  String get goalGainMuscle;

  /// Health goal hint
  ///
  /// In en, this message translates to:
  /// **'Build muscle'**
  String get goalGainMuscleHint;

  /// Health goal
  ///
  /// In en, this message translates to:
  /// **'Eat healthier'**
  String get goalEatHealthier;

  /// Health goal
  ///
  /// In en, this message translates to:
  /// **'Control my blood sugar'**
  String get goalManageBloodSugar;

  /// Health goal hint
  ///
  /// In en, this message translates to:
  /// **'For example, with diabetes'**
  String get goalManageBloodSugarHint;

  /// Processing screen title
  ///
  /// In en, this message translates to:
  /// **'Personalising your meals…'**
  String get setupProcessingTitle;

  /// Processing stage 1
  ///
  /// In en, this message translates to:
  /// **'Saving your preferences'**
  String get setupStageSaving;

  /// Processing stage 2
  ///
  /// In en, this message translates to:
  /// **'Matching recipes to your taste'**
  String get setupStageMatching;

  /// Processing stage 3
  ///
  /// In en, this message translates to:
  /// **'Checking allergies and budget'**
  String get setupStageChecking;

  /// Setup save failed; nothing stored
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t save your answers. Please try again.'**
  String get setupSaveFailed;

  /// Placeholder title of the recipe detail screen until it is built
  ///
  /// In en, this message translates to:
  /// **'Recipe {id}'**
  String recipeDetailsTitle(String id);

  /// Form error: new password empty (sign-up, reset)
  ///
  /// In en, this message translates to:
  /// **'Please enter a password'**
  String get fieldNewPasswordMissing;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
