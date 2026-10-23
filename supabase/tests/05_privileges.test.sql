-- Structural guarantees: RLS on every public table, no anon table access,
-- and SECURITY DEFINER functions closed to anon. Also exercises the one
-- client-callable definer function, register_push_token, and the
-- 12-month interaction retention.
begin;
create extension if not exists pgtap with schema extensions;
select plan(15);

select is(
  (select count(*) from pg_class c join pg_namespace n on n.oid = c.relnamespace
   where n.nspname = 'public' and c.relkind in ('r', 'p') and not c.relrowsecurity),
  0::bigint,
  'every table in public has RLS enabled'
);
select is(
  (select count(*) from information_schema.role_table_grants
   where table_schema = 'public' and grantee = 'anon'),
  0::bigint,
  'anon has no privilege on any public table'
);
select is(
  (select count(*) from information_schema.role_column_grants
   where table_schema = 'public' and grantee = 'anon'),
  0::bigint,
  'anon has no column privilege in public'
);
select is(
  (select count(*) from pg_proc p join pg_namespace n on n.oid = p.pronamespace
   where n.nspname in ('public', 'private') and p.prosecdef
     and has_function_privilege('anon', p.oid, 'execute')),
  0::bigint,
  'anon can execute no SECURITY DEFINER function'
);
select is(
  (select count(*) from pg_proc p join pg_namespace n on n.oid = p.pronamespace
   where n.nspname in ('public', 'private') and p.prosecdef
     and not exists (select 1 from unnest(p.proconfig) c where c = 'search_path=""')),
  0::bigint,
  'every SECURITY DEFINER function pins an empty search_path'
);
select ok(not has_schema_privilege('authenticated', 'private', 'usage'), 'authenticated cannot use the private schema');
select ok(not has_function_privilege('authenticated', 'private.handle_new_user()', 'execute'), 'authenticated cannot call the signup trigger function');
select ok(has_function_privilege('authenticated', 'public.register_push_token(text, public.push_platform)', 'execute'), 'authenticated can register push tokens');

-- register_push_token moves a token to whoever registers it last.
insert into auth.users (id, email) values
  ('11111111-1111-4111-8111-111111111111', 'a@test.local'),
  ('22222222-2222-4222-8222-222222222222', 'b@test.local');

set local role authenticated;
select set_config('request.jwt.claims',
  '{"sub":"11111111-1111-4111-8111-111111111111","role":"authenticated"}', true);
select lives_ok($$select public.register_push_token('shared-device', 'android')$$, 'A registers a token');
select throws_ok($$select public.register_push_token('', 'android')$$, '22023', null, 'an empty token is rejected');

select set_config('request.jwt.claims',
  '{"sub":"22222222-2222-4222-8222-222222222222","role":"authenticated"}', true);
select lives_ok($$select public.register_push_token('shared-device', 'android')$$, 'B registers the same device token');
select is((select count(*) from public.push_tokens where token = 'shared-device'), 1::bigint, 'B now sees the token');
reset role;
select is((select user_id from public.push_tokens where token = 'shared-device'), '22222222-2222-4222-8222-222222222222'::uuid, 'the token moved to B');

set local role anon;
select throws_ok($$select public.register_push_token('x', 'ios')$$, '42501', null, 'anon cannot register push tokens');
reset role;

-- Retention: rows older than 12 months are purged, newer ones stay.
insert into public.cuisines (slug, name) values ('test_cuisine', 'Test');
insert into public.recipes (id, slug, title, cuisine_slug, difficulty, servings, is_published)
values ('aaaaaaaa-0000-4000-8000-000000000001', 'test-recipe', 'Test', 'test_cuisine', 'easy', 2, true);
insert into public.recipe_interactions (user_id, recipe_id, interaction, created_at) values
  ('11111111-1111-4111-8111-111111111111', 'aaaaaaaa-0000-4000-8000-000000000001', 'viewed', now() - interval '13 months'),
  ('11111111-1111-4111-8111-111111111111', 'aaaaaaaa-0000-4000-8000-000000000001', 'viewed', now() - interval '11 months');
select private.purge_expired_interactions();
select is((select count(*) from public.recipe_interactions where user_id = '11111111-1111-4111-8111-111111111111'), 1::bigint, 'only the interaction older than 12 months is purged');

select * from finish();
rollback;
