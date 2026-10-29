-- Food catalog (LF01): unit/conversion rules, the publishing guard
-- (linked lines, active foods, allergens), cost and nutrition views against
-- hand-calculated values, unknown nutrients staying unknown, and access.
begin;
create extension if not exists pgtap with schema extensions;
select plan(44);

-- Run the deferred publishing checks at the end of each statement, so each
-- refusal can be asserted on its own.
set constraints all immediate;

-- ── Unit and conversion rules ───────────────────────────────────────────────

create temp table base on commit drop as
select 'test'::text as name_fr, 'other'::public.ingredient_category as category,
       date '2026-10-29' as price_updated_at, 'test'::text as price_source,
       'test'::text as nutrient_source;

select throws_ok($$insert into public.ingredients (slug, name_en, name_fr, category, pricing_unit, price_updated_at, price_source, nutrient_source)
  select 't-piece', 'x', name_fr, category, 'piece', price_updated_at, price_source, nutrient_source from base$$,
  '23514', null, 'a food sold by the piece needs grams per piece');
select throws_ok($$insert into public.ingredients (slug, name_en, name_fr, category, pricing_unit, price_updated_at, price_source, nutrient_source)
  select 't-litre', 'x', name_fr, category, 'litre', price_updated_at, price_source, nutrient_source from base$$,
  '23514', null, 'a food sold by the litre needs a density');
select throws_ok($$insert into public.ingredients (slug, name_en, name_fr, category, pricing_unit, density_g_per_ml, price_updated_at, price_source, nutrient_source)
  select 't-kg-density', 'x', name_fr, category, 'kg', 0.9, price_updated_at, price_source, nutrient_source from base$$,
  '23514', null, 'only litre foods carry a density');
select lives_ok($$insert into public.ingredients (slug, name_en, name_fr, category, pricing_unit, grams_per_piece, price_updated_at, price_source, nutrient_source)
  select 't-kg-grams', 'x', name_fr, category, 'kg', 250, price_updated_at, price_source, nutrient_source from base$$,
  'a kg food may carry grams per piece');
select throws_ok($$insert into public.ingredients (slug, name_en, name_fr, category, pricing_unit, is_active, price_updated_at, price_source, nutrient_source)
  select 't-active', 'x', name_fr, category, 'kg', true, price_updated_at, price_source, nutrient_source from base$$,
  '23514', null, 'an active food needs a price');
select throws_ok($$insert into public.ingredients (slug, name_en, name_fr, category, pricing_unit, price_xaf, price_low_xaf, price_high_xaf, price_confidence, price_updated_at, price_source, nutrient_source)
  select 't-range', 'x', name_fr, category, 'kg', 900, 100, 500, 'low', price_updated_at, price_source, nutrient_source from base$$,
  '23514', null, 'the price must sit inside its range');
select throws_ok($$insert into public.ingredients (slug, name_en, name_fr, category, pricing_unit, price_xaf, price_updated_at, price_source, nutrient_source)
  select 't-partial', 'x', name_fr, category, 'kg', 900, price_updated_at, price_source, nutrient_source from base$$,
  '23514', null, 'price, range and confidence are set together');
select throws_ok($$insert into public.ingredients (slug, name_en, name_fr, category, pricing_unit, edible_portion, price_updated_at, price_source, nutrient_source)
  select 't-edible', 'x', name_fr, category, 'kg', 1.2, price_updated_at, price_source, nutrient_source from base$$,
  '23514', null, 'edible portion is at most 1');
select throws_ok($$insert into public.ingredients (slug, name_en, name_fr, category, pricing_unit, kcal, price_updated_at, price_source, nutrient_source)
  select 't-kcal', 'x', name_fr, category, 'kg', 901, price_updated_at, price_source, nutrient_source from base$$,
  '23514', null, 'nutrients are bounded (kcal per 100 g)');
select throws_ok($$insert into public.ingredients (slug, name_en, name_fr, category, pricing_unit, fat_g, sat_fat_g, price_updated_at, price_source, nutrient_source)
  select 't-satfat', 'x', name_fr, category, 'kg', 10, 12, price_updated_at, price_source, nutrient_source from base$$,
  '23514', null, 'saturated fat cannot exceed fat');
select throws_ok($$insert into public.ingredients (slug, name_en, name_fr, category, pricing_unit, aliases, price_updated_at, price_source, nutrient_source)
  select 't-aliases', 'x', name_fr, category, 'kg', array['a','b','c','d','e','f','g','h','i','j','k'], price_updated_at, price_source, nutrient_source from base$$,
  '23514', null, 'at most 10 local names');
select throws_ok($$insert into public.ingredients (slug, name_en, name_fr, category, pricing_unit, price_updated_at, price_source, nutrient_source)
  select 'Not A Slug', 'x', name_fr, category, 'kg', price_updated_at, price_source, nutrient_source from base$$,
  '23514', null, 'slugs are lower-case-with-dashes');

-- ── Test foods with round numbers ───────────────────────────────────────────
-- A: kg, 1 000 FCFA, half edible, 100 kcal, sodium 10 mg, carries peanuts.
-- B: litre, 2 000 FCFA, density 0.9, 900 kcal, sodium 0.
-- C: piece of 40 g, 50 FCFA, 150 kcal, sodium UNKNOWN.
-- D: piece of 200 g, 100 FCFA, not eaten (edible 0), no nutrient data.
-- X: inactive, no price.
insert into public.ingredients (
  id, slug, name_en, name_fr, category, pricing_unit, price_xaf, price_low_xaf,
  price_high_xaf, price_confidence, price_updated_at, price_source,
  grams_per_piece, density_g_per_ml, edible_portion, kcal, sodium_mg,
  nutrient_source, allergens, is_active
) values
  ('bbbbbbbb-0000-4000-8000-00000000000a', 't-a', 'A', 'A', 'other', 'kg', 1000, 1000, 1000, 'low', '2026-10-29', 'test', null, null, 0.5, 100, 10, 'test', '{peanuts}', true),
  ('bbbbbbbb-0000-4000-8000-00000000000b', 't-b', 'B', 'B', 'other', 'litre', 2000, 2000, 2000, 'low', '2026-10-29', 'test', null, 0.9, 1, 900, 0, 'test', '{}', true),
  ('bbbbbbbb-0000-4000-8000-00000000000c', 't-c', 'C', 'C', 'other', 'piece', 50, 50, 50, 'low', '2026-10-29', 'test', 40, null, 1, 150, null, 'test', '{}', true),
  ('bbbbbbbb-0000-4000-8000-00000000000d', 't-d', 'D', 'D', 'other', 'piece', 100, 100, 100, 'low', '2026-10-29', 'test', 200, null, 0, null, null, 'test', '{}', true),
  ('bbbbbbbb-0000-4000-8000-0000000000ff', 't-x', 'X', 'X', 'other', 'kg', null, null, null, null, '2026-10-29', 'test', null, null, 1, null, null, 'test', '{}', false);

insert into public.recipes (id, slug, title, cuisine_slug, difficulty, servings, allergens, est_cost_xaf, is_published) values
  ('cccccccc-0000-4000-8000-000000000001', 't-recipe', 'T', 'cameroonian', 'easy', 2, '{}', null, false),
  ('cccccccc-0000-4000-8000-000000000002', 't-empty', 'E', 'cameroonian', 'easy', 2, '{}', 999, false);

select throws_ok($$insert into public.recipe_ingredients (recipe_id, position, name, amount)
  values ('cccccccc-0000-4000-8000-000000000001', 9, 'x', 1)$$,
  '23514', null, 'an amount needs a linked food');

-- ── Publishing guard ────────────────────────────────────────────────────────

select throws_ok($$update public.recipes set is_published = true where slug = 't-empty'$$,
  '23514', null, 'a recipe with no ingredients cannot be published');

insert into public.recipe_ingredients (recipe_id, position, name, quantity, unit, ingredient_id, amount) values
  ('cccccccc-0000-4000-8000-000000000001', 1, 'A', 500, 'g', 'bbbbbbbb-0000-4000-8000-00000000000a', 0.5),
  ('cccccccc-0000-4000-8000-000000000001', 2, 'B', 100, 'ml', 'bbbbbbbb-0000-4000-8000-00000000000b', 0.1),
  ('cccccccc-0000-4000-8000-000000000001', 3, 'C', 3, null, 'bbbbbbbb-0000-4000-8000-00000000000c', 3),
  ('cccccccc-0000-4000-8000-000000000001', 4, 'D', 1, null, 'bbbbbbbb-0000-4000-8000-00000000000d', 1),
  ('cccccccc-0000-4000-8000-000000000001', 5, 'Unlinked', 1, 'tsp', null, null);

select throws_ok($$update public.recipes set is_published = true where slug = 't-recipe'$$,
  '23514', null, 'a measured line without a food blocks publishing');
update public.recipe_ingredients set quantity = null, unit = null
where recipe_id = 'cccccccc-0000-4000-8000-000000000001' and position = 5;
select throws_ok($$update public.recipes set is_published = true where slug = 't-recipe'$$,
  '23514', 'recipe_not_publishable: t-recipe does not list allergens {peanuts}',
  'allergens must cover every food (S11)');
update public.recipes set allergens = '{peanuts}' where slug = 't-recipe';
select lives_ok($$update public.recipes set is_published = true where slug = 't-recipe'$$,
  'a linked recipe listing its allergens can be published; "to taste" lines need no food');

select throws_ok($$insert into public.recipe_ingredients (recipe_id, position, name, quantity, ingredient_id, amount)
  values ('cccccccc-0000-4000-8000-000000000001', 6, 'X', 1, 'bbbbbbbb-0000-4000-8000-0000000000ff', 1)$$,
  '23514', null, 'a published recipe cannot use an inactive food');
select throws_ok($$update public.ingredients set allergens = '{peanuts,milk}' where slug = 't-c'$$,
  '23514', null, 'adding an allergen to a food used by a published recipe is refused');
select throws_ok($$update public.ingredients set price_xaf = null, price_low_xaf = null, price_high_xaf = null, price_confidence = null, is_active = false where slug = 't-c'$$,
  '23514', null, 'deactivating a food used by a published recipe is refused');
select throws_ok($$update public.recipe_ingredients set ingredient_id = null, amount = null where recipe_id = 'cccccccc-0000-4000-8000-000000000001' and position = 1$$,
  '23514', null, 'unlinking a measured line of a published recipe is refused');
select throws_ok($$update public.recipes set allergens = '{}' where slug = 't-recipe'$$,
  '23514', null, 'dropping an allergen from a published recipe is refused');
select throws_ok($$delete from public.ingredients where slug = 't-a'$$,
  '23503', null, 'a food in use cannot be deleted');

-- Default (deferred) mode: a published recipe and its lines in any order,
-- checked at commit (here: when the checks are forced).
set constraints all deferred;
insert into public.recipes (id, slug, title, cuisine_slug, difficulty, servings, allergens, is_published) values
  ('cccccccc-0000-4000-8000-000000000003', 't-deferred', 'D', 'cameroonian', 'easy', 1, '{}', true);
insert into public.recipe_ingredients (recipe_id, position, name, quantity, ingredient_id, amount) values
  ('cccccccc-0000-4000-8000-000000000003', 1, 'B', 1, 'bbbbbbbb-0000-4000-8000-00000000000b', 0.05);
select lives_ok($$set constraints all immediate$$, 'deferred: lines added after a published recipe pass at commit');

-- ── Derived figures, hand-calculated ────────────────────────────────────────
-- t-recipe, 2 servings: cost A 0.5 × 1 000 + B 0.1 × 2 000 + C 3 × 50 + D 1 × 100 = 950.
-- kcal: A 500 g × 0.5 edible × 1.00 + B 90 g × 9.00 + C 120 g × 1.50 + D 0 = 1 240 → 620 / serving.

select is((select cost_xaf from public.recipe_costs where recipe_id = 'cccccccc-0000-4000-8000-000000000001'), 950, 'cost = Σ amount × price');
select is((select cost_per_serving_xaf from public.recipe_costs where recipe_id = 'cccccccc-0000-4000-8000-000000000001'), 475, 'cost per serving');
select is((select cost_source from public.recipe_costs where recipe_id = 'cccccccc-0000-4000-8000-000000000001'), 'catalog', 'cost comes from the catalog');
select is((select cost_source from public.recipe_costs where recipe_id = 'cccccccc-0000-4000-8000-000000000002'), 'estimate', 'a recipe with no catalog lines falls back to est_cost_xaf');
select is((select cost_xaf from public.recipe_costs where recipe_id = 'cccccccc-0000-4000-8000-000000000002'), 999, 'fallback value is the hand-entered estimate');

-- An unlinked "to taste" line makes every nutrient unknown: link it first.
update public.recipe_ingredients set ingredient_id = 'bbbbbbbb-0000-4000-8000-00000000000b', amount = 0.001
where recipe_id = 'cccccccc-0000-4000-8000-000000000001' and position = 5;
-- B 0.001 L = 0.9 g × 9 = 8.1 kcal → (1 240 + 8.1) / 2 = 624.05 → 624.1.
select is((select kcal from public.recipe_nutrition where recipe_id = 'cccccccc-0000-4000-8000-000000000001'), 624.1, 'kcal per serving from edible grams');
select is((select sodium_mg from public.recipe_nutrition where recipe_id = 'cccccccc-0000-4000-8000-000000000001'), null, 'an unknown nutrient makes the total unknown, not 0 (H2)');
select is((select minerals_complete from public.recipe_nutrition where recipe_id = 'cccccccc-0000-4000-8000-000000000001'), false, 'minerals group reported incomplete');
select is((select energy_complete from public.recipe_nutrition where recipe_id = 'cccccccc-0000-4000-8000-000000000001'), true, 'energy group complete; uneaten wrapping counts 0');

update public.ingredients set sodium_mg = 0 where slug = 't-c';
-- Sodium: A 250 g × 10 / 100 = 25 mg → 12.5 / serving.
select is((select sodium_mg from public.recipe_nutrition where recipe_id = 'cccccccc-0000-4000-8000-000000000001'), 12.5, 'once known, the nutrient total appears');

-- ── Seed recipes against the catalog, by hand ───────────────────────────────
-- Koki (6): cowpeas 0.5 × 950 + palm oil 0.15 × 900 + greens 0.2 × 425
--   + pepper 0.1 × 100 + banana leaves 0.6 × 100 (seed placeholder) = 765.
-- kcal: 1 625 + 138 g × 8.98 (1 239.24) + 60.8 + 3.431 + 0 = 2 928.471 / 6.
select is((select cost_xaf from public.recipe_costs c join public.recipes r on r.id = c.recipe_id where r.slug = 'koki'), 765, 'Koki cost from the catalog');
select is((select kcal from public.recipe_nutrition n join public.recipes r on r.id = n.recipe_id where r.slug = 'koki'), 488.1, 'Koki kcal per serving');
-- Jollof (4): rice 0.4 × 500 + tomato 0.4 × 525 + peppers 0.3 × 1 500 (seed
--   placeholder) + onion 0.2 × 900 + water 0.6 × 267 + oil 0.06 × 1 450 = 1 287.2.
-- sodium: 24 + 47.32 + 24.6 + 17.8 + 12 + 0 = 125.72 / 4 = 31.43.
select is((select cost_xaf from public.recipe_costs c join public.recipes r on r.id = c.recipe_id where r.slug = 'vegetable-jollof-rice'), 1287, 'Jollof cost from the catalog');
select is((select sodium_mg from public.recipe_nutrition n join public.recipes r on r.id = n.recipe_id where r.slug = 'vegetable-jollof-rice'), 31.4, 'Jollof sodium per serving');
select is((select count(*) from public.recipes r join public.recipe_costs c on c.recipe_id = r.id where r.slug not like 't-%' and c.cost_source = 'catalog'), 12::bigint, 'every seed recipe is costed from the catalog');

-- ── Access ──────────────────────────────────────────────────────────────────

insert into auth.users (id, email) values ('11111111-1111-4111-8111-111111111111', 'a@test.local');
set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"11111111-1111-4111-8111-111111111111","role":"authenticated"}', true);
select is((select count(*) from public.ingredients where slug = 't-x'), 0::bigint, 'inactive foods are invisible');
select is((select count(*) from public.ingredients where slug = 'rice-imported'), 1::bigint, 'active foods are readable');
select throws_ok($$update public.ingredients set price_xaf = 1$$, '42501', null, 'no client writes to the catalog');
reset role;
set local role anon;
select throws_ok($$select 1 from public.ingredients$$, '42501', null, 'anon cannot read the catalog');
select throws_ok($$select 1 from public.recipe_costs$$, '42501', null, 'anon cannot read recipe costs');
reset role;

select * from finish();
rollback;
