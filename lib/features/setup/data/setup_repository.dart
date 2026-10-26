import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/providers/supabase_provider.dart';
import '../domain/setup_draft.dart';
import '../domain/setup_vocabulary.dart';

/// A cuisine users can like or dislike (reference data).
class Cuisine {
  const Cuisine({required this.slug, required this.name});

  final String slug;
  final String name;
}

/// Reads setup reference data and saves the answers. The Profile screen
/// (T1) reuses [completeSetup] to edit answers later: it replaces them all
/// in one transaction.
class SetupRepository {
  SetupRepository(this._client);

  final SupabaseClient _client;

  Future<List<Cuisine>> fetchCuisines() async {
    final rows = await _client
        .from('cuisines')
        .select('slug, name')
        .order('name');
    return [
      for (final row in rows)
        Cuisine(slug: row['slug'] as String, name: row['name'] as String),
    ];
  }

  /// Saves every answer and marks setup complete, atomically, through the
  /// `complete_setup` RPC (security invoker: RLS applies). Throws on any
  /// failure; nothing is saved then.
  Future<void> completeSetup(SetupDraft draft) async {
    List<String> cuisinesWith(CuisinePreference preference) => [
      for (final entry in draft.cuisines.entries)
        if (entry.value == preference) entry.key,
    ];

    await _client.rpc<dynamic>(
      'complete_setup',
      params: {
        'p_lifestyle': draft.lifestyle!.dbValue,
        'p_household_size': draft.householdSize,
        'p_budget_amount_xaf': draft.budgetAmount,
        'p_budget_period': draft.budgetPeriod!.dbValue,
        'p_cooking_skill': draft.cookingSkill!.dbValue,
        'p_max_cook_minutes': draft.maxCookMinutes,
        'p_cuisine_likes': cuisinesWith(CuisinePreference.like),
        'p_cuisine_dislikes': cuisinesWith(CuisinePreference.dislike),
        'p_sensitive_data_consent': draft.consentGiven,
        'p_dietary_tags': [for (final tag in draft.diet) tag.dbValue],
        'p_allergens': [
          for (final allergen in draft.allergies) allergen.dbValue,
        ],
        'p_health_goals': [for (final goal in draft.goals) goal.dbValue],
      },
    );
  }
}

final setupRepositoryProvider = Provider<SetupRepository>((ref) {
  return SetupRepository(ref.watch(supabaseClientProvider));
});
