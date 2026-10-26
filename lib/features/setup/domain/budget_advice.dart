import 'setup_vocabulary.dart';

/// Budget advice (owner, 2026-10-24; monthly set to 30 000 on 2026-10-26):
/// the app advises, it never enforces.
/// A budget under the suggestion is still accepted; the user only sees why
/// a bit more would help.
///
/// One configuration place, tuned by the owner:
/// - [suggestedBaseFcfa] is the suggested minimum for one person;
/// - each extra person adds [extraPersonSharePercent] % of it, because
///   cooking for a household costs less per head than cooking alone.
const suggestedBaseFcfa = {
  BudgetPeriod.daily: 1000,
  BudgetPeriod.weekly: 10000,
  BudgetPeriod.monthly: 30000,
};
const extraPersonSharePercent = 70;

/// Suggested minimum for [householdSize] people, rounded up to 100 FCFA.
/// Integer arithmetic only: no floating-point drift in money.
int suggestedMinimumBudget(BudgetPeriod period, int householdSize) {
  final people = householdSize < 1 ? 1 : householdSize;
  final base = suggestedBaseFcfa[period]!;
  final hundredths = base * (100 + extraPersonSharePercent * (people - 1));
  final amount = (hundredths + 99) ~/ 100; // ceil(base × share)
  return ((amount + 99) ~/ 100) * 100; // up to the next 100 FCFA
}

/// The suggested minimum when [amount] is below it, else null.
int? budgetSuggestion({
  required int? amount,
  required BudgetPeriod? period,
  required int householdSize,
}) {
  if (amount == null || period == null) return null;
  final suggested = suggestedMinimumBudget(period, householdSize);
  return amount < suggested ? suggested : null;
}
