# SmartMeal — Login Flow Personalization Prompt Pack (LF)

> **Version** 1.0 · **Authored** 2026-10-29 · **Basis** owner feedback on the setup flow (2026-10-28/29), the code on `main` after P16 + L10N, and schema v1 (`supabase/migrations/`)
> **Status lives in [`prompt-tracker.md`](prompt-tracker.md)** (rows LF01–LF05). This file holds instructions only, never status.
> All paths are relative to the repository root.

---

## How to use this pack (operator instructions)

This pack extends [`prompt.md`](prompt.md). It covers what happens **between sign-in and the first Home screen**: the setup questions, the data behind them, and the first personalized recommendations. It also defines **My Kitchen**, because setup seeds it and the recommendation engine depends on it.

1. Run the prompts in ID order. A prompt may start only when every prompt in its **Depends on** field is ✅ in the tracker.
2. **P17 now depends on LF04.** The engine is built once, with kitchen, health and nutrition rules from day one, not retrofitted later. Appendix A lists the changes to the P17 spec.
3. Fill every input a prompt lists in the tracker's **Inputs register** before starting it. An unfilled `{{PLACEHOLDER}}` means stop and ask.
4. Start a fresh agent session per prompt and send exactly:

   ```text
   Read docs/prompt.md §0 and docs/promptLoginFlow.md §0 in full, then execute prompt LF01 from docs/promptLoginFlow.md.
   Inputs: <values from the Inputs register, or "none">
   Commits: authorized | not authorized
   ```

### Prompt index

| ID | Title | Priority | Depends on |
|---|---|---|---|
| [LF01](#lf01--food-catalog-ingredients-prices-and-nutrients) | Food catalog: ingredients, prices and nutrients | 🔴 Critical | P16 |
| [LF02](#lf02--setup-v2-data-model-and-atomic-completion) | Setup v2 data model and atomic completion | 🔴 Critical | LF01 |
| [LF03](#lf03--setup-v2-screens) | Setup v2 screens | 🔴 Critical | LF02, L10N |
| [LF04](#lf04--health-rules-and-nutrition-targets) | Health rules and nutrition targets | 🔴 Critical | LF01, LF02 (merges to `main` only after the doctor signs) |
| [LF05](#lf05--my-kitchen-the-store-room) | My Kitchen (the store room) | 🟠 High | LF03, LF04, P18 |

---

## §0 Rules for this pack

Everything in `docs/prompt.md` §0 applies unchanged (role, mandatory reading, non-negotiables, S1–S12, workflow, Definition of Done, tracker protocol, commits, report format, placeholders). This section adds the rules that health and money data require. If the two disagree, the stricter rule wins.

### 0.1 Owner decisions this pack implements

| # | Decision (owner, 2026-10-29) | Consequence |
|---|---|---|
| D1 | Food items carry an **estimated market price per kg**, and **per litre** for palm oil and vegetable oil | A canonical ingredient catalog (LF01) that recipes and kitchens both point to. Items sold by the unit in Cameroonian markets (eggs, bouillon cubes, plantain) are priced **per piece**: you can't price an egg per kg at the market |
| D2 | The setup "At home" answer personalizes the **first** recommendations. After that, **My Kitchen** is the store room the user keeps stocked, and the engine learns from it | Setup records *which* items are at home (yes/no). My Kitchen records *how much* (kg / L / pieces) and stays current |
| D3 | Health conditions approved as proposed, including "Me / Someone I cook for", applied to the whole household | LF02 schema, LF03 screen, LF04 rules |
| D4 | "Gain weight" becomes a goal, with different calculations for men and women; remove everything unnecessary | Weight goal = one required choice (lose / keep / gain). Sex, age, height, weight and activity feed the energy calculation. Overlapping goals are retired (§0.4) |

**Owner answers, 2026-10-29 (second round):**
- The agent researches the prices and keeps them in the repo. Done: [`reference/ingredient-prices-cm.md`](reference/ingredient-prices-cm.md).
- The doctor signs the health rules and the lawyer confirms the data handling **once the build is done**. So LF02 and LF04 are built and tested on their branches, but nothing that depends on a sign-off reaches `main` before it: the GitHub integration deploys every migration on `main` to production.
- A2 and A3 approved.

**Owner answers, 2026-10-29 (LF01 plan approval):**
- Plan approved; P16 checked on the phone ("everything is perfect").
- Activate all foods and recipes, priced as retailed (per ball, bundle, heap or pack, unless the user buys in bulk): ndolé and eru from 1 000 FCFA, crayfish 100 FCFA a pack, smoked fish 200–500 FCFA a piece, pepper and green spices from 100 FCFA, spaghetti 250 / 500 FCFA by pack size. Foods still without a price get local-only placeholders for the seed (a + b); production keeps them inactive until priced.
- Plantain is priced per finger (owner 2026-10-29: a heap of 5–8 fingers from 1 000 FCFA, good big ones about 4 000 FCFA or more), as D1 says; an edible-portion factor is added; frying oil stores the absorbed amount and the rest stays in My Kitchen (LF05); water is bottled drinking water (400 FCFA per 1.5 L, 1 500 FCFA per 6 × 1.5 L, 1 200 FCFA per 10 L); missing-price rows are dated the day the list was checked; staples, local names and the cautious bouillon / curry allergens approved.
- `NUTRIENT_SOURCE`: the agent compares the sources and uses the best. Done: FAO/INFOODS WAFCT 2019 first, USDA FoodData Central for the gaps (method page, "Nutrients"). The owner wants nutrition data linked through APIs; the catalog stores each food's WAFCT code and USDA id so a server-side refresh can call the USDA API later. The app itself never calls a nutrition API (H5, S1).

### 0.2 Analyst defaults (A2 and A3 approved by the owner 2026-10-29; the rest confirmed at plan approval)

| # | Default | Why |
|---|---|---|
| A1 | The "At home" step is **required**: pick items, or explicitly "Nothing at home right now". "None" is an answer, as for allergies | "Forced" with no dead end: the engine always knows the kitchen state |
| A2 | My Kitchen is **not** a sixth tab; it opens from a Home card and from the Planner. Input `{{KITCHEN_ENTRY_POINT}}` | The bottom bar already has five destinations (Material maximum); adding one is a redesign |
| A3 | Existing users (setup v1 complete) are **not** sent through all 12 steps again. They see consent v2 and the four new or changed steps only, then land on Home | The answers they gave stay valid; re-asking them wastes their time |
| A4 | Body data stores the **current** value only (no weight history), and **birth year**, not full birth date | Data minimization (S6). A weight history is nutrition tracking, which `project-overview.md` lists as long-term |
| A5 | Missing nutrition data **fails closed**: a recipe whose nutrients are incomplete is never shown to a user whose health rules need those nutrients | The same principle as S11 for allergens |

### 0.3 Health safety rules — every LF change must satisfy all of these

| # | Rule |
|---|---|
| H1 | **Health rules are hard filters, enforced server-side**, exactly like S11. The app never decides what is safe; it displays what the server returns. |
| H2 | **Fail closed.** An unlinked ingredient, a missing nutrient or an unknown condition rule removes the recipe for affected users. It never silently passes. |
| H3 | **No invented clinical numbers.** Every threshold (sodium cap, carb portion, calorie surplus, protein target, age limit) comes from the `{{MEDICAL_RULES}}` table signed off by `{{MEDICAL_REVIEWER}}`. An agent may draft values, labelled *draft*, but never ships them unreviewed. |
| H4 | **No medical claims.** Copy never says *treat, cure, heal, reverse* or *guaranteed*. Every health screen shows the approved `{{HEALTH_DISCLAIMER_COPY}}`. Type 1 diabetes, kidney disease, pregnancy and breastfeeding also show the "talk to your doctor or dietitian" notice. |
| H5 | **Health data stays server-side** and is used only to filter and score the owner's own recommendations. Never in logs (S4), analytics, push payloads or third-party calls, and never sent to an LLM. A future LLM explanation feature needs a new consent first. |
| H6 | **Conflicting rules: the stricter one wins** (e.g. kidney disease limits potassium even when the hypertension rules favour it). The precedence order is part of `{{MEDICAL_RULES}}`. |

### 0.4 What this pack deliberately leaves out

These were considered and rejected as unnecessary for this phase. Do not build them; log any request for them as an owner decision.

- Free-text "Other condition" or "Other food". The engine can't act on free text, and it collects data we can't use.
- Pregnancy trimester, HbA1c, blood pressure readings, lab values, medication lists (except the yes/no insulin question).
- Target weight, weekly weigh-ins, weight history, calorie counting or food logging.
- Separate profiles per household member.
- Quantities in setup (they belong in My Kitchen).
- City-level or live prices, barcode scanning, receipt scanning.
- Conditions already covered elsewhere: coeliac disease → allergy *gluten* + diet *gluten-free*; lactose intolerance → diet *dairy-free*; obesity → weight goal + BMI from "About you".
- Retired goals: `lose_weight` and `maintain_weight` become the weight-goal choice; `manage_blood_sugar` is replaced by the specific diabetes condition. The Postgres enum keeps the values (they can never be removed) but the app stops offering them and the database refuses new writes (LF02).

### 0.5 Languages

Every new string ships in English **and** French (ARB parity is tested since L10N). The agent drafts both. The owner, or the French reviewer used for L10N, approves them on the phone. Food names carry both languages plus common local names (e.g. *bobolo*, *miondo*, *njama njama*) for search.

---

## The flow after this pack

| # | Step | Status | Required | Data class |
|---|---|---|---|---|
| 1 | Lifestyle | unchanged | yes | personal |
| 2 | Household size | unchanged | yes | sensitive (S6) |
| 3 | Food budget | unchanged | yes | sensitive (S6) |
| 4 | **What do you have at home?** | **new** (LF03) | yes ("Nothing at home" is an answer) | personal |
| 5 | Cooking skill + time | unchanged | yes | personal |
| 6 | Cuisines liked / disliked | unchanged | optional | personal |
| — | Breather pause | unchanged | — | — |
| 7 | Consent | **v2 copy** | yes | — |
| 8 | **About you** (sex, birth year, height, weight, activity) | **new** | yes | sensitive (S6) |
| 9 | **Health conditions** (+ follow-ups, "who has it") | **new** | yes ("None" is an answer) | sensitive health |
| 10 | Diet | unchanged | yes | sensitive (S6) |
| 11 | Allergies | unchanged | yes | sensitive (S6) |
| 12 | **Goals**: weight goal (required, one choice) + focus (optional) | **reworked** | weight goal yes | sensitive (S6) |
| → | Processing: "Your plan is built around…" summary, then the first recommendations | **extended** | — | — |

Steps 1–5 stay on `/setup/lifestyle`, steps 6–12 on `/setup/preferences`. No new routes.

---

## LF01 — Food catalog: ingredients, prices and nutrients

| Priority | Depends on | Plan approval | Inputs | New dependencies |
|---|---|---|---|---|
| 🔴 Critical | P16 | **Required** (schema) | `INGREDIENT_PRICE_LIST` = [`docs/reference/ingredient-prices-cm.csv`](reference/ingredient-prices-cm.csv) (supplied 2026-10-29), `{{NUTRIENT_SOURCE}}`, `{{REMOTE_PUSH_APPROVAL}}` | none |

**Load first:** the `supabase` and `supabase-postgres-best-practices` skills.

**Objective.** One canonical list of foods with an estimated price and nutrients, so that recipes, the user's kitchen, budget estimates and health rules all speak about the *same* rice and the *same* palm oil.

**Evidence.**
- `recipe_ingredients.name` is free text (`supabase/migrations/20261023102159_schema_v1.sql`), so "Rice", "riz" and "long-grain rice" can't be matched to a kitchen item.
- `recipes` has no nutrition data, so no health rule can be checked.
- `recipes.est_cost_xaf` and `recipe_ingredients.est_cost_xaf` are hand-entered seed placeholders.

**Requirements.**
1. **Vocabularies** (Postgres enums, additive only):
   - `pricing_unit`: `kg`, `litre`, `piece`.
   - `ingredient_category`: `grains_flours`, `tubers_plantain`, `legumes_nuts_seeds`, `oils_fats`, `meat_poultry`, `fish_seafood`, `eggs_dairy`, `vegetables_leaves`, `fruits`, `spices_seasoning`, `other`. These are also the My Kitchen shelves.
   - `ingredient_flag` (for health rules, LF04): `organ_meat`, `high_purine`, `processed_meat`, `alcohol`, `raw_or_undercooked_egg`, `high_mercury_fish`, `bouillon_cube`, `refined_starch`, `added_sugar`, `deep_fried`, `very_spicy`, `acidic`. The final list is confirmed in `{{MEDICAL_RULES}}`.
2. **`ingredients`** (public reference data, like `cuisines`):
   - `id uuid PK`, `slug unique`, `name_en`, `name_fr` (≤ 80), `aliases text[]` (≤ 10 local names), `category`.
   - `pricing_unit`, `price_xaf integer > 0` per pricing unit (null only while inactive), `price_low_xaf` / `price_high_xaf` (the typical range), `price_confidence` (`high` / `medium` / `low`), `price_updated_at date not null`, `price_source text not null`. Values come straight from the price list's columns.
   - `grams_per_piece numeric` (required iff `piece`), `density_g_per_ml numeric` (required iff `litre`), so every amount converts to grams.
   - Nutrients **per 100 g edible portion**, all nullable (null = unknown, never 0): `kcal`, `carbs_g`, `sugars_g`, `fibre_g`, `protein_g`, `fat_g`, `sat_fat_g`, `sodium_mg`, `potassium_mg`, `phosphorus_mg`, `iron_mg`, `folate_ug`; plus `nutrient_source text`.
   - `allergens allergen[] not null default '{}'`, `flags ingredient_flag[] not null default '{}'`.
   - `is_kitchen_staple boolean`: shown in the setup "At home" grid.
   - `is_active boolean`.
   - CHECK constraints for every range and every unit/conversion pairing. RLS: `authenticated` select active rows; no client writes.
3. **Link recipes.** Add `ingredient_id uuid references ingredients` and `amount numeric(10,3) > 0` (in the ingredient's pricing unit: 0.5 kg rice, 0.1 L palm oil, 2 pieces eggs) to `recipe_ingredients`. Keep `name`, `quantity` and `unit` as the display text.
   - A trigger refuses **publishing** a recipe while any non-"to taste" line lacks `ingredient_id` + `amount`.
   - A trigger refuses publishing a recipe whose `allergens` does not contain every allergen of its ingredients. This strengthens S11: the allergen list can no longer drift from the ingredients.
4. **Derived figures** (security-invoker views, so RLS applies):
   - `recipe_costs`: cost per recipe and per serving = Σ amount × price. `est_cost_xaf` stays only as a fallback for unlinked legacy rows; log the plan to drop it.
   - `recipe_nutrition`: nutrients per serving, plus `nutrition_complete boolean` per nutrient group. Null propagates, so an unknown nutrient makes the total unknown (H2).
5. **Seed and reference data.**
   - Reference data (shipped by migration, like `cuisines`): every row of `docs/reference/ingredient-prices-cm.csv`, with prices exactly as listed. Rows with status `ready` are active; `field_check` and `missing` rows are loaded with `is_active = false` until the owner's market check fills them in (see the price list's method page). Nutrients come from `{{NUTRIENT_SOURCE}}` (recommended: FAO/INFOODS *West African Food Composition Table*, 2019). Record each value's source.
   - The list will grow toward the foods the recipe catalog needs. New rows follow the same method page, and monthly refreshes use `tool/wfp_prices.sh`.
   - `supabase/seed.sql`: link all 12 seed recipes.
6. **Docs.** `context/data-model.md` (ERD, tables, vocabularies, RLS matrix); `docs/SECURITY.md` §3: the catalog is *public*.

**Tests (pgTAP).** Constraint tests for each unit pairing; publish refused when a line is unlinked or allergens drift; cost and nutrition views match hand-calculated values for two seed recipes; unknown nutrient → null, not 0; anon has no access; no client writes.

**Acceptance criteria.**
- [ ] Every seed recipe is linked, and its cost comes from the catalog.
- [ ] The publish-time allergen check exists and is tested.
- [ ] Prices and sources match `{{INGREDIENT_PRICE_LIST}}` line by line.
- [ ] `prompt.md` §0.6 Definition of Done.

---

## LF02 — Setup v2 data model and atomic completion

| Priority | Depends on | Plan approval | Inputs | New dependencies |
|---|---|---|---|---|
| 🔴 Critical | LF01 | **Required** (schema) | `{{CONSENT_COPY_V2}}`, `{{COUNSEL_HEALTH_DATA}}` (before the remote push), `{{REMOTE_PUSH_APPROVAL}}` | none |

**Objective.** Store the new answers with the same guarantees P16 gave the old ones: validated server-side, written in one transaction, owner-only, consent-gated and deleted with the account.

**Requirements.**
1. **New vocabularies.**
   - `sex`: `female`, `male`. Used only for the energy calculation; the copy says so.
   - `activity_level`: `sedentary`, `light`, `moderate`, `very_active`.
   - `weight_goal`: `lose`, `maintain`, `gain`.
   - `health_condition`: `diabetes`, `hypertension`, `high_cholesterol`, `heart_disease`, `kidney_disease`, `gout`, `ulcer_gastritis`, `anaemia`, `sickle_cell`, `pregnancy`, `breastfeeding`.
   - `diabetes_type`: `type_1`, `type_2`, `prediabetes`, `gestational`.
   - `condition_subject`: `me`, `someone_i_cook_for`, `both`.
2. **`user_preferences`, new columns.**
   - `sex`, `birth_year smallint` (current year − 100 … current year − 13, checked by a trigger because the bound moves), `height_cm smallint 100–250`, `weight_kg numeric(4,1) 25–300`, `activity_level`, `weight_goal`.
   - `health_conditions_declared boolean not null default false` (separates "None" from "not answered", like `allergens_declared`).
   - `kitchen_declared boolean not null default false`.
   - `sensitive_data_consent_version smallint`.
   - Extend `sensitive_data_needs_consent`: body data, weight goal and health conditions require consent.
   - New CHECK: `health_goals` may not contain `lose_weight`, `maintain_weight` or `manage_blood_sugar` (retired, §0.4).
3. **`user_health_conditions`.**
   - `(user_id, condition) PK → profiles on delete cascade`, `subject condition_subject not null`, `diabetes_type` (required iff diabetes), `uses_insulin boolean` (required iff diabetes; forced true for type 1), `on_dialysis boolean` (required iff kidney disease).
   - CHECKs: each follow-up column is null unless its condition applies; `gestational` diabetes and `pregnancy`/`breastfeeding` with subject `me` require `sex = female` (checked in the RPC).
   - At most 11 rows per user. RLS own CRUD. Sensitive health class.
4. **`kitchen_items`** (setup seeds it; LF05 extends it).
   - `(user_id, ingredient_id) PK`, `quantity numeric(10,3)` (null = "I have some", which is what setup records), `source` (`setup`, `manual`, `cooked`), `updated_at`.
   - Only active ingredients; ≤ 300 rows per user (S9). RLS own CRUD. *Personal* class (not sensitive).
5. **Setup versioning.**
   - `profiles.setup_version smallint not null default 0`.
   - `private.current_setup_version()` returns 2.
   - "Setup complete" now means `setup_completed_at is not null and setup_version >= current`. Update the setup-status repository and `resolveRedirect` in the same change, with the P15 table tests extended. Existing v1 users become "incomplete" and are routed to the upgrade path (A3).
6. **`complete_setup_v2(...)` RPC** (security invoker, one transaction).
   - Takes every v1 argument plus `p_kitchen_ingredient_ids uuid[]` (≤ 200, staples only), the body fields, `p_weight_goal`, `p_health_conditions_declared`, `p_health_conditions jsonb` (≤ 11 objects, strictly validated: known keys only, types, the follow-up rules above) and `p_consent_version`.
   - Upserts preferences, replaces cuisine preferences, health conditions and setup-sourced kitchen items (never touches `manual` rows), and sets `setup_completed_at` and `setup_version`.
   - **Safety conflicts refused server-side** with typed error codes the app maps to approved copy:
     - `weight_goal = lose` with pregnancy or breastfeeding (subject `me` or `both`);
     - `lose` with BMI below the `{{MEDICAL_RULES}}` underweight threshold;
     - `lose` under the age the rules set.
   - Keep `complete_setup` (v1) working for installed old builds; it sets `setup_version = 1`. Log a follow-up to drop it after one release.
7. **Consent v2.** Store the version. Copy `{{CONSENT_COPY_V2}}`. The agent drafts it; proposed English:

   > "I agree that Smart Meal stores my allergies, diet, health conditions, body measurements and goals — and the health conditions of people I cook for — to personalise my meals. Only I can see them, and I can delete them anytime."

   v1 consent is not enough for v2 data (the RPC checks the version).
8. **Third-party health data.** "Someone I cook for" stores a condition of a person who has not consented. Mitigation built in: no name, age or identity is ever stored for them, only the condition and the subject flag. The lawyer confirms this under Law No. 2024/017 once the build is done (owner, 2026-10-29). Hand them a one-page data sheet: what is stored, why, who sees it, retention, deletion, hosting region. The migration stays on the LF02 branch until `COUNSEL_HEALTH_DATA` is recorded, because migrations on `main` deploy to production.
9. **Docs.**
   - `docs/SECURITY.md` §3: add a **Sensitive health** row (conditions, body data, weight goal: special-category handling, never in analytics, deleted with the account or on consent withdrawal); add H1–H6; record the third-party data note.
   - `context/data-model.md`.

**Tests (pgTAP).** RLS isolation for both new tables; every follow-up CHECK; consent v1 refused for v2 data; each safety conflict returns its code; retired goals refused; atomicity (a failure halfway leaves nothing); manual kitchen rows survive a re-run; v1 RPC still works and leaves the gate closed; account deletion cascades the new rows.

**Acceptance criteria.**
- [ ] A v1-complete user is routed to the upgrade path and cannot reach `/home` until v2 is complete.
- [ ] "None" and "not answered" are distinguishable for conditions and kitchen.
- [ ] Counsel confirmation is recorded before the remote push.
- [ ] `prompt.md` §0.6 Definition of Done.

---

## LF03 — Setup v2 screens

| Priority | Depends on | Plan approval | Inputs | New dependencies |
|---|---|---|---|---|
| 🔴 Critical | LF02, L10N | **Required** | `{{SETUP_V2_COPY}}` (EN + FR), `{{HEALTH_DISCLAIMER_COPY}}`, `{{SETUP_V2_ILLUSTRATIONS}}` (At home, About you, Health) | none |

**Design source.** As for P16 (owner, 2026-10-24): the app's existing setup style (`SetupStepLayout`, `ChoiceTile`, one question per step, large illustration). The code is the source of truth; the owner reviews on the phone.

**Requirements.**
1. **Domain.**
   - Extend `SetupStep` to the 12 steps in the flow table and `SetupDraft` with the new answers and `isAnswered` rules. The draft stays **in memory only** (S6), as today.
   - Weight goal is a single value; focus goals are a set limited to `gain_muscle` and `eat_healthier`.
   - **Upgrade path (A3):** for a v1-complete user, load the saved answers through the repository and show only consent v2, At home, About you, Health and Goals; then submit `complete_setup_v2` with the merged answers.
2. **Step 4 — "What do you have at home right now?"**
   - Grid of `is_kitchen_staple` ingredients grouped by category (the future shelves), each with a name and image or icon, one tap = have it. A search field filters by name and alias in the current language.
   - "Nothing at home right now" is exclusive, like "None" for allergies.
   - Subtitle: "We'll use these first, so you buy less." **No savings figure here**: an honest number needs real recipes, so it appears on the processing screen (requirement 6).
   - Offline/error state reuses the cuisines-step pattern.
3. **Step 8 — "About you".** One screen:
   - sex (Female / Male, with "used to estimate your energy needs");
   - birth year picker;
   - height (cm) and weight (kg) with numeric keyboards;
   - activity level (4 tiles with plain examples, e.g. "Mostly sitting — office or classes").
   - Client bounds mirror the database exactly; the server stays the authority (S3).
4. **Step 9 — "Does anyone you cook for have any of these?"**
   - "None" (exclusive), then the 11 conditions in plain words. Pregnancy and breastfeeding are hidden only when the user is male **and** cooks for one person.
   - Selecting a condition expands it inline:
     - "Who?" — Me / Someone I cook for / Both. When household size is 1, it is "Me" and not asked.
     - Diabetes: type (Type 1 / Type 2 / Prediabetes / During pregnancy), then "Uses insulin?"
     - Kidney disease: "On dialysis?"
   - The disclaimer is always visible. Type 1, kidney disease, pregnancy and breastfeeding add the doctor notice (H4).
5. **Step 12 — "What's your goal?"**
   - Required single choice: Lose weight / Keep my weight / Gain weight.
   - Optional focus: Build muscle / Eat healthier.
   - Server conflict codes (LF02 §6) show the approved explanation on this step and keep the user here. "Lose weight" is shown disabled with that explanation when the draft already makes it impossible (pregnancy, underweight, age).
   - The labels are the same for men and women; the difference is in the targets LF04 computes (D4). Gain-weight copy never promises *where* weight goes.
6. **Processing screen.**
   - While the save runs, show a "Your plan is built around…" summary from the draft: budget, household, number of kitchen items, conditions in plain words, weight goal. This is the "made for me" moment.
   - Once P17 exists, the first recommendations treat setup kitchen items as available for the first plan week, and the screen shows "Using what you have saves about X FCFA" from the real recipe costs (`recipe_costs`).
7. **Illustrations.** New WebP assets in `assets/images/setup_*.webp`, same size and compression as the existing ones (P04 rules), from `{{SETUP_V2_ILLUSTRATIONS}}`.

**Tests.**
- Draft rules (exclusivity, follow-ups required, subject skipped for one-person households, pregnancy visibility, conflict pre-checks).
- Notifier: the upgrade path loads and merges, and every LF02 error code maps to its copy.
- A widget test per new step in both languages; ARB parity; back navigation across the section boundary; the breather still appears after cuisines.
- Golden path against the local stack: new user, and v1 user upgrade.

**Acceptance criteria.**
- [ ] A new user answers 12 steps and lands on Home; a v1 user answers only the new ones.
- [ ] No sensitive draft data is written to the device.
- [ ] Each safety conflict is explained, never a raw error (S5).
- [ ] Owner phone check in English and French.
- [ ] `prompt.md` §0.6 Definition of Done.

---

## LF04 — Health rules and nutrition targets

| Priority | Depends on | Plan approval | Inputs | New dependencies |
|---|---|---|---|---|
| 🔴 Critical | LF01, LF02 | **Required + MEDICAL GATE** | `{{MEDICAL_REVIEWER}}`, `{{MEDICAL_RULES}}` (signed off) | none |

**Medical gate.** The owner's doctor signs the rules once the build is done (owner, 2026-10-29). So:
1. Draft the rules table (format below) from published clinical guidance, with each value's source, and mark every row `reviewed_at = null`.
2. Build and test everything on the LF04 branch.
3. Hand the doctor a printable review sheet (rule, value, source, plain-language effect).
4. Only after the signed sheet comes back: record the doctor's name, qualification and date, set the review fields, and merge to `main`. An unreviewed rule is ignored by design (H3), so nothing ships with draft values.

**Objective.** Turn the setup answers into server-side rules the P17 engine applies: which recipes a household may never see, which ones to prefer, and the user's own daily energy and protein targets.

**Requirements.**
1. **`health_rules`** (reference data, admin-written, readable by `authenticated` so explanations can name the rule): `condition`, optional `diabetes_type`/`dialysis` qualifier, `kind` (`exclude_flag`, `max_per_serving`, `min_per_serving`, `prefer_flag`, `prefer_nutrient`), `flag` or `nutrient`, `value`, `unit`, `precedence`, `source`, `reviewed_by`, `reviewed_at not null`.
   - A rule without a review date is not loaded (H3).
   - Examples for the reviewer to confirm, **not** values to ship: hypertension → `exclude_flag bouillon_cube`, `max_per_serving sodium_mg`; gout → `exclude_flag organ_meat, high_purine`; pregnancy → `exclude_flag alcohol, raw_or_undercooked_egg, high_mercury_fish`; diabetes → `max_per_serving carbs_g`, `prefer_nutrient fibre_g`; ulcer → `exclude_flag very_spicy`; anaemia → `prefer_nutrient iron_mg`.
2. **`private.eligible_recipes(user_id)`**, the single gate P17 must use. Published recipes minus: allergens (S11), diet tags, every `exclude_flag` of every condition in the household, every `max_per_serving` exceeded, and every recipe whose required nutrient is unknown (H2). Conflicts resolve by `precedence` (H6). Security definer only if unavoidable, with `search_path = ''`, not executable by `anon`/`authenticated` directly.
3. **`private.nutrition_targets(user_id)`** for the user (not the household):
   - Mifflin–St Jeor basal energy, using the sex-specific constant (D4: the men/women difference lives here), × the activity factor.
   - ± the weight-goal adjustment, and the energy floors per sex, from `{{MEDICAL_RULES}}`.
   - Protein per kg, raised for gain weight / build muscle.
   - Returns `{kcal, protein_g, per_meal_kcal}` plus the rule versions used. Exposed to the owner through `my_nutrition_targets()` for display in P17/P18 and Profile.
4. **Explainable outputs.** Both functions return the rule IDs that applied, so P17's reasons can say "low in salt for high blood pressure" from a template (Appendix A). They never return prose.

**Tests (pgTAP).**
- **Property-style:** for random households and recipes, no eligible recipe contains an excluded flag, exceeds a cap, lacks a required nutrient, or contains a declared allergen.
- Precedence conflicts; an unreviewed rule is ignored.
- Targets match hand-calculated values for one man and one woman across all three goals; floors hold; a pregnancy + lose combination is impossible (LF02) and therefore untested here by design — note it.

**Acceptance criteria.**
- [ ] The reviewer's sign-off (name, date, version) is recorded in the tracker.
- [ ] The property test passes.
- [ ] No rule value exists in Dart code.
- [ ] `prompt.md` §0.6 Definition of Done.

---

## LF05 — My Kitchen (the store room)

| Priority | Depends on | Plan approval | Inputs | New dependencies |
|---|---|---|---|---|
| 🟠 High | LF03, LF04, P18 | **Required** | `{{KITCHEN_DESIGN}}` (Figma URL, or "existing style" as for setup), `{{KITCHEN_ENTRY_POINT}}` (default A2), `{{KITCHEN_COPY}}` (EN + FR) | none |

**Objective.** A kitchen store room the user keeps stocked: what is on the shelves, how much, and what it is worth. The engine cooks from it first and learns from it.

**Requirements.**
1. **Screen** (`features/kitchen/`, data / domain / presentation, sealed states).
   - Shelves = the LF01 categories. Each item shows its name, image or icon, quantity in its own unit (kg / L / pieces), and its state: *plenty*, *running low* (below a per-ingredient threshold in the catalog), or *check me* (not updated for 14 days).
   - The header shows the shelf value ("Your store room: about 12 400 FCFA"), from catalog prices.
2. **Stocking.** Add from the catalog only (search by name or alias, plus quick-add staples). Quantities use steppers in sensible steps (0.5 kg, 0.25 L, 1 piece).
   - Items seeded by setup without a quantity are marked "How much do you have?" until answered. This is the "forced" part (D2, A1): the engine treats them as available only for the first plan week, and the Home card asks until they are answered.
   - Optimistic edits with rollback and an error snackbar, as P18's favorites. Offline edits are refused with the approved copy, never queued silently.
3. **Learning (server side).**
   - RPC `mark_cooked(recipe_id, servings)` logs the `cooked` interaction and deducts amount × servings from kitchen items, floored at 0, `source = 'cooked'`, in one transaction.
   - **What is bought vs what is used (owner, 2026-10-29).** A recipe line's `amount` (LF01) is what the food consumes; frying oil counts only what the food absorbs. Buying for a recipe adds the line's display quantity (e.g. the whole 1 L of frying oil) to the kitchen, and cooking deducts only `amount`, so the rest stays on the shelf until the user marks the item finished.
   - P17 uses the kitchen as described in Appendix A.
4. **Home card** (inside P18's Home). "Cook from your kitchen": shows the number of items, and the asks (unanswered quantities, items to check). It opens My Kitchen.
5. **Bounds.** ≤ 300 items, quantity 0–999.999 per unit; validated in the RPCs and table CHECKs (S9).

**Tests.** Notifier (optimistic add / edit / rollback / offline); deduction never goes negative and leaves other users' rows untouched (pgTAP); shelf value math; widget tests for empty, stocked, low and stale items, in both languages.

**Acceptance criteria.**
- [ ] Setup items appear on the shelves on first open.
- [ ] Cooking a recipe updates the shelves.
- [ ] Recommendations visibly change when the kitchen changes (P17 reason "uses what you have").
- [ ] Owner phone check.
- [ ] `prompt.md` §0.6 Definition of Done.

---

## Appendix A — Changes to P17 (recommendation engine) in `prompt.md`

The agent executing **LF04** applies these edits to `docs/prompt.md` P17, records them in the tracker, and the owner re-approves `{{SCORING_WEIGHTS}}`.

1. **Depends on:** P13, P16, **LF04**.
2. **Hard filters:** candidates come only from `private.eligible_recipes(user_id)` (allergens S11, diet, health H1/H2). If `health_conditions_declared` or `kitchen_declared` is false, return `setup_incomplete`, as for allergens today.
3. **Budget fit** uses the recipe cost **minus the cost covered by the kitchen** (items with a quantity: the amount actually on the shelf; setup items without a quantity: fully covered in the first plan week only).
4. **New scoring components.** Proposed defaults (owner tunes):
   - budget 25;
   - taste/cuisine 20;
   - **kitchen fit 15** (share of the recipe's cost already on the shelves, with a bonus for items *running low* or *check me*, so food is used before it spoils);
   - time/skill 15;
   - **nutrition fit 10** (closeness of per-meal energy to `nutrition_targets`, plus `prefer_*` rules);
   - behaviour 10 (now also ingredient affinity: foods the user keeps restocking);
   - variety 5.
5. **Structured reasons** gain `{factor: "kitchen", ingredient_ids, saved_xaf}`, `{factor: "health", rule_ids}` and `{factor: "goal", weight_goal}`. Health reasons appear only to the owner and never name a household member.
6. **Property test** extended to the health rules (LF04 §Tests).

## Appendix B — Traceability: owner request → prompt

| Owner request (2026-10-28) | Delivered by |
|---|---|
| Ask what food the user already has at home, after the budget step | LF03 step 4, stored by LF02 |
| Have it reduce the weekly spend and personalize the next steps | LF01 prices, LF03 processing summary, Appendix A §3–4 |
| Prices per kg, and per litre for palm oil and vegetable oil (2026-10-29) | LF01 `pricing_unit`, `price_xaf` |
| My Kitchen as a store room the engine learns from | LF05, Appendix A §4 |
| Ask specifically about diabetes and other conditions, "very specific and perfect" | LF02 vocabularies + follow-ups, LF03 step 9, LF04 reviewed rules (H1–H6) |
| Gain weight as a goal, different for men and women | LF02 `weight_goal` + body data, LF03 step 12, LF04 sex-specific targets |
| Remove everything unnecessary | §0.4, retired goals (LF02 §2) |
