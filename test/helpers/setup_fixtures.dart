import 'package:smart_meal/features/setup/domain/setup_draft.dart';
import 'package:smart_meal/features/setup/domain/setup_vocabulary.dart';

/// A draft with every required answer (family of 4, peanut allergy).
SetupDraft completeDraft() => const SetupDraft()
    .withLifestyle(Lifestyle.family)
    .withHouseholdSize(4)
    .withBudget(amount: 15000, period: BudgetPeriod.weekly)
    .withCookingSkill(CookingSkill.intermediate)
    .withMaxCookMinutes(60)
    .withConsent(true)
    .withDietNone()
    .withAllergyToggled(Allergen.peanuts);
