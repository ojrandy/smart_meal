import 'setup_vocabulary.dart';

/// The setup questions, in the order users see them (owner, 2026-10-24:
/// one question per step). Consent comes right before the sensitive ones.
enum SetupStep {
  lifestyle,
  household,
  budget,
  cooking,
  cuisines,
  consent,
  diet,
  allergies,
  goals;

  /// Steps 1–4 live on `/setup/lifestyle`, the rest on `/setup/preferences`.
  bool get isLifestyleSection => index <= SetupStep.cooking.index;

  int get number => index + 1;
  static int get total => SetupStep.values.length;
}

/// Answers given so far. Held in memory only, never written to the device:
/// it contains sensitive data (S6). Immutable; edit with the `with…`
/// methods.
class SetupDraft {
  const SetupDraft({
    this.lifestyle,
    this.householdSize = 1,
    this.budgetAmount,
    this.budgetPeriod,
    this.cookingSkill,
    this.maxCookMinutes,
    this.cuisines = const {},
    this.consentGiven = false,
    this.dietNone = false,
    this.diet = const {},
    this.allergiesNone = false,
    this.allergies = const {},
    this.goals = const {},
  });

  final Lifestyle? lifestyle;
  final int householdSize;
  final int? budgetAmount;
  final BudgetPeriod? budgetPeriod;
  final CookingSkill? cookingSkill;
  final int? maxCookMinutes;

  /// Cuisine slug → like or dislike; absent means no opinion.
  final Map<String, CuisinePreference> cuisines;
  final bool consentGiven;

  /// "None" is an answer: [dietNone] and [diet] are mutually exclusive.
  final bool dietNone;
  final Set<DietaryTag> diet;
  final bool allergiesNone;
  final Set<Allergen> allergies;
  final Set<HealthGoal> goals;

  bool get isBudgetValid {
    final amount = budgetAmount;
    return amount != null &&
        amount >= minBudgetFcfa &&
        amount <= maxBudgetFcfa &&
        budgetPeriod != null;
  }

  /// Whether [step] has the answer it needs to move on.
  bool isAnswered(SetupStep step) => switch (step) {
    SetupStep.lifestyle => lifestyle != null,
    SetupStep.household =>
      householdSize >= minHouseholdSize && householdSize <= maxHouseholdSize,
    SetupStep.budget => isBudgetValid,
    SetupStep.cooking => cookingSkill != null && maxCookMinutes != null,
    SetupStep.cuisines => true, // optional
    SetupStep.consent => consentGiven,
    SetupStep.diet => dietNone || diet.isNotEmpty,
    SetupStep.allergies => allergiesNone || allergies.isNotEmpty,
    SetupStep.goals => true, // optional
  };

  /// The first step still missing an answer, or null when all are done.
  SetupStep? get firstIncompleteStep {
    for (final step in SetupStep.values) {
      if (!isAnswered(step)) return step;
    }
    return null;
  }

  SetupDraft withLifestyle(Lifestyle value) => _copy(lifestyle: value);

  SetupDraft withHouseholdSize(int value) =>
      _copy(householdSize: value.clamp(minHouseholdSize, maxHouseholdSize));

  SetupDraft withBudget({
    required int? amount,
    required BudgetPeriod? period,
  }) => _copy(budgetAmount: () => amount, budgetPeriod: () => period);

  SetupDraft withCookingSkill(CookingSkill value) => _copy(cookingSkill: value);

  SetupDraft withMaxCookMinutes(int value) => _copy(maxCookMinutes: value);

  /// Cycles a cuisine: no opinion → like → dislike → no opinion.
  SetupDraft withCuisineToggled(String slug) {
    final next = Map<String, CuisinePreference>.of(cuisines);
    switch (next[slug]) {
      case null:
        next[slug] = CuisinePreference.like;
      case CuisinePreference.like:
        next[slug] = CuisinePreference.dislike;
      case CuisinePreference.dislike:
        next.remove(slug);
    }
    return _copy(cuisines: next);
  }

  SetupDraft withConsent(bool value) => _copy(consentGiven: value);

  SetupDraft withDietNone() => _copy(dietNone: true, diet: const {});

  SetupDraft withDietToggled(DietaryTag tag) {
    final next = Set<DietaryTag>.of(diet);
    if (!next.remove(tag)) next.add(tag);
    return _copy(dietNone: false, diet: next);
  }

  SetupDraft withAllergiesNone() =>
      _copy(allergiesNone: true, allergies: const {});

  SetupDraft withAllergyToggled(Allergen allergen) {
    final next = Set<Allergen>.of(allergies);
    if (!next.remove(allergen)) next.add(allergen);
    return _copy(allergiesNone: false, allergies: next);
  }

  SetupDraft withGoalToggled(HealthGoal goal) {
    final next = Set<HealthGoal>.of(goals);
    if (!next.remove(goal)) next.add(goal);
    return _copy(goals: next);
  }

  SetupDraft _copy({
    Lifestyle? lifestyle,
    int? householdSize,
    int? Function()? budgetAmount,
    BudgetPeriod? Function()? budgetPeriod,
    CookingSkill? cookingSkill,
    int? maxCookMinutes,
    Map<String, CuisinePreference>? cuisines,
    bool? consentGiven,
    bool? dietNone,
    Set<DietaryTag>? diet,
    bool? allergiesNone,
    Set<Allergen>? allergies,
    Set<HealthGoal>? goals,
  }) => SetupDraft(
    lifestyle: lifestyle ?? this.lifestyle,
    householdSize: householdSize ?? this.householdSize,
    budgetAmount: budgetAmount != null ? budgetAmount() : this.budgetAmount,
    budgetPeriod: budgetPeriod != null ? budgetPeriod() : this.budgetPeriod,
    cookingSkill: cookingSkill ?? this.cookingSkill,
    maxCookMinutes: maxCookMinutes ?? this.maxCookMinutes,
    cuisines: cuisines ?? this.cuisines,
    consentGiven: consentGiven ?? this.consentGiven,
    dietNone: dietNone ?? this.dietNone,
    diet: diet ?? this.diet,
    allergiesNone: allergiesNone ?? this.allergiesNone,
    allergies: allergies ?? this.allergies,
    goals: goals ?? this.goals,
  );
}
