-- Setup flow (P16): cuisine reference data and the atomic complete_setup().

-- ── Cuisines: permanent reference data (owner, 2026-10-24) ──────────────────
-- Names are what users read, in plain words; the app adds familiar dish
-- examples per slug. More can be added later (insert, never rename slugs).
insert into public.cuisines (slug, name, region) values
  ('cameroonian', 'Cameroonian food', 'Central Africa'),
  ('west_african', 'West African food', 'West Africa'),
  ('italian', 'Italian food', 'Europe'),
  ('french', 'French food', 'Europe'),
  ('indian', 'Indian food', 'South Asia'),
  ('chinese', 'Chinese food', 'East Asia')
on conflict (slug) do nothing;

-- ── complete_setup ──────────────────────────────────────────────────────────
-- Saves every setup answer and marks setup complete in ONE transaction:
-- user_preferences, the cuisine likes/dislikes and
-- profiles.setup_completed_at either all change or none do.
--
-- SECURITY INVOKER: it runs as the caller, so RLS and the column grants of
-- P13 apply to every write; it can only ever touch the caller's own rows.
-- Inputs are validated here (S3) even though the app validates too.
-- Sensitive answers require explicit consent (S6, owner: consent required).
create function public.complete_setup(
  p_lifestyle public.lifestyle,
  p_household_size integer,
  p_budget_amount_xaf integer,
  p_budget_period public.budget_period,
  p_cooking_skill public.cooking_skill,
  p_max_cook_minutes integer,
  p_cuisine_likes text[],
  p_cuisine_dislikes text[],
  p_sensitive_data_consent boolean,
  p_dietary_tags public.dietary_tag[],
  p_allergens public.allergen[],
  p_health_goals public.health_goal[]
)
returns timestamptz
language plpgsql
security invoker
set search_path = ''
as $$
declare
  caller uuid := auth.uid();
  completed_at timestamptz := now();
  likes text[];
  dislikes text[];
begin
  if caller is null then
    raise exception 'not authenticated' using errcode = '42501';
  end if;

  if p_lifestyle is null or p_budget_period is null or p_cooking_skill is null then
    raise exception 'invalid_answer: a required answer is missing' using errcode = '22023';
  end if;
  if p_household_size is null or p_household_size not between 1 and 20 then
    raise exception 'invalid_answer: household_size' using errcode = '22023';
  end if;
  -- At least 1 FCFA: a zero budget would make budget fit meaningless. Low
  -- budgets are advised against in the app, never refused (owner).
  if p_budget_amount_xaf is null or p_budget_amount_xaf not between 1 and 10000000 then
    raise exception 'invalid_answer: budget_amount_xaf' using errcode = '22023';
  end if;
  if p_max_cook_minutes is null or p_max_cook_minutes not between 5 and 480 then
    raise exception 'invalid_answer: max_cook_minutes' using errcode = '22023';
  end if;
  if p_sensitive_data_consent is distinct from true then
    raise exception 'consent_required' using errcode = '22023';
  end if;
  if p_dietary_tags is null or p_allergens is null or p_health_goals is null
     or p_cuisine_likes is null or p_cuisine_dislikes is null
     or array_position(p_dietary_tags, null) is not null
     or array_position(p_allergens, null) is not null
     or array_position(p_health_goals, null) is not null
     or array_position(p_cuisine_likes, null) is not null
     or array_position(p_cuisine_dislikes, null) is not null then
    raise exception 'invalid_answer: lists must be present and contain no nulls'
      using errcode = '22023';
  end if;

  likes := array(select distinct s from unnest(p_cuisine_likes) s order by s);
  dislikes := array(select distinct s from unnest(p_cuisine_dislikes) s order by s);
  if cardinality(likes) > 50 or cardinality(dislikes) > 50 then
    raise exception 'invalid_answer: too many cuisines' using errcode = '22023';
  end if;
  if likes && dislikes then
    raise exception 'invalid_answer: a cuisine cannot be liked and disliked'
      using errcode = '22023';
  end if;

  insert into public.user_preferences as p (
    user_id, lifestyle, household_size, budget_amount_xaf, budget_period,
    cooking_skill, max_cook_minutes, dietary_tags, allergens,
    allergens_declared, health_goals, sensitive_data_consent_at
  ) values (
    caller, p_lifestyle, p_household_size, p_budget_amount_xaf, p_budget_period,
    p_cooking_skill, p_max_cook_minutes,
    array(select distinct t from unnest(p_dietary_tags) t order by t),
    array(select distinct a from unnest(p_allergens) a order by a),
    -- The allergy question is always answered in setup: an empty list
    -- means "None", never "not answered".
    true,
    array(select distinct g from unnest(p_health_goals) g order by g),
    completed_at
  )
  on conflict (user_id) do update set
    lifestyle = excluded.lifestyle,
    household_size = excluded.household_size,
    budget_amount_xaf = excluded.budget_amount_xaf,
    budget_period = excluded.budget_period,
    cooking_skill = excluded.cooking_skill,
    max_cook_minutes = excluded.max_cook_minutes,
    dietary_tags = excluded.dietary_tags,
    allergens = excluded.allergens,
    allergens_declared = excluded.allergens_declared,
    health_goals = excluded.health_goals,
    sensitive_data_consent_at = excluded.sensitive_data_consent_at;

  delete from public.user_cuisine_preferences where user_id = caller;
  insert into public.user_cuisine_preferences (user_id, cuisine_slug, preference)
  select caller, s, 'like'::public.cuisine_preference from unnest(likes) s
  union all
  select caller, s, 'dislike'::public.cuisine_preference from unnest(dislikes) s;

  update public.profiles
  set setup_completed_at = completed_at
  where id = caller;

  return completed_at;
end;
$$;

revoke execute on function public.complete_setup(
  public.lifestyle, integer, integer, public.budget_period, public.cooking_skill,
  integer, text[], text[], boolean, public.dietary_tag[], public.allergen[],
  public.health_goal[]
) from public, anon;
grant execute on function public.complete_setup(
  public.lifestyle, integer, integer, public.budget_period, public.cooking_skill,
  integer, text[], text[], boolean, public.dietary_tag[], public.allergen[],
  public.health_goal[]
) to authenticated;
