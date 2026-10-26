import '../domain/setup_vocabulary.dart';

/// What users read for each setup answer: plain words people in Cameroon
/// use every day, with familiar examples (owner, 2026-10-24). The formal
/// term appears only as a hint where it helps. Database values never
/// change with this wording.
typedef ChoiceLabel = ({String label, String? hint});

ChoiceLabel _l(String label, [String? hint]) => (label: label, hint: hint);

ChoiceLabel lifestyleLabel(Lifestyle value) => switch (value) {
  Lifestyle.student => _l('Student', 'School or university'),
  Lifestyle.workingProfessional => _l('Working', 'Job, business or trade'),
  Lifestyle.family => _l('Cooking for my family'),
  Lifestyle.athlete => _l('Sports / very active'),
};

ChoiceLabel cookingSkillLabel(CookingSkill value) => switch (value) {
  CookingSkill.beginner => _l("I'm still learning"),
  CookingSkill.intermediate => _l('I cook often'),
  CookingSkill.advanced => _l("I'm a very good cook"),
};

String budgetPeriodLabel(BudgetPeriod value) => switch (value) {
  BudgetPeriod.daily => 'Per day',
  BudgetPeriod.weekly => 'Per week',
  BudgetPeriod.monthly => 'Per month',
};

String budgetPeriodNoun(BudgetPeriod value) => switch (value) {
  BudgetPeriod.daily => 'day',
  BudgetPeriod.weekly => 'week',
  BudgetPeriod.monthly => 'month',
};

String cookTimeLabel(int minutes) => switch (minutes) {
  60 => '1 h',
  90 => '1 h 30',
  120 => '2 h',
  _ => '$minutes min',
};

ChoiceLabel dietLabel(DietaryTag value) => switch (value) {
  DietaryTag.vegetarian => _l('No meat', 'Vegetarian'),
  DietaryTag.vegan => _l(
    'No food from animals',
    'No meat, fish, eggs or milk (vegan)',
  ),
  DietaryTag.pescatarian => _l('Fish, but no meat'),
  DietaryTag.halal => _l('Halal only'),
  DietaryTag.glutenFree => _l(
    'No wheat flour',
    'No bread, puff-puff or pasta (gluten-free)',
  ),
  DietaryTag.dairyFree => _l('No milk products', 'No milk, cheese or yoghurt'),
  DietaryTag.lowCarb => _l(
    'Less starch',
    'Less rice, garri, bread and pasta (low-carb)',
  ),
};

ChoiceLabel allergenLabel(Allergen value) => switch (value) {
  Allergen.gluten => _l('Wheat flour', 'Bread, puff-puff, pasta, beignets'),
  Allergen.crustaceans => _l('Crayfish, prawns, crabs'),
  Allergen.molluscs => _l('Snails, mussels, oysters'),
  Allergen.fish => _l('Fish', 'Fresh, smoked or dried'),
  Allergen.eggs => _l('Eggs'),
  Allergen.milk => _l('Milk', 'And cheese, yoghurt, butter'),
  Allergen.peanuts => _l('Groundnuts', 'Peanuts, groundnut paste'),
  Allergen.treeNuts => _l('Cashew, almonds and other nuts'),
  Allergen.soy => _l('Soya', 'Soya beans, soy sauce'),
  Allergen.sesame => _l('Sesame (benne) seeds'),
  Allergen.celery => _l('Celery'),
  Allergen.mustard => _l('Mustard'),
  Allergen.sulphites => _l('Sulphites', 'In some wine, dried fruit, vinegar'),
  Allergen.lupin => _l('Lupin flour', 'Rare; in some imported breads'),
};

ChoiceLabel healthGoalLabel(HealthGoal value) => switch (value) {
  HealthGoal.loseWeight => _l('Lose weight'),
  HealthGoal.maintainWeight => _l('Keep my weight'),
  HealthGoal.gainMuscle => _l('Get stronger', 'Build muscle'),
  HealthGoal.eatHealthier => _l('Eat healthier'),
  HealthGoal.manageBloodSugar => _l(
    'Control my blood sugar',
    'For example, with diabetes',
  ),
};

/// Familiar dishes shown under each cuisine (by slug); unknown slugs show
/// the name alone.
const cuisineExamples = {
  'cameroonian': 'Ndolé, eru, achu, koki',
  'west_african': 'Jollof rice, puff-puff',
  'italian': 'Spaghetti, pasta, pizza',
  'french': 'Omelette, salads, gratin',
  'indian': 'Curry, chapati',
  'chinese': 'Fried rice, noodles',
};
