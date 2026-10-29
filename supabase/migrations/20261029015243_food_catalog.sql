-- Food catalog (LF01, plan approved by the owner 2026-10-29).
--
-- One canonical list of foods, so recipes, the user's kitchen (LF05),
-- budget estimates and health rules (LF04) all mean the same rice and the
-- same palm oil:
--   * public.ingredients: reference data like cuisines. Price per pricing
--     unit (kg, litre or piece, owner decision D1) and nutrients per 100 g
--     edible portion. A nutrient is null when unknown, never 0 (H2).
--   * recipe_ingredients now point at a food with an amount in its pricing
--     unit. A published recipe must be fully linked to active foods and
--     must declare every allergen of its foods (strengthens S11). The check
--     runs at commit, whichever table changes.
--   * recipe_costs and recipe_nutrition derive cost and nutrients per
--     serving. Both are security-invoker views, so RLS applies.
-- Data: docs/reference/ingredient-*.csv, loaded by the generated block at
-- the end (tool/food_catalog.dart). Method: docs/reference/ingredient-prices-cm.md.

-- ── Vocabularies (closed sets; values may be added, never removed) ───────────

create type public.pricing_unit as enum ('kg', 'litre', 'piece');
-- Also the shelves of My Kitchen (LF05).
create type public.ingredient_category as enum (
  'grains_flours', 'tubers_plantain', 'legumes_nuts_seeds', 'oils_fats',
  'meat_poultry', 'fish_seafood', 'eggs_dairy', 'vegetables_leaves', 'fruits',
  'spices_seasoning', 'other'
);
-- For the health rules (LF04). DRAFT until the medical review signs
-- {{MEDICAL_RULES}}; the tags on each food are drafts too.
create type public.ingredient_flag as enum (
  'organ_meat', 'high_purine', 'processed_meat', 'alcohol',
  'raw_or_undercooked_egg', 'high_mercury_fish', 'bouillon_cube',
  'refined_starch', 'added_sugar', 'deep_fried', 'very_spicy', 'acidic'
);
create type public.price_confidence as enum ('high', 'medium', 'low');

-- ── ingredients (reference data; read-only for clients) ─────────────────────

create table public.ingredients (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique
    check (slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$' and char_length(slug) <= 60),
  name_en text not null check (char_length(name_en) between 1 and 80),
  name_fr text not null check (char_length(name_fr) between 1 and 80),
  -- Local names for search (bobolo, njama njama…): at most 10.
  aliases text[] not null default '{}' check (
    cardinality(aliases) <= 10
    and array_position(aliases, null) is null
    and not ('' = any (aliases))
    and char_length(array_to_string(aliases, '')) <= 400
  ),
  category public.ingredient_category not null,

  -- Estimated market price per pricing unit, whole francs. Null only while
  -- the food is inactive (no reliable price yet).
  pricing_unit public.pricing_unit not null,
  price_xaf integer check (price_xaf between 1 and 1000000),
  price_low_xaf integer check (price_low_xaf between 1 and 1000000),
  price_high_xaf integer check (price_high_xaf between 1 and 1000000),
  price_confidence public.price_confidence,
  -- Newest observation, or the day the list was checked when there is none.
  price_updated_at date not null,
  price_source text not null check (char_length(price_source) between 1 and 1000),

  -- Every amount converts to grams: kg × 1000, litre × 1000 × density,
  -- piece × grams_per_piece (as bought). Kg foods sold by the piece too
  -- (plantain) may carry grams_per_piece for display.
  grams_per_piece numeric(8, 2) check (grams_per_piece > 0 and grams_per_piece <= 100000),
  density_g_per_ml numeric(4, 3) check (density_g_per_ml between 0.5 and 2),
  -- Share of what is bought that is eaten (peel, bone): 0 for wrapping
  -- leaves, 1 for oil.
  edible_portion numeric(4, 3) not null default 1 check (edible_portion between 0 and 1),

  -- Nutrients per 100 g edible portion. Null = unknown, never 0 (H2).
  kcal numeric(6, 2) check (kcal between 0 and 900),
  carbs_g numeric(6, 3) check (carbs_g between 0 and 100),
  sugars_g numeric(6, 3) check (sugars_g between 0 and 100),
  fibre_g numeric(6, 3) check (fibre_g between 0 and 100),
  protein_g numeric(6, 3) check (protein_g between 0 and 100),
  fat_g numeric(6, 3) check (fat_g between 0 and 100),
  sat_fat_g numeric(6, 3) check (sat_fat_g between 0 and 100),
  sodium_mg numeric(8, 2) check (sodium_mg between 0 and 40000),
  potassium_mg numeric(8, 2) check (potassium_mg between 0 and 10000),
  phosphorus_mg numeric(8, 2) check (phosphorus_mg between 0 and 5000),
  iron_mg numeric(6, 3) check (iron_mg between 0 and 200),
  folate_ug numeric(7, 2) check (folate_ug between 0 and 5000),
  -- Which source gave which value (FAO/INFOODS WAFCT 2019 first, USDA
  -- FoodData Central for the gaps), plus their codes for refreshes.
  nutrient_source text not null check (char_length(nutrient_source) between 1 and 1000),
  wafct_code text check (wafct_code ~ '^[0-9]{2}_[0-9]{3}$'),
  fdc_id integer check (fdc_id > 0),

  allergens public.allergen[] not null default '{}'
    check (array_position(allergens, null) is null),
  flags public.ingredient_flag[] not null default '{}'
    check (array_position(flags, null) is null),
  -- Shown in the setup "At home" grid (LF03).
  is_kitchen_staple boolean not null default false,
  is_active boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint price_fields_together check (
    (price_xaf is null) = (price_low_xaf is null)
    and (price_xaf is null) = (price_high_xaf is null)
    and (price_xaf is null) = (price_confidence is null)
  ),
  constraint price_within_range
    check (price_low_xaf <= price_xaf and price_xaf <= price_high_xaf),
  constraint active_needs_price check (not is_active or price_xaf is not null),
  constraint piece_needs_grams check (pricing_unit <> 'piece' or grams_per_piece is not null),
  constraint litre_needs_density check ((pricing_unit = 'litre') = (density_g_per_ml is not null)),
  constraint sat_fat_within_fat check (sat_fat_g <= fat_g)
);
alter table public.ingredients enable row level security;

create trigger ingredients_set_updated_at
  before update on public.ingredients
  for each row execute function private.set_updated_at();

-- Public reference data (docs/SECURITY.md §3), but only for signed-in users
-- and only active rows: an inactive food has no trusted price yet.
grant select on public.ingredients to authenticated;

create policy "ingredients: select active" on public.ingredients
  for select to authenticated
  using (is_active);

-- ── recipe_ingredients → ingredients ────────────────────────────────────────

-- name / quantity / unit stay the display text ("Oil for frying, 1 L");
-- amount is what the recipe consumes, in the food's pricing unit (0.5 kg
-- rice, 0.15 L of frying oil, 2 eggs), for cost and nutrition.
alter table public.recipe_ingredients
  add column ingredient_id uuid references public.ingredients (id),
  add column amount numeric(10, 3) check (amount > 0 and amount <= 1000),
  add constraint amount_needs_ingredient check (amount is null or ingredient_id is not null);
create index recipe_ingredients_ingredient_id_idx
  on public.recipe_ingredients (ingredient_id);

-- ── Publishing guard ────────────────────────────────────────────────────────

-- A published recipe must:
--   1. have at least one ingredient line;
--   2. link every measured line (quantity set) to a food, with an amount;
--   3. use active foods only (no estimate rests on a missing price);
--   4. list every allergen of its foods in recipes.allergens (S11).
-- Deferred to commit, so a recipe and its lines can be written in any
-- order inside one transaction. Fires on all three tables: a later edit of
-- a line or a food can never silently break a published recipe.
create function private.check_recipe_publishable()
returns trigger
language plpgsql
set search_path = ''
as $$
declare
  recipe_ids uuid[];
  rec record;
  missing public.allergen[];
begin
  if tg_table_name = 'recipes' then
    recipe_ids := array[new.id];
  elsif tg_table_name = 'recipe_ingredients' then
    if tg_op = 'INSERT' then
      recipe_ids := array[new.recipe_id];
    elsif tg_op = 'UPDATE' then
      recipe_ids := array[new.recipe_id, old.recipe_id];
    else
      recipe_ids := array[old.recipe_id];
    end if;
  else
    recipe_ids := array(
      select distinct ri.recipe_id from public.recipe_ingredients ri
      where ri.ingredient_id = new.id
    );
  end if;

  for rec in
    select r.id, r.slug, r.allergens from public.recipes r
    where r.id = any (recipe_ids) and r.is_published
  loop
    if not exists (select 1 from public.recipe_ingredients ri where ri.recipe_id = rec.id) then
      raise exception 'recipe_not_publishable: % has no ingredients', rec.slug
        using errcode = '23514';
    end if;
    if exists (
      select 1 from public.recipe_ingredients ri
      where ri.recipe_id = rec.id
        and ri.quantity is not null
        and (ri.ingredient_id is null or ri.amount is null)
    ) then
      raise exception 'recipe_not_publishable: % has a measured line not linked to the catalog', rec.slug
        using errcode = '23514';
    end if;
    if exists (
      select 1 from public.recipe_ingredients ri
      join public.ingredients i on i.id = ri.ingredient_id
      where ri.recipe_id = rec.id and not i.is_active
    ) then
      raise exception 'recipe_not_publishable: % uses an inactive food', rec.slug
        using errcode = '23514';
    end if;
    select array_agg(distinct a order by a) into missing
    from public.recipe_ingredients ri
    join public.ingredients i on i.id = ri.ingredient_id
    cross join lateral unnest(i.allergens) as a
    where ri.recipe_id = rec.id and not (a = any (rec.allergens));
    if missing is not null then
      raise exception 'recipe_not_publishable: % does not list allergens %', rec.slug, missing
        using errcode = '23514';
    end if;
  end loop;
  return null;
end;
$$;
revoke execute on function private.check_recipe_publishable() from public, anon, authenticated;

create constraint trigger recipes_publishable
  after insert or update of is_published, allergens on public.recipes
  deferrable initially deferred
  for each row execute function private.check_recipe_publishable();
create constraint trigger recipe_ingredients_publishable
  after insert or update or delete on public.recipe_ingredients
  deferrable initially deferred
  for each row execute function private.check_recipe_publishable();
-- Deleting a food in use is already refused by the foreign key.
create constraint trigger ingredients_publishable
  after update of is_active, allergens on public.ingredients
  deferrable initially deferred
  for each row execute function private.check_recipe_publishable();

-- ── Derived figures ─────────────────────────────────────────────────────────

-- Cost = Σ amount × price per unit. "To taste" lines with no amount count
-- as free. When any other line has no catalog price, the catalog total is
-- not trusted and the hand-entered recipes.est_cost_xaf is the fallback
-- (legacy rows only; it is dropped once every recipe is catalog-costed).
create view public.recipe_costs
with (security_invoker = true)
as
with lines as (
  select
    ri.recipe_id,
    ri.amount * i.price_xaf as cost_xaf,
    (ri.amount is not null and i.price_xaf is not null)
      or (ri.quantity is null and ri.amount is null) as costed
  from public.recipe_ingredients ri
  left join public.ingredients i on i.id = ri.ingredient_id
),
totals as (
  select recipe_id, bool_and(costed) as complete, sum(cost_xaf) as cost_xaf
  from lines
  group by recipe_id
)
select
  r.id as recipe_id,
  r.servings,
  case
    when t.complete then round(t.cost_xaf)::integer
    else r.est_cost_xaf
  end as cost_xaf,
  case
    when t.complete then round(t.cost_xaf / r.servings)::integer
    else round(r.est_cost_xaf::numeric / r.servings)::integer
  end as cost_per_serving_xaf,
  case
    when t.complete then 'catalog'
    when r.est_cost_xaf is not null then 'estimate'
  end as cost_source
from public.recipes r
left join totals t on t.recipe_id = r.id;

-- Nutrients per serving. A line contributes amount → edible grams ×
-- value / 100. A line with no food, no amount or an unknown value makes
-- that nutrient's total unknown (null), never 0 (H2); food that is not
-- eaten (edible_portion 0) contributes 0.
create view public.recipe_nutrition
with (security_invoker = true)
as
with lines as (
  select
    ri.recipe_id,
    f.per100 as p,
    i.kcal, i.carbs_g, i.sugars_g, i.fibre_g, i.protein_g, i.fat_g,
    i.sat_fat_g, i.sodium_mg, i.potassium_mg, i.phosphorus_mg, i.iron_mg,
    i.folate_ug
  from public.recipe_ingredients ri
  left join public.ingredients i on i.id = ri.ingredient_id
  cross join lateral (
    select ri.amount
      * case i.pricing_unit
          when 'kg' then 1000
          when 'litre' then 1000 * i.density_g_per_ml
          else i.grams_per_piece
        end
      * i.edible_portion / 100 as per100
  ) f
),
contributions as (
  select
    recipe_id,
    case when p = 0 then 0 else p * kcal end as kcal,
    case when p = 0 then 0 else p * carbs_g end as carbs_g,
    case when p = 0 then 0 else p * sugars_g end as sugars_g,
    case when p = 0 then 0 else p * fibre_g end as fibre_g,
    case when p = 0 then 0 else p * protein_g end as protein_g,
    case when p = 0 then 0 else p * fat_g end as fat_g,
    case when p = 0 then 0 else p * sat_fat_g end as sat_fat_g,
    case when p = 0 then 0 else p * sodium_mg end as sodium_mg,
    case when p = 0 then 0 else p * potassium_mg end as potassium_mg,
    case when p = 0 then 0 else p * phosphorus_mg end as phosphorus_mg,
    case when p = 0 then 0 else p * iron_mg end as iron_mg,
    case when p = 0 then 0 else p * folate_ug end as folate_ug
  from lines
),
-- sum() skips nulls; the count comparison makes one unknown line unknown.
totals as (
  select
    recipe_id,
    case when count(*) = count(kcal) then sum(kcal) end as kcal,
    case when count(*) = count(carbs_g) then sum(carbs_g) end as carbs_g,
    case when count(*) = count(sugars_g) then sum(sugars_g) end as sugars_g,
    case when count(*) = count(fibre_g) then sum(fibre_g) end as fibre_g,
    case when count(*) = count(protein_g) then sum(protein_g) end as protein_g,
    case when count(*) = count(fat_g) then sum(fat_g) end as fat_g,
    case when count(*) = count(sat_fat_g) then sum(sat_fat_g) end as sat_fat_g,
    case when count(*) = count(sodium_mg) then sum(sodium_mg) end as sodium_mg,
    case when count(*) = count(potassium_mg) then sum(potassium_mg) end as potassium_mg,
    case when count(*) = count(phosphorus_mg) then sum(phosphorus_mg) end as phosphorus_mg,
    case when count(*) = count(iron_mg) then sum(iron_mg) end as iron_mg,
    case when count(*) = count(folate_ug) then sum(folate_ug) end as folate_ug
  from contributions
  group by recipe_id
)
select
  r.id as recipe_id,
  r.servings,
  round(t.kcal / r.servings, 1) as kcal,
  round(t.carbs_g / r.servings, 2) as carbs_g,
  round(t.sugars_g / r.servings, 2) as sugars_g,
  round(t.fibre_g / r.servings, 2) as fibre_g,
  round(t.protein_g / r.servings, 2) as protein_g,
  round(t.fat_g / r.servings, 2) as fat_g,
  round(t.sat_fat_g / r.servings, 2) as sat_fat_g,
  round(t.sodium_mg / r.servings, 1) as sodium_mg,
  round(t.potassium_mg / r.servings, 1) as potassium_mg,
  round(t.phosphorus_mg / r.servings, 1) as phosphorus_mg,
  round(t.iron_mg / r.servings, 2) as iron_mg,
  round(t.folate_ug / r.servings, 1) as folate_ug,
  t.kcal is not null as energy_complete,
  t.carbs_g is not null and t.sugars_g is not null and t.fibre_g is not null
    and t.protein_g is not null and t.fat_g is not null and t.sat_fat_g is not null
    as macros_complete,
  t.sodium_mg is not null and t.potassium_mg is not null
    and t.phosphorus_mg is not null and t.iron_mg is not null
    as minerals_complete,
  t.folate_ug is not null as folate_complete,
  coalesce(
    t.kcal is not null and t.carbs_g is not null and t.sugars_g is not null
      and t.fibre_g is not null and t.protein_g is not null and t.fat_g is not null
      and t.sat_fat_g is not null and t.sodium_mg is not null
      and t.potassium_mg is not null and t.phosphorus_mg is not null
      and t.iron_mg is not null and t.folate_ug is not null,
    false
  ) as nutrition_complete
from public.recipes r
left join totals t on t.recipe_id = r.id;

grant select on public.recipe_costs, public.recipe_nutrition to authenticated;

-- Belt and braces: nothing new in public for anon.
revoke all on public.ingredients, public.recipe_costs, public.recipe_nutrition from anon;

-- ── Reference data ──────────────────────────────────────────────────────────

-- BEGIN GENERATED: food catalog (tool/food_catalog.dart sql)
-- Do not edit by hand: change docs/reference/*.csv and re-run.
insert into public.ingredients (
  slug, name_en, name_fr, aliases, category, pricing_unit, price_xaf, price_low_xaf, price_high_xaf, price_confidence, price_updated_at, price_source, grams_per_piece, density_g_per_ml, edible_portion, kcal, carbs_g, sugars_g, fibre_g, protein_g, fat_g, sat_fat_g, sodium_mg, potassium_mg, phosphorus_mg, iron_mg, folate_ug, nutrient_source, wafct_code, fdc_id, allergens, flags, is_kitchen_staple, is_active
) values
  ('rice-imported', 'Rice, imported (25 % broken)', 'Riz importé (25 % de brisures)', array['riz', 'rice']::text[], 'grains_flours', 'kg', 500, 450, 550, 'medium', '2026-01-31', 'MINCOMMERCE ceiling 11 Apr 2024: 22 250 FCFA (Douala) / 23 000 FCFA (Yaoundé) per 50 kg sack = 445–460 FCFA/kg; FAO GIEWS country brief (Apr 2026): imported rice prices flat year on year to Jan 2026 under stabilisation measures; per-kg retail 450–550 (infospratiques.cm 2026)', null, null, 1, 351, 78.6, 0.12, 1.9, 6.8, 0.6, 0.15, 6, 87, 179, 1.1, 10, 'FAO/INFOODS WAFCT 2019 01_036: kcal carbs_g fibre_g protein_g fat_g sat_fat_g sodium_mg potassium_mg phosphorus_mg iron_mg folate_ug; USDA FoodData Central SR Legacy 169756: sugars_g', '01_036', 169756, '{}'::public.allergen[], array['refined_starch']::public.ingredient_flag[], true, true),
  ('rice-local', 'Rice, local', 'Riz local', array['riz local', 'local rice']::text[], 'grains_flours', 'kg', 375, 300, 425, 'medium', '2026-08-15', 'WFP/HDX retail, Kumbo + Nkambe (North-West producer markets)', null, null, 1, 344, 75.9, 0.12, 3.6, 7, 0.6, 0.15, 3, 181, 168, 1.9, 16, 'FAO/INFOODS WAFCT 2019 01_037: kcal carbs_g fibre_g protein_g fat_g sat_fat_g sodium_mg potassium_mg phosphorus_mg iron_mg folate_ug; USDA FoodData Central SR Legacy 169756: sugars_g', '01_037', 169756, '{}'::public.allergen[], '{}'::public.ingredient_flag[], false, true),
  ('maize-dry', 'Maize, dry grain', 'Maïs, grain sec', array['corn', 'maïs']::text[], 'grains_flours', 'kg', 250, 225, 300, 'high', '2026-08-15', 'WFP/HDX retail, southern urban markets (white maize)', null, null, 1, 346, 62.6, null, 11.5, 9.7, 3.8, 0.57, 15, 316, 267, 3.3, 71, 'FAO/INFOODS WAFCT 2019 01_004: kcal carbs_g fibre_g protein_g fat_g sat_fat_g sodium_mg potassium_mg phosphorus_mg iron_mg folate_ug', '01_004', 168920, '{}'::public.allergen[], '{}'::public.ingredient_flag[], false, true),
  ('maize-flour', 'Maize flour', 'Farine de maïs', array['corn flour', 'farine de maïs']::text[], 'grains_flours', 'kg', 300, 275, 325, 'low', '2026-08-15', 'WFP/HDX retail, all markets (one southern observation: 268 FCFA, Oct 2025)', null, null, 1, 353, 68.6, 0.64, 7, 8.7, 3.3, 0.5, 4, 197, 153, 3.2, 29, 'FAO/INFOODS WAFCT 2019 01_080: kcal carbs_g fibre_g protein_g fat_g sat_fat_g sodium_mg potassium_mg phosphorus_mg iron_mg folate_ug; USDA FoodData Central SR Legacy 169748: sugars_g', '01_080', 169748, '{}'::public.allergen[], '{}'::public.ingredient_flag[], true, true),
  ('wheat-flour', 'Wheat flour', 'Farine de blé', array['flour', 'farine']::text[], 'grains_flours', 'kg', 475, 450, 500, 'high', '2026-08-15', 'WFP/HDX retail, southern urban markets', null, null, 1, 352, 72.2, 0.27, 2.8, 10.4, 1.8, 0.24, 4, 111, 100, 2, 240, 'FAO/INFOODS WAFCT 2019 01_043: kcal carbs_g fibre_g protein_g fat_g sat_fat_g sodium_mg potassium_mg phosphorus_mg iron_mg folate_ug; USDA FoodData Central SR Legacy 169761: sugars_g', '01_043', 169761, array['gluten']::public.allergen[], array['refined_starch']::public.ingredient_flag[], true, true),
  ('cassava-chips', 'Dried cassava chips (for fufu and couscous)', 'Cossettes de manioc', array['cossettes', 'water fufu']::text[], 'grains_flours', 'kg', 500, 475, 550, 'medium', '2025-12-15', 'WFP/HDX retail, southern urban markets', null, null, 1, 344, 79.3, null, 5.6, 1.7, 0.9, 0.28, 5, 394, 60, 1.4, 44, 'FAO/INFOODS WAFCT 2019 02_002: kcal carbs_g fibre_g protein_g fat_g sat_fat_g sodium_mg potassium_mg phosphorus_mg iron_mg folate_ug', '02_002', null, '{}'::public.allergen[], '{}'::public.ingredient_flag[], false, true),
  ('gari', 'Gari', 'Gari', array['garri']::text[], 'grains_flours', 'kg', 550, 550, 625, 'medium', '2025-12-15', 'WFP/HDX retail, southern urban markets', null, null, 1, 351, 82.9, null, 5, 1.2, 0.5, 0.11, 2, 309, 104, 1.6, 49, 'FAO/INFOODS WAFCT 2019 02_039: kcal carbs_g fibre_g protein_g fat_g sat_fat_g sodium_mg potassium_mg phosphorus_mg iron_mg folate_ug', '02_039', null, '{}'::public.allergen[], '{}'::public.ingredient_flag[], true, true),
  ('pasta-spaghetti', 'Spaghetti, 500 g pack', 'Spaghetti, paquet de 500 g', array['spaghetti', 'macaroni', 'pâtes']::text[], 'grains_flours', 'piece', 500, 500, 500, 'low', '2026-10-29', 'Owner market quote 2026-10-29: 250 FCFA for the small pack, 500 FCFA for the large pack', 500, null, 1, 358, 72.2, 2.67, 3.2, 12.3, 1.5, 0.25, 4, 199, 180, 1.3, 18, 'FAO/INFOODS WAFCT 2019 01_052: kcal carbs_g fibre_g protein_g fat_g sat_fat_g sodium_mg potassium_mg phosphorus_mg iron_mg folate_ug; USDA FoodData Central SR Legacy 168927: sugars_g', '01_052', 168927, array['gluten']::public.allergen[], array['refined_starch']::public.ingredient_flag[], true, true),
  ('cassava-fresh', 'Cassava, fresh', 'Manioc frais', array['manioc', 'cassava']::text[], 'tubers_plantain', 'kg', 150, 100, 200, 'high', '2026-08-15', 'WFP/HDX retail, southern urban markets', null, null, 0.84, 142, 31.6, 1.7, 3.7, 1.3, 0.3, 0.09, 2, 167, 50, 1.5, 24, 'FAO/INFOODS WAFCT 2019 02_001: kcal carbs_g fibre_g protein_g fat_g sat_fat_g sodium_mg potassium_mg phosphorus_mg iron_mg folate_ug; USDA FoodData Central SR Legacy 169985: sugars_g', '02_001', 169985, '{}'::public.allergen[], '{}'::public.ingredient_flag[], false, true),
  ('cocoyam-macabo', 'Cocoyam (macabo)', 'Macabo', array['macabo', 'ibo coco']::text[], 'tubers_plantain', 'kg', 700, 475, 800, 'low', '2026-07-15', 'WFP/HDX retail, southern urban markets', null, null, 0.81, 136, 28.9, null, 2, 3.3, 0.3, 0.08, 9, 531, 59, 0.7, 23, 'FAO/INFOODS WAFCT 2019 02_005: kcal carbs_g fibre_g protein_g fat_g sat_fat_g sodium_mg potassium_mg phosphorus_mg iron_mg folate_ug', '02_005', null, '{}'::public.allergen[], '{}'::public.ingredient_flag[], false, true),
  ('taro', 'Taro (cocoyam for achu)', 'Taro', array['taro', 'achu cocoyam']::text[], 'tubers_plantain', 'kg', 525, 500, 575, 'medium', '2025-12-15', 'WFP/HDX retail, southern urban markets', null, null, 0.86, 127, 25.2, 0.4, 4.1, 2.7, 0.8, 0.19, 17, 350, 88, 1.6, 22, 'FAO/INFOODS WAFCT 2019 02_015: kcal carbs_g fibre_g protein_g fat_g sat_fat_g sodium_mg potassium_mg phosphorus_mg iron_mg folate_ug; USDA FoodData Central SR Legacy 169308: sugars_g', '02_015', 169308, '{}'::public.allergen[], '{}'::public.ingredient_flag[], false, true),
  ('yam', 'Yam', 'Igname', array['igname', 'yam']::text[], 'tubers_plantain', 'kg', 875, 825, 975, 'medium', '2025-12-15', 'WFP/HDX retail, southern urban markets', null, null, 0.83, 126, 25.5, 0.5, 5.6, 2.3, 0.4, 0.1, 7, 383, 53, 1.6, 27, 'FAO/INFOODS WAFCT 2019 02_019: kcal carbs_g fibre_g protein_g fat_g sat_fat_g sodium_mg potassium_mg phosphorus_mg iron_mg folate_ug; USDA FoodData Central SR Legacy 170071: sugars_g', '02_019', 170071, '{}'::public.allergen[], '{}'::public.ingredient_flag[], false, true),
  ('potato-irish', 'Irish potatoes', 'Pommes de terre', array['pomme de terre', 'Irish']::text[], 'tubers_plantain', 'kg', 500, 450, 525, 'medium', '2025-12-15', 'WFP/HDX retail, southern urban markets', null, null, 0.9, 79, 17.4, 0.82, 1.7, 1.5, 0.1, 0.01, 8, 469, 51, 1, 10, 'FAO/INFOODS WAFCT 2019 02_009: kcal carbs_g fibre_g protein_g fat_g sat_fat_g sodium_mg potassium_mg phosphorus_mg iron_mg folate_ug; USDA FoodData Central SR Legacy 170026: sugars_g', '02_009', 170026, '{}'::public.allergen[], '{}'::public.ingredient_flag[], true, true),
  ('sweet-potato', 'Sweet potatoes', 'Patates douces', array['patate', 'sweet potato']::text[], 'tubers_plantain', 'kg', 350, 300, 375, 'low', '2025-12-15', 'WFP/HDX retail, southern urban markets (WFP item "Potatoes")', null, null, 0.83, 96, 20.5, 4.18, 3, 1.5, 0.2, 0.06, 31, 283, 39, 1.3, 26, 'FAO/INFOODS WAFCT 2019 02_022: kcal carbs_g fibre_g protein_g fat_g sat_fat_g sodium_mg potassium_mg phosphorus_mg iron_mg folate_ug; USDA FoodData Central SR Legacy 168482: sugars_g', '02_022', 168482, '{}'::public.allergen[], '{}'::public.ingredient_flag[], false, true),
  ('plantain', 'Plantain (one finger)', 'Plantain (un doigt)', array['plantain', 'banane plantain']::text[], 'tubers_plantain', 'piece', 150, 125, 800, 'medium', '2026-10-29', 'Owner market quote 2026-10-29: a heap of 5–8 fingers from 1 000 FCFA; good big ones about 4 000 FCFA or more', 250, null, 0.61, 143, 32.9, 17.51, 2.3, 1.4, 0.2, 0.09, 4, 499, 27, 1.1, 22, 'FAO/INFOODS WAFCT 2019 02_042: kcal carbs_g fibre_g protein_g fat_g sat_fat_g sodium_mg potassium_mg phosphorus_mg iron_mg folate_ug; USDA FoodData Central SR Legacy 169130: sugars_g', '02_042', 169130, '{}'::public.allergen[], '{}'::public.ingredient_flag[], true, true),
  ('banana', 'Banana (sweet)', 'Banane douce', array['banane', 'banana']::text[], 'fruits', 'kg', 325, 200, 400, 'medium', '2026-08-15', 'WFP/HDX retail, southern urban markets', null, null, 0.62, 121, 27.7, 12.23, 1.9, 1.3, 0.2, 0.07, 2, 329, 23, 0.9, 17, 'FAO/INFOODS WAFCT 2019 05_003: kcal carbs_g fibre_g protein_g fat_g sat_fat_g sodium_mg potassium_mg phosphorus_mg iron_mg folate_ug; USDA FoodData Central SR Legacy 173944: sugars_g', '05_003', 173944, '{}'::public.allergen[], '{}'::public.ingredient_flag[], false, true),
  ('beans-red', 'Red beans', 'Haricots rouges', array['haricot', 'beans']::text[], 'legumes_nuts_seeds', 'kg', 700, 575, 1075, 'high', '2026-08-15', 'WFP/HDX retail, southern urban markets', null, null, 1, 337, 61.29, 2.1, 15.2, 22.53, 1.06, 0.154, 12, 1359, 406, 6.69, 394, 'USDA FoodData Central SR Legacy 173744: kcal carbs_g sugars_g fibre_g protein_g fat_g sat_fat_g sodium_mg potassium_mg phosphorus_mg iron_mg folate_ug', null, 173744, '{}'::public.allergen[], '{}'::public.ingredient_flag[], true, true),
  ('cowpeas', 'Cowpeas (black-eyed beans)', 'Niébé', array['niébé', 'black-eyed beans', 'koki beans']::text[], 'legumes_nuts_seeds', 'kg', 950, 900, 1200, 'medium', '2025-12-15', 'WFP/HDX retail, southern urban markets', null, null, 1, 325, 49, 6.9, 12.6, 22.6, 1.5, 0.36, 22, 1120, 416, 6.2, 420, 'FAO/INFOODS WAFCT 2019 03_004: kcal carbs_g fibre_g protein_g fat_g sat_fat_g sodium_mg potassium_mg phosphorus_mg iron_mg folate_ug; USDA FoodData Central SR Legacy 173758: sugars_g', '03_004', 173758, '{}'::public.allergen[], '{}'::public.ingredient_flag[], false, true),
  ('groundnuts', 'Groundnuts, shelled', 'Arachides décortiquées', array['arachide', 'groundnut', 'peanuts']::text[], 'legumes_nuts_seeds', 'kg', 1200, 1075, 1200, 'medium', '2025-12-15', 'WFP/HDX retail, southern urban markets', null, null, 1, 574, 17.4, 4.72, 8.3, 22.4, 44.2, 8.92, 6, 619, 445, 3.5, 110, 'FAO/INFOODS WAFCT 2019 06_010: kcal carbs_g fibre_g protein_g fat_g sat_fat_g sodium_mg potassium_mg phosphorus_mg iron_mg folate_ug; USDA FoodData Central SR Legacy 172430: sugars_g', '06_010', 172430, array['peanuts']::public.allergen[], '{}'::public.ingredient_flag[], true, true),
  ('egusi', 'Egusi (melon seeds)', 'Pistache (graines de courge)', array['pistache', 'egusi']::text[], 'legumes_nuts_seeds', 'kg', null, null, null, null, '2026-10-29', 'No reliable source (only per-glass prices from an undated list)', null, null, 1, 574, 11.6, null, 6, 27.6, 45, 11.11, 37, 610, 836, 6.3, 58, 'FAO/INFOODS WAFCT 2019 06_013: kcal carbs_g fibre_g protein_g fat_g sat_fat_g sodium_mg potassium_mg phosphorus_mg iron_mg folate_ug', '06_013', 169407, '{}'::public.allergen[], '{}'::public.ingredient_flag[], false, false),
  ('njansang', 'Njansang', 'Njansan', array['djansang', 'njangsang']::text[], 'spices_seasoning', 'kg', null, null, null, null, '2026-10-29', 'No source found', null, null, 1, null, null, null, null, null, null, null, null, null, null, null, null, 'No composition data found', null, null, '{}'::public.allergen[], '{}'::public.ingredient_flag[], false, false),
  ('palm-oil', 'Palm oil', 'Huile de palme', array['huile rouge', 'red oil']::text[], 'oils_fats', 'litre', 900, 800, 1000, 'high', '2026-08-15', 'WFP/HDX retail, southern urban markets (10 markets)', null, 0.92, 1, 898, 0, 0, 0, 0, 99.8, 48.5, 0, 0, 2, 0.2, 0, 'FAO/INFOODS WAFCT 2019 11_004: kcal carbs_g fibre_g protein_g fat_g sat_fat_g sodium_mg potassium_mg phosphorus_mg iron_mg folate_ug; USDA FoodData Central SR Legacy 171015: sugars_g', '11_004', 171015, '{}'::public.allergen[], '{}'::public.ingredient_flag[], true, true),
  ('vegetable-oil', 'Vegetable oil, refined', 'Huile végétale raffinée', array['huile', 'oil']::text[], 'oils_fats', 'litre', 1450, 1350, 1500, 'medium', '2026-05-07', 'MINCOMMERCE homologated 1-litre bottle price 1 500 FCFA; Carrefour Cameroun Oléo 5 L at 6 800 FCFA (= 1 360 FCFA/L, offer to 7 May 2026); WFP/HDX cotton-seed oil, southern markets: 1 500 FCFA/L (Nov 2025)', null, 0.92, 1, 900, 0, 0, 0, 0, 100, 48.6, 0, 0, 0, 0.2, 0, 'FAO/INFOODS WAFCT 2019 11_007: kcal carbs_g fibre_g protein_g fat_g sat_fat_g sodium_mg potassium_mg phosphorus_mg iron_mg folate_ug; USDA FoodData Central SR Legacy 171015: sugars_g', '11_007', 171015, '{}'::public.allergen[], '{}'::public.ingredient_flag[], true, true),
  ('beef-boneless', 'Beef, boneless', 'Viande de bœuf sans os', array['viande', 'beef']::text[], 'meat_poultry', 'kg', 4000, 3800, 4500, 'medium', '2026-05-15', 'Market quotes at Mfoundi: 3 800–4 000 FCFA (237online); DataCameroon 15 May 2026: up at least 500 FCFA in Yaoundé markets; official ceiling 3 000 FCFA (June 2025)', null, null, 1, 239, 0, 0, 0, 18.6, 18.2, 8.51, 91, 290, 164, 1.2, 10, 'FAO/INFOODS WAFCT 2019 07_002: kcal carbs_g fibre_g protein_g fat_g sat_fat_g sodium_mg potassium_mg phosphorus_mg iron_mg folate_ug; USDA FoodData Central SR Legacy 171796: sugars_g', '07_002', 171796, '{}'::public.allergen[], '{}'::public.ingredient_flag[], false, true),
  ('beef-bone-in', 'Beef, with bone', 'Viande de bœuf avec os', array['viande avec os', 'beef with bone']::text[], 'meat_poultry', 'kg', 3000, 2500, 3500, 'low', '2026-05-15', 'Official ceiling 2 500 FCFA (June 2025); reports of market prices above it (no figure)', null, null, 0.8, 239, 0, 0, 0, 18.6, 18.2, 8.51, 91, 290, 164, 1.2, 10, 'FAO/INFOODS WAFCT 2019 07_002: kcal carbs_g fibre_g protein_g fat_g sat_fat_g sodium_mg potassium_mg phosphorus_mg iron_mg folate_ug; USDA FoodData Central SR Legacy 171796: sugars_g', '07_002', 171796, '{}'::public.allergen[], '{}'::public.ingredient_flag[], false, true),
  ('chicken', 'Chicken, whole', 'Poulet entier', array['poulet', 'chicken']::text[], 'meat_poultry', 'kg', 3000, 2800, 3500, 'medium', '2026-09-30', 'Carrefour Cameroun whole chicken 2 790 FCFA/kg (offer to 21 May 2026); combien-coute.net 3 100–3 500 FCFA/kg (Sep 2026, unsourced); IPAVIC farm-gate reference 2 300 FCFA per 1.8–2 kg bird', null, null, 0.68, 232, 0, 0, 0, 16.7, 18.3, 5.4, 73, 178, 136, 1, 7, 'FAO/INFOODS WAFCT 2019 07_030: kcal carbs_g fibre_g protein_g fat_g sat_fat_g sodium_mg potassium_mg phosphorus_mg iron_mg folate_ug; USDA FoodData Central SR Legacy 171447: sugars_g', '07_030', 171447, '{}'::public.allergen[], '{}'::public.ingredient_flag[], false, true),
  ('mackerel-frozen', 'Mackerel, frozen', 'Maquereau congelé', array['maquereau', 'mackerel']::text[], 'fish_seafood', 'kg', 2000, 1600, 2400, 'low', '2026-10-15', 'Retailers: 20 kg carton up from 25 000 to 29 000–32 000 FCFA in Oct 2026 (1 450–1 600 FCFA/kg wholesale) after the Congelcam import quota was halved (KOACI 15 Oct 2026; camerounactuel); DataCameroon: small fish from 1 900 FCFA/kg after the shortage', null, null, 0.71, 120, 0, 0, 0, 19.6, 4.6, 1.97, 130, 360, 221, 1.6, 15, 'FAO/INFOODS WAFCT 2019 09_003: kcal carbs_g fibre_g protein_g fat_g sat_fat_g sodium_mg potassium_mg phosphorus_mg iron_mg folate_ug; USDA FoodData Central SR Legacy 175119: sugars_g', '09_003', 175119, array['fish']::public.allergen[], '{}'::public.ingredient_flag[], false, true),
  ('crayfish-dried', 'Crayfish, dried, small pack', 'Crevettes séchées (crayfish), petit paquet', array['crayfish', 'crevettes séchées']::text[], 'fish_seafood', 'piece', 100, 100, 100, 'low', '2026-10-29', 'Owner market quote 2026-10-29: 100 FCFA for a single pack; Cameroon News Agency (May 2026): 100→200 FCFA cups in Douala', 25, null, 1, 322, 7.9, 0, 0, 63.1, 4.2, 1.83, 1298, 1107, 1332, 25.3, 140, 'FAO/INFOODS WAFCT 2019 09_057: kcal carbs_g fibre_g protein_g fat_g sat_fat_g sodium_mg potassium_mg phosphorus_mg iron_mg folate_ug; USDA FoodData Central SR Legacy 174206: sugars_g', '09_057', 174206, array['crustaceans']::public.allergen[], array['high_purine']::public.ingredient_flag[], true, true),
  ('fish-smoked', 'Fish, smoked (one piece)', 'Poisson fumé (un morceau)', array['poisson fumé', 'smoked fish']::text[], 'fish_seafood', 'piece', 500, 200, 500, 'low', '2026-10-29', 'Owner market quote 2026-10-29: about 200 FCFA for a very small piece, 500 FCFA for a usual piece', 150, null, 1, 316, 0, 0, 0, 60.4, 8.2, 2.97, 147, 707, 1525, 7.4, 46, 'FAO/INFOODS WAFCT 2019 09_053: kcal carbs_g fibre_g protein_g fat_g sat_fat_g sodium_mg potassium_mg phosphorus_mg iron_mg folate_ug; USDA FoodData Central SR Legacy 173712: sugars_g', '09_053', 173712, array['fish']::public.allergen[], array['high_purine']::public.ingredient_flag[], false, true),
  ('stockfish', 'Stockfish', 'Stockfish', array['morue séchée', 'stockfish']::text[], 'fish_seafood', 'kg', null, null, null, null, '2026-10-29', 'No source found', null, null, 1, 316, 0, 0, 0, 60.4, 8.2, 2.97, 147, 707, 1525, 7.4, 46, 'FAO/INFOODS WAFCT 2019 09_053: kcal carbs_g fibre_g protein_g fat_g sat_fat_g sodium_mg potassium_mg phosphorus_mg iron_mg folate_ug; capped at the carbohydrate or fat total: sugars_g', '09_053', null, array['fish']::public.allergen[], array['high_purine']::public.ingredient_flag[], false, false),
  ('eggs', 'Eggs', 'Œufs', array['œufs', 'eggs']::text[], 'eggs_dairy', 'piece', 90, 75, 95, 'medium', '2026-10-28', 'Trays of 30: 2 600 FCFA (Glotelho, Douala, was 2 800); 2 550 FCFA (Carrefour, offer to 14 Aug 2025); 2 200 FCFA (farm eggs, Tchopexpress)', 60, null, 0.87, 150, 0.2, 0.2, 0, 13.5, 10.6, 2.89, 165, 150, 233, 2.2, 83, 'FAO/INFOODS WAFCT 2019 08_001: kcal carbs_g fibre_g protein_g fat_g sat_fat_g sodium_mg potassium_mg phosphorus_mg iron_mg folate_ug; USDA FoodData Central SR Legacy 171287: sugars_g; capped at the carbohydrate or fat total: sugars_g', '08_001', 171287, array['eggs']::public.allergen[], '{}'::public.ingredient_flag[], true, true),
  ('milk-powder', 'Milk powder', 'Lait en poudre', array['lait en poudre', 'powdered milk']::text[], 'eggs_dairy', 'kg', 8750, 8750, 8800, 'medium', '2025-12-15', 'WFP/HDX retail, southern urban markets: 3 500 FCFA per 400 g', null, null, 1, 493, 37.3, 37.3, 0, 25.8, 26.8, 16.7, 380, 1140, 680, 0.8, 37, 'FAO/INFOODS WAFCT 2019 10_002: kcal carbs_g fibre_g protein_g fat_g sat_fat_g sodium_mg potassium_mg phosphorus_mg iron_mg folate_ug; USDA FoodData Central SR Legacy 170876: sugars_g; capped at the carbohydrate or fat total: sugars_g', '10_002', 170876, array['milk']::public.allergen[], '{}'::public.ingredient_flag[], false, true),
  ('tomato', 'Tomatoes', 'Tomates', array['tomate', 'tomato']::text[], 'vegetables_leaves', 'kg', 525, 475, 850, 'medium', '2025-12-15', 'WFP/HDX retail, southern urban markets', null, null, 0.91, 22, 3.4, 2.63, 1.4, 1.1, 0.2, 0.03, 13, 235, 33, 0.7, 23, 'FAO/INFOODS WAFCT 2019 04_021: kcal carbs_g fibre_g protein_g fat_g sat_fat_g sodium_mg potassium_mg phosphorus_mg iron_mg folate_ug; USDA FoodData Central SR Legacy 170457: sugars_g', '04_021', 170457, '{}'::public.allergen[], array['acidic']::public.ingredient_flag[], true, true),
  ('onion', 'Onions', 'Oignons', array['oignon', 'onion']::text[], 'vegetables_leaves', 'kg', 900, 700, 1100, 'medium', '2025-12-15', 'WFP/HDX retail, southern urban markets', null, null, 0.89, 37, 7.1, 4.24, 1.8, 1.1, 0.1, 0.03, 10, 162, 44, 0.7, 17, 'FAO/INFOODS WAFCT 2019 04_018: kcal carbs_g fibre_g protein_g fat_g sat_fat_g sodium_mg potassium_mg phosphorus_mg iron_mg folate_ug; USDA FoodData Central SR Legacy 170000: sugars_g', '04_018', 170000, '{}'::public.allergen[], '{}'::public.ingredient_flag[], true, true),
  ('okra-fresh', 'Okra, fresh', 'Gombo frais', array['gombo', 'okra']::text[], 'vegetables_leaves', 'kg', 1000, 925, 1150, 'medium', '2025-12-15', 'WFP/HDX retail, southern urban markets', null, null, 0.86, 34, 4.2, 1.48, 4.1, 1.7, 0.2, 0.07, 11, 382, 54, 0.8, 88, 'FAO/INFOODS WAFCT 2019 04_017: kcal carbs_g fibre_g protein_g fat_g sat_fat_g sodium_mg potassium_mg phosphorus_mg iron_mg folate_ug; USDA FoodData Central SR Legacy 169260: sugars_g', '04_017', 169260, '{}'::public.allergen[], '{}'::public.ingredient_flag[], false, true),
  ('leafy-greens', 'Leafy greens (njama njama, folong, amaranth)', 'Légumes-feuilles (njama njama, folong, amarante)', array['njama njama', 'folong', 'amaranth']::text[], 'vegetables_leaves', 'kg', 425, 400, 525, 'medium', '2025-12-15', 'WFP/HDX retail, southern urban markets ("Leafy vegetables")', null, null, 0.76, 40, 3, null, 3.8, 4.1, 0.4, 0.11, 7, 545, 69, 7.2, 76, 'FAO/INFOODS WAFCT 2019 04_023: kcal carbs_g fibre_g protein_g fat_g sat_fat_g sodium_mg potassium_mg phosphorus_mg iron_mg folate_ug', '04_023', null, '{}'::public.allergen[], '{}'::public.ingredient_flag[], false, true),
  ('ndole-leaves', 'Ndolé leaves, washed (one ball)', 'Feuilles de ndolé lavées (une boule)', array['ndolé', 'bitterleaf']::text[], 'vegetables_leaves', 'piece', 1000, 1000, 1000, 'low', '2026-10-29', 'Owner market quote 2026-10-29: from 1 000 FCFA', 500, null, 1, 65, 6.7, null, 5.1, 5, 0.9, 0.25, 11, 594, 75, 2.1, 57, 'FAO/INFOODS WAFCT 2019 04_022: kcal carbs_g fibre_g protein_g fat_g sat_fat_g sodium_mg potassium_mg phosphorus_mg iron_mg folate_ug', '04_022', null, '{}'::public.allergen[], '{}'::public.ingredient_flag[], false, true),
  ('eru-leaves', 'Eru (okok), sliced (one bundle)', 'Eru (okok) émincé (une botte)', array['eru', 'okok', 'okazi']::text[], 'vegetables_leaves', 'piece', 1000, 1000, 1000, 'low', '2026-10-29', 'Owner market quote 2026-10-29: from 1 000 FCFA', 400, null, 1, null, null, null, null, null, null, null, null, null, null, null, null, 'No composition data found', null, null, '{}'::public.allergen[], '{}'::public.ingredient_flag[], false, true),
  ('garlic', 'Garlic', 'Ail', array['ail', 'garlic']::text[], 'vegetables_leaves', 'kg', 2000, 1775, 2500, 'low', '2026-07-15', 'WFP/HDX retail, northern markets only', null, null, 0.85, 126, 21.6, 1, 5.3, 6.5, 0.3, 0.07, 10, 442, 195, 1.7, 3, 'FAO/INFOODS WAFCT 2019 04_015: kcal carbs_g fibre_g protein_g fat_g sat_fat_g sodium_mg potassium_mg phosphorus_mg iron_mg folate_ug; USDA FoodData Central SR Legacy 169230: sugars_g', '04_015', 169230, '{}'::public.allergen[], '{}'::public.ingredient_flag[], false, true),
  ('ginger', 'Ginger', 'Gingembre', array['gingembre', 'ginger']::text[], 'spices_seasoning', 'kg', null, null, null, null, '2026-10-29', 'No reliable source (aggregator ranges only; 237online, May 2025: sacks up tenfold at Mvog-Mbi)', null, null, 0.79, 63, 9, 1.7, 5.4, 2.2, 0.9, 0.23, 10, 407, 44, 1.9, 11, 'FAO/INFOODS WAFCT 2019 04_082: kcal carbs_g fibre_g protein_g fat_g sat_fat_g sodium_mg potassium_mg phosphorus_mg iron_mg folate_ug; USDA FoodData Central SR Legacy 169231: sugars_g', '04_082', 169231, '{}'::public.allergen[], '{}'::public.ingredient_flag[], false, false),
  ('pepper-fresh', 'Hot pepper, fresh (one heap)', 'Piment frais (un tas)', array['piment', 'pepe', 'scotch bonnet']::text[], 'spices_seasoning', 'piece', 100, 100, 100, 'low', '2026-10-29', 'Owner market quote 2026-10-29: from 100 FCFA', 100, null, 0.73, 47, 7.5, 5.3, 3.5, 1.8, 0.3, 0.05, 2, 345, 39, 1.3, 15, 'FAO/INFOODS WAFCT 2019 04_046: kcal carbs_g fibre_g protein_g fat_g sat_fat_g sodium_mg potassium_mg phosphorus_mg iron_mg folate_ug; USDA FoodData Central SR Legacy 170106: sugars_g', '04_046', 170106, '{}'::public.allergen[], array['very_spicy']::public.ingredient_flag[], true, true),
  ('salt', 'Salt', 'Sel', array['sel', 'salt']::text[], 'spices_seasoning', 'kg', 375, 325, 400, 'medium', '2025-12-15', 'WFP/HDX retail, southern urban markets', null, null, 1, 0, 0, 0, 0, 0, 0, 0, 38800, 5, 5, 1.3, 0, 'FAO/INFOODS WAFCT 2019 13_015: kcal carbs_g fibre_g protein_g fat_g sat_fat_g sodium_mg potassium_mg phosphorus_mg iron_mg folate_ug; USDA FoodData Central SR Legacy 173468: sugars_g', '13_015', 173468, '{}'::public.allergen[], '{}'::public.ingredient_flag[], true, true),
  ('sugar', 'Sugar', 'Sucre', array['sucre', 'sugar']::text[], 'spices_seasoning', 'kg', 900, 825, 1000, 'medium', '2025-12-15', 'WFP/HDX retail, southern urban markets; matches Sosucam 1 kg at 850–900 FCFA (Glotelho)', null, null, 1, 400, 100, 99.8, 0, 0, 0, 0, 1, 2, 0, 0.1, 0, 'FAO/INFOODS WAFCT 2019 13_002: kcal carbs_g fibre_g protein_g fat_g sat_fat_g sodium_mg potassium_mg phosphorus_mg iron_mg folate_ug; USDA FoodData Central SR Legacy 169655: sugars_g', '13_002', 169655, '{}'::public.allergen[], array['added_sugar']::public.ingredient_flag[], true, true),
  ('bouillon-cube', 'Bouillon cube (Maggi type)', 'Cube d''assaisonnement (type Maggi)', array['Maggi', 'cube']::text[], 'spices_seasoning', 'piece', 9, 9, 9, 'low', '2026-10-29', 'Glotelho: Maggi Etoile pack of 100 cubes (400 g) at 899 FCFA (listing seen 2026-10-29)', 4, null, 1, 213, 17.4, 16.71, 0, 15.97, 8.89, 4.32, 26000, 446, 320, 1, 32, 'USDA FoodData Central SR Legacy 171560: kcal carbs_g sugars_g fibre_g protein_g fat_g sat_fat_g sodium_mg potassium_mg phosphorus_mg iron_mg folate_ug', null, 171560, array['gluten', 'celery', 'soy']::public.allergen[], array['bouillon_cube']::public.ingredient_flag[], true, true),
  ('tomato-paste', 'Tomato paste, 70 g sachet', 'Concentré de tomate, sachet 70 g', array['tomate concentrée', 'tomato paste']::text[], 'spices_seasoning', 'piece', null, null, null, null, '2026-10-29', 'No source found', 70, null, 1, 80, 13.6, 12.18, 4.1, 3.2, 0.5, 0.08, 31, 862, 73, 0.8, 21, 'FAO/INFOODS WAFCT 2019 04_066: kcal carbs_g fibre_g protein_g fat_g sat_fat_g sodium_mg potassium_mg phosphorus_mg iron_mg folate_ug; USDA FoodData Central SR Legacy 170459: sugars_g', '04_066', 170459, '{}'::public.allergen[], array['acidic']::public.ingredient_flag[], true, false),
  ('drinking-water', 'Drinking water, bottled', 'Eau de boisson en bouteille', array['eau', 'water']::text[], 'other', 'litre', 267, 120, 267, 'medium', '2026-10-29', 'Owner market quote 2026-10-29: 400 FCFA per 1.5 L bottle; 1 500 FCFA per pack of 6 × 1.5 L; 1 200 FCFA per 10 L', null, 1.0, 1, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 'FAO/INFOODS WAFCT 2019 12_019: kcal carbs_g fibre_g protein_g fat_g sat_fat_g sodium_mg potassium_mg phosphorus_mg iron_mg folate_ug; capped at the carbohydrate or fat total: sugars_g', '12_019', null, '{}'::public.allergen[], '{}'::public.ingredient_flag[], false, true),
  ('celery', 'Celery (one bunch of green spices)', 'Céleri (une botte d''épices vertes)', array['céleri', 'green spices']::text[], 'vegetables_leaves', 'piece', 100, 100, 100, 'low', '2026-10-29', 'Owner market quote 2026-10-29: green spices from 100 FCFA', 50, null, 1, 14, 2.97, 1.34, 1.6, 0.69, 0.17, 0.042, 80, 260, 24, 0.2, 36, 'USDA FoodData Central SR Legacy 169988: kcal carbs_g sugars_g fibre_g protein_g fat_g sat_fat_g sodium_mg potassium_mg phosphorus_mg iron_mg folate_ug', null, 169988, array['celery']::public.allergen[], '{}'::public.ingredient_flag[], false, true),
  ('spring-onion', 'Spring onions (one bunch)', 'Oignons verts (une botte)', array['oignon vert', 'green spices']::text[], 'vegetables_leaves', 'piece', 100, 100, 100, 'low', '2026-10-29', 'Owner market quote 2026-10-29: green spices from 100 FCFA', 100, null, 1, 32, 7.34, 2.33, 2.6, 1.83, 0.19, 0.032, 16, 276, 37, 1.48, 64, 'USDA FoodData Central SR Legacy 170005: kcal carbs_g sugars_g fibre_g protein_g fat_g sat_fat_g sodium_mg potassium_mg phosphorus_mg iron_mg folate_ug', null, 170005, '{}'::public.allergen[], '{}'::public.ingredient_flag[], false, true),
  ('prawns', 'Prawns, fresh', 'Crevettes fraîches', array['crevettes', 'prawns']::text[], 'fish_seafood', 'kg', null, null, null, null, '2026-10-29', 'No reliable source (aggregators only)', null, null, 0.57, 98, 1, null, 0, 21.6, 0.9, 0.2, 126, 196, 267, 1.6, 14, 'FAO/INFOODS WAFCT 2019 09_059: kcal carbs_g fibre_g protein_g fat_g sat_fat_g sodium_mg potassium_mg phosphorus_mg iron_mg folate_ug', '09_059', 175179, array['crustaceans']::public.allergen[], array['high_purine']::public.ingredient_flag[], false, false),
  ('waterleaf', 'Waterleaf', 'Feuilles de waterleaf (pourpier)', array['waterleaf', 'pourpier']::text[], 'vegetables_leaves', 'kg', null, null, null, null, '2026-10-29', 'No source found', null, null, 0.8, 40, 4.3, null, 3.9, 2.3, 0.7, 0.18, 38, 413, 27, 1.1, 24, 'FAO/INFOODS WAFCT 2019 04_078: kcal carbs_g fibre_g protein_g fat_g sat_fat_g sodium_mg potassium_mg phosphorus_mg iron_mg folate_ug', '04_078', null, '{}'::public.allergen[], '{}'::public.ingredient_flag[], false, false),
  ('beef-skin-kanda', 'Beef skin (kanda)', 'Peau de bœuf (kanda)', array['kanda', 'peau de bœuf']::text[], 'meat_poultry', 'kg', null, null, null, null, '2026-10-29', 'No source found', null, null, 1, null, null, null, null, null, null, null, null, null, null, null, null, 'No composition data found', null, null, '{}'::public.allergen[], '{}'::public.ingredient_flag[], false, false),
  ('limestone-kanwa', 'Limestone for achu (nikki, kanwa)', 'Sel de potasse pour achu (nikki, kanwa)', array['nikki', 'kanwa']::text[], 'other', 'kg', null, null, null, null, '2026-10-29', 'No source found', null, null, 1, null, null, null, null, null, null, null, null, null, null, null, null, 'No composition data found', null, null, '{}'::public.allergen[], '{}'::public.ingredient_flag[], false, false),
  ('achu-spice', 'Achu spice mix', 'Épices pour achu', array['achu spice', 'épices achu']::text[], 'spices_seasoning', 'kg', null, null, null, null, '2026-10-29', 'No source found', null, null, 1, null, null, null, null, null, null, null, null, null, null, null, null, 'No composition data found', null, null, '{}'::public.allergen[], '{}'::public.ingredient_flag[], false, false),
  ('mbongo-spice', 'Mbongo spice, roasted', 'Épice mbongo grillée', array['mbongo', 'mbongo tchobi spice']::text[], 'spices_seasoning', 'kg', null, null, null, null, '2026-10-29', 'No source found', null, null, 1, null, null, null, null, null, null, null, null, null, null, null, null, 'No composition data found', null, null, '{}'::public.allergen[], '{}'::public.ingredient_flag[], false, false),
  ('banana-leaves', 'Banana leaves for wrapping (one bundle)', 'Feuilles de bananier pour emballer (une botte)', array['feuilles de bananier', 'banana leaves']::text[], 'other', 'piece', null, null, null, null, '2026-10-29', 'No source found', 200, null, 0, null, null, null, null, null, null, null, null, null, null, null, null, 'No composition data found', null, null, '{}'::public.allergen[], '{}'::public.ingredient_flag[], false, false),
  ('carrot', 'Carrots', 'Carottes', array['carotte', 'carrot']::text[], 'vegetables_leaves', 'kg', null, null, null, null, '2026-10-29', 'No source found', null, null, 0.92, 34, 5.5, 4.74, 3.2, 0.9, 0.2, 0.03, 35, 225, 48, 0.8, 17, 'FAO/INFOODS WAFCT 2019 04_006: kcal carbs_g fibre_g protein_g fat_g sat_fat_g sodium_mg potassium_mg phosphorus_mg iron_mg folate_ug; USDA FoodData Central SR Legacy 170393: sugars_g', '04_006', 170393, '{}'::public.allergen[], '{}'::public.ingredient_flag[], false, false),
  ('green-beans', 'Green beans', 'Haricots verts', array['haricots verts', 'green beans']::text[], 'vegetables_leaves', 'kg', null, null, null, null, '2026-10-29', 'No source found', null, null, 0.92, 40, 5.2, 3.26, 4.4, 2, 0.3, 0.07, 2, 250, 75, 1.2, 36, 'FAO/INFOODS WAFCT 2019 04_003: kcal carbs_g fibre_g protein_g fat_g sat_fat_g sodium_mg potassium_mg phosphorus_mg iron_mg folate_ug; USDA FoodData Central SR Legacy 169961: sugars_g', '04_003', 169961, '{}'::public.allergen[], '{}'::public.ingredient_flag[], false, false),
  ('fish-fresh', 'Fish, fresh whole (carp, tilapia)', 'Poisson frais entier (carpe, tilapia)', array['carpe', 'tilapia', 'fresh fish']::text[], 'fish_seafood', 'kg', null, null, null, null, '2026-10-29', 'No reliable source (aggregators only)', null, null, 0.6, 90, 0, 0, 0, 18.2, 1.9, 0.51, 51, 317, 185, 0.9, 13, 'FAO/INFOODS WAFCT 2019 09_007: kcal carbs_g fibre_g protein_g fat_g sat_fat_g sodium_mg potassium_mg phosphorus_mg iron_mg folate_ug; USDA FoodData Central SR Legacy 171952: sugars_g', '09_007', 171952, array['fish']::public.allergen[], '{}'::public.ingredient_flag[], false, false),
  ('bell-pepper', 'Sweet peppers (poivrons)', 'Poivrons', array['poivron', 'bell pepper']::text[], 'vegetables_leaves', 'kg', null, null, null, null, '2026-10-29', 'No source found', null, null, 0.82, 48, 7.1, 4.2, 2.5, 2, 0.8, 0.16, 10, 177, 50, 2.2, 24, 'FAO/INFOODS WAFCT 2019 04_047: kcal carbs_g fibre_g protein_g fat_g sat_fat_g sodium_mg potassium_mg phosphorus_mg iron_mg folate_ug; USDA FoodData Central SR Legacy 170108: sugars_g', '04_047', 170108, '{}'::public.allergen[], '{}'::public.ingredient_flag[], false, false),
  ('yeast-dry', 'Yeast, dried', 'Levure sèche', array['levure', 'yeast']::text[], 'other', 'kg', null, null, null, null, '2026-10-29', 'No source found', null, null, 1, 342, 21.2, 0, 23.3, 38.4, 6.3, 0.83, 111, 1210, 749, 2.8, 3200, 'FAO/INFOODS WAFCT 2019 13_017: kcal carbs_g fibre_g protein_g fat_g sat_fat_g sodium_mg potassium_mg phosphorus_mg iron_mg folate_ug; USDA FoodData Central SR Legacy 175043: sugars_g', '13_017', 175043, '{}'::public.allergen[], '{}'::public.ingredient_flag[], false, false),
  ('tomato-tinned', 'Tomatoes, tinned (400 g)', 'Tomates pelées en boîte (400 g)', array['tomates pelées', 'tinned tomatoes']::text[], 'vegetables_leaves', 'piece', null, null, null, null, '2026-10-29', 'No source found', 400, null, 1, 18, 2, 2, 1.9, 1, 0.2, 0.03, 99, 210, 18, 0.6, 17, 'FAO/INFOODS WAFCT 2019 04_065: kcal carbs_g fibre_g protein_g fat_g sat_fat_g sodium_mg potassium_mg phosphorus_mg iron_mg folate_ug; USDA FoodData Central SR Legacy 170051: sugars_g; capped at the carbohydrate or fat total: sugars_g', '04_065', 170051, '{}'::public.allergen[], array['acidic']::public.ingredient_flag[], false, false),
  ('parmesan', 'Parmesan', 'Parmesan', array['parmesan']::text[], 'eggs_dairy', 'kg', null, null, null, null, '2026-10-29', 'No source found', null, null, 1, 392, 3.22, 0.11, 0, 35.75, 25, 14.85, 1175, 92, 694, 0.82, 7, 'USDA FoodData Central SR Legacy 170848: kcal carbs_g sugars_g fibre_g protein_g fat_g sat_fat_g sodium_mg potassium_mg phosphorus_mg iron_mg folate_ug', null, 170848, array['milk']::public.allergen[], '{}'::public.ingredient_flag[], false, false),
  ('milk-uht', 'Milk, UHT (liquid)', 'Lait UHT (liquide)', array['lait', 'milk']::text[], 'eggs_dairy', 'litre', null, null, null, null, '2026-10-29', 'No reliable source (aggregator only: about 1 600 FCFA/L, Douala)', null, 1.03, 1, 64, 5.1, 5.05, 0, 3.3, 3.4, 2.11, 45, 147, 111, 0.1, 8, 'FAO/INFOODS WAFCT 2019 10_001: kcal carbs_g fibre_g protein_g fat_g sat_fat_g sodium_mg potassium_mg phosphorus_mg iron_mg folate_ug; USDA FoodData Central SR Legacy 171265: sugars_g', '10_001', 171265, array['milk']::public.allergen[], '{}'::public.ingredient_flag[], false, false),
  ('butter', 'Butter', 'Beurre', array['beurre', 'butter']::text[], 'eggs_dairy', 'kg', null, null, null, null, '2026-10-29', 'No reliable source (one out-of-stock listing)', null, null, 1, 739, 0.2, 0.06, 0, 1, 81.5, 54.5, 716, 12, 15, 0, 5, 'FAO/INFOODS WAFCT 2019 11_011: kcal carbs_g fibre_g protein_g fat_g sat_fat_g sodium_mg potassium_mg phosphorus_mg iron_mg folate_ug; USDA FoodData Central SR Legacy 173410: sugars_g', '11_011', 173410, array['milk']::public.allergen[], '{}'::public.ingredient_flag[], false, false),
  ('chickpeas-tinned', 'Chickpeas, tinned (400 g)', 'Pois chiches en boîte (400 g)', array['pois chiches', 'chickpeas']::text[], 'legumes_nuts_seeds', 'piece', null, null, null, null, '2026-10-29', 'No source found', 240, null, 1, 139, 22.53, 4.01, 6.4, 7.05, 2.77, 0.214, 246, 126, 85, 1.07, 48, 'USDA FoodData Central SR Legacy 173800: kcal carbs_g sugars_g fibre_g protein_g fat_g sat_fat_g sodium_mg potassium_mg phosphorus_mg iron_mg folate_ug', null, 173800, '{}'::public.allergen[], '{}'::public.ingredient_flag[], false, false),
  ('coconut-milk', 'Coconut milk, tinned (400 ml)', 'Lait de coco en boîte (400 ml)', array['lait de coco', 'coconut milk']::text[], 'other', 'piece', null, null, null, null, '2026-10-29', 'No source found', 380, null, 1, 201, 3.9, null, 1.3, 0.1, 20.3, 18.14, 16, 210, 73, 1.9, 15, 'FAO/INFOODS WAFCT 2019 06_006: kcal carbs_g fibre_g protein_g fat_g sat_fat_g sodium_mg potassium_mg phosphorus_mg iron_mg folate_ug', '06_006', 170173, '{}'::public.allergen[], '{}'::public.ingredient_flag[], false, false),
  ('mustard-seeds', 'Mustard seeds', 'Graines de moutarde', array['moutarde', 'mustard seeds']::text[], 'spices_seasoning', 'kg', null, null, null, null, '2026-10-29', 'No source found', null, null, 1, 508, 28.09, 6.79, 12.2, 26.08, 36.24, 1.989, 13, 738, 828, 9.21, 162, 'USDA FoodData Central SR Legacy 170929: kcal carbs_g sugars_g fibre_g protein_g fat_g sat_fat_g sodium_mg potassium_mg phosphorus_mg iron_mg folate_ug', null, 170929, array['mustard']::public.allergen[], '{}'::public.ingredient_flag[], false, false),
  ('curry-powder', 'Curry powder', 'Curry en poudre', array['curry']::text[], 'spices_seasoning', 'kg', null, null, null, null, '2026-10-29', 'No source found', null, null, 1, 293, 6.8, 2.76, 53.2, 11.9, 12.4, 1.46, 251, 1500, 319, 19.1, 56, 'FAO/INFOODS WAFCT 2019 13_022: kcal carbs_g fibre_g protein_g fat_g sat_fat_g sodium_mg potassium_mg phosphorus_mg iron_mg folate_ug; USDA FoodData Central SR Legacy 170924: sugars_g', '13_022', 170924, array['celery', 'mustard']::public.allergen[], '{}'::public.ingredient_flag[], false, false),
  ('soy-sauce', 'Soy sauce', 'Sauce soja', array['sauce soja', 'soy sauce']::text[], 'spices_seasoning', 'litre', null, null, null, null, '2026-10-29', 'No source found', null, 1.08, 1, 53, 4.93, 0.4, 0.8, 8.14, 0.57, 0.073, 5493, 435, 166, 1.45, 14, 'USDA FoodData Central SR Legacy 174277: kcal carbs_g sugars_g fibre_g protein_g fat_g sat_fat_g sodium_mg potassium_mg phosphorus_mg iron_mg folate_ug', null, 174277, array['soy', 'gluten']::public.allergen[], '{}'::public.ingredient_flag[], false, false),
  ('sesame-oil', 'Sesame oil', 'Huile de sésame', array['huile de sésame', 'sesame oil']::text[], 'oils_fats', 'litre', null, null, null, null, '2026-10-29', 'No source found', null, 0.92, 1, 884, 0, 0, 0, 0, 100, 14.2, 0, 0, 0, 0, 0, 'USDA FoodData Central SR Legacy 171016: kcal carbs_g sugars_g fibre_g protein_g fat_g sat_fat_g sodium_mg potassium_mg phosphorus_mg iron_mg folate_ug', null, 171016, array['sesame']::public.allergen[], '{}'::public.ingredient_flag[], false, false)
on conflict (slug) do update set
  name_en = excluded.name_en,
  name_fr = excluded.name_fr,
  aliases = excluded.aliases,
  category = excluded.category,
  pricing_unit = excluded.pricing_unit,
  price_xaf = excluded.price_xaf,
  price_low_xaf = excluded.price_low_xaf,
  price_high_xaf = excluded.price_high_xaf,
  price_confidence = excluded.price_confidence,
  price_updated_at = excluded.price_updated_at,
  price_source = excluded.price_source,
  grams_per_piece = excluded.grams_per_piece,
  density_g_per_ml = excluded.density_g_per_ml,
  edible_portion = excluded.edible_portion,
  kcal = excluded.kcal,
  carbs_g = excluded.carbs_g,
  sugars_g = excluded.sugars_g,
  fibre_g = excluded.fibre_g,
  protein_g = excluded.protein_g,
  fat_g = excluded.fat_g,
  sat_fat_g = excluded.sat_fat_g,
  sodium_mg = excluded.sodium_mg,
  potassium_mg = excluded.potassium_mg,
  phosphorus_mg = excluded.phosphorus_mg,
  iron_mg = excluded.iron_mg,
  folate_ug = excluded.folate_ug,
  nutrient_source = excluded.nutrient_source,
  wafct_code = excluded.wafct_code,
  fdc_id = excluded.fdc_id,
  allergens = excluded.allergens,
  flags = excluded.flags,
  is_kitchen_staple = excluded.is_kitchen_staple,
  is_active = excluded.is_active;
-- END GENERATED: food catalog
