-- Per-user rate limit for the delete-account Edge Function (P14).
--
-- Only the service role (the Edge Function's admin client) can touch it.
-- No foreign key to auth.users on purpose: the counter must still work for
-- a retry after the user is already deleted (the function is idempotent).
-- It holds only a user ID and a counter, and rows older than a day are
-- swept on every call.

create table private.account_deletion_attempts (
  user_id uuid primary key,
  window_start timestamptz not null default now(),
  attempts integer not null default 1 check (attempts >= 1)
);
alter table private.account_deletion_attempts enable row level security;

revoke all on private.account_deletion_attempts from public, anon, authenticated;
grant usage on schema private to service_role;
grant select, insert, update, delete on private.account_deletion_attempts to service_role;

-- True while the caller is within 5 attempts per rolling hour.
create function public.note_account_deletion_attempt(p_user_id uuid)
returns boolean
language plpgsql
security invoker
set search_path = ''
as $$
declare
  current_attempts integer;
begin
  delete from private.account_deletion_attempts
  where window_start < now() - interval '1 day';

  insert into private.account_deletion_attempts as a (user_id)
  values (p_user_id)
  on conflict (user_id) do update
    set attempts = case
          when a.window_start < now() - interval '1 hour' then 1
          else a.attempts + 1
        end,
        window_start = case
          when a.window_start < now() - interval '1 hour' then now()
          else a.window_start
        end
  returning attempts into current_attempts;

  return current_attempts <= 5;
end;
$$;
revoke execute on function public.note_account_deletion_attempt(uuid) from public, anon, authenticated;
grant execute on function public.note_account_deletion_attempt(uuid) to service_role;
