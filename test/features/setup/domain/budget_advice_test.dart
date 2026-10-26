import 'package:flutter_test/flutter_test.dart';
import 'package:smart_meal/features/setup/domain/budget_advice.dart';
import 'package:smart_meal/features/setup/domain/setup_vocabulary.dart';

void main() {
  group('suggestedMinimumBudget', () {
    // Owner figures for one person; each extra person adds 70 %.
    for (final (period, people, expected) in [
      (BudgetPeriod.daily, 1, 1000),
      (BudgetPeriod.weekly, 1, 10000),
      (BudgetPeriod.monthly, 1, 30000),
      (BudgetPeriod.daily, 2, 1700),
      (BudgetPeriod.daily, 4, 3100), // not 3 200: no floating-point drift
      (BudgetPeriod.weekly, 5, 38000),
      (BudgetPeriod.monthly, 3, 72000),
      (BudgetPeriod.daily, 20, 14300),
    ]) {
      test('$people × ${period.name} → $expected', () {
        expect(suggestedMinimumBudget(period, people), expected);
      });
    }

    test('always rises with household size', () {
      for (final period in BudgetPeriod.values) {
        for (var people = 1; people < 20; people++) {
          expect(
            suggestedMinimumBudget(period, people + 1),
            greaterThan(suggestedMinimumBudget(period, people)),
          );
        }
      }
    });

    test('is a whole 100 FCFA', () {
      for (final period in BudgetPeriod.values) {
        for (var people = 1; people <= 20; people++) {
          expect(suggestedMinimumBudget(period, people) % 100, 0);
        }
      }
    });
  });

  group('budgetSuggestion (advice, never a block)', () {
    test('below the suggestion → the suggestion', () {
      expect(
        budgetSuggestion(
          amount: 2000,
          period: BudgetPeriod.daily,
          householdSize: 4,
        ),
        3100,
      );
    });

    test('at or above it → no advice', () {
      expect(
        budgetSuggestion(
          amount: 3100,
          period: BudgetPeriod.daily,
          householdSize: 4,
        ),
        isNull,
      );
      expect(
        budgetSuggestion(
          amount: 50000,
          period: BudgetPeriod.weekly,
          householdSize: 1,
        ),
        isNull,
      );
    });

    test('nothing to compare yet → no advice', () {
      expect(
        budgetSuggestion(
          amount: null,
          period: BudgetPeriod.daily,
          householdSize: 1,
        ),
        isNull,
      );
      expect(
        budgetSuggestion(amount: 500, period: null, householdSize: 1),
        isNull,
      );
    });
  });
}
