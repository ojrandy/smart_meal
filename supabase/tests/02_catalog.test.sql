-- Catalog: authenticated users read published recipes only, and have no
-- write path to any catalog table.
begin;
create extension if not exists pgtap with schema extensions;
select plan(14);

insert into auth.users (id, email) values
  ('11111111-1111-4111-8111-111111111111', 'a@test.local');
insert into public.cuisines (slug, name) values ('test_cuisine', 'Test');
insert into public.recipes (id, slug, title, cuisine_slug, difficulty, servings, is_published) values
  ('aaaaaaaa-0000-4000-8000-000000000001', 'test-published', 'Published', 'test_cuisine', 'easy', 2, true),
  ('aaaaaaaa-0000-4000-8000-000000000002', 'test-draft', 'Draft', 'test_cuisine', 'easy', 2, false);
insert into public.recipe_ingredients (recipe_id, position, name) values
  ('aaaaaaaa-0000-4000-8000-000000000001', 1, 'Salt'),
  ('aaaaaaaa-0000-4000-8000-000000000002', 1, 'Secret');
insert into public.recipe_steps (recipe_id, position, instruction) values
  ('aaaaaaaa-0000-4000-8000-000000000001', 1, 'Cook.'),
  ('aaaaaaaa-0000-4000-8000-000000000002', 1, 'Secret.');

set local role authenticated;
select set_config('request.jwt.claims',
  '{"sub":"11111111-1111-4111-8111-111111111111","role":"authenticated"}', true);

select is((select count(*) from public.recipes where slug = 'test-published'), 1::bigint, 'published recipe is visible');
select is((select count(*) from public.recipes where slug = 'test-draft'), 0::bigint, 'unpublished recipe is invisible');
select is((select count(*) from public.recipe_ingredients where recipe_id = 'aaaaaaaa-0000-4000-8000-000000000002'), 0::bigint, 'ingredients of an unpublished recipe are invisible');
select is((select count(*) from public.recipe_steps where recipe_id = 'aaaaaaaa-0000-4000-8000-000000000002'), 0::bigint, 'steps of an unpublished recipe are invisible');
select is((select count(*) from public.recipe_ingredients where recipe_id = 'aaaaaaaa-0000-4000-8000-000000000001'), 1::bigint, 'ingredients of a published recipe are visible');
select ok((select count(*) from public.cuisines) >= 1, 'cuisines are readable');

-- A foreign key alone would accept a guessed draft id; the policies do not.
select throws_ok($$insert into public.favorites (recipe_id) values ('aaaaaaaa-0000-4000-8000-000000000002')$$, '42501', null, 'cannot favorite an unpublished recipe');
select throws_ok($$insert into public.recipe_interactions (recipe_id, interaction) values ('aaaaaaaa-0000-4000-8000-000000000002', 'viewed')$$, '42501', null, 'cannot log an interaction on an unpublished recipe');
select lives_ok($$insert into public.favorites (recipe_id) values ('aaaaaaaa-0000-4000-8000-000000000001')$$, 'can favorite a published recipe');

-- No client writes to the catalog.
select throws_ok($$insert into public.recipes (slug, title, cuisine_slug, difficulty, servings) values ('x', 'X', 'test_cuisine', 'easy', 1)$$, '42501', null, 'no client insert into recipes');
select throws_ok($$update public.recipes set is_published = true$$, '42501', null, 'no client update of recipes');
select throws_ok($$delete from public.recipes$$, '42501', null, 'no client delete from recipes');
select throws_ok($$insert into public.cuisines (slug, name) values ('x', 'X')$$, '42501', null, 'no client insert into cuisines');
select throws_ok($$insert into public.recipe_steps (recipe_id, position, instruction) values ('aaaaaaaa-0000-4000-8000-000000000001', 9, 'x')$$, '42501', null, 'no client insert into recipe_steps');

reset role;
select * from finish();
rollback;
