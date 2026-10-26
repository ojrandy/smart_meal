/// The closed vocabularies of the setup answers, mirroring the Postgres
/// enums of schema v1 (`context/data-model.md`). [dbValue] is what the
/// database stores; what users read lives in the presentation layer.
library;

enum Lifestyle {
  student('student'),
  workingProfessional('working_professional'),
  family('family'),
  athlete('athlete');

  const Lifestyle(this.dbValue);
  final String dbValue;
}

enum BudgetPeriod {
  daily('daily'),
  weekly('weekly'),
  monthly('monthly');

  const BudgetPeriod(this.dbValue);
  final String dbValue;
}

enum CookingSkill {
  beginner('beginner'),
  intermediate('intermediate'),
  advanced('advanced');

  const CookingSkill(this.dbValue);
  final String dbValue;
}

enum DietaryTag {
  vegetarian('vegetarian'),
  vegan('vegan'),
  pescatarian('pescatarian'),
  halal('halal'),
  glutenFree('gluten_free'),
  dairyFree('dairy_free'),
  lowCarb('low_carb');

  const DietaryTag(this.dbValue);
  final String dbValue;
}

/// One set shared by recipes and users, so the allergy filter is exact
/// (S11). Never remove a value.
enum Allergen {
  gluten('gluten'),
  crustaceans('crustaceans'),
  molluscs('molluscs'),
  fish('fish'),
  eggs('eggs'),
  milk('milk'),
  peanuts('peanuts'),
  treeNuts('tree_nuts'),
  soy('soy'),
  sesame('sesame'),
  celery('celery'),
  mustard('mustard'),
  sulphites('sulphites'),
  lupin('lupin');

  const Allergen(this.dbValue);
  final String dbValue;
}

enum HealthGoal {
  loseWeight('lose_weight'),
  maintainWeight('maintain_weight'),
  gainMuscle('gain_muscle'),
  eatHealthier('eat_healthier'),
  manageBloodSugar('manage_blood_sugar');

  const HealthGoal(this.dbValue);
  final String dbValue;
}

enum CuisinePreference { like, dislike }

/// Cooking-time choices offered in setup, in minutes (5–480 in the DB).
const cookTimeChoices = [15, 30, 45, 60, 90, 120];

/// Bounds mirrored from `complete_setup` and the table constraints.
const minHouseholdSize = 1;
const maxHouseholdSize = 20;
const minBudgetFcfa = 1;
const maxBudgetFcfa = 10000000;
