-- SmartMeal schema v1 (P13, owner-approved 2026-10-23).
--
-- Secure by default:
--   * every table has RLS enabled in this migration, one policy per
--     operation, `to authenticated` plus an ownership predicate;
--   * `anon` has no table access; `authenticated` gets only the columns it
--     may write, so `id`, `user_id` and `created_at` can never change;
--   * catalog tables have no client write path (service role / admin only);
--   * the one SECURITY DEFINER function callable by clients is
--     public.register_push_token; the rest live in the unexposed `private`
--     schema. All of them pin `search_path = ''`.
-- Deleting an auth user cascades through profiles to every user row (P14).
-- See context/data-model.md for the ERD and the RLS matrix.

-- ── Privileges baseline ─────────────────────────────────────────────────────

-- Nothing created by this role in `public` is exposed automatically: each
-- table below grants exactly what it needs.
alter default privileges in schema public revoke all on tables from anon, authenticated;
alter default privileges in schema public revoke all on sequences from anon, authenticated;
alter default privileges in schema public revoke execute on functions from public, anon, authenticated;

-- Internal helpers, not reachable through the Data API.
create schema private;
revoke all on schema private from public, anon, authenticated;

-- ── Vocabularies (closed sets; values may be added, never removed) ───────────

-- One allergen set shared by recipes and user preferences, so the allergen
-- filter is exact (S11). Groundnuts = peanuts; dried crayfish = crustaceans.
create type public.allergen as enum (
  'gluten', 'crustaceans', 'molluscs', 'fish', 'eggs', 'milk', 'peanuts',
  'tree_nuts', 'soy', 'sesame', 'celery', 'mustard', 'sulphites', 'lupin'
);
create type public.dietary_tag as enum (
  'vegetarian', 'vegan', 'pescatarian', 'halal', 'gluten_free', 'dairy_free',
  'low_carb'
);
create type public.health_goal as enum (
  'lose_weight', 'maintain_weight', 'gain_muscle', 'eat_healthier',
  'manage_blood_sugar'
);
create type public.lifestyle as enum (
  'student', 'working_professional', 'family', 'athlete'
);
create type public.cooking_skill as enum ('beginner', 'intermediate', 'advanced');
create type public.budget_period as enum ('daily', 'weekly', 'monthly');
create type public.cuisine_preference as enum ('like', 'dislike');
create type public.recipe_difficulty as enum ('easy', 'medium', 'hard');
create type public.meal_slot as enum ('breakfast', 'lunch', 'dinner', 'snack');
create type public.interaction_type as enum (
  'viewed', 'favorited', 'unfavorited', 'planned', 'cooked', 'dismissed', 'rated'
);
create type public.push_platform as enum ('android', 'ios');

-- ── Shared trigger: updated_at ──────────────────────────────────────────────

create function private.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;
revoke execute on function private.set_updated_at() from public, anon, authenticated;

-- ── profiles ────────────────────────────────────────────────────────────────

create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  display_name text check (char_length(display_name) between 1 and 80),
  -- Always inside the owner's avatars folder: `{id}/…`.
  avatar_path text check (
    char_length(avatar_path) <= 512 and avatar_path like id::text || '/%'
  ),
  country_code char(2) not null default 'CM' check (country_code ~ '^[A-Z]{2}$'),
  currency_code char(3) not null default 'XAF' check (currency_code ~ '^[A-Z]{3}$'),
  onboarding_completed_at timestamptz,
  setup_completed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
alter table public.profiles enable row level security;

create trigger profiles_set_updated_at
  before update on public.profiles
  for each row execute function private.set_updated_at();

-- Rows are created by the signup trigger and removed by account deletion,
-- so clients only read and update their own.
grant select on public.profiles to authenticated;
grant update (
  display_name, avatar_path, country_code, currency_code,
  onboarding_completed_at, setup_completed_at
) on public.profiles to authenticated;

create policy "profiles: select own" on public.profiles
  for select to authenticated
  using ((select auth.uid()) = id);
create policy "profiles: update own" on public.profiles
  for update to authenticated
  using ((select auth.uid()) = id)
  with check ((select auth.uid()) = id);

-- Signup trigger. SECURITY DEFINER because the auth service inserts users
-- as a role with no rights on public.profiles. user_metadata is
-- user-controlled: used only as a display-name suggestion, never for
-- authorization.
create function private.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, display_name)
  values (
    new.id,
    nullif(btrim(left(coalesce(new.raw_user_meta_data ->> 'full_name', ''), 80)), '')
  );
  return new;
end;
$$;
revoke execute on function private.handle_new_user() from public, anon, authenticated;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function private.handle_new_user();

-- ── user_preferences (setup answers; sensitive data, S6) ────────────────────

create table public.user_preferences (
  user_id uuid primary key default auth.uid()
    references public.profiles (id) on delete cascade,
  lifestyle public.lifestyle,
  household_size smallint check (household_size between 1 and 20),
  -- XAF has no minor unit: whole francs.
  budget_amount_xaf integer check (budget_amount_xaf between 0 and 10000000),
  budget_period public.budget_period,
  cooking_skill public.cooking_skill,
  max_cook_minutes smallint check (max_cook_minutes between 5 and 480),
  dietary_tags public.dietary_tag[] not null default '{}'
    check (cardinality(dietary_tags) <= 20 and array_position(dietary_tags, null) is null),
  allergens public.allergen[] not null default '{}'
    check (cardinality(allergens) <= 20 and array_position(allergens, null) is null),
  -- Separates "no allergies" (declared, empty) from "not answered".
  allergens_declared boolean not null default false,
  health_goals public.health_goal[] not null default '{}'
    check (cardinality(health_goals) <= 20 and array_position(health_goals, null) is null),
  sensitive_data_consent_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint budget_amount_and_period_together
    check ((budget_amount_xaf is null) = (budget_period is null)),
  constraint allergens_only_when_declared
    check (allergens_declared or cardinality(allergens) = 0),
  -- S6: allergy, diet and health data only after explicit consent.
  constraint sensitive_data_needs_consent check (
    sensitive_data_consent_at is not null
    or (
      not allergens_declared
      and cardinality(allergens) = 0
      and cardinality(dietary_tags) = 0
      and cardinality(health_goals) = 0
    )
  )
);
alter table public.user_preferences enable row level security;

create trigger user_preferences_set_updated_at
  before update on public.user_preferences
  for each row execute function private.set_updated_at();

grant select, delete on public.user_preferences to authenticated;
grant insert (
  user_id, lifestyle, household_size, budget_amount_xaf, budget_period,
  cooking_skill, max_cook_minutes, dietary_tags, allergens, allergens_declared,
  health_goals, sensitive_data_consent_at
) on public.user_preferences to authenticated;
grant update (
  lifestyle, household_size, budget_amount_xaf, budget_period, cooking_skill,
  max_cook_minutes, dietary_tags, allergens, allergens_declared, health_goals,
  sensitive_data_consent_at
) on public.user_preferences to authenticated;

create policy "user_preferences: select own" on public.user_preferences
  for select to authenticated
  using ((select auth.uid()) = user_id);
create policy "user_preferences: insert own" on public.user_preferences
  for insert to authenticated
  with check ((select auth.uid()) = user_id);
create policy "user_preferences: update own" on public.user_preferences
  for update to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);
create policy "user_preferences: delete own" on public.user_preferences
  for delete to authenticated
  using ((select auth.uid()) = user_id);

-- ── cuisines (lookup; grows over time) ──────────────────────────────────────

create table public.cuisines (
  slug text primary key check (slug ~ '^[a-z0-9]+(_[a-z0-9]+)*$' and char_length(slug) <= 40),
  name text not null check (char_length(name) between 1 and 60),
  region text check (char_length(region) between 1 and 60)
);
alter table public.cuisines enable row level security;

grant select on public.cuisines to authenticated;

create policy "cuisines: select all" on public.cuisines
  for select to authenticated
  using (true);

-- ── user_cuisine_preferences ────────────────────────────────────────────────

create table public.user_cuisine_preferences (
  user_id uuid not null default auth.uid()
    references public.profiles (id) on delete cascade,
  cuisine_slug text not null references public.cuisines (slug) on delete cascade,
  preference public.cuisine_preference not null,
  created_at timestamptz not null default now(),
  primary key (user_id, cuisine_slug)
);
create index user_cuisine_preferences_cuisine_slug_idx
  on public.user_cuisine_preferences (cuisine_slug);
alter table public.user_cuisine_preferences enable row level security;

grant select, delete on public.user_cuisine_preferences to authenticated;
grant insert (user_id, cuisine_slug, preference) on public.user_cuisine_preferences to authenticated;
grant update (preference) on public.user_cuisine_preferences to authenticated;

create policy "user_cuisine_preferences: select own" on public.user_cuisine_preferences
  for select to authenticated
  using ((select auth.uid()) = user_id);
create policy "user_cuisine_preferences: insert own" on public.user_cuisine_preferences
  for insert to authenticated
  with check ((select auth.uid()) = user_id);
create policy "user_cuisine_preferences: update own" on public.user_cuisine_preferences
  for update to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);
create policy "user_cuisine_preferences: delete own" on public.user_cuisine_preferences
  for delete to authenticated
  using ((select auth.uid()) = user_id);

-- ── recipes (catalog; read-only for clients) ────────────────────────────────

create table public.recipes (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique
    check (slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$' and char_length(slug) <= 80),
  title text not null check (char_length(title) between 1 and 120),
  summary text check (char_length(summary) <= 500),
  cuisine_slug text not null references public.cuisines (slug),
  image_path text check (char_length(image_path) <= 512),
  prep_minutes smallint not null default 0 check (prep_minutes between 0 and 1440),
  cook_minutes smallint not null default 0 check (cook_minutes between 0 and 1440),
  difficulty public.recipe_difficulty not null,
  servings smallint not null check (servings between 1 and 50),
  -- Whole recipe, whole francs; null while unknown.
  est_cost_xaf integer check (est_cost_xaf >= 0),
  dietary_tags public.dietary_tag[] not null default '{}'
    check (array_position(dietary_tags, null) is null),
  -- Never null: an empty set means "contains none of the listed allergens".
  allergens public.allergen[] not null default '{}'
    check (array_position(allergens, null) is null),
  is_published boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index recipes_cuisine_slug_idx on public.recipes (cuisine_slug);
create index recipes_published_idx on public.recipes (id) where is_published;
-- Allergen exclusion (`not allergens && …`) and diet filters.
create index recipes_allergens_idx on public.recipes using gin (allergens);
create index recipes_dietary_tags_idx on public.recipes using gin (dietary_tags);
alter table public.recipes enable row level security;

create trigger recipes_set_updated_at
  before update on public.recipes
  for each row execute function private.set_updated_at();

grant select on public.recipes to authenticated;

create policy "recipes: select published" on public.recipes
  for select to authenticated
  using (is_published);

create table public.recipe_ingredients (
  recipe_id uuid not null references public.recipes (id) on delete cascade,
  position smallint not null check (position between 1 and 200),
  name text not null check (char_length(name) between 1 and 120),
  -- Null for "to taste".
  quantity numeric(10, 3) check (quantity > 0),
  unit text check (char_length(unit) between 1 and 20),
  est_cost_xaf integer check (est_cost_xaf >= 0),
  primary key (recipe_id, position)
);
alter table public.recipe_ingredients enable row level security;

grant select on public.recipe_ingredients to authenticated;

create policy "recipe_ingredients: select when published" on public.recipe_ingredients
  for select to authenticated
  using (exists (
    select 1 from public.recipes r
    where r.id = recipe_id and r.is_published
  ));

create table public.recipe_steps (
  recipe_id uuid not null references public.recipes (id) on delete cascade,
  position smallint not null check (position between 1 and 100),
  instruction text not null check (char_length(instruction) between 1 and 2000),
  primary key (recipe_id, position)
);
alter table public.recipe_steps enable row level security;

grant select on public.recipe_steps to authenticated;

create policy "recipe_steps: select when published" on public.recipe_steps
  for select to authenticated
  using (exists (
    select 1 from public.recipes r
    where r.id = recipe_id and r.is_published
  ));

-- ── favorites ───────────────────────────────────────────────────────────────

create table public.favorites (
  user_id uuid not null default auth.uid()
    references public.profiles (id) on delete cascade,
  recipe_id uuid not null references public.recipes (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, recipe_id)
);
create index favorites_recipe_id_idx on public.favorites (recipe_id);
alter table public.favorites enable row level security;

grant select, delete on public.favorites to authenticated;
grant insert (user_id, recipe_id) on public.favorites to authenticated;

create policy "favorites: select own" on public.favorites
  for select to authenticated
  using ((select auth.uid()) = user_id);
-- A foreign key does not go through RLS, so the published check is here.
create policy "favorites: insert own, published recipes" on public.favorites
  for insert to authenticated
  with check (
    (select auth.uid()) = user_id
    and exists (select 1 from public.recipes r where r.id = recipe_id and r.is_published)
  );
create policy "favorites: delete own" on public.favorites
  for delete to authenticated
  using ((select auth.uid()) = user_id);

-- ── meal_plans / meal_plan_entries ──────────────────────────────────────────

create table public.meal_plans (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid()
    references public.profiles (id) on delete cascade,
  -- ISO week: always a Monday.
  week_start date not null check (extract(isodow from week_start) = 1),
  created_at timestamptz not null default now(),
  unique (user_id, week_start),
  -- Target of the entries' composite key, which pins entries to the week.
  unique (id, week_start)
);
alter table public.meal_plans enable row level security;

-- No update: a plan's week never changes; delete and recreate instead.
grant select, delete on public.meal_plans to authenticated;
grant insert (user_id, week_start) on public.meal_plans to authenticated;

create policy "meal_plans: select own" on public.meal_plans
  for select to authenticated
  using ((select auth.uid()) = user_id);
create policy "meal_plans: insert own" on public.meal_plans
  for insert to authenticated
  with check ((select auth.uid()) = user_id);
create policy "meal_plans: delete own" on public.meal_plans
  for delete to authenticated
  using ((select auth.uid()) = user_id);

create table public.meal_plan_entries (
  id uuid primary key default gen_random_uuid(),
  meal_plan_id uuid not null,
  -- Copy of the plan's week_start (enforced by the composite key), so the
  -- date range can be a plain CHECK.
  week_start date not null,
  plan_date date not null,
  meal_slot public.meal_slot not null,
  recipe_id uuid not null references public.recipes (id) on delete cascade,
  servings smallint not null default 1 check (servings between 1 and 20),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  foreign key (meal_plan_id, week_start)
    references public.meal_plans (id, week_start) on delete cascade,
  check (plan_date between week_start and week_start + 6),
  unique (meal_plan_id, plan_date, meal_slot)
);
create index meal_plan_entries_recipe_id_idx on public.meal_plan_entries (recipe_id);
create index meal_plan_entries_plan_week_idx on public.meal_plan_entries (meal_plan_id, week_start);
alter table public.meal_plan_entries enable row level security;

create trigger meal_plan_entries_set_updated_at
  before update on public.meal_plan_entries
  for each row execute function private.set_updated_at();

grant select, delete on public.meal_plan_entries to authenticated;
grant insert (meal_plan_id, week_start, plan_date, meal_slot, recipe_id, servings)
  on public.meal_plan_entries to authenticated;
grant update (plan_date, meal_slot, recipe_id, servings)
  on public.meal_plan_entries to authenticated;

create policy "meal_plan_entries: select own" on public.meal_plan_entries
  for select to authenticated
  using (exists (
    select 1 from public.meal_plans p
    where p.id = meal_plan_id and p.user_id = (select auth.uid())
  ));
create policy "meal_plan_entries: insert own, published recipes" on public.meal_plan_entries
  for insert to authenticated
  with check (
    exists (
      select 1 from public.meal_plans p
      where p.id = meal_plan_id and p.user_id = (select auth.uid())
    )
    and exists (select 1 from public.recipes r where r.id = recipe_id and r.is_published)
  );
create policy "meal_plan_entries: update own, published recipes" on public.meal_plan_entries
  for update to authenticated
  using (exists (
    select 1 from public.meal_plans p
    where p.id = meal_plan_id and p.user_id = (select auth.uid())
  ))
  with check (
    exists (
      select 1 from public.meal_plans p
      where p.id = meal_plan_id and p.user_id = (select auth.uid())
    )
    and exists (select 1 from public.recipes r where r.id = recipe_id and r.is_published)
  );
create policy "meal_plan_entries: delete own" on public.meal_plan_entries
  for delete to authenticated
  using (exists (
    select 1 from public.meal_plans p
    where p.id = meal_plan_id and p.user_id = (select auth.uid())
  ));

-- ── recipe_interactions (learning signal; append-only for clients) ──────────

create table public.recipe_interactions (
  id bigint generated always as identity primary key,
  user_id uuid not null default auth.uid()
    references public.profiles (id) on delete cascade,
  recipe_id uuid not null references public.recipes (id) on delete cascade,
  interaction public.interaction_type not null,
  rating smallint check (rating between 1 and 5),
  created_at timestamptz not null default now(),
  -- A rating comes with "rated" and only with it.
  check ((interaction = 'rated') = (rating is not null))
);
create index recipe_interactions_user_created_idx
  on public.recipe_interactions (user_id, created_at desc);
create index recipe_interactions_recipe_id_idx on public.recipe_interactions (recipe_id);
-- Retention sweeps scan by age.
create index recipe_interactions_created_at_idx
  on public.recipe_interactions using brin (created_at);
alter table public.recipe_interactions enable row level security;

grant select on public.recipe_interactions to authenticated;
grant insert (user_id, recipe_id, interaction, rating)
  on public.recipe_interactions to authenticated;

create policy "recipe_interactions: select own" on public.recipe_interactions
  for select to authenticated
  using ((select auth.uid()) = user_id);
create policy "recipe_interactions: insert own, published recipes" on public.recipe_interactions
  for insert to authenticated
  with check (
    (select auth.uid()) = user_id
    and exists (select 1 from public.recipes r where r.id = recipe_id and r.is_published)
  );

-- Retention: 12 months (owner, 2026-10-23). Scheduled with pg_cron below.
create function private.purge_expired_interactions()
returns void
language sql
set search_path = ''
as $$
  delete from public.recipe_interactions
  where created_at < now() - interval '12 months';
$$;
revoke execute on function private.purge_expired_interactions() from public, anon, authenticated;

-- ── push_tokens ─────────────────────────────────────────────────────────────

create table public.push_tokens (
  token text primary key check (char_length(token) between 1 and 4096),
  user_id uuid not null references public.profiles (id) on delete cascade,
  platform public.push_platform not null,
  created_at timestamptz not null default now(),
  last_seen_at timestamptz not null default now()
);
create index push_tokens_user_id_idx on public.push_tokens (user_id);
alter table public.push_tokens enable row level security;

-- Writes only through register_push_token (a token moves to whoever
-- registers it last: shared devices).
grant select, delete on public.push_tokens to authenticated;

create policy "push_tokens: select own" on public.push_tokens
  for select to authenticated
  using ((select auth.uid()) = user_id);
create policy "push_tokens: delete own" on public.push_tokens
  for delete to authenticated
  using ((select auth.uid()) = user_id);

-- SECURITY DEFINER: reassigning a token means updating another user's row,
-- which RLS rightly forbids to the caller. The caller is always auth.uid().
create function public.register_push_token(p_token text, p_platform public.push_platform)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  caller uuid := auth.uid();
begin
  if caller is null then
    raise exception 'not authenticated' using errcode = '42501';
  end if;
  if p_token is null or char_length(p_token) not between 1 and 4096 then
    raise exception 'invalid push token' using errcode = '22023';
  end if;
  if p_platform is null then
    raise exception 'invalid platform' using errcode = '22023';
  end if;

  insert into public.push_tokens (token, user_id, platform)
  values (p_token, caller, p_platform)
  on conflict (token) do update
    set user_id = excluded.user_id,
        platform = excluded.platform,
        last_seen_at = now();
end;
$$;
revoke execute on function public.register_push_token(text, public.push_platform) from public, anon;
grant execute on function public.register_push_token(text, public.push_platform) to authenticated;

-- ── Belt and braces: nothing in public for anon ─────────────────────────────

revoke all on all tables in schema public from anon;
revoke all on all sequences in schema public from anon;

-- ── Storage ─────────────────────────────────────────────────────────────────

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values
  -- Public read through public URLs; no client writes (no policies).
  ('recipe-images', 'recipe-images', true, 5242880,
   array['image/jpeg', 'image/png', 'image/webp']),
  -- Private; each user owns `{uid}/…`.
  ('avatars', 'avatars', false, 5242880,
   array['image/jpeg', 'image/png', 'image/webp'])
on conflict (id) do nothing;

create policy "avatars: select own folder" on storage.objects
  for select to authenticated
  using (bucket_id = 'avatars' and (storage.foldername(name))[1] = (select auth.uid())::text);
create policy "avatars: insert own folder" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'avatars' and (storage.foldername(name))[1] = (select auth.uid())::text);
create policy "avatars: update own folder" on storage.objects
  for update to authenticated
  using (bucket_id = 'avatars' and (storage.foldername(name))[1] = (select auth.uid())::text)
  with check (bucket_id = 'avatars' and (storage.foldername(name))[1] = (select auth.uid())::text);
create policy "avatars: delete own folder" on storage.objects
  for delete to authenticated
  using (bucket_id = 'avatars' and (storage.foldername(name))[1] = (select auth.uid())::text);

-- ── Scheduled jobs ──────────────────────────────────────────────────────────

create extension if not exists pg_cron with schema pg_catalog;

select cron.schedule(
  'purge-expired-recipe-interactions',
  '17 3 * * *',
  $$select private.purge_expired_interactions()$$
);
