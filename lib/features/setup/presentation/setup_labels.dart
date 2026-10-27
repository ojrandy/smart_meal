import '../../../core/l10n/l10n.dart';
import '../domain/setup_vocabulary.dart';

/// What users read for each setup answer: plain words people in Cameroon
/// use every day, with familiar examples (owner, 2026-10-24), in English or
/// French. The formal term appears only as a hint where it helps. Database
/// values never change with this wording.
typedef ChoiceLabel = ({String label, String? hint});

ChoiceLabel _l(String label, [String? hint]) => (label: label, hint: hint);

ChoiceLabel lifestyleLabel(AppLocalizations l10n, Lifestyle value) =>
    switch (value) {
      Lifestyle.student => _l(l10n.lifestyleStudent, l10n.lifestyleStudentHint),
      Lifestyle.workingProfessional => _l(
        l10n.lifestyleWorking,
        l10n.lifestyleWorkingHint,
      ),
      Lifestyle.family => _l(l10n.lifestyleFamily),
      Lifestyle.athlete => _l(l10n.lifestyleAthlete),
    };

ChoiceLabel cookingSkillLabel(AppLocalizations l10n, CookingSkill value) =>
    switch (value) {
      CookingSkill.beginner => _l(l10n.cookingSkillBeginner),
      CookingSkill.intermediate => _l(l10n.cookingSkillIntermediate),
      CookingSkill.advanced => _l(l10n.cookingSkillAdvanced),
    };

String budgetPeriodLabel(AppLocalizations l10n, BudgetPeriod value) =>
    switch (value) {
      BudgetPeriod.daily => l10n.budgetPerDay,
      BudgetPeriod.weekly => l10n.budgetPerWeek,
      BudgetPeriod.monthly => l10n.budgetPerMonth,
    };

String cookTimeLabel(AppLocalizations l10n, int minutes) => switch (minutes) {
  60 => l10n.cookTimeOneHour,
  90 => l10n.cookTimeOneHourThirty,
  120 => l10n.cookTimeTwoHours,
  _ => l10n.cookTimeMinutes(minutes),
};

ChoiceLabel dietLabel(AppLocalizations l10n, DietaryTag value) =>
    switch (value) {
      DietaryTag.vegetarian => _l(l10n.dietVegetarian, l10n.dietVegetarianHint),
      DietaryTag.vegan => _l(l10n.dietVegan, l10n.dietVeganHint),
      DietaryTag.pescatarian => _l(l10n.dietPescatarian),
      DietaryTag.halal => _l(l10n.dietHalal),
      DietaryTag.glutenFree => _l(l10n.dietGlutenFree, l10n.dietGlutenFreeHint),
      DietaryTag.dairyFree => _l(l10n.dietDairyFree, l10n.dietDairyFreeHint),
      DietaryTag.lowCarb => _l(l10n.dietLowCarb, l10n.dietLowCarbHint),
    };

ChoiceLabel allergenLabel(AppLocalizations l10n, Allergen value) =>
    switch (value) {
      Allergen.gluten => _l(l10n.allergenGluten, l10n.allergenGlutenHint),
      Allergen.crustaceans => _l(l10n.allergenCrustaceans),
      Allergen.molluscs => _l(l10n.allergenMolluscs),
      Allergen.fish => _l(l10n.allergenFish, l10n.allergenFishHint),
      Allergen.eggs => _l(l10n.allergenEggs),
      Allergen.milk => _l(l10n.allergenMilk, l10n.allergenMilkHint),
      Allergen.peanuts => _l(l10n.allergenPeanuts, l10n.allergenPeanutsHint),
      Allergen.treeNuts => _l(l10n.allergenTreeNuts),
      Allergen.soy => _l(l10n.allergenSoy, l10n.allergenSoyHint),
      Allergen.sesame => _l(l10n.allergenSesame),
      Allergen.celery => _l(l10n.allergenCelery),
      Allergen.mustard => _l(l10n.allergenMustard),
      Allergen.sulphites => _l(
        l10n.allergenSulphites,
        l10n.allergenSulphitesHint,
      ),
      Allergen.lupin => _l(l10n.allergenLupin, l10n.allergenLupinHint),
    };

ChoiceLabel healthGoalLabel(AppLocalizations l10n, HealthGoal value) =>
    switch (value) {
      HealthGoal.loseWeight => _l(l10n.goalLoseWeight),
      HealthGoal.maintainWeight => _l(l10n.goalMaintainWeight),
      HealthGoal.gainMuscle => _l(l10n.goalGainMuscle, l10n.goalGainMuscleHint),
      HealthGoal.eatHealthier => _l(l10n.goalEatHealthier),
      HealthGoal.manageBloodSugar => _l(
        l10n.goalManageBloodSugar,
        l10n.goalManageBloodSugarHint,
      ),
    };

/// A cuisine's name and familiar dishes (by slug). The server's English
/// name is the fallback for a slug the app does not know yet.
ChoiceLabel cuisineLabel(AppLocalizations l10n, String slug, String name) =>
    switch (slug) {
      'cameroonian' => _l(l10n.cuisineCameroonian, l10n.cuisineCameroonianHint),
      'west_african' => _l(
        l10n.cuisineWestAfrican,
        l10n.cuisineWestAfricanHint,
      ),
      'italian' => _l(l10n.cuisineItalian, l10n.cuisineItalianHint),
      'french' => _l(l10n.cuisineFrench, l10n.cuisineFrenchHint),
      'indian' => _l(l10n.cuisineIndian, l10n.cuisineIndianHint),
      'chinese' => _l(l10n.cuisineChinese, l10n.cuisineChineseHint),
      _ => _l(name),
    };
