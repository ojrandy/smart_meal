-- Account lifecycle: signup creates a profile; deleting the auth user
-- removes every row the user owns (the basis of P14). Storage objects do
-- not cascade — P14's Edge Function deletes them.
begin;
create extension if not exists pgtap with schema extensions;
select plan(13);

insert into auth.users (id, email, raw_user_meta_data) values
  ('11111111-1111-4111-8111-111111111111', 'a@test.local', '{"full_name":"  Ada Lovelace  "}'),
  ('22222222-2222-4222-8222-222222222222', 'b@test.local', '{}');

select is((select count(*) from public.profiles where id = '11111111-1111-4111-8111-111111111111'), 1::bigint, 'signup creates a profile');
select is((select display_name from public.profiles where id = '11111111-1111-4111-8111-111111111111'), 'Ada Lovelace', 'display name taken from full_name, trimmed');
select is((select display_name from public.profiles where id = '22222222-2222-4222-8222-222222222222'), null, 'no full_name → no display name');
select is((select country_code || currency_code from public.profiles where id = '22222222-2222-4222-8222-222222222222'), 'CMXAF', 'defaults to Cameroon / XAF');

-- Give A a row in every user table.
insert into public.cuisines (slug, name) values ('test_cuisine', 'Test');
insert into public.recipes (id, slug, title, cuisine_slug, difficulty, servings, is_published)
values ('aaaaaaaa-0000-4000-8000-000000000001', 'test-recipe', 'Test', 'test_cuisine', 'easy', 2, true);
insert into public.user_preferences (user_id) values ('11111111-1111-4111-8111-111111111111');
insert into public.user_cuisine_preferences (user_id, cuisine_slug, preference)
values ('11111111-1111-4111-8111-111111111111', 'test_cuisine', 'like');
insert into public.favorites (user_id, recipe_id)
values ('11111111-1111-4111-8111-111111111111', 'aaaaaaaa-0000-4000-8000-000000000001');
insert into public.meal_plans (id, user_id, week_start)
values ('bbbbbbbb-0000-4000-8000-00000000000a', '11111111-1111-4111-8111-111111111111', '2026-10-19');
insert into public.meal_plan_entries (meal_plan_id, week_start, plan_date, meal_slot, recipe_id)
values ('bbbbbbbb-0000-4000-8000-00000000000a', '2026-10-19', '2026-10-19', 'dinner', 'aaaaaaaa-0000-4000-8000-000000000001');
insert into public.recipe_interactions (user_id, recipe_id, interaction)
values ('11111111-1111-4111-8111-111111111111', 'aaaaaaaa-0000-4000-8000-000000000001', 'cooked');
insert into public.push_tokens (token, user_id, platform)
values ('token-a', '11111111-1111-4111-8111-111111111111', 'android');
-- B keeps a favorite, to prove the cascade is scoped to A.
insert into public.favorites (user_id, recipe_id)
values ('22222222-2222-4222-8222-222222222222', 'aaaaaaaa-0000-4000-8000-000000000001');

delete from auth.users where id = '11111111-1111-4111-8111-111111111111';

select is((select count(*) from public.profiles where id = '11111111-1111-4111-8111-111111111111'), 0::bigint, 'profile deleted');
select is((select count(*) from public.user_preferences where user_id = '11111111-1111-4111-8111-111111111111'), 0::bigint, 'preferences deleted');
select is((select count(*) from public.user_cuisine_preferences where user_id = '11111111-1111-4111-8111-111111111111'), 0::bigint, 'cuisine preferences deleted');
select is((select count(*) from public.favorites where user_id = '11111111-1111-4111-8111-111111111111'), 0::bigint, 'favorites deleted');
select is((select count(*) from public.meal_plans where user_id = '11111111-1111-4111-8111-111111111111'), 0::bigint, 'meal plans deleted');
select is((select count(*) from public.meal_plan_entries where meal_plan_id = 'bbbbbbbb-0000-4000-8000-00000000000a'), 0::bigint, 'meal plan entries deleted');
select is((select count(*) from public.recipe_interactions where user_id = '11111111-1111-4111-8111-111111111111'), 0::bigint, 'interactions deleted');
select is((select count(*) from public.push_tokens where user_id = '11111111-1111-4111-8111-111111111111'), 0::bigint, 'push tokens deleted');
select is((select count(*) from public.favorites where user_id = '22222222-2222-4222-8222-222222222222'), 1::bigint, 'another user''s rows are untouched');

select * from finish();
rollback;
