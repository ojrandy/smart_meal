-- User isolation: user A can never read, insert, update or delete another
-- user's rows, and anon can read nothing. Each "cannot" check has a
-- positive control (A sees exactly their own row) so no test passes
-- vacuously. Runs in a transaction that is rolled back.
begin;
create extension if not exists pgtap with schema extensions;
select plan(55);

-- ── Fixture (as postgres) ───────────────────────────────────────────────────
insert into auth.users (id, email) values
  ('11111111-1111-4111-8111-111111111111', 'a@test.local'),
  ('22222222-2222-4222-8222-222222222222', 'b@test.local'),
  ('33333333-3333-4333-8333-333333333333', 'c@test.local');

insert into public.cuisines (slug, name) values ('test_cuisine', 'Test');
insert into public.recipes (id, slug, title, cuisine_slug, difficulty, servings, is_published)
values ('aaaaaaaa-0000-4000-8000-000000000001', 'test-recipe', 'Test', 'test_cuisine', 'easy', 2, true);

insert into public.user_preferences (user_id, household_size) values
  ('11111111-1111-4111-8111-111111111111', 2),
  ('22222222-2222-4222-8222-222222222222', 3);
insert into public.user_cuisine_preferences (user_id, cuisine_slug, preference) values
  ('11111111-1111-4111-8111-111111111111', 'test_cuisine', 'like'),
  ('22222222-2222-4222-8222-222222222222', 'test_cuisine', 'like');
insert into public.favorites (user_id, recipe_id) values
  ('11111111-1111-4111-8111-111111111111', 'aaaaaaaa-0000-4000-8000-000000000001'),
  ('22222222-2222-4222-8222-222222222222', 'aaaaaaaa-0000-4000-8000-000000000001');
insert into public.meal_plans (id, user_id, week_start) values
  ('bbbbbbbb-0000-4000-8000-00000000000a', '11111111-1111-4111-8111-111111111111', '2026-10-19'),
  ('bbbbbbbb-0000-4000-8000-00000000000b', '22222222-2222-4222-8222-222222222222', '2026-10-19');
insert into public.meal_plan_entries (meal_plan_id, week_start, plan_date, meal_slot, recipe_id) values
  ('bbbbbbbb-0000-4000-8000-00000000000a', '2026-10-19', '2026-10-20', 'lunch', 'aaaaaaaa-0000-4000-8000-000000000001'),
  ('bbbbbbbb-0000-4000-8000-00000000000b', '2026-10-19', '2026-10-20', 'lunch', 'aaaaaaaa-0000-4000-8000-000000000001');
insert into public.recipe_interactions (user_id, recipe_id, interaction) values
  ('11111111-1111-4111-8111-111111111111', 'aaaaaaaa-0000-4000-8000-000000000001', 'viewed'),
  ('22222222-2222-4222-8222-222222222222', 'aaaaaaaa-0000-4000-8000-000000000001', 'viewed');
insert into public.push_tokens (token, user_id, platform) values
  ('token-a', '11111111-1111-4111-8111-111111111111', 'android'),
  ('token-b', '22222222-2222-4222-8222-222222222222', 'ios');

-- ── As user A ───────────────────────────────────────────────────────────────
set local role authenticated;
select set_config('request.jwt.claims',
  '{"sub":"11111111-1111-4111-8111-111111111111","role":"authenticated"}', true);

-- Read: only A's own row is visible in every user table.
select is((select count(*) from public.profiles), 1::bigint, 'profiles: A sees only own row');
select is((select id from public.profiles), '11111111-1111-4111-8111-111111111111'::uuid, 'profiles: the visible row is A''s');
select is((select count(*) from public.user_preferences), 1::bigint, 'user_preferences: A sees only own row');
select is((select household_size from public.user_preferences), 2::smallint, 'user_preferences: the visible row is A''s');
select is((select count(*) from public.user_cuisine_preferences), 1::bigint, 'user_cuisine_preferences: A sees only own row');
select is((select count(*) from public.favorites), 1::bigint, 'favorites: A sees only own row');
select is((select count(*) from public.meal_plans), 1::bigint, 'meal_plans: A sees only own row');
select is((select count(*) from public.meal_plan_entries), 1::bigint, 'meal_plan_entries: A sees only own row');
select is((select count(*) from public.recipe_interactions), 1::bigint, 'recipe_interactions: A sees only own row');
select is((select token from public.push_tokens), 'token-a', 'push_tokens: A sees only own token');
select is((select count(*) from public.push_tokens), 1::bigint, 'push_tokens: exactly one visible');

-- Update: B's rows are untouched (0 rows), A's own update works.
with u as (update public.profiles set display_name = 'x'
           where id = '22222222-2222-4222-8222-222222222222' returning 1)
select is((select count(*) from u), 0::bigint, 'profiles: A cannot update B');
with u as (update public.profiles set display_name = 'Ada'
           where id = '11111111-1111-4111-8111-111111111111' returning 1)
select is((select count(*) from u), 1::bigint, 'profiles: A can update own');
with u as (update public.user_preferences set household_size = 9
           where user_id = '22222222-2222-4222-8222-222222222222' returning 1)
select is((select count(*) from u), 0::bigint, 'user_preferences: A cannot update B');
with u as (update public.user_preferences set household_size = 4
           where user_id = '11111111-1111-4111-8111-111111111111' returning 1)
select is((select count(*) from u), 1::bigint, 'user_preferences: A can update own');
with u as (update public.user_cuisine_preferences set preference = 'dislike'
           where user_id = '22222222-2222-4222-8222-222222222222' returning 1)
select is((select count(*) from u), 0::bigint, 'user_cuisine_preferences: A cannot update B');
with u as (update public.meal_plan_entries set servings = 5
           where meal_plan_id = 'bbbbbbbb-0000-4000-8000-00000000000b' returning 1)
select is((select count(*) from u), 0::bigint, 'meal_plan_entries: A cannot update B');
with u as (update public.meal_plan_entries set servings = 5
           where meal_plan_id = 'bbbbbbbb-0000-4000-8000-00000000000a' returning 1)
select is((select count(*) from u), 1::bigint, 'meal_plan_entries: A can update own');

-- Tables with no client update path at all.
select throws_ok($$update public.favorites set created_at = now()$$, '42501', null, 'favorites: no update privilege');
select throws_ok($$update public.meal_plans set week_start = '2026-10-26'$$, '42501', null, 'meal_plans: no update privilege');
select throws_ok($$update public.recipe_interactions set rating = 5$$, '42501', null, 'recipe_interactions: no update privilege');
select throws_ok($$update public.push_tokens set platform = 'ios'$$, '42501', null, 'push_tokens: no direct update');

-- Immutable columns, even on A's own rows.
select throws_ok($$update public.profiles set id = '33333333-3333-4333-8333-333333333333'$$, '42501', null, 'profiles.id is immutable');
select throws_ok($$update public.profiles set created_at = now()$$, '42501', null, 'profiles.created_at is immutable');
select throws_ok($$update public.user_preferences set user_id = '22222222-2222-4222-8222-222222222222'$$, '42501', null, 'user_preferences.user_id is immutable');
select throws_ok($$update public.user_cuisine_preferences set user_id = '22222222-2222-4222-8222-222222222222'$$, '42501', null, 'user_cuisine_preferences.user_id is immutable');
select throws_ok($$update public.meal_plan_entries set meal_plan_id = 'bbbbbbbb-0000-4000-8000-00000000000b'$$, '42501', null, 'meal_plan_entries cannot move to another plan');

-- Insert on behalf of someone else is refused.
select throws_ok($$insert into public.user_preferences (user_id) values ('33333333-3333-4333-8333-333333333333')$$, '42501', null, 'user_preferences: A cannot insert for C');
select throws_ok($$insert into public.user_cuisine_preferences (user_id, cuisine_slug, preference) values ('33333333-3333-4333-8333-333333333333', 'test_cuisine', 'like')$$, '42501', null, 'user_cuisine_preferences: A cannot insert for C');
select throws_ok($$insert into public.favorites (user_id, recipe_id) values ('33333333-3333-4333-8333-333333333333', 'aaaaaaaa-0000-4000-8000-000000000001')$$, '42501', null, 'favorites: A cannot insert for C');
select throws_ok($$insert into public.meal_plans (user_id, week_start) values ('33333333-3333-4333-8333-333333333333', '2026-10-26')$$, '42501', null, 'meal_plans: A cannot insert for C');
select throws_ok($$insert into public.meal_plan_entries (meal_plan_id, week_start, plan_date, meal_slot, recipe_id) values ('bbbbbbbb-0000-4000-8000-00000000000b', '2026-10-19', '2026-10-21', 'dinner', 'aaaaaaaa-0000-4000-8000-000000000001')$$, '42501', null, 'meal_plan_entries: A cannot add to B''s plan');
select throws_ok($$insert into public.recipe_interactions (user_id, recipe_id, interaction) values ('33333333-3333-4333-8333-333333333333', 'aaaaaaaa-0000-4000-8000-000000000001', 'viewed')$$, '42501', null, 'recipe_interactions: A cannot insert for C');
select throws_ok($$insert into public.push_tokens (token, user_id, platform) values ('t', '11111111-1111-4111-8111-111111111111', 'ios')$$, '42501', null, 'push_tokens: no direct insert');
select throws_ok($$insert into public.profiles (id) values ('33333333-3333-4333-8333-333333333333')$$, '42501', null, 'profiles: no client insert');

-- A's own inserts work, with user_id defaulting to the caller.
select lives_ok($$insert into public.recipe_interactions (recipe_id, interaction, rating) values ('aaaaaaaa-0000-4000-8000-000000000001', 'rated', 4)$$, 'recipe_interactions: A can insert own (user_id defaults to caller)');
select is((select count(*) from public.recipe_interactions), 2::bigint, 'recipe_interactions: the new row is A''s');

-- Delete: B's rows are untouched.
with d as (delete from public.user_preferences where user_id = '22222222-2222-4222-8222-222222222222' returning 1)
select is((select count(*) from d), 0::bigint, 'user_preferences: A cannot delete B');
with d as (delete from public.user_cuisine_preferences where user_id = '22222222-2222-4222-8222-222222222222' returning 1)
select is((select count(*) from d), 0::bigint, 'user_cuisine_preferences: A cannot delete B');
with d as (delete from public.favorites where user_id = '22222222-2222-4222-8222-222222222222' returning 1)
select is((select count(*) from d), 0::bigint, 'favorites: A cannot delete B');
with d as (delete from public.meal_plans where user_id = '22222222-2222-4222-8222-222222222222' returning 1)
select is((select count(*) from d), 0::bigint, 'meal_plans: A cannot delete B');
with d as (delete from public.meal_plan_entries where meal_plan_id = 'bbbbbbbb-0000-4000-8000-00000000000b' returning 1)
select is((select count(*) from d), 0::bigint, 'meal_plan_entries: A cannot delete B');
with d as (delete from public.push_tokens where token = 'token-b' returning 1)
select is((select count(*) from d), 0::bigint, 'push_tokens: A cannot delete B');
select throws_ok($$delete from public.profiles$$, '42501', null, 'profiles: no client delete');
select throws_ok($$delete from public.recipe_interactions$$, '42501', null, 'recipe_interactions: no client delete');
with d as (delete from public.favorites where user_id = '11111111-1111-4111-8111-111111111111' returning 1)
select is((select count(*) from d), 1::bigint, 'favorites: A can delete own');

-- Back to postgres: B's data is all still there.
reset role;
select is((select count(*) from public.user_preferences where user_id = '22222222-2222-4222-8222-222222222222'), 1::bigint, 'B''s preferences survived');
select is((select household_size from public.user_preferences where user_id = '22222222-2222-4222-8222-222222222222'), 3::smallint, 'B''s preferences unchanged');
select is((select count(*) from public.favorites where user_id = '22222222-2222-4222-8222-222222222222'), 1::bigint, 'B''s favorite survived');
select is((select count(*) from public.push_tokens where token = 'token-b'), 1::bigint, 'B''s push token survived');

-- ── As anon: nothing at all ─────────────────────────────────────────────────
set local role anon;
select set_config('request.jwt.claims', '{"role":"anon"}', true);
select throws_ok($$select 1 from public.profiles$$, '42501', null, 'anon: no profiles');
select throws_ok($$select 1 from public.user_preferences$$, '42501', null, 'anon: no user_preferences');
select throws_ok($$select 1 from public.recipes$$, '42501', null, 'anon: no recipes');
select throws_ok($$select 1 from public.favorites$$, '42501', null, 'anon: no favorites');
select throws_ok($$select 1 from public.push_tokens$$, '42501', null, 'anon: no push_tokens');
reset role;

select * from finish();
rollback;
