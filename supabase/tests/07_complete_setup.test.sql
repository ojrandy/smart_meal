-- complete_setup (P16): saves all answers and the completion time in one
-- transaction, only for the caller, with every input validated.
begin;
create extension if not exists pgtap with schema extensions;
select plan(22);

insert into auth.users (id, email) values
  ('11111111-1111-4111-8111-111111111111', 'a@test.local'),
  ('22222222-2222-4222-8222-222222222222', 'b@test.local');

select ok((select count(*) from public.cuisines where slug in
  ('cameroonian', 'west_african', 'italian', 'french', 'indian', 'chinese')) = 6,
  'the six cuisines are reference data');
select ok(not has_function_privilege('anon',
  'public.complete_setup(public.lifestyle, integer, integer, public.budget_period, public.cooking_skill, integer, text[], text[], boolean, public.dietary_tag[], public.allergen[], public.health_goal[])',
  'execute'), 'anon cannot call complete_setup');
select is((select prosecdef from pg_proc where proname = 'complete_setup'), false,
  'complete_setup is SECURITY INVOKER');

set local role authenticated;
select set_config('request.jwt.claims',
  '{"sub":"11111111-1111-4111-8111-111111111111","role":"authenticated"}', true);

-- Invalid inputs change nothing.
select throws_ok($$select public.complete_setup('student', 0, 5000, 'weekly', 'beginner', 30, '{}', '{}', true, '{}', '{}', '{}')$$, '22023', null, 'household 0 rejected');
select throws_ok($$select public.complete_setup('student', 21, 5000, 'weekly', 'beginner', 30, '{}', '{}', true, '{}', '{}', '{}')$$, '22023', null, 'household 21 rejected');
select throws_ok($$select public.complete_setup('student', 2, 0, 'weekly', 'beginner', 30, '{}', '{}', true, '{}', '{}', '{}')$$, '22023', null, 'budget 0 rejected');
select throws_ok($$select public.complete_setup('student', 2, 10000001, 'weekly', 'beginner', 30, '{}', '{}', true, '{}', '{}', '{}')$$, '22023', null, 'budget above 10 000 000 rejected');
select throws_ok($$select public.complete_setup('student', 2, 5000, 'weekly', 'beginner', 4, '{}', '{}', true, '{}', '{}', '{}')$$, '22023', null, 'cook time below 5 rejected');
select throws_ok($$select public.complete_setup('student', 2, 5000, 'weekly', 'beginner', 30, '{}', '{}', false, '{}', '{}', '{}')$$, '22023', 'consent_required', 'no consent, no setup');
select throws_ok($$select public.complete_setup(null, 2, 5000, 'weekly', 'beginner', 30, '{}', '{}', true, '{}', '{}', '{}')$$, '22023', null, 'missing lifestyle rejected');
select throws_ok($$select public.complete_setup('student', 2, 5000, 'weekly', 'beginner', 30, '{italian}', '{italian}', true, '{}', '{}', '{}')$$, '22023', null, 'liked and disliked at once rejected');
select throws_ok($$select public.complete_setup('student', 2, 5000, 'weekly', 'beginner', 30, '{}', '{}', true, '{}', '{groundnut}', '{}')$$, '22P02', null, 'allergen outside the closed set rejected');

-- Atomicity: an unknown cuisine fails after the preferences insert would
-- have run, and nothing at all is kept.
select throws_ok($$select public.complete_setup('student', 2, 5000, 'weekly', 'beginner', 30, '{no_such_cuisine}', '{}', true, '{}', '{peanuts}', '{}')$$, '23503', null, 'unknown cuisine rejected');
select is((select count(*) from public.user_preferences), 0::bigint, 'a failed call leaves no preferences');
select is((select setup_completed_at from public.profiles), null, 'a failed call leaves setup unfinished');

-- Success.
select lives_ok($$select public.complete_setup('family', 4, 15000, 'weekly', 'intermediate', 60, '{cameroonian,west_african}', '{chinese}', true, '{halal}', '{peanuts,crustaceans,peanuts}', '{eat_healthier}')$$, 'a full, valid answer is accepted');
select ok((select setup_completed_at is not null from public.profiles), 'setup is marked complete');
select is(
  (select row(household_size, budget_amount_xaf, allergens_declared, allergens::text, sensitive_data_consent_at is not null)::text
   from public.user_preferences),
  row(4::smallint, 15000, true, '{crustaceans,peanuts}', true)::text,
  'answers stored; duplicate allergens collapsed; declared and consented'
);
select is(
  (select string_agg(cuisine_slug || ':' || preference, ',' order by cuisine_slug) from public.user_cuisine_preferences),
  'cameroonian:like,chinese:dislike,west_african:like',
  'cuisine likes and dislikes stored'
);

-- "None" for allergies is an answer: declared with an empty list.
select lives_ok($$select public.complete_setup('student', 1, 1000, 'daily', 'beginner', 15, '{}', '{}', true, '{}', '{}', '{}')$$, 'answering again replaces the answers');
select is((select row(allergens_declared, cardinality(allergens))::text from public.user_preferences), row(true, 0)::text, 'no allergies is stored as declared and empty, not as unanswered');

reset role;
select is((select count(*) from public.user_preferences where user_id = '22222222-2222-4222-8222-222222222222'), 0::bigint, 'nothing was written for another user');

select * from finish();
rollback;
