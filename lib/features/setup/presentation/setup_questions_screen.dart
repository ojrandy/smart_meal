import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/formatting/fcfa.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/domain/auth_notifier.dart';
import '../data/setup_repository.dart';
import '../domain/budget_advice.dart';
import '../domain/setup_draft.dart';
import '../domain/setup_notifier.dart';
import '../domain/setup_vocabulary.dart';
import 'setup_labels.dart';
import 'widgets/choice_tile.dart';
import 'widgets/setup_step_layout.dart';

const _lifestyleRoute = '/setup/lifestyle';
const _preferencesRoute = '/setup/preferences';
const _processingRoute = '/setup/processing';
const _chooseOption = 'Please choose an option';
const _consentText =
    'I agree that Smart Meal stores my allergies, diet and health goals to '
    'personalise my meals. Only I can see them, and I can delete them '
    'anytime.';

/// Cuisines for the "kinds of food" step, loaded once per session.
final cuisinesProvider = FutureProvider<List<Cuisine>>(
  (ref) => ref.watch(setupRepositoryProvider).fetchCuisines(),
);

/// The setup questions, one per step (owner, 2026-10-24). One widget serves
/// both routes: `/setup/lifestyle` shows steps 1–4 and
/// `/setup/preferences` steps 5–9; the step itself comes from
/// [setupNotifierProvider].
class SetupQuestionsScreen extends ConsumerStatefulWidget {
  const SetupQuestionsScreen({super.key, required this.lifestyleSection});

  final bool lifestyleSection;

  @override
  ConsumerState<SetupQuestionsScreen> createState() =>
      _SetupQuestionsScreenState();
}

class _SetupQuestionsScreenState extends ConsumerState<SetupQuestionsScreen> {
  late final TextEditingController _budgetController;
  bool _showMissing = false;

  SetupNotifier get _notifier => ref.read(setupNotifierProvider.notifier);

  @override
  void initState() {
    super.initState();
    final amount = ref.read(setupNotifierProvider).draft.budgetAmount;
    _budgetController = TextEditingController(
      text: amount == null ? '' : groupThousands(amount),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _alignStepToRoute());
  }

  @override
  void dispose() {
    _budgetController.dispose();
    super.dispose();
  }

  /// Keeps the shown step inside this route's section, e.g. after the app
  /// restarted (empty draft) or a system back between sections.
  void _alignStepToRoute() {
    if (!mounted) return;
    final state = ref.read(setupNotifierProvider);
    final step = state is SetupEditing ? state.step : SetupStep.goals;
    if (step.isLifestyleSection == widget.lifestyleSection) return;

    if (widget.lifestyleSection) {
      _notifier.show(SetupStep.cooking);
    } else {
      final missing = state.draft.firstIncompleteStep;
      if (missing != null && missing.isLifestyleSection) {
        _notifier.show(missing);
        context.go(_lifestyleRoute);
      } else {
        _notifier.show(SetupStep.cuisines);
      }
    }
  }

  void _continue(SetupStep step) {
    final draft = ref.read(setupNotifierProvider).draft;
    if (!draft.isAnswered(step)) {
      setState(() => _showMissing = true);
      return;
    }
    setState(() => _showMissing = false);
    FocusScope.of(context).unfocus();

    if (step == SetupStep.goals) {
      context.go(_processingRoute);
      return;
    }
    final next = _notifier.next();
    if (next.isLifestyleSection != widget.lifestyleSection) {
      context.go(_preferencesRoute);
    }
  }

  void _back(SetupStep step) {
    setState(() => _showMissing = false);
    final previous = _notifier.back();
    if (previous.isLifestyleSection != widget.lifestyleSection) {
      context.go(_lifestyleRoute);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(setupNotifierProvider);
    final step = state is SetupEditing ? state.step : SetupStep.goals;
    final draft = state.draft;
    final showError = _showMissing && !draft.isAnswered(step);

    final (title, subtitle, body) = switch (step) {
      SetupStep.lifestyle => (
        'What best describes you?',
        null,
        _singleChoice<Lifestyle>(
          Lifestyle.values,
          draft.lifestyle,
          lifestyleLabel,
          (v) => _notifier.edit((d) => d.withLifestyle(v)),
        ),
      ),
      SetupStep.household => (
        'How many people do you cook for?',
        'Count yourself too.',
        _householdCounter(draft.householdSize),
      ),
      SetupStep.budget => (
        'How much do you spend on food?',
        "We'll suggest meals that fit it.",
        _budget(draft),
      ),
      SetupStep.cooking => ('How do you like to cook?', null, _cooking(draft)),
      SetupStep.cuisines => (
        'What kinds of food do you like?',
        "Tap once if you like it, twice if you don't. You can skip this.",
        _cuisines(draft),
      ),
      SetupStep.consent => (
        'Your health information, your choice',
        null,
        _consent(draft),
      ),
      SetupStep.diet => ("Is there food you don't eat?", null, _diet(draft)),
      SetupStep.allergies => (
        'Does any food make you sick?',
        "Food allergies. We'll never suggest a meal that contains these.",
        _allergies(draft),
      ),
      SetupStep.goals => (
        'What should your food help you with?',
        'Optional — choose any.',
        _goals(draft),
      ),
    };

    final continueLabel = switch (step) {
      SetupStep.goals => draft.goals.isEmpty ? 'Skip' : 'Finish',
      _ => 'Continue',
    };
    final isFirst = step == SetupStep.lifestyle;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !isFirst) _back(step);
      },
      child: SetupStepLayout(
        step: step,
        title: title,
        subtitle: subtitle,
        body: body,
        continueLabel: continueLabel,
        onContinue: () => _continue(step),
        onBack: isFirst ? null : () => _back(step),
        topAction: isFirst || step == SetupStep.consent ? _signOut() : null,
        error: showError
            ? (step == SetupStep.budget
                  ? 'Enter an amount between 1 and 10 000 000 FCFA'
                  : _chooseOption)
            : null,
      ),
    );
  }

  // ── Steps ──────────────────────────────────────────────────────────────────

  Widget _singleChoice<T>(
    List<T> values,
    T? selected,
    ChoiceLabel Function(T value) labelOf,
    void Function(T value) onSelect,
  ) {
    return Column(
      children: [
        for (final value in values) ...[
          ChoiceTile(
            label: labelOf(value).label,
            hint: labelOf(value).hint,
            mark: value == selected ? ChoiceMark.selected : ChoiceMark.none,
            onTap: () => onSelect(value),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _householdCounter(int size) {
    Widget roundButton(IconData icon, String tooltip, VoidCallback? onTap) {
      return IconButton.filledTonal(
        onPressed: onTap,
        tooltip: tooltip,
        iconSize: 28,
        style: IconButton.styleFrom(
          minimumSize: const Size(56, 56),
          backgroundColor: AppColors.primaryLight,
          foregroundColor: AppColors.primary,
        ),
        icon: Icon(icon),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        roundButton(
          Icons.remove_rounded,
          'Fewer people',
          size > minHouseholdSize
              ? () => _notifier.edit((d) => d.withHouseholdSize(size - 1))
              : null,
        ),
        SizedBox(
          width: 120,
          child: Semantics(
            liveRegion: true,
            label: size == 1 ? '1 person' : '$size people',
            excludeSemantics: true,
            child: Column(
              children: [
                Text(
                  '$size',
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  size == 1 ? 'person' : 'people',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ),
        roundButton(
          Icons.add_rounded,
          'More people',
          size < maxHouseholdSize
              ? () => _notifier.edit((d) => d.withHouseholdSize(size + 1))
              : null,
        ),
      ],
    );
  }

  Widget _budget(SetupDraft draft) {
    final suggestion = budgetSuggestion(
      amount: draft.budgetAmount,
      period: draft.budgetPeriod,
      householdSize: draft.householdSize,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _budgetController,
          keyboardType: TextInputType.number,
          inputFormatters: const [FcfaInputFormatter()],
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            labelText: 'Amount in FCFA',
            suffixText: 'FCFA',
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          ),
          onChanged: (text) => _notifier.edit(
            (d) =>
                d.withBudget(amount: parseFcfa(text), period: d.budgetPeriod),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final period in BudgetPeriod.values)
              ChoiceChip(
                label: Text(budgetPeriodLabel(period)),
                selected: draft.budgetPeriod == period,
                selectedColor: AppColors.primaryLight,
                onSelected: (_) => _notifier.edit(
                  (d) => d.withBudget(amount: d.budgetAmount, period: period),
                ),
              ),
          ],
        ),
        if (suggestion != null && draft.isBudgetValid) ...[
          const SizedBox(height: 20),
          _BudgetAdviceNote(
            householdSize: draft.householdSize,
            period: draft.budgetPeriod!,
            suggested: suggestion,
          ),
        ],
      ],
    );
  }

  Widget _cooking(SetupDraft draft) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _singleChoice<CookingSkill>(
          CookingSkill.values,
          draft.cookingSkill,
          cookingSkillLabel,
          (v) => _notifier.edit((d) => d.withCookingSkill(v)),
        ),
        const SizedBox(height: 12),
        const Text(
          'How much time can you spend cooking?',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final minutes in cookTimeChoices)
              ChoiceChip(
                label: Text(cookTimeLabel(minutes)),
                selected: draft.maxCookMinutes == minutes,
                selectedColor: AppColors.primaryLight,
                onSelected: (_) =>
                    _notifier.edit((d) => d.withMaxCookMinutes(minutes)),
              ),
          ],
        ),
      ],
    );
  }

  Widget _cuisines(SetupDraft draft) {
    final cuisines = ref.watch(cuisinesProvider);
    return cuisines.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(32),
        child: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      ),
      error: (_, _) => Column(
        children: [
          const Text(
            'No connection. Check your internet and try again.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textPrimary, height: 1.5),
          ),
          TextButton(
            onPressed: () => ref.invalidate(cuisinesProvider),
            child: const Text('Try again'),
          ),
        ],
      ),
      data: (list) => Column(
        children: [
          for (final cuisine in list) ...[
            ChoiceTile(
              label: cuisine.name,
              hint: cuisineExamples[cuisine.slug],
              mark: switch (draft.cuisines[cuisine.slug]) {
                CuisinePreference.like => ChoiceMark.selected,
                CuisinePreference.dislike => ChoiceMark.rejected,
                null => ChoiceMark.none,
              },
              markLabel: switch (draft.cuisines[cuisine.slug]) {
                CuisinePreference.like => 'Like',
                CuisinePreference.dislike => "Don't like",
                null => null,
              },
              onTap: () =>
                  _notifier.edit((d) => d.withCuisineToggled(cuisine.slug)),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }

  Widget _consent(SetupDraft draft) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Why we ask: knowing your allergies is how we keep every meal we '
          'suggest safe for you.',
          style: TextStyle(
            fontSize: 15,
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 20),
        Material(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          child: CheckboxListTile(
            value: draft.consentGiven,
            onChanged: (value) =>
                _notifier.edit((d) => d.withConsent(value ?? false)),
            controlAffinity: ListTileControlAffinity.leading,
            activeColor: AppColors.primary,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              _consentText,
              style: TextStyle(
                fontSize: 15,
                color: AppColors.textPrimary,
                height: 1.5,
              ),
            ),
            subtitle: const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'I agree',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _diet(SetupDraft draft) {
    return Column(
      children: [
        ChoiceTile(
          label: 'I eat everything',
          mark: draft.dietNone ? ChoiceMark.selected : ChoiceMark.none,
          onTap: () => _notifier.edit((d) => d.withDietNone()),
        ),
        const SizedBox(height: 12),
        for (final tag in DietaryTag.values) ...[
          ChoiceTile(
            label: dietLabel(tag).label,
            hint: dietLabel(tag).hint,
            mark: draft.diet.contains(tag)
                ? ChoiceMark.selected
                : ChoiceMark.none,
            onTap: () => _notifier.edit((d) => d.withDietToggled(tag)),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _allergies(SetupDraft draft) {
    return Column(
      children: [
        ChoiceTile(
          label: 'No, none',
          mark: draft.allergiesNone ? ChoiceMark.selected : ChoiceMark.none,
          onTap: () => _notifier.edit((d) => d.withAllergiesNone()),
        ),
        const SizedBox(height: 12),
        for (final allergen in Allergen.values) ...[
          ChoiceTile(
            label: allergenLabel(allergen).label,
            hint: allergenLabel(allergen).hint,
            mark: draft.allergies.contains(allergen)
                ? ChoiceMark.selected
                : ChoiceMark.none,
            onTap: () => _notifier.edit((d) => d.withAllergyToggled(allergen)),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _goals(SetupDraft draft) {
    return Column(
      children: [
        for (final goal in HealthGoal.values) ...[
          ChoiceTile(
            label: healthGoalLabel(goal).label,
            hint: healthGoalLabel(goal).hint,
            mark: draft.goals.contains(goal)
                ? ChoiceMark.selected
                : ChoiceMark.none,
            onTap: () => _notifier.edit((d) => d.withGoalToggled(goal)),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _signOut() {
    return TextButton(
      onPressed: () => ref.read(authNotifierProvider.notifier).signOut(),
      child: const Text(
        'Sign out',
        style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// Friendly advice when the budget is below the suggestion. Never blocks:
/// the app advises, it does not enforce (owner, 2026-10-24).
class _BudgetAdviceNote extends StatelessWidget {
  const _BudgetAdviceNote({
    required this.householdSize,
    required this.period,
    required this.suggested,
  });

  final int householdSize;
  final BudgetPeriod period;
  final int suggested;

  @override
  Widget build(BuildContext context) {
    final people = householdSize == 1 ? '1 person' : '$householdSize people';
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.warning.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.lightbulb_outline_rounded,
              color: AppColors.textPrimary,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'For $people, we suggest at least ${formatFcfa(suggested)} '
                'per ${budgetPeriodNoun(period)} so we can find enough good '
                "meals. You can keep your amount — we'll do our best with it.",
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
