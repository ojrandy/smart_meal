-- The delete-account rate limit: only the service role may count attempts,
-- five per rolling hour are allowed, and an expired window starts over.
begin;
create extension if not exists pgtap with schema extensions;
select plan(9);

select ok(not has_function_privilege('anon', 'public.note_account_deletion_attempt(uuid)', 'execute'), 'anon cannot count attempts');
select ok(not has_function_privilege('authenticated', 'public.note_account_deletion_attempt(uuid)', 'execute'), 'authenticated cannot count attempts');
select ok(has_function_privilege('service_role', 'public.note_account_deletion_attempt(uuid)', 'execute'), 'service_role can count attempts');
select ok(not has_table_privilege('authenticated', 'private.account_deletion_attempts', 'select'), 'authenticated cannot read the counters');

set local role service_role;
select is(
  (select array_agg(public.note_account_deletion_attempt('11111111-1111-4111-8111-111111111111'))
   from generate_series(1, 5)),
  array[true, true, true, true, true],
  'the first five attempts are allowed'
);
select is(public.note_account_deletion_attempt('11111111-1111-4111-8111-111111111111'), false, 'the sixth within the hour is refused');
select is(public.note_account_deletion_attempt('22222222-2222-4222-8222-222222222222'), true, 'another user has their own limit');
reset role;

update private.account_deletion_attempts
set window_start = now() - interval '61 minutes'
where user_id = '11111111-1111-4111-8111-111111111111';

set local role service_role;
select is(public.note_account_deletion_attempt('11111111-1111-4111-8111-111111111111'), true, 'after an hour the window starts over');
reset role;

select is(
  (select attempts from private.account_deletion_attempts
   where user_id = '11111111-1111-4111-8111-111111111111'),
  1,
  'the counter was reset'
);

select * from finish();
rollback;
