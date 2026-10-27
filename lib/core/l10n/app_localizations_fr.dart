// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appName => 'Smart Meal';

  @override
  String get languageSwitchLabel => 'Langue';

  @override
  String get errorNoConnection =>
      'Pas de connexion. Vérifiez votre internet et réessayez.';

  @override
  String get errorGeneric => 'Une erreur s\'est produite. Veuillez réessayer.';

  @override
  String get tryAgain => 'Réessayer';

  @override
  String get signOut => 'Se déconnecter';

  @override
  String get authErrorInvalidCredentials =>
      'E-mail ou mot de passe incorrect. Veuillez réessayer.';

  @override
  String get authErrorEmailExists =>
      'Un compte existe déjà avec cet e-mail. Essayez de vous connecter.';

  @override
  String get authErrorWeakPassword =>
      'Choisissez un mot de passe plus sûr : au moins 8 caractères, avec des majuscules, des minuscules, un chiffre et un symbole.';

  @override
  String get authErrorEmailNotConfirmed =>
      'Veuillez confirmer votre e-mail avant de vous connecter.';

  @override
  String get authErrorTooManyAttempts =>
      'Trop de tentatives. Patientez un moment, puis réessayez.';

  @override
  String get authErrorSignupDisabled =>
      'Les inscriptions sont suspendues pour le moment. Veuillez réessayer plus tard.';

  @override
  String get authErrorEmailAddressInvalid =>
      'Cette adresse e-mail ne peut pas être utilisée. Vérifiez-la et réessayez.';

  @override
  String get authErrorValidationFailed =>
      'Vérifiez vos informations et réessayez.';

  @override
  String get authErrorSamePassword =>
      'Votre nouveau mot de passe doit être différent de l\'actuel.';

  @override
  String get authErrorSessionExpired =>
      'Votre session a expiré. Veuillez vous reconnecter.';

  @override
  String get authErrorUserBanned =>
      'Ce compte ne peut pas se connecter pour le moment.';

  @override
  String get authErrorGoogleSignInFailed =>
      'La connexion avec Google a échoué. Veuillez réessayer.';

  @override
  String get authErrorSignOutFailed =>
      'La déconnexion a échoué. Veuillez réessayer.';

  @override
  String get authErrorAccountDeletionFailed =>
      'Nous n\'avons pas pu supprimer votre compte. Veuillez réessayer.';

  @override
  String get fieldEmailMissing => 'Veuillez saisir votre e-mail';

  @override
  String get fieldEmailInvalid => 'Veuillez saisir un e-mail valide';

  @override
  String get fieldPasswordMissing => 'Veuillez saisir votre mot de passe';

  @override
  String fieldPasswordTooShort(int count) {
    return 'Le mot de passe doit contenir au moins $count caractères';
  }

  @override
  String get fieldPasswordTooLong => 'Le mot de passe est trop long';

  @override
  String get fieldPasswordTooSimple =>
      'Utilisez des majuscules, des minuscules, un chiffre et un symbole';

  @override
  String get fieldConfirmationMissing =>
      'Veuillez confirmer votre mot de passe';

  @override
  String get fieldConfirmationMismatch =>
      'Les mots de passe ne correspondent pas';

  @override
  String get loginTitleLead => 'Bon retour sur';

  @override
  String get loginSubtitle =>
      'Connectez-vous pour recevoir vos\nsuggestions de repas personnalisées ✨';

  @override
  String get emailLabel => 'E-mail';

  @override
  String get emailHint => 'nom@email.com';

  @override
  String get passwordLabel => 'Mot de passe';

  @override
  String get forgotPasswordLink => 'Mot de passe oublié ?';

  @override
  String get signInButton => 'Se connecter ✨';

  @override
  String get orContinueWith => 'ou continuer avec';

  @override
  String get continueWithGoogle => 'Continuer avec Google';

  @override
  String get noAccountPrompt => 'Pas encore de compte ?';

  @override
  String get signUpLink => 'S\'inscrire';

  @override
  String get signupConfirmationSent =>
      'Presque fini ! Nous avons envoyé un lien de confirmation à votre e-mail.';

  @override
  String get signupTitleLead => 'Créez votre';

  @override
  String get signupTitleAccent => 'compte Smart Meal';

  @override
  String get signupSubtitle =>
      'Découvrez des repas personnalisés selon vos goûts ✨';

  @override
  String get confirmPasswordLabel => 'Confirmer le mot de passe';

  @override
  String get createAccountButton => 'Créer mon compte ✨';

  @override
  String get haveAccountPrompt => 'Vous avez déjà un compte ?';

  @override
  String get logInLink => 'Se connecter';

  @override
  String get forgotPasswordTitleLead => 'Mot de passe';

  @override
  String get forgotPasswordTitleAccent => 'oublié ?';

  @override
  String get forgotPasswordSubtitle =>
      'Saisissez l\'e-mail de votre compte et nous vous enverrons un lien pour choisir un nouveau mot de passe.';

  @override
  String get sendResetLinkButton => 'Envoyer le lien';

  @override
  String resendInSeconds(int seconds) {
    return 'Renvoyer dans $seconds s';
  }

  @override
  String get resendLinkButton => 'Renvoyer le lien';

  @override
  String get resetEmailSentNotice =>
      'Si un compte existe avec cet e-mail, nous vous avons envoyé un lien pour réinitialiser votre mot de passe.';

  @override
  String get passwordUpdatedNotice => 'Votre mot de passe a été modifié.';

  @override
  String get resetPasswordTitleLead => 'Choisissez un nouveau';

  @override
  String get resetPasswordTitleAccent => 'mot de passe';

  @override
  String get newPasswordLabel => 'Nouveau mot de passe';

  @override
  String get confirmNewPasswordLabel => 'Confirmer le mot de passe';

  @override
  String get savePasswordButton => 'Enregistrer';

  @override
  String get aiChefHeading => 'VOTRE CHEF IA VOUS PROPOSE';

  @override
  String get seeWhyButton => 'Voir pourquoi';

  @override
  String get showPasswordLabel => 'Afficher le mot de passe';

  @override
  String get hidePasswordLabel => 'Masquer le mot de passe';

  @override
  String get addToFavoritesLabel => 'Ajouter aux favoris';

  @override
  String get removeFromFavoritesLabel => 'Retirer des favoris';

  @override
  String get navHome => 'Accueil';

  @override
  String get navDiscover => 'Découvrir';

  @override
  String get navPlanner => 'Planning';

  @override
  String get navFavorites => 'Favoris';

  @override
  String get navProfile => 'Profil';

  @override
  String get homeWelcome => 'Bienvenue sur Smart Meal';

  @override
  String homeWelcomeName(String name) {
    return 'Bienvenue, $name';
  }

  @override
  String homeSignedInAs(String email) {
    return 'Connecté avec $email';
  }

  @override
  String get homeComingSoon =>
      'Vos repas personnalisés apparaîtront bientôt ici ✨';

  @override
  String get splashTagline => 'Votre compagnon culinaire IA';

  @override
  String get splashByline => 'par OJ Tech';

  @override
  String get onboardingDiscoverTitle => 'Bienvenue sur SmartMeal';

  @override
  String get onboardingDiscoverBody =>
      'Découvrez des repas que vous allez aimer, grâce à des suggestions intelligentes adaptées à vos goûts.';

  @override
  String get onboardingPlanTitle => 'Planifiez vos repas';

  @override
  String get onboardingPlanBody =>
      'Gérez votre budget et préparez les repas de la semaine facilement, avec un suivi intelligent.';

  @override
  String get onboardingDecideTitle => 'Mieux choisir ce que vous mangez';

  @override
  String get onboardingDecideBody =>
      'Recevez des suggestions et des conseils personnalisés pour manger plus sainement.';

  @override
  String get getStartedButton => 'Commencer';

  @override
  String get nextButton => 'Suivant';

  @override
  String get skipButton => 'Passer';

  @override
  String get authLinkErrorNotice =>
      'Ce lien n\'est pas valide ou a expiré. Veuillez en demander un nouveau.';

  @override
  String get setupLoadingMessage => 'Préparation en cours…';

  @override
  String setupStepCounter(int number, int total) {
    return 'Étape $number sur $total';
  }

  @override
  String get setupProgressLabel => 'Progression';

  @override
  String get setupChooseOption => 'Veuillez choisir une option';

  @override
  String get continueButton => 'Continuer';

  @override
  String get finishButton => 'Terminer';

  @override
  String get setupLifestyleTitle => 'Qu\'est-ce qui vous décrit le mieux ?';

  @override
  String get lifestyleStudent => 'Élève ou étudiant';

  @override
  String get lifestyleStudentHint => 'Collège, lycée ou université';

  @override
  String get lifestyleWorking => 'Je travaille';

  @override
  String get lifestyleWorkingHint => 'Emploi, commerce ou petit métier';

  @override
  String get lifestyleFamily => 'Je cuisine pour ma famille';

  @override
  String get lifestyleAthlete => 'Sport / très actif';

  @override
  String get setupHouseholdTitle => 'Pour combien de personnes cuisinez-vous ?';

  @override
  String get setupHouseholdSubtitle => 'Comptez-vous aussi.';

  @override
  String get setupHouseholdFewer => 'Moins de personnes';

  @override
  String get setupHouseholdMore => 'Plus de personnes';

  @override
  String peopleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count personnes',
      one: '1 personne',
    );
    return '$_temp0';
  }

  @override
  String peopleUnit(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'personnes',
      one: 'personne',
    );
    return '$_temp0';
  }

  @override
  String get setupBudgetTitle => 'Combien dépensez-vous pour la nourriture ?';

  @override
  String get setupBudgetSubtitle =>
      'Nous vous proposerons des repas adaptés à ce budget.';

  @override
  String get setupBudgetAmountLabel => 'Montant en FCFA';

  @override
  String get setupBudgetInvalid =>
      'Saisissez un montant entre 1 et 10 000 000 FCFA';

  @override
  String get budgetPerDay => 'Par jour';

  @override
  String get budgetPerWeek => 'Par semaine';

  @override
  String get budgetPerMonth => 'Par mois';

  @override
  String setupBudgetAdviceDaily(int count, String amount) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count personnes',
      one: '1 personne',
    );
    return 'Pour $_temp0, nous conseillons au moins $amount par jour pour trouver assez de bons repas. Vous pouvez garder votre montant — nous ferons de notre mieux avec.';
  }

  @override
  String setupBudgetAdviceWeekly(int count, String amount) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count personnes',
      one: '1 personne',
    );
    return 'Pour $_temp0, nous conseillons au moins $amount par semaine pour trouver assez de bons repas. Vous pouvez garder votre montant — nous ferons de notre mieux avec.';
  }

  @override
  String setupBudgetAdviceMonthly(int count, String amount) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count personnes',
      one: '1 personne',
    );
    return 'Pour $_temp0, nous conseillons au moins $amount par mois pour trouver assez de bons repas. Vous pouvez garder votre montant — nous ferons de notre mieux avec.';
  }

  @override
  String get setupCookingTitle => 'Comment aimez-vous cuisiner ?';

  @override
  String get cookingSkillBeginner => 'J\'apprends encore';

  @override
  String get cookingSkillIntermediate => 'Je cuisine souvent';

  @override
  String get cookingSkillAdvanced => 'Je cuisine très bien';

  @override
  String get setupCookTimeQuestion =>
      'Combien de temps pouvez-vous passer à cuisiner ?';

  @override
  String cookTimeMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String get cookTimeOneHour => '1 h';

  @override
  String get cookTimeOneHourThirty => '1 h 30';

  @override
  String get cookTimeTwoHours => '2 h';

  @override
  String get setupCuisinesTitle => 'Quels plats aimez-vous ?';

  @override
  String get setupCuisinesSubtitle =>
      'Touchez une fois si vous aimez, deux fois si vous n\'aimez pas. Vous pouvez passer cette étape.';

  @override
  String get cuisineLike => 'J\'aime';

  @override
  String get cuisineDislike => 'Je n\'aime pas';

  @override
  String get cuisineCameroonian => 'Plats camerounais';

  @override
  String get cuisineCameroonianHint => 'Ndolé, eru, achu, koki';

  @override
  String get cuisineWestAfrican => 'Plats d\'Afrique de l\'Ouest';

  @override
  String get cuisineWestAfricanHint => 'Riz jollof, beignets';

  @override
  String get cuisineItalian => 'Plats italiens';

  @override
  String get cuisineItalianHint => 'Spaghetti, pâtes, pizza';

  @override
  String get cuisineFrench => 'Plats français';

  @override
  String get cuisineFrenchHint => 'Omelette, salades, gratin';

  @override
  String get cuisineIndian => 'Plats indiens';

  @override
  String get cuisineIndianHint => 'Curry, chapati';

  @override
  String get cuisineChinese => 'Plats chinois';

  @override
  String get cuisineChineseHint => 'Riz sauté, nouilles';

  @override
  String get setupConsentTitle => 'Vos informations de santé, votre choix';

  @override
  String get setupConsentWhy =>
      'Pourquoi nous demandons : connaître vos allergies nous permet de vous proposer uniquement des repas sans danger pour vous.';

  @override
  String get setupConsentText =>
      'J\'accepte que Smart Meal enregistre mes allergies, mon régime et mes objectifs de santé pour personnaliser mes repas. Je suis seul(e) à pouvoir les voir, et je peux les supprimer à tout moment.';

  @override
  String get setupConsentAgree => 'J\'accepte';

  @override
  String get setupDietTitle => 'Y a-t-il des aliments que vous ne mangez pas ?';

  @override
  String get dietNone => 'Je mange de tout';

  @override
  String get dietVegetarian => 'Pas de viande';

  @override
  String get dietVegetarianHint => 'Végétarien';

  @override
  String get dietVegan => 'Aucun produit animal';

  @override
  String get dietVeganHint => 'Ni viande, ni poisson, ni œufs, ni lait (végan)';

  @override
  String get dietPescatarian => 'Du poisson, mais pas de viande';

  @override
  String get dietHalal => 'Halal uniquement';

  @override
  String get dietGlutenFree => 'Pas de farine de blé';

  @override
  String get dietGlutenFreeHint =>
      'Ni pain, ni beignets, ni pâtes (sans gluten)';

  @override
  String get dietDairyFree => 'Pas de produits laitiers';

  @override
  String get dietDairyFreeHint => 'Ni lait, ni fromage, ni yaourt';

  @override
  String get dietLowCarb => 'Moins de féculents';

  @override
  String get dietLowCarbHint => 'Moins de riz, de gari, de pain et de pâtes';

  @override
  String get setupAllergiesTitle => 'Un aliment vous rend-il malade ?';

  @override
  String get setupAllergiesSubtitle =>
      'Allergies alimentaires. Nous ne vous proposerons jamais un repas qui en contient.';

  @override
  String get allergiesNone => 'Non, aucun';

  @override
  String get allergenGluten => 'Farine de blé';

  @override
  String get allergenGlutenHint => 'Pain, beignets, pâtes';

  @override
  String get allergenCrustaceans => 'Écrevisses, crevettes, crabes';

  @override
  String get allergenMolluscs => 'Escargots, moules, huîtres';

  @override
  String get allergenFish => 'Poisson';

  @override
  String get allergenFishHint => 'Frais, fumé ou séché';

  @override
  String get allergenEggs => 'Œufs';

  @override
  String get allergenMilk => 'Lait';

  @override
  String get allergenMilkHint => 'Et fromage, yaourt, beurre';

  @override
  String get allergenPeanuts => 'Arachides';

  @override
  String get allergenPeanutsHint => 'Cacahuètes, pâte d\'arachide';

  @override
  String get allergenTreeNuts => 'Noix de cajou, amandes et autres noix';

  @override
  String get allergenSoy => 'Soja';

  @override
  String get allergenSoyHint => 'Graines de soja, sauce soja';

  @override
  String get allergenSesame => 'Graines de sésame';

  @override
  String get allergenCelery => 'Céleri';

  @override
  String get allergenMustard => 'Moutarde';

  @override
  String get allergenSulphites => 'Sulfites';

  @override
  String get allergenSulphitesHint =>
      'Dans certains vins, fruits secs, vinaigres';

  @override
  String get allergenLupin => 'Farine de lupin';

  @override
  String get allergenLupinHint => 'Rare ; dans certains pains importés';

  @override
  String get setupGoalsTitle =>
      'En quoi votre alimentation doit-elle vous aider ?';

  @override
  String get setupGoalsSubtitle => 'Facultatif — choisissez librement.';

  @override
  String get goalLoseWeight => 'Perdre du poids';

  @override
  String get goalMaintainWeight => 'Garder mon poids';

  @override
  String get goalGainMuscle => 'Devenir plus fort';

  @override
  String get goalGainMuscleHint => 'Prendre du muscle';

  @override
  String get goalEatHealthier => 'Manger plus sainement';

  @override
  String get goalManageBloodSugar => 'Contrôler mon taux de sucre';

  @override
  String get goalManageBloodSugarHint => 'Par exemple, en cas de diabète';

  @override
  String get setupProcessingTitle => 'Nous personnalisons vos repas…';

  @override
  String get setupStageSaving => 'Enregistrement de vos préférences';

  @override
  String get setupStageMatching => 'Recherche de recettes à votre goût';

  @override
  String get setupStageChecking => 'Vérification des allergies et du budget';

  @override
  String get setupSaveFailed =>
      'Nous n\'avons pas pu enregistrer vos réponses. Veuillez réessayer.';

  @override
  String recipeDetailsTitle(String id) {
    return 'Recette $id';
  }

  @override
  String get fieldNewPasswordMissing => 'Veuillez saisir un mot de passe';
}
