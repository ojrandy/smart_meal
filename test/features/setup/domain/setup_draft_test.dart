import 'package:flutter_test/flutter_test.dart';
import 'package:smart_meal/features/setup/domain/setup_draft.dart';
import 'package:smart_meal/features/setup/domain/setup_vocabulary.dart';

import '../../../helpers/setup_fixtures.dart';

void main() {
  test('nine steps, the first four in the lifestyle section', () {
    expect(SetupStep.total, 9);
    expect(SetupStep.values.where((s) => s.isLifestyleSection), [
      SetupStep.lifestyle,
      SetupStep.household,
      SetupStep.budget,
      SetupStep.cooking,
    ]);
  });

  test('an empty draft starts at the first question', () {
    expect(const SetupDraft().firstIncompleteStep, SetupStep.lifestyle);
  });

  test('a complete draft has nothing missing', () {
    expect(completeDraft().firstIncompleteStep, isNull);
  });

  group('required answers', () {
    test('budget needs an amount in range and a period', () {
      const draft = SetupDraft();
      expect(
        draft
            .withBudget(amount: 5000, period: null)
            .isAnswered(SetupStep.budget),
        isFalse,
      );
      expect(
        draft
            .withBudget(amount: 0, period: BudgetPeriod.daily)
            .isAnswered(SetupStep.budget),
        isFalse,
      );
      expect(
        draft
            .withBudget(amount: 10000001, period: BudgetPeriod.daily)
            .isAnswered(SetupStep.budget),
        isFalse,
      );
      expect(
        draft
            .withBudget(amount: 1, period: BudgetPeriod.daily)
            .isAnswered(SetupStep.budget),
        isTrue,
      );
    });

    test('a low budget is still an answer (advice, not a rule)', () {
      final draft = const SetupDraft()
          .withHouseholdSize(6)
          .withBudget(amount: 500, period: BudgetPeriod.daily);
      expect(draft.isAnswered(SetupStep.budget), isTrue);
    });

    test('cooking needs skill and time', () {
      final skillOnly = const SetupDraft().withCookingSkill(
        CookingSkill.beginner,
      );
      expect(skillOnly.isAnswered(SetupStep.cooking), isFalse);
      expect(
        skillOnly.withMaxCookMinutes(30).isAnswered(SetupStep.cooking),
        isTrue,
      );
    });

    test('consent is required', () {
      expect(const SetupDraft().isAnswered(SetupStep.consent), isFalse);
      expect(
        const SetupDraft().withConsent(true).isAnswered(SetupStep.consent),
        isTrue,
      );
    });

    test('cuisines and goals are optional', () {
      expect(const SetupDraft().isAnswered(SetupStep.cuisines), isTrue);
      expect(const SetupDraft().isAnswered(SetupStep.goals), isTrue);
    });
  });

  group('"None" is an answer, not a blank (S6)', () {
    test('allergies: unanswered until None or an allergen is chosen', () {
      expect(const SetupDraft().isAnswered(SetupStep.allergies), isFalse);
      expect(
        const SetupDraft().withAllergiesNone().isAnswered(SetupStep.allergies),
        isTrue,
      );
    });

    test(
      'choosing None clears allergens, choosing an allergen clears None',
      () {
        final withPeanuts = const SetupDraft().withAllergyToggled(
          Allergen.peanuts,
        );
        final none = withPeanuts.withAllergiesNone();
        expect(none.allergies, isEmpty);
        expect(none.allergiesNone, isTrue);

        final fish = none.withAllergyToggled(Allergen.fish);
        expect(fish.allergiesNone, isFalse);
        expect(fish.allergies, {Allergen.fish});
      },
    );

    test('toggling the last allergen off leaves the question unanswered', () {
      final draft = const SetupDraft()
          .withAllergyToggled(Allergen.eggs)
          .withAllergyToggled(Allergen.eggs);
      expect(draft.isAnswered(SetupStep.allergies), isFalse);
    });

    test('diet works the same way', () {
      expect(const SetupDraft().isAnswered(SetupStep.diet), isFalse);
      final halal = const SetupDraft().withDietNone().withDietToggled(
        DietaryTag.halal,
      );
      expect(halal.dietNone, isFalse);
      expect(halal.isAnswered(SetupStep.diet), isTrue);
    });
  });

  test('a cuisine cycles: like → dislike → no opinion', () {
    final liked = const SetupDraft().withCuisineToggled('italian');
    expect(liked.cuisines['italian'], CuisinePreference.like);
    final disliked = liked.withCuisineToggled('italian');
    expect(disliked.cuisines['italian'], CuisinePreference.dislike);
    expect(disliked.withCuisineToggled('italian').cuisines, isEmpty);
  });

  test('household size stays within 1–20', () {
    expect(const SetupDraft().withHouseholdSize(0).householdSize, 1);
    expect(const SetupDraft().withHouseholdSize(25).householdSize, 20);
  });
}
