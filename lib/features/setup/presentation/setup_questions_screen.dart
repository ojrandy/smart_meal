import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/formatting/fcfa.dart';
import '../../../core/l10n/l10n.dart';
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

  /// True during the short pause after the food-likes step (step 5), before
  /// the health questions, so the questionnaire does not feel endless
  /// (owner request, 2026-10-27).
  bool _breather = false;
  static const _breatherHold = Duration(milliseconds: 1800);

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
    if (step == SetupStep.cuisines) {
      unawaited(_pauseThenNext());
      return;
    }
    final next = _notifier.next();
    if (next.isLifestyleSection != widget.lifestyleSection) {
      context.go(_preferencesRoute);
    }
  }

  Future<void> _pauseThenNext() async {
    setState(() => _breather = true);
    await Future<void>.delayed(_breatherHold);
    if (!mounted) return;
    _notifier.next();
    setState(() => _breather = false);
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
    if (_breather) {
      return const PopScope(canPop: false, child: _SetupBreather());
    }
    final state = ref.watch(setupNotifierProvider);
    final step = state is SetupEditing ? state.step : SetupStep.goals;
    final draft = state.draft;
    final showError = _showMissing && !draft.isAnswered(step);
    final l10n = context.l10n;

    final (title, subtitle, body) = switch (step) {
      SetupStep.lifestyle => (
        l10n.setupLifestyleTitle,
        null,
        _singleChoice<Lifestyle>(
          Lifestyle.values,
          draft.lifestyle,
          (v) => lifestyleLabel(l10n, v),
          (v) => _notifier.edit((d) => d.withLifestyle(v)),
        ),
      ),
      SetupStep.household => (
        l10n.setupHouseholdTitle,
        l10n.setupHouseholdSubtitle,
        _householdCounter(l10n, draft.householdSize),
      ),
      SetupStep.budget => (
        l10n.setupBudgetTitle,
        l10n.setupBudgetSubtitle,
        _budget(l10n, draft),
      ),
      SetupStep.cooking => (
        l10n.setupCookingTitle,
        null,
        _cooking(l10n, draft),
      ),
      SetupStep.cuisines => (
        l10n.setupCuisinesTitle,
        l10n.setupCuisinesSubtitle,
        _cuisines(l10n, draft),
      ),
      SetupStep.consent => (
        l10n.setupConsentTitle,
        null,
        _consent(l10n, draft),
      ),
      SetupStep.diet => (l10n.setupDietTitle, null, _diet(l10n, draft)),
      SetupStep.allergies => (
        l10n.setupAllergiesTitle,
        l10n.setupAllergiesSubtitle,
        _allergies(l10n, draft),
      ),
      SetupStep.goals => (
        l10n.setupGoalsTitle,
        l10n.setupGoalsSubtitle,
        _goals(l10n, draft),
      ),
    };

    final continueLabel = switch (step) {
      SetupStep.goals =>
        draft.goals.isEmpty ? l10n.skipButton : l10n.finishButton,
      _ => l10n.continueButton,
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
        topAction: isFirst || step == SetupStep.consent ? _signOut(l10n) : null,
        error: showError
            ? (step == SetupStep.budget
                  ? l10n.setupBudgetInvalid
                  : l10n.setupChooseOption)
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

  Widget _householdCounter(AppLocalizations l10n, int size) {
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
          l10n.setupHouseholdFewer,
          size > minHouseholdSize
              ? () => _notifier.edit((d) => d.withHouseholdSize(size - 1))
              : null,
        ),
        SizedBox(
          width: 120,
          child: Semantics(
            liveRegion: true,
            label: l10n.peopleCount(size),
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
                  l10n.peopleUnit(size),
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ),
        roundButton(
          Icons.add_rounded,
          l10n.setupHouseholdMore,
          size < maxHouseholdSize
              ? () => _notifier.edit((d) => d.withHouseholdSize(size + 1))
              : null,
        ),
      ],
    );
  }

  Widget _budget(AppLocalizations l10n, SetupDraft draft) {
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
            labelText: l10n.setupBudgetAmountLabel,
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
                label: Text(budgetPeriodLabel(l10n, period)),
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

  Widget _cooking(AppLocalizations l10n, SetupDraft draft) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _singleChoice<CookingSkill>(
          CookingSkill.values,
          draft.cookingSkill,
          (v) => cookingSkillLabel(l10n, v),
          (v) => _notifier.edit((d) => d.withCookingSkill(v)),
        ),
        const SizedBox(height: 12),
        Text(
          l10n.setupCookTimeQuestion,
          style: const TextStyle(
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
                label: Text(cookTimeLabel(l10n, minutes)),
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

  Widget _cuisines(AppLocalizations l10n, SetupDraft draft) {
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
          Text(
            l10n.errorNoConnection,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textPrimary, height: 1.5),
          ),
          TextButton(
            onPressed: () => ref.invalidate(cuisinesProvider),
            child: Text(l10n.tryAgain),
          ),
        ],
      ),
      data: (list) => Column(
        children: [
          for (final cuisine in list) ...[
            ChoiceTile(
              label: cuisineLabel(l10n, cuisine.slug, cuisine.name).label,
              hint: cuisineLabel(l10n, cuisine.slug, cuisine.name).hint,
              mark: switch (draft.cuisines[cuisine.slug]) {
                CuisinePreference.like => ChoiceMark.selected,
                CuisinePreference.dislike => ChoiceMark.rejected,
                null => ChoiceMark.none,
              },
              markLabel: switch (draft.cuisines[cuisine.slug]) {
                CuisinePreference.like => l10n.cuisineLike,
                CuisinePreference.dislike => l10n.cuisineDislike,
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

  Widget _consent(AppLocalizations l10n, SetupDraft draft) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.setupConsentWhy,
          style: const TextStyle(
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
            title: Text(
              l10n.setupConsentText,
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.textPrimary,
                height: 1.5,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                l10n.setupConsentAgree,
                style: const TextStyle(
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

  Widget _diet(AppLocalizations l10n, SetupDraft draft) {
    return Column(
      children: [
        ChoiceTile(
          label: l10n.dietNone,
          mark: draft.dietNone ? ChoiceMark.selected : ChoiceMark.none,
          onTap: () => _notifier.edit((d) => d.withDietNone()),
        ),
        const SizedBox(height: 12),
        for (final tag in DietaryTag.values) ...[
          ChoiceTile(
            label: dietLabel(l10n, tag).label,
            hint: dietLabel(l10n, tag).hint,
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

  Widget _allergies(AppLocalizations l10n, SetupDraft draft) {
    return Column(
      children: [
        ChoiceTile(
          label: l10n.allergiesNone,
          mark: draft.allergiesNone ? ChoiceMark.selected : ChoiceMark.none,
          onTap: () => _notifier.edit((d) => d.withAllergiesNone()),
        ),
        const SizedBox(height: 12),
        for (final allergen in Allergen.values) ...[
          ChoiceTile(
            label: allergenLabel(l10n, allergen).label,
            hint: allergenLabel(l10n, allergen).hint,
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

  Widget _goals(AppLocalizations l10n, SetupDraft draft) {
    return Column(
      children: [
        for (final goal in HealthGoal.values) ...[
          ChoiceTile(
            label: healthGoalLabel(l10n, goal).label,
            hint: healthGoalLabel(l10n, goal).hint,
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

  Widget _signOut(AppLocalizations l10n) {
    return TextButton(
      onPressed: () => ref.read(authNotifierProvider.notifier).signOut(),
      child: Text(
        l10n.signOut,
        style: const TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
        ),
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
    final l10n = context.l10n;
    final amount = formatFcfa(suggested);
    final advice = switch (period) {
      BudgetPeriod.daily => l10n.setupBudgetAdviceDaily(householdSize, amount),
      BudgetPeriod.weekly => l10n.setupBudgetAdviceWeekly(
        householdSize,
        amount,
      ),
      BudgetPeriod.monthly => l10n.setupBudgetAdviceMonthly(
        householdSize,
        amount,
      ),
    };
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
                advice,
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

/// The pause after step 5: a spinner around a bowl, a cheer, and what comes
/// next. It moves on by itself after [_SetupQuestionsScreenState._breatherHold].
class _SetupBreather extends StatelessWidget {
  const _SetupBreather();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(
          width: 88,
          height: 88,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox.expand(
                child: CircularProgressIndicator(
                  strokeWidth: 4,
                  color: AppColors.primary,
                  backgroundColor: AppColors.primaryLight,
                ),
              ),
              ExcludeSemantics(
                child: Text(
                  '🍲',
                  textScaler: TextScaler.noScaling,
                  style: TextStyle(fontSize: 34, height: 1),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        Semantics(
          liveRegion: true,
          child: Text(
            l10n.setupBreatherTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          l10n.setupBreatherBody,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 16,
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
      ],
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: reduceMotion
                ? content
                : content
                      .animate()
                      .fadeIn(duration: 350.ms)
                      .scale(
                        begin: const Offset(0.92, 0.92),
                        duration: 450.ms,
                        curve: Curves.easeOutBack,
                      ),
          ),
        ),
      ),
    );
  }
}
