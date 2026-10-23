-- Constraints: out-of-range and invalid values are rejected by the
-- database itself (S3, S9), whatever the client sends.
begin;
create extension if not exists pgtap with schema extensions;
select plan(24);

insert into auth.users (id, email) values
  ('11111111-1111-4111-8111-111111111111', 'a@test.local');
insert into public.cuisines (slug, name) values ('test_cuisine', 'Test');
insert into public.recipes (id, slug, title, cuisine_slug, difficulty, servings, is_published)
values ('aaaaaaaa-0000-4000-8000-000000000001', 'test-recipe', 'Test', 'test_cuisine', 'easy', 2, true);
insert into public.meal_plans (id, user_id, week_start)
values ('bbbbbbbb-0000-4000-8000-00000000000a', '11111111-1111-4111-8111-111111111111', '2026-10-19');

-- profiles
select throws_ok($$update public.profiles set display_name = repeat('x', 81) where id = '11111111-1111-4111-8111-111111111111'$$, '23514', null, 'display_name over 80 characters');
select throws_ok($$update public.profiles set display_name = '' where id = '11111111-1111-4111-8111-111111111111'$$, '23514', null, 'empty display_name');
select throws_ok($$update public.profiles set avatar_path = '22222222-2222-4222-8222-222222222222/me.png' where id = '11111111-1111-4111-8111-111111111111'$$, '23514', null, 'avatar_path outside the owner''s folder');
select throws_ok($$update public.profiles set country_code = 'cm' where id = '11111111-1111-4111-8111-111111111111'$$, '23514', null, 'lowercase country code');

-- user_preferences
select throws_ok($$insert into public.user_preferences (user_id, household_size) values ('11111111-1111-4111-8111-111111111111', 21)$$, '23514', null, 'household_size above 20');
select throws_ok($$insert into public.user_preferences (user_id, household_size) values ('11111111-1111-4111-8111-111111111111', 0)$$, '23514', null, 'household_size below 1');
select throws_ok($$insert into public.user_preferences (user_id, budget_amount_xaf, budget_period) values ('11111111-1111-4111-8111-111111111111', 10000001, 'weekly')$$, '23514', null, 'budget above 10 000 000 XAF');
select throws_ok($$insert into public.user_preferences (user_id, budget_amount_xaf) values ('11111111-1111-4111-8111-111111111111', 5000)$$, '23514', null, 'budget without a period');
select throws_ok($$insert into public.user_preferences (user_id, max_cook_minutes) values ('11111111-1111-4111-8111-111111111111', 4)$$, '23514', null, 'max_cook_minutes below 5');
select throws_ok($$insert into public.user_preferences (user_id, allergens, allergens_declared, sensitive_data_consent_at) values ('11111111-1111-4111-8111-111111111111', '{peanuts}', false, now())$$, '23514', null, 'allergens without declaring');
select throws_ok($$insert into public.user_preferences (user_id, allergens, allergens_declared) values ('11111111-1111-4111-8111-111111111111', '{peanuts}', true)$$, '23514', null, 'allergens without consent (S6)');
select throws_ok($$insert into public.user_preferences (user_id, dietary_tags) values ('11111111-1111-4111-8111-111111111111', '{vegan}')$$, '23514', null, 'diet tags without consent (S6)');
select throws_ok($$insert into public.user_preferences (user_id, allergens, allergens_declared, sensitive_data_consent_at) values ('11111111-1111-4111-8111-111111111111', '{groundnut}', true, now())$$, '22P02', null, 'allergen outside the closed set');
select lives_ok($$insert into public.user_preferences (user_id, allergens, allergens_declared, sensitive_data_consent_at) values ('11111111-1111-4111-8111-111111111111', '{peanuts,crustaceans}', true, now())$$, 'declared allergens with consent are accepted');

-- recipes
select throws_ok($$insert into public.recipes (slug, title, cuisine_slug, difficulty, servings) values ('Bad Slug', 'X', 'test_cuisine', 'easy', 2)$$, '23514', null, 'invalid recipe slug');
select throws_ok($$insert into public.recipes (slug, title, cuisine_slug, difficulty, servings) values ('x-1', 'X', 'test_cuisine', 'easy', 51)$$, '23514', null, 'servings above 50');
select throws_ok($$insert into public.recipes (slug, title, cuisine_slug, difficulty, servings, est_cost_xaf) values ('x-2', 'X', 'test_cuisine', 'easy', 2, -1)$$, '23514', null, 'negative cost');
select throws_ok($$insert into public.recipes (slug, title, cuisine_slug, difficulty, servings, allergens) values ('x-3', 'X', 'test_cuisine', 'easy', 2, null)$$, '23502', null, 'recipe allergens cannot be null');
select throws_ok($$insert into public.recipe_ingredients (recipe_id, position, name, quantity) values ('aaaaaaaa-0000-4000-8000-000000000001', 1, 'Salt', 0)$$, '23514', null, 'ingredient quantity must be positive');

-- meal plans
select throws_ok($$insert into public.meal_plans (user_id, week_start) values ('11111111-1111-4111-8111-111111111111', '2026-10-21')$$, '23514', null, 'week_start must be a Monday');
select throws_ok($$insert into public.meal_plan_entries (meal_plan_id, week_start, plan_date, meal_slot, recipe_id) values ('bbbbbbbb-0000-4000-8000-00000000000a', '2026-10-19', '2026-10-26', 'lunch', 'aaaaaaaa-0000-4000-8000-000000000001')$$, '23514', null, 'entry date outside the plan week');
select throws_ok($$insert into public.meal_plan_entries (meal_plan_id, week_start, plan_date, meal_slot, recipe_id) values ('bbbbbbbb-0000-4000-8000-00000000000a', '2026-10-26', '2026-10-27', 'lunch', 'aaaaaaaa-0000-4000-8000-000000000001')$$, '23503', null, 'entry week must match its plan');

-- interactions
select throws_ok($$insert into public.recipe_interactions (user_id, recipe_id, interaction) values ('11111111-1111-4111-8111-111111111111', 'aaaaaaaa-0000-4000-8000-000000000001', 'rated')$$, '23514', null, '"rated" requires a rating');
select throws_ok($$insert into public.recipe_interactions (user_id, recipe_id, interaction, rating) values ('11111111-1111-4111-8111-111111111111', 'aaaaaaaa-0000-4000-8000-000000000001', 'viewed', 3)$$, '23514', null, 'a rating only with "rated"');

select * from finish();
rollback;
