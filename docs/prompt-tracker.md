# SmartMeal — Prompt Execution Tracker

> Companion to [`prompt.md`](prompt.md). The executing agent updates this file at the end of **every** prompt and whenever it is blocked (protocol: `prompt.md` §0.7). Use absolute dates (`YYYY-MM-DD`). Keep entries honest — 🟡 means actively being worked on in the current session, not "started once".

**Last updated:** 2026-10-29 — LF01 ✅ on `main` (`d16c62a`, `5cf64e8`) and live in production (food catalog, 70 foods, WAFCT 2019 + USDA nutrients; plantain priced per finger). P16 ✅ (owner phone check). Earlier: L10N ⏸️ on `main` (English + French; French approved; on the owner's phone for the check). CI gitleaks fixed: the one finding was a fake key in a test, accepted by fingerprint in `.gitleaksignore`. P15 + P16 on `main` (`5971120`) and live (migration `20261024073206` applied by the GitHub integration; copy approved; monthly budget suggestion 30 000 FCFA); both wait on the owner's phone check. Next: bilingual app (English + French, owner 2026-10-26). Phase 4 planned with the owner (order P15 → P16 → P17 → P18; inputs recorded below; `EXPLANATION_COPY` and Home empty/error copy come with P17/P18). P14 ✅ (deletion live: Edge Function, rate limit, web page on GitHub Pages; in-app button comes with T1-Profile). P13 ✅ (schema v1 live on the hosted project via the GitHub integration; Advisors empty). P11 ⏸️ on `p11-password-recovery` (password recovery + auth deep links; uncommitted until the owner authorizes; waiting on the Dashboard allow-list, email templates and a device check). P10 ⏸️ on `p10-auth-flow` (auth hardening + the launch-routing part of P15 that needs no database; owner phone check and copy approval pending; on `main`). P08 ✅ (owner smoke-tested the obfuscated release APK; the Xcode step waits for the owner's Mac). P06–P08 on `main` (fast-forward on the owner's instruction). P07 ⏸️: env config + `docs/SECURITY.md` done, waiting on owner review and a phone run. P01–P05 ✅, all on `main` (fast-forwarded to `67b1fa0` on the owner's instruction; CI run 38766137427 green: quality gate + debug APK, gitleaks, OSV). P06 ✅ on `p06-app-identity` (owner phone check 2026-10-20; iOS build pending, no Mac).

## Status legend

⬜ Not started · 🟡 In progress · ⏸️ Waiting on owner input · 🔴 Blocked · ✅ Done

## Status board

| ID | Title | Phase | Priority | Depends on | Status | Started | Completed | Commit(s) | Verification evidence | Notes |
|---|---|---|---|---|---|---|---|---|---|---|
| P01 | Make push bootstrap crash-proof and non-blocking | 0 | 🔴 Critical | — | ✅ | 2026-10-14 | 2026-10-14 | `4274bbc` (branch `p01-push-bootstrap`, pushed) | Regression test red before fix (`[core/no-app]`), 4/4 green after; `flutter test` → 5 passed; `flutter analyze` → no issues; `dart format` on touched files → 0 changed; grep: no `requestPermission` reachable from `main()`, no token interpolated in any log; owner confirmed on a physical phone (2026-10-14) that the app works | Android emulator unusable on this host — runtime check done by the owner on a phone. Tracker/context doc updates are not in the commit (`docs/`, `context/` are still untracked — P02's commit plan). Repo-wide `dart format` gate fails on 13 pre-existing files (logged as a Known issue) |
| P02 | Repository hygiene and documentation truth | 0 | 🟠 High | P01 | ✅ | 2026-10-14 | 2026-10-14 | `d15bcc0` `b02c05b` `e35da6a` `0705187` `6a9e90d` `84805b8` `019c014` + docs commit (branch `p02-repo-hygiene`, pushed) | Clean `git worktree` per code commit: `flutter analyze` → no issues at `d15bcc0`, `b02c05b`, `e35da6a`; `flutter test` at `e35da6a` → 5 passed; no Dart/pubspec changes after `e35da6a`; `git add --renormalize .` → 0 files changed; grep for stale claims (`anonKey`, placeholder values, `superpowers`, circular pointer) → none left | Plan approved by owner. Renormalize was a no-op (index already LF), so no renormalize commit. `auth_notifier.dart` cosmetic comment edit reverted on owner instruction. `.claude/skills/` (duplicate of `.agents/skills/`) and `.claude/*.lock` now in `.gitignore` |
| P03 | CI quality and security gates | 0 | 🟠 High | P02 | ✅ | 2026-10-14 | 2026-10-15 | `d8b11cf` `766049f` `15c260a` `55a3f16` `41da534` + tracker commit (branch `p03-ci-gates`, pushed) | `tool/verify.sh` → all checks passed (analyze `--fatal-infos` clean, 5 tests); unformatted `lib/main.dart` → gate exit 1 at format step, then reverted; gitleaks 8.30.1 (checksum-verified) full history, all refs, 11 commits → no leaks, with and without `.gitleaks.toml` | First CI run: on `main` after the owner had P01–P05 fast-forwarded there instead of a stacked PR (2026-10-15) — run 38766137427 at `67b1fa0`: all 3 jobs green (Format/analyze/test/build, gitleaks full history, OSV). OSV job non-blocking until **2026-11-14** (remove `continue-on-error` then). Plan approved by owner |
| P04 | Dependency, asset and font diet | 1 | 🟡 Medium | P03 | ✅ | 2026-10-14 | 2026-10-15 | `6698dbf` `cfa83ff` `53e03c1` `1619800` `257f81c` `ac3f30a` + tracker commit (branch `p04-diet`, off `p03-ci-gates`; **not pushed** — needs the owner's GitHub credentials) | `tool/verify.sh` → all checks passed (analyze clean, 18 tests); removed packages absent from `pubspec.lock` (192 lines removed, 0 added); grep `bckimg\|img_login\|img_signup\|app logo` in `lib/` → none; 5 bundled Inter files SHA-256 = `google_fonts` 8.1.0 pins; shipped WebP byte-identical to the approved `compare.html` set; offline render test + engine screenshots (splash/onboarding/login/signup, fetching off) show bundled Inter and all images; release arm64 APK 35,074,878 → 20,873,226 B (−40.5 %) | Plan + WebP approved by owner (2026-10-14/15). Pushed to `main` with P05 (2026-10-15), CI green (run 38766137427); owner confirmed on their phone that everything works (2026-10-15). Size builds ran Gradle directly with `-x lintVital*` because local Android lint is broken (see Known issues) |
| P05 | UI standards and accessibility cleanup | 1 | 🟡 Medium | P04 | ✅ | 2026-10-15 | 2026-10-15 | `3b429c5` widgets/theme · `f279b00` splash + onboarding · `3615750` auth screens + docs commit (branch `p05-ui-a11y`) | `tool/verify.sh` → all checks passed (analyze `--fatal-infos` clean, 48 tests, coverage 64.6 %); enforcement grep (word-bounded, see notes) → nothing; screenshots: splash pixel-identical, login/signup identical below the title apart from a 34 dp shift (title now Inter via `Text.rich`); onboarding now with owner-approved overlays; onboarding contrast test (real artwork, worst visible pixel) passes AA on all 3 slides at 3 sizes and fails on the old scrim; system-back, onboarding layout and button tests red on the old code, green on the new; owner verified on a phone (2026-10-15) | Started while P04 was ⏸️ — stacked like P04 on P03. Owner approved the 4 screen-reader labels, onboarding overlays, the visible primary loading spinner, and system back matching the on-screen back. The prompt's enforcement command (`Colors\.` has no word boundary) also matches every `AppColors.`; run it with `\bColors\.` instead. Still open: splash accent/subtitle contrast and `textHint` icons (need a color decision) |
| P06 | Permanent app identity | 1 | 🟠 High | P03 | ✅ | 2026-10-15 | 2026-10-20 | `c8474ac` `54f556d` (branch `p06-app-identity`, off `p05-ui-a11y` = `main`) | `tool/verify.sh` → all checks passed (analyze clean, 48 tests); `flutter clean` + `flutter build apk --debug` → built; `aapt dump badging` → `package: name='com.ojtech.smartmeal'`, `application-label:'Smart Meal'`, launcher `com.ojtech.smartmeal.MainActivity`; built manifest `screenOrientation=0x1` (portrait); `git grep com.example` in `android/` `ios/` → none | Plan + inputs approved by owner (2026-10-15). Owner confirmed on their phone (2026-10-20) that the app installs and works under the new ID. iOS `flutter build ios --no-codesign` pending (no Mac). Desktop folders still carry `com.example` — out of scope (Known issue). Must run before P11, P12 and P19 |
| P07 | Environment config, secrets policy, threat model | 1 | 🟠 High | P06 | ⏸️ | 2026-10-20 | | `887db90` `5908e50` `dd7e815` + tracker commit (branch `p07-env-config`, off `p06-app-identity`) | `tool/verify.sh` → format clean, analyze no issues, 65 tests passed (17 new in `test/core/config/app_config_test.dart`); `flutter build apk --debug --dart-define-from-file=env/example.json` (the CI command) → built; validator: `env/dev.json` valid, `env/example.json` → 3 placeholder errors; no defines → `AppConfigException` listing 4 problems + fix (see log); value grep over `lib/` → none | Plan + inputs approved by owner (2026-10-20). **Waiting:** (1) owner review of `docs/SECURITY.md` (`SECURITY_DOC_REVIEW`); (2) owner runs **SmartMeal (dev)** from VS Code on their phone and confirms sign-in screens still load. iOS `Info.plist` per-env mechanism specified for P12 (`SECURITY.md` §2), not built (no Mac) |
| P08 | Android and iOS platform hardening | 1 | 🟠 High | P06, P07 | ✅ | 2026-10-20 | 2026-10-21 | `d813220` `cd85d12` `a0ea732` `965474d` + tracker commit (on `main`) | Release build without `key.properties` → clear failure; obfuscated AAB + APK built with a throwaway key; merged manifest: backup off, cleartext off, only `MainActivity` exported (log 2026-10-20); 2026-10-21 rebuild of the current code (P09 secure storage, new splash/photos) → `app-release.apk` 19.1 MB arm64, owner smoke test passed (splash, photos, email login, Google, restart keeps the session) | Creates `docs/RELEASE.md`. Plan approved by owner (2026-10-20). **Pending, not blocking:** add `PrivacyInfo.xcprivacy` to the Runner target in Xcode when the owner has a Mac (`MACOS_ACCESS`); the owner creates the real upload keystore before the first Play upload (`RELEASE_KEYSTORE`) |
| P09 | Encrypted session storage | 2 | 🟠 High | P08 | ⏸️ | 2026-10-21 | | `a77233f` `4f4ad1d` `e63ffbb` + tracker commits (branch `p09-secure-session`, pushed to `main`) | `tool/verify.sh` → format clean, analyze no issues, 78 tests passed (12 new in `test/core/services/secure_session_storage_test.dart`); `flutter build apk --debug` → built | Authorizes `flutter_secure_storage` (v10: v11 needs Dart 3.10). Plan approved by owner (2026-10-21); started while P08 waits on the owner smoke test, on the owner's instruction. **Waiting:** owner phone checks — no token in `shared_prefs` after sign-in, restart keeps the session, upgrade from the pre-P09 build keeps the session and removes the plaintext copy |
| P10 | Auth hardening: errors, validation, state model | 2 | 🟠 High | P09 | ⏸️ | 2026-10-21 | | `b404a0f` code + tests · `65a9e39` context docs + tracker commit (branch `p10-auth-flow`, fast-forwarded onto `main` and pushed) | `flutter analyze --fatal-infos` → no issues; `flutter test` → 174 passed (96 new: validators, `formatAuthError` per code + network + default, `AuthNotifier` against the fake, `resolveRedirect` table, whole-app launch routing incl. failed sign-out, screen validation/loading/cancel/confirmation); grep `e\.message`, `toString().contains`, `RegExp(` in `lib/features` → nothing | Owner chose (2026-10-21): P10 plus the database-free part of P15 (onboarding seen persisted, session-aware splash), an interim Home with sign-out, Apple/Facebook hidden until P12, sign-up copy "Almost there! We've sent a confirmation link to your email." **Waiting:** owner phone check, approval of the other new messages (log) |
| P11 | Password recovery and auth deep links | 2 | 🟠 High | P10, P06 | ⏸️ | 2026-10-23 | | `66cdf44` code + tests · `27189c0` Supabase config, templates, SECURITY.md · `c13a75a` + tracker commit (branch `p11-password-recovery`, fast-forwarded onto `main` and pushed) | `dart format` → 0 changed; `flutter analyze --fatal-infos` → no issues; `flutter test` → 216 passed (was 174: redirect table for recovery, recovery notifier + persisted flag, rate-limit neutrality, `isAuthLinkError`, both screens, whole-app recovery routing and link-error snackbar); grep `e\.message`, `toString().contains`, `RegExp(` in `lib/features` → nothing | Owner (2026-10-23): screens in the login style instead of Figma, redirect `com.ojtech.smartmeal://auth-callback`, copy approved, minimal `supabase/config.toml`. P10 still ⏸️ (owner phone check) — P11 started on the owner's instruction. Dashboard allow-list applied by owner 2026-10-23. **Waiting:** email templates pasted in the Dashboard, end-to-end check with a real mailbox, `adb` invalid-code check |
| P12 | Social sign-in completion | 2 | 🟠 High | P06, P10 | ⬜ | | | | | Authorizes `sign_in_with_apple` (+ `crypto` if needed) |
| P13 | Supabase schema v1, RLS, storage, DB tests | 3 | 🔴 Critical | P07 | ✅ | 2026-10-23 | 2026-10-23 | `60553db` migration, seed, tests, config · `b72a9d1` docs + tracker (branch `p13-schema`, fast-forwarded onto `main` and pushed) | Local stack (CLI 2.121.0 via npx, Docker): `db reset` → migration + seed apply cleanly; `test db` → 5 files, 121 assertions, PASS; `db lint` → no schema errors; `db advisors --local --type all` → no issues; real local sign-up via GoTrue → profile created by the trigger, weak password 422; REST: anon recipes 401, signed-in 12 recipes, client catalog write 403, `register_push_token` 204; cascade removed the probe's token | Owner approved schema, vocabularies and 12-month retention (2026-10-23). Live (2026-10-23): migration applied by the GitHub integration on push to `main`; live = local on policies (28 + 4 avatar), buckets, signup trigger, 0 tables without RLS, 0 anon grants; no seed (0 recipes). `db advisors --linked` printed nothing (inconclusive). Owner (2026-10-23): Dashboard Security + Performance Advisors empty; 0 users because the owner deleted the old accounts. Prompt note: parallel-safe with P08–P12; owner approves the schema before remote push |
| P14 | Account deletion and data rights | 3 | 🟠 High | P10, P13 | ✅ | 2026-10-23 | 2026-10-24 | `4b1e091` rate limit · `0ee7e18` Edge Function · `53dd4ed` app · `d1a125c` web page · `6e559fd` docs (on `main`; `gh-pages` = `1c778c5`) | Deno: 10 passed (handler: 405, 403 re-auth incl. window edge and missing `amr`, 429, success order, failure stops before the user and logs no PII; entry point: no token 401, forged token 401). pgTAP: 6 files, 130 assertions PASS (new: rate limit, service-role only); `db lint` clean. Flutter: format 0 changed, analyze no issues, 220 tests passed (4 new). Local end to end, twice — Deno-served function and Supabase edge-runtime behind the gateway with `verify_jwt` on: user with a row in all 9 user tables + 2 avatar files → no token 401, GET 405, delete 200, retry 200 → all 0, catalog untouched, logs without user id or email. `grep` secret keys in `lib/` → only comments and the guard rejecting `sb_secret_` | UI entry point comes with T1-Profile. Live (2026-10-23, deployed by the GitHub integration): migration `20261023172323` applied; `delete-account` ACTIVE v1, `verify_jwt` true; production smoke test: no token 401, forged token 401; `note_account_deletion_attempt` not executable by anon or authenticated; counter table RLS on. GitHub Pages enabled by the owner; "pages build and deployment" run succeeded; owner checked the page on the phone (2026-10-24). Follow-up: the in-app button and a real deletion on the phone come with T1-Profile |
| P15 | Launch routing: session, onboarding, setup gates | 4 | 🔴 Critical | P10, P13 | ⏸️ | 2026-10-24 | | `99fbe35` `d02ae8b` (on `main` with P16 `5971120`, 2026-10-26) | `dart format` → 0 changed; `flutter analyze --fatal-infos` → no issues; `flutter test` → 251 passed (new: redirect table for the setup gate incl. every main route, setup routes, signed-out and recovery precedence; `SetupStatusNotifier` — first check, cached-then-corrected, offline keeps cache, offline without cache → retry, sign-in, sign-out clears the user's cache, app resume; app: splash → setup for unfinished users, sign-in → setup, offline retry → home, cached + offline → home). No database change | Plan approved by owner ("go", 2026-10-24). **Waiting:** owner phone check (on `main` since 2026-10-26). Copy approved 2026-10-24. Earlier note: Part done in P10 (owner, 2026-10-21): onboarding persistence, splash without navigation, `resolveRedirect` + `LaunchSnapshot` with session / onboarding / ready. Left: setup status (`profiles.setup_completed_at`), the recovery row (P11), the setup gate and its table rows |
| P16 | Setup / preferences flow | 4 | 🔴 Critical | P15 | ✅ | 2026-10-24 | 2026-10-29 | `5971120` (with P15 `99fbe35` `d02ae8b`; fast-forwarded to `main` and pushed 2026-10-26 on the owner's instruction) | pgTAP: 7 files, 152 assertions PASS (new `07_complete_setup`: 22 — validation, consent required, atomicity, "None" allergies = declared + empty, caller-only, anon refused, invoker); `db lint` clean. Flutter: format 0 changed, analyze no issues, 315 tests passed (new: FCFA formatter, budget advice incl. household scaling and no float drift, draft rules incl. "None" exclusivity, notifier incl. failure/retry/double submit/minimum display/sign-out reset, 12 screen tests, setup-status race regression). Local end to end over REST: 6 cuisines visible; no consent → 400 and gate stays closed; full answers → 200, gate open, answers and consent stored, cuisines like/dislike | Owner (2026-10-24): one question per step, consent required, cuisines as reference data, plain Cameroonian wording, budget advice not enforcement (1 000 / 10 000 / 30 000 FCFA per person per day / week / month, +70 % per extra person; monthly raised from 25 000 on 2026-10-26). Deployed 2026-10-26: production refuses anon on `complete_setup` and `cuisines` (42501), so the migration is live. Copy approved 2026-10-26. Owner phone check passed 2026-10-29 ("everything is perfect") |
| L10N | Bilingual app: English + French (owner request, not in the pack) | 4 | 🟠 High | P16 | ⏸️ | 2026-10-26 | | branch `l10n-bilingual` (from `main` `95060c0`) | `dart format` → 0 changed; `flutter analyze --fatal-infos --fatal-warnings` → No issues found; `flutter test` → 333 passed (new: ARB parity/descriptions/untranslated check, locale resolution, language pick saved and restored, EN→FR switch, French setup screen incl. budget advice, field errors in both languages). No database change | Owner (2026-10-26): follow the phone's language with an EN | FR switch (onboarding and sign-in now, Profile with T1); agent drafts the French, owner or a trusted French speaker reviews on the phone; scope = all app screens (auth emails and the deletion web page stay English for now). French approved by the owner 2026-10-27; merged to `main` and installed on the owner's Pixel 6a (profile build). **Waiting:** owner phone check |
| LF01 | Food catalog: ingredients, prices (per kg / L / piece), nutrients | 4 | 🔴 Critical | P16 | ✅ | 2026-10-29 | 2026-10-29 | `d16c62a`, `5cf64e8` on `main` (branch `lf01-food-catalog`, off `main` `5998b46`) | `db reset` → 4 migrations + seed clean (guard accepted all 12 recipes); `test db` → 8 files, 196 assertions PASS (new `08_food_catalog`: 44); `db lint` + `db advisors --local` → none; DB vs price CSV → 70 rows, all fields match; REST: anon 401 on `ingredients` and `recipe_costs`, signed-in 65 active foods (local), Koki 765 FCFA, client PATCH 403; `dart format` 0 changed; `flutter analyze --fatal-infos --fatal-warnings` → no issues; `flutter test` → 356 passed (12 new in `test/tool/food_catalog_test.dart`) | Plan + all Q1–Q8 answers approved by owner 2026-10-29 (`promptLoginFlow.md` §0.1). All acceptance criteria met locally. Owner approved commit + merge to `main` (production deploy) 2026-10-29. Plantain re-priced per finger from the owner's heap prices (Poulet DG now 4 623 FCFA, 1 156 per serving). Live: Supabase GitHub integration applied the migration (check "Supabase Preview" success on `5cf64e8`); production REST: `ingredients`, `recipe_costs`, `recipe_nutrition` → 401 for anon (missing table → 404); CI run 40846655575 green (quality gate, gitleaks, OSV). Owner market check continues under `INGREDIENT_PRICE_LIST`. No UI, so no device check |
| LF02 | Setup v2 data model and atomic completion | 4 | 🔴 Critical | LF01 | ⬜ | | | | | Counsel confirmation on health + third-party data before the remote push |
| LF03 | Setup v2 screens (At home, About you, Health, Goals) | 4 | 🔴 Critical | LF02, L10N | ⬜ | | | | | v1 users answer only the new steps |
| LF04 | Health rules and nutrition targets | 4 | 🔴 Critical | LF01, LF02 | ⬜ | | | | | Medical gate: rules signed off by `MEDICAL_REVIEWER` before anything ships |
| LF05 | My Kitchen (the store room) | 4 | 🟠 High | LF03, LF04, P18 | ⬜ | | | | | Opens from a Home card + the Planner by default, not a sixth tab |
| P17 | Recommendation engine v1 (explainable) | 4 | 🔴 Critical | P13, P16, LF04 | ⬜ | | | | | Decision gate: engine placement and weights. Depends on LF04 since 2026-10-29: apply `docs/promptLoginFlow.md` Appendix A to the P17 spec first; weights re-approved then |
| P18 | Home tab on live data | 4 | 🟠 High | P17 | ⬜ | | | | | |
| P19 | Push notifications activation | 5 | 🟡 Medium | P06, P07, P13, P16 | ⬜ | | | | | Needs a Firebase project and APNs key. From P01: only the `PushNotificationService` instance created in `main()` has listeners attached and `isAvailable == true` — give the UI a handle to *that* instance (e.g. a provider overridden in `ProviderScope`), not a new one. `getInitialMessage()` (cold-start taps) is not handled yet |
| P20 | Release readiness and security verification | 5 | 🟠 High | all above | ⬜ | | | | | Failures become new rows P21+ |

### T1 screen instances

Add one row per screen built with the T1 template.

| ID | Screen | Route | Depends on | Status | Started | Completed | Commit(s) | Verification evidence | Notes |
|---|---|---|---|---|---|---|---|---|---|
| T1-Discover | Discover | `/discover` | P17 | ⬜ | | | | | |
| T1-Planner | Planner | `/planner` | P13, P16 | ⬜ | | | | | Budget math in domain/Edge Function |
| T1-Favorites | Favorites | `/favorites` | P18 | ⬜ | | | | | |
| T1-Profile | Profile | `/profile` | P14, P16 | ⬜ | | | | | Delete-account entry: call `AuthNotifier.deleteAccount()`; on `AuthReauthenticationRequired` ask the user to sign in again, then retry; on `AuthAccountDeleted` the router signs out. Avatar upload re-adds `image_picker` |
| T1-RecipeDetail | Recipe detail | `/home/recipe/:id` | P18 | ⬜ | | | | | |

## Inputs register (owner supplies — agents must never guess)

| Key | Needed by | What it is | Value / decision | Status |
|---|---|---|---|---|
| `COMMIT_AUTHORIZATION` | every prompt | Whether agents may create commits in a session | P01, P02, P03, P04: authorized 2026-10-14 — commit and push to its own branch (ask again each prompt). P05: authorized 2026-10-15 — commit and push to `main`. P06: authorized 2026-10-15 — commit and push branch `p06-app-identity`. P07: authorized 2026-10-20 — commit and push branch `p07-env-config`. P08: authorized 2026-10-20 — commit and push to `main` (fast-forward, which also lands P06 and P07). Logo change + P09: authorized 2026-10-21 — commit and push to `main`. P10: authorized 2026-10-22 — commit and push to `main`. P11: authorized 2026-10-23 — commit and push (fast-forward onto `main`, as P10). P13: authorized 2026-10-23 — commit, push, fast-forward `main`. P14: authorized 2026-10-23 — commit, push, fast-forward `main` (deploys the migration + Edge Function), publish `gh-pages` | ✅ |
| `AGENT_SKILLS_IN_GIT` | P02 | Commit `.agents/` + `skills-lock.json`? | Yes (2026-10-14): commit `.agents/skills/` + `skills-lock.json`; ignore the duplicate `.claude/skills/` | ✅ |
| `GIT_HOST` | P03 | Where CI runs (GitHub by default) | GitHub — `origin` is `github.com/ojrandy/smart_meal` (public). PR base for P03: `p02-repo-hygiene` (owner, 2026-10-14) | ✅ |
| `IMAGE_RECOMPRESSION_APPROVAL` | P04 | Sign-off on WebP/resized hero images | Proposal ready: 5 heroes PNG → WebP q85 (no resize; all ≤ 1404 px wide), 10.27 MB → 0.89 MB, YUV PSNR 43–44 dB. Side-by-side page in the P04 session scratchpad (`webp-out/compare.html`); `app_logo.png` stays PNG (alpha, 9 KB). **Approved by owner 2026-10-15**; applied in `257f81c` (shipped files byte-identical to the reviewed set; masters kept in `design-assets/source/`) | ✅ |
| `APP_ID` | P06 → P11, P12, P19 | Permanent reverse-DNS app ID you own (no underscores, for iOS) | **`com.ojtech.smartmeal`** (owner, 2026-10-15). Applied in P06 to Android `namespace`/`applicationId` and the iOS bundle ID (`.RunnerTests` for tests). Downstream — register everything under this ID, never the old `com.example.smart_meal` / `com.example.smartMeal`: **P12** Android OAuth client with the debug, upload *and* Play App Signing SHA-1s (an earlier client keyed to `com.example.smart_meal` + debug SHA-1 `A3:AA:…:08:DD` must be replaced), iOS OAuth client + Sign in with Apple for this bundle ID; **P19** Firebase Android + iOS apps; **P11** deep-link scheme / Supabase redirect allow-list built from it | ✅ |
| `APP_DISPLAY_NAME` | P06 | Launcher name on both platforms | "Smart Meal" (owner, 2026-10-15) — same as `MaterialApp.title`; the splash "SmartMeal AI" wordmark is design and unchanged | ✅ |
| `ORIENTATION_POLICY` | P06 | Default: portrait-only on phones | Portrait-only on phones (owner, 2026-10-15): Android activity `screenOrientation="portrait"`, iPhone `UISupportedInterfaceOrientations` = portrait; iPad list unchanged | ✅ |
| `MACOS_ACCESS` | P06, P08, P12, P19, P20 | A Mac with Xcode, for iOS steps | None yet; the owner expects one soon (2026-10-21). Pending until then: P06's `flutter build ios --no-codesign`; P08's *Target Membership* for `ios/Runner/PrivacyInfo.xcprivacy` (owner does it when the Mac arrives) | ⬜ |
| `SUPABASE_ENVIRONMENTS` | P07 | Separate dev/staging Supabase project? | **One project only** (owner, 2026-10-20): every `APP_ENV` points at the current project. Risk logged in `docs/SECURITY.md` §9 + Known issues — create a separate prod project before public launch | ✅ |
| `LAUNCH_MARKETS` | P07 | Countries at launch (drives data-protection obligations) | **Cameroon** only for now (owner, 2026-10-20). GDPR out of scope until EU residents are served | ✅ |
| `SECURITY_DOC_REVIEW` | P07 | Owner review of `docs/SECURITY.md` | Written 2026-10-20 (`5908e50`); **owner review pending**. Disclosure contact set to the owner's email (owner, 2026-10-20) | ⏸️ |
| `SECURITY_DOC_PLACEHOLDERS` | P07 → P20 | `{{ACK_DAYS}}` (acknowledge reports within N business days), `{{INCIDENT_LEAD}}`, `{{INCIDENT_CONTACTS_LOCATION}}` in `docs/SECURITY.md` §7 | | ⬜ |
| `SUPABASE_AUTH_HARDENING` | P07 → P10, P13 | Owner applies `docs/SECURITY.md` §5 in the Supabase Dashboard and dates each item; CAPTCHA decision | | ⬜ |
| `RELEASE_KEYSTORE` | P08 → P20 | Owner-held upload keystore + `key.properties` values (never in git) | Not needed for P08: verified with a throwaway keystore outside the repo, deleted afterwards (2026-10-20). **Owner creates the real upload keystore** per `docs/RELEASE.md` §2 before the first Play upload | ⬜ |
| `COPY_APPROVALS` | P10, P11, P16, P17, P18 | Approval of new user-facing messages | P05 screen-reader labels "Show password", "Hide password", "Add to favorites", "Remove from favorites": approved by owner 2026-10-15. P10: sign-up confirmation "Almost there! We've sent a confirmation link to your email." approved 2026-10-21; the other P10 messages (log 2026-10-21) pending. P11 (owner, 2026-10-23) approved: "If an account exists for that email, we've sent a link to reset your password." · "Resend link" / "Resend in {s}s" · "Set a new password" · "Confirm password" · "Your password has been updated." · "This link is invalid or has expired. Please request a new one."; also approved 2026-10-23: "Forgot your password?" (title), "Enter your account email and we'll send you a link to set a new password.", "Send reset link", "New password", "Save password"; mismatch message: owner left the choice to the agent → "Passwords don't match" on sign-up and reset (contractions match the rest of the app). P14 approved by owner 2026-10-23: "We couldn't delete your account. Please try again." and the full text of `site/delete-account.html` (owner's address as the public contact, deletion by email within 30 days). P15 approved by owner 2026-10-24: "Getting things ready…", "Try again". L10N approved by owner 2026-10-27: all French text in `lib/core/l10n/app_fr.arb` (drafted by the agent, plain Cameroonian French, "vous"). P16 approved by owner 2026-10-26: all setup wording (titles, plain-language options and hints in `setup_labels.dart`, budget advice sentence, consent "Why we ask" line, processing stages, "Setup progress" screen-reader label). Other prompts: pending | ⬜ |
| `FIGMA_FORGOT_PASSWORD_URL` | P11 | Figma frame(s) | Not used: owner chose screens built in the existing login style (2026-10-23); the code is the source of truth for them | ✅ |
| `FIGMA_RESET_PASSWORD_URL` | P11 | Figma frame(s) | Not used: same decision (2026-10-23) | ✅ |
| `AUTH_REDIRECT_URI` | P11 | e.g. `<APP_ID>://auth-callback` | **`com.ojtech.smartmeal://auth-callback`** (owner, 2026-10-23). In `AuthRepository.authRedirectUri`, the Android intent filter, iOS `CFBundleURLTypes` and `supabase/config.toml` | ✅ |
| `APP_LINK_DOMAIN` | P11 (optional) → later | Domain for App Links / Universal Links | None yet; migration planned in `docs/SECURITY.md` §10 | ⬜ |
| `SUPABASE_REDIRECT_ALLOWLIST` | P11 | Owner sets Dashboard → Authentication → URL Configuration: Site URL and Redirect URLs = exactly `com.ojtech.smartmeal://auth-callback`, no wildcards. Until then Supabase falls back to the current Site URL and links will not open the app | **Applied by owner 2026-10-23** (screenshot): Site URL = `com.ojtech.smartmeal://auth-callback`; Redirect URLs = that one URI only (Total URLs: 1), no wildcard | ✅ |
| `SUPABASE_EMAIL_TEMPLATES` | P11 | Owner updates the "Confirm signup" and "Reset password" templates: keep `{{ .ConfirmationURL }}` as the link, brand "Smart Meal", short friendly tone (`docs/SECURITY.md` §10) | Owner said yes (2026-10-23). Drafted in `supabase/templates/confirmation.html` + `recovery.html` (subjects in `supabase/config.toml`); owner pastes them into Dashboard → Authentication → Emails (no CLI access from the session) | ⏸️ |
| `GOOGLE_CLOUD_ACCESS` + SHA-1s | P12 | Debug, upload and Play App Signing fingerprints for `APP_ID` | | ⬜ |
| `GOOGLE_IOS_CLIENT_ID` | P12 | iOS OAuth client for the bundle ID | | ⬜ |
| `APPLE_TEAM_ID` | P12 | Apple Developer Program membership | | ⬜ |
| `DECISION_APPLE_ON_ANDROID` | P12 | Show Apple sign-in on Android? (recommendation: iOS only) | | ⬜ |
| `DECISION_FACEBOOK` | P12 | Implement now or hide? (recommendation: hide until built) | | ⬜ |
| `SCHEMA_APPROVAL` | P13 | Owner approval of the proposed schema | **Approved 2026-10-23**: the 12 tables of P13, enum vocabularies, cuisines as a lookup table, two storage buckets — built and tested locally only | ✅ |
| `VOCABULARIES` | P13 | Allergens, dietary tags, health goals, cuisines, lifestyle types | **Approved 2026-10-23**. Allergens: gluten, crustaceans (incl. dried crayfish), molluscs, fish, eggs, milk, peanuts (groundnuts), tree nuts, soy, sesame, celery, mustard, sulphites, lupin. Diet: vegetarian, vegan, pescatarian, halal, gluten_free, dairy_free, low_carb. Goals: lose_weight, maintain_weight, gain_muscle, eat_healthier, manage_blood_sugar. Lifestyle: student, working_professional, family, athlete. Skill: beginner, intermediate, advanced. Cuisines: seed rows only (lookup table) | ✅ |
| `INTERACTION_RETENTION` | P13 | How long `recipe_interactions` are kept | **12 months** (owner, 2026-10-23); daily pg_cron purge in the migration | ✅ |
| `REMOTE_PUSH_APPROVAL` | P13 | Approval to run `supabase link` + `supabase db push` on the remote project | **Approved 2026-10-23** (with the commit). Applied by the Supabase GitHub integration when `main` was pushed (`b72a9d1`), not by `db push`: the production branch follows git `main`. Owner linked the CLI (no DB password asked: CLI 2.121 uses a temporary login role) | ✅ |
| `ACCOUNT_DELETION_WEB_URL` | P14 | Web page for deletion requests (Google Play) | Owner chose GitHub Pages (2026-10-23): `https://ojrandy.github.io/smart_meal/delete-account.html`, source `site/`, published from a `gh-pages` branch. Live: owner enabled Pages and checked the page (2026-10-24) | ✅ |
| `REAUTH_POLICY` | P14 | Default: sign-in within the last 10 minutes | **10 minutes** (owner, 2026-10-23); checked server-side from the token's `amr` timestamps | ✅ |
| `DATA_EXPORT` | P14 → later | JSON export of a user's data | **Later** (owner, 2026-10-23): needed before serving EU residents | ✅ |
| `SPLASH_MIN_DURATION` | P15 | Currently 5 s; recommendation ≤ 2 s | **1.6 s** — set by the owner-approved first-run redesign (2026-10-21, `LaunchReadyNotifier.splashHold`); confirmed in Phase 4 planning (2026-10-24) | ✅ |
| `FIGMA_SETUP_FLOW_URL` | P16 | All setup frames and states | Not used: owner chose screens built in the app's existing style (2026-10-24); the code becomes the source of truth; owner reviews on the phone | ✅ |
| `SETUP_QUESTIONS` | P16 | Confirmed questions and answer options | **Approved 2026-10-24**, in order: 1 lifestyle (student / working professional / family / athlete); 2 household size 1–20; 3 food budget in XAF + per day/week/month; 4 cooking skill + max cooking time; 5 cuisines liked / disliked; 6 diet (the 7 tags or "None"); 7 allergies (the 14 or "None", required); 8 health goals (optional). Consent shown before 6–8 | ✅ |
| `CONSENT_COPY` | P16 | Consent text for allergy/diet data | **Approved 2026-10-24**: "I agree that Smart Meal stores my allergies, diet and health goals to personalise my meals. Only I can see them, and I can delete them anytime." | ✅ |
| `SETUP_LAYOUT` | P16 | One question per step vs grouped pages | **One question per step** with progress bar, Back and Continue (owner, 2026-10-24) | ✅ |
| `CONSENT_POLICY` | P16 | What happens if the user declines sensitive-data consent | **Consent required** to finish setup; the screen explains why (allergy safety, S11) and offers sign-out instead (owner, 2026-10-24) | ✅ |
| `CUISINE_REFERENCE_DATA` | P16 | Cuisine list in production | **Migration** with Cameroonian, West African, Italian, French, Indian, Chinese (owner, 2026-10-24); more can be added later | ✅ |
| `PRODUCTION_CATALOG` | P17 | First recipes in production | **Promote the 12 seed recipes** with a one-off, owner-approved script **after the owner validates the FCFA prices** (owner, 2026-10-24). Prices pending | ⬜ |
| `ENGINE_DECISION` | P17 | A (Edge Function, recommended) / B (Dart) | **A — Edge Function** (owner, 2026-10-24): deterministic TypeScript scoring under the caller's JWT (RLS; never the secret key) | ✅ |
| `SCORING_WEIGHTS` | P17 | Default 30 / 25 / 20 / 15 / 10 | **Defaults approved** (owner, 2026-10-24): budget 30, taste/cuisine 25, time + skill 20, behaviour 15, variety 10; kept in one config place | ✅ |
| `EXPLANATION_COPY` | P17 | Approved "X% match because…" templates | | ⬜ |
| `FIGMA_HOME_URL` | P18 | Home frames, including empty/error states | | ⬜ |
| `CURRENCY_DISPLAY` | P18 | "FCFA" vs "XAF" | **FCFA**, e.g. "2 500 FCFA" (owner, 2026-10-24); zero decimals, shared formatter in `core/` | ✅ |
| `FIREBASE_PROJECT` | P19 | Android + iOS apps registered for `APP_ID` | | ⬜ |
| `APNS_KEY` | P19 | Uploaded to Firebase | | ⬜ |
| `NOTIFICATION_USE_CASES` | P19 | Use cases, copy, and the moment to ask for permission | | ⬜ |
| `PRIVACY_POLICY_URL` | P20 | Live URL | | ⬜ |
| `CRASH_REPORTING_DECISION` | P20 | Crashlytics / Sentry / none (a new dependency if chosen) | | ⬜ |
| `INGREDIENT_PRICE_LIST` | LF01 | Everyday foods with an estimated FCFA price per kg, per litre (palm oil, vegetable oil) or per piece (eggs, cubes, sachets), with source and date | **Supplied 2026-10-29** (owner asked the agent to research): `docs/reference/ingredient-prices-cm.csv` + method page. 45 foods: 27 ready (WFP market survey to Aug 2026, MINCOMMERCE, shelf prices), 6 to check at a market, 12 with no reliable source (left empty, not guessed). Monthly refresh: `tool/wfp_prices.sh`. **Updated 2026-10-29 (LF01):** owner activated the 6 field-check rows and quoted retail prices (ndolé, eru, crayfish, smoked fish, pepper, spaghetti, green spices, bottled water); 22 foods for the seed recipes added → 70 foods, 43 ready, 27 missing (inactive in production) | 🟡 owner market check pending (27 prices + 9 piece weights, list on the method page) |
| `NUTRIENT_SOURCE` | LF01 | Source of nutrient values per 100 g | **Decided 2026-10-29** (owner: agent picks the best sources): FAO/INFOODS WAFCT 2019 first (West African foods, edible portion), USDA FoodData Central SR Legacy (CC0) for the gaps and all sugars. Per-food codes stored for refreshes; method in `docs/reference/ingredient-prices-cm.md` → Nutrients | ✅ |
| `CONSENT_COPY_V2` | LF02 | Consent text that also names health conditions, body measurements and conditions of people the user cooks for (EN + FR) | Draft in `promptLoginFlow.md` LF02 §7 | ⬜ |
| `COUNSEL_HEALTH_DATA` | LF02 | Counsel confirmation for health data and "someone I cook for" data under Law No. 2024/017 | Owner (2026-10-29): the lawyer confirms once the build is done. LF02 stays on its branch until then (migrations on `main` deploy to production) | ⬜ |
| `SETUP_V2_COPY` | LF03 | All new setup strings, EN + FR | Agent drafts; owner / French reviewer approves | ⬜ |
| `HEALTH_DISCLAIMER_COPY` | LF03, LF04 | "Does not replace your doctor" text + the stronger doctor notice (EN + FR) | | ⬜ |
| `SETUP_V2_ILLUSTRATIONS` | LF03 | Images for At home, About you, Health | | ⬜ |
| `MEDICAL_REVIEWER` | LF04 | Dietitian or doctor who signs off the health rules (name, qualification) | Owner (2026-10-29): a doctor signs once the build is done. LF04 is built with draft rules marked unreviewed and merges to `main` only after the signed review sheet | ⬜ |
| `MEDICAL_RULES` | LF02, LF04 | Signed-off rules: exclusions, caps, preferences, energy adjustments and floors per sex, age limits, precedence | Agent drafts; reviewer signs | ⬜ |
| `KITCHEN_DESIGN` | LF05 | Figma URL, or "existing style" as for setup | | ⬜ |
| `KITCHEN_ENTRY_POINT` | LF05 | Where My Kitchen opens from | **Approved 2026-10-29:** Home card + Planner, no sixth tab (A2). Also approved: v1 users answer only the new setup steps (A3) | ✅ |
| `KITCHEN_COPY` | LF05 | My Kitchen strings, EN + FR | | ⬜ |

## Baseline metrics

| Metric | Baseline (2026-10-14) | Latest | Updated by |
|---|---|---|---|
| `flutter analyze` issues | 0 (stock `flutter_lints`) | 0 under strict modes + 9 extra lints, `--fatal-infos` (2026-10-14) | P03 |
| Tests | 1 (placeholder `expect(true, isTrue)`) | 356 (2026-10-29, LF01 adds 12 catalog-tool tests); 65 (2026-10-20): P07 adds 17 `AppConfig` tests; earlier 48 (2026-10-15): P04's 18 + 2 `AppColors` + 3 `CustomButton` + 2 `CustomTextField` + 1 `RecipeCard` + 7 onboarding + 3 onboarding contrast + 12 auth-screen a11y/navigation | P07 |
| Files failing `dart format --set-exit-if-changed` | not measured | 0 (2026-10-14, gated in CI) | P03 |
| Coverage | not measured | 64.6 % lines (484/749, 2026-10-15; was 25.4 % on 2026-10-14) | P05 |
| Bundled image assets | 14.7 MB (4.4 MB unused) | 0.90 MB, 6 files (5 WebP + logo PNG), 0 unused (2026-10-15) | P04 |
| Packages never imported in `lib/` | 8 | 3 — `lottie`, `intl`, `shared_preferences`, all scheduled (2026-10-15) | P04 |
| Release APK size (arm64) | 35,074,878 B (2026-10-14, pre-P04) | 20,873,226 B, −40.5 % (2026-10-15): images −13.76 MB, dex −1.06 MB, other −0.17 MB, Inter +0.79 MB (intermediate, before WebP: 30,253,533 B). Gradle `assembleRelease -Ptarget-platform=android-arm64 -x lintVital*` from a clean tree; `--analyze-size` unavailable (local lint broken) | P04 |
| Cold start on low-end Android | not measured | | P20 |
| Tables with RLS / total tables | 0 / 0 | | P13 |
| pgTAP tests | 0 | 196 assertions in 8 files (2026-10-29) | LF01 |

## Execution log
### 2026-10-29 — LF01 — ✅ Live in production
Agent/session: Claude Code (Opus 5.5)
Summary: `main` fast-forwarded `5998b46..5cf64e8` on the owner's instruction ("commit and deploy to main"); branch `lf01-food-catalog` pushed. The Supabase GitHub integration applied `20261029015243_food_catalog.sql` (43 foods active, 27 inactive until priced; no published recipes in production yet). No UI, so no device check.
Commits: `d16c62a`, `5cf64e8`, plus this record
Verification:
  GitHub checks on `5cf64e8`: Supabase Preview success; Format, analyze, test, build success (run 40846655575); gitleaks success; OSV-Scanner success
  Production REST as anon: `ingredients`, `recipe_costs`, `recipe_nutrition` → 401 (a missing table → 404), so the objects exist and anon is refused
  `supabase migration list --linked` timed out initialising the login role (network); not needed given the integration check
Inputs consumed: none new
New inputs or decisions needed: owner market check (27 prices, 9 piece weights)
Known issues added/closed: none

### 2026-10-29 — LF01 — ⏸️ Committed and merged to `main` (production deploy); plantain per finger
Agent/session: Claude Code (Opus 5.5)
Summary: Owner answered the plantain question (a heap of 5–8 fingers from 1 000 FCFA; good big ones about 4 000 FCFA or more) and approved commit + deploy to `main`. Plantain moved from 475 FCFA/kg to **150 FCFA per finger** (range 125–800, tier O, medium), as decision D1 already said; Poulet DG's line is now 3 fingers. The ordinary-heap price matches WFP's measured 350–550 FCFA/kg at about 250 g a finger. Migration data regenerated by `tool/food_catalog.dart sql`.
Commits: `d16c62a` (data, tool, migration, seed, tests); docs + trackers in the next commit
Verification:
  `db reset` clean (guard accepted all 12 recipes); `test db` → 8 files, 196 assertions PASS; `db advisors --local --type all` → no issues; Poulet DG `recipe_costs` → 4 623 FCFA, 1 156 per serving, source catalog
  `dart format` 0 changed; `flutter analyze --fatal-infos --fatal-warnings` → no issues; `flutter test` → 356 passed
Inputs consumed: plantain heap answer; commit + `REMOTE_PUSH_APPROVAL` for LF01
New inputs or decisions needed: owner market check (27 prices, 9 piece weights incl. a plantain finger from an ordinary and a big heap)
Known issues added/closed: closed — plantain heap weight question

### 2026-10-29 — LF01 — ⏸️ Built and verified locally; waiting on commit + production deploy approval
Agent/session: Claude Code (Opus 5.5)
Summary: Owner approved the plan and answered Q1–Q8 (recorded in `promptLoginFlow.md` §0.1); P16 phone check passed (P16 ✅). Nutrient sources compared: FAO/INFOODS WAFCT 2019 (West African foods, edible-portion coefficient, no sugars, free Excel), USDA FoodData Central (public domain; API needs a data.gov key, bulk CSV needs none), ANSES-CIQUAL (French foods, attribution required), Open Food Facts (packaged products, ODbL share-alike, thin African coverage), commercial APIs (paid, terms forbid caching). Chosen: WAFCT first, USDA SR Legacy for gaps and sugars; values extracted once from the downloaded files, never called from the app (H5, S1). Built: price list extended to 70 foods (owner retail quotes per ball / bundle / heap / pack, water as bottled drinking water); `ingredient-catalog-cm.csv` (codes, edible portions, piece weights, densities, allergens, draft flags, staples, local names); `tool/food_catalog.dart` (generates `ingredient-nutrients-cm.csv` and the migration's data block, an upsert); migration `20261029015243_food_catalog.sql` (4 enums, `ingredients` with unit/price/nutrient CHECKs and RLS active-only, `recipe_ingredients.ingredient_id` + `amount`, deferred publishing guard on 3 tables, `recipe_costs` + `recipe_nutrition` security-invoker views); seed: 12 recipes linked, placeholder costs removed, curry gets celery, DEV PLACEHOLDER prices for 22 unpriced foods (local only). Found and fixed while building: USDA sugars above WAFCT carbohydrate for milk powder, eggs and tinned tomatoes, so the tool now caps parts at their whole. USDA's low-sodium bouillon entry would have understated a cube's salt about 25-fold, so the regular powder is used instead.
Commits: none (not authorized this session)
Verification:
  `npx supabase@2.121.0 db reset` → 4 migrations + seed applied (guard accepted all 12 recipes)
  `npx supabase@2.121.0 test db` → 8 files, 196 assertions, PASS (`08_food_catalog`: 44 — unit pairings, ranges, publish refusals incl. allergen drift and later edits, deferred mode, hand-calculated cost/kcal/sodium, unknown → null, anon + client-write refusals)
  `db lint` → no schema errors; `db advisors --local --type all` → no issues
  DB export vs `ingredient-prices-cm.csv` (scratch compare script) → 70 rows, every field matches (22 local placeholders only on rows without a price)
  REST (local): anon 401 on `ingredients` and `recipe_costs`; signed-in 65 active foods, Koki 765 FCFA / 128 per serving from the catalog, Jollof nutrition complete; client PATCH on `ingredients` 403
  `dart format --set-exit-if-changed .` → 0 changed; `flutter analyze --fatal-infos --fatal-warnings` → No issues found; `flutter test` → 356 passed
Inputs consumed: plan approval, Q1–Q8, `NUTRIENT_SOURCE` (agent choice per owner), `INGREDIENT_PRICE_LIST` (extended)
New inputs or decisions needed: commit authorization; production deploy (merge to `main`) approval; owner market check (27 prices, 9 piece weights)
Known issues added/closed: added — 27 unpriced foods inactive in production; estimated piece weights; foods without composition data; draft allergens/flags; legacy `est_cost_xaf`. Closed — seed recipe placeholder prices.

### 2026-10-29 — LF01 — ⏸️ Plan posted; waiting on plan approval and inputs
Agent/session: Claude Code (Opus 5.5)
Summary: Read `prompt.md` §0, `promptLoginFlow.md` §0 + LF01, schema v1, seed, the price list and its method page. No code written (plan approval required). Findings: (1) **No seed recipe can be fully linked to active catalog rows.** Each needs at least one food that is `missing`/`field_check` (ndolé leaves, eru, crayfish, smoked fish, fresh pepper, spaghetti, mackerel) or absent from the list (about 25: prawns, waterleaf, carrots, green beans, bell peppers, yeast, chickpeas, coconut milk, soy sauce, sesame oil, butter, fresh milk, parmesan, celery, spring onions, curry powder, mustard seeds, limestone, achu spice, mbongo spice, whole fish, beef skin, tinned tomatoes, banana leaves, water). (2) D1 says plantain is priced per piece; the CSV prices it per kg. (3) Nutrients are per 100 g edible portion but prices are as bought (peel, bone), so the views need an edible-portion factor the prompt does not list. (4) Deep-frying oil (puff-puff 1 L) would count all the oil as eaten. (5) Curry powder and bouillon cubes usually carry celery/mustard/gluten/soy; the publish-time allergen check will refuse current seed lists if the catalog marks them. (6) `price_updated_at not null` has no date for `missing` rows. (7) `is_kitchen_staple` and `aliases` are not in the CSV. (8) Cross-table invariants need deferred constraint triggers on `recipes`, `recipe_ingredients` and `ingredients`, or a later catalog edit could silently break a published recipe.
Commits: none (not authorized)
Verification: n/a (plan only)
Inputs consumed: `INGREDIENT_PRICE_LIST`
New inputs or decisions needed: plan approval; `NUTRIENT_SOURCE`; Q1–Q8 (end-of-task report of this session); go-ahead while P16 is ⏸️; commit + `REMOTE_PUSH_APPROVAL` for LF01
Known issues added/closed: none yet (logged at implementation)

### 2026-10-29 — Ingredient price list — ✅ Compiled (market check pending)
Agent/session: Claude Code (Opus 5.5)
Summary: On the owner's request, researched estimated Cameroonian market prices for the LF01 catalog. Backbone: WFP's Cameroon retail price survey on HDX (CC BY-IGO; compiled from MINCOMMERCE, INS, MINADER, FAO), 77 268 rows up to 2026-08-15. Median of the last 12 months in 10 southern urban markets (Yaoundé, Douala, Buea, Limbé, Kumba, Bamenda, Mamfé, Tiko, Mutengene, Muea); rural producer and northern markets excluded because they sell well below city prices. Products WFP doesn't cover (rice, vegetable oil, beef, chicken, eggs, mackerel) come from MINCOMMERCE ceilings, supermarket shelf prices and dated 2026 press reports. Items with no reliable source were left empty, not guessed. Wrote `docs/reference/ingredient-prices-cm.csv` (45 foods: 27 ready, 6 field check, 12 missing), its method page, the 659 WFP observations used, and `tool/wfp_prices.sh` for monthly refreshes. Recorded the owner's answers in `promptLoginFlow.md` (doctor and lawyer sign after the build, so LF02/LF04 stay off `main` until then; A2 + A3 approved).
Commits: none (not authorized)
Verification: `tool/wfp_prices.sh` re-downloaded the dataset and reproduced every WFP median in the list; CSV check: 46 lines × 16 columns, every price within its range
Inputs consumed: `INGREDIENT_PRICE_LIST` (agent-researched), A2, A3
New inputs or decisions needed: owner market check of 18 items (list on the method page)
Known issues added/closed: none

### 2026-10-29 — Login-flow prompt pack — ✅ Written
Agent/session: Claude Code (Opus 5.5)
Summary: The owner's requests of 2026-10-28/29 ("what do you have at home" after the budget step, specific health conditions, gain weight for men and women, My Kitchen as a store room) turned into `docs/promptLoginFlow.md`. LF01: food catalog with prices per kg / litre / piece and nutrients. LF02: setup v2 schema + `complete_setup_v2`. LF03: setup v2 screens (12 steps; v1 users answer only the new ones). LF04: reviewed health rules + sex-specific energy targets. LF05: My Kitchen. The pack adds health safety rules H1–H6 and lists what is deliberately left out. P17 now depends on LF04 (Appendix A). No code changed.
Commits: none
Verification: n/a (documentation only)
Inputs consumed: owner decisions D1–D4 (2026-10-29)
New inputs or decisions needed: the 12 LF inputs in the register; confirm analyst defaults A1–A5 at LF01 plan approval
Known issues added/closed: none

### 2026-10-28 — Polish + offline — ✅ Owner approved, committed
Agent/session: Claude Code (Opus 5.5)
Summary: Owner requests 2026-10-27/28 on branch `l10n-bilingual`, uncommitted. Fixed Google sign-in: added an Android OAuth client, and the owner enabled the Supabase Google provider (`/auth/v1/settings` → `google: true`). Removed every field placeholder. Swapped in real West/Central African food photos (credits in `design-assets/source/PHOTO-CREDITS.md`). Gave the onboarding photos a slow zoom and made the text larger. Added an animated `/auth/check-email` screen with a resend cooldown after email sign-up. Added a short pause after setup step 5. Replaced the small step avatar with a large unDraw illustration per setup step (owner: "too small … 40–50 % of the screen"): 40 % of the screen height (180–380 px), recoloured to the app green with brown skin tones, at the top of the scrolling question and hidden while the keyboard is open. Offline (owner: "stuck at a personalization screen"): every Supabase request now goes through `TimeoutHttpClient` (20 s for the response to start and for each pause in the body), and `isConnectionError` turns a failed save into "No internet connection…" with a wifi-off icon and Try again, keeping the answers. Email sending: the owner set up Brevo SMTP; Supabase custom SMTP and the email rate limit are being set by the owner.
Verification:
  `flutter analyze` → no issues
  `flutter test` → 344 passed (new: TimeoutHttpClient + isConnectionError unit tests, offline/timed-out save, step illustration)
  debug APK built; owner (2026-10-28): "everything is okay. commit it"
Inputs consumed: owner design decisions above
New inputs or decisions needed: French wording of the new strings (check-email, breather, `setupSaveNoConnection`); Supabase SMTP and rate-limit setup; release SHA-1s for the Google Android client
Known issues added/closed: closed — requests could hang forever offline (no timeout); closed — Google sign-in failed (no Android OAuth client, provider disabled)

### 2026-10-27 — L10N + CI — ⏸️ French approved, merged, on the owner's phone
Agent/session: Claude Code (Opus 5.5)
Summary: Owner (2026-10-27): French approved; install the app on the phone; run gitleaks locally. Gitleaks 8.30.1 (the CI version) with `.gitleaks.toml` over the full history found one finding: rule `generic-api-key`, `test/core/config/app_config_test.dart:91`, commit `887db90` (P07, 2026-10-20) — the fake values `'sb_secret_abc'` and `'eyJhbGciOiJIUzI1NiJ9.x.y'` that test AppConfig's refusal of secret keys. Not a credential, nothing to rotate. Added `.gitleaksignore` with that one fingerprint and the reason; any other finding still fails CI. Merged `l10n-bilingual` into `main` (fast-forward) and pushed. Built a profile APK from `main` (AOT like release, debug-signed because `android/key.properties` does not exist yet) with `env/dev.json` and installed it on the owner's Pixel 6a over adb.
Verification:
  local gitleaks after the change → "78 commits scanned … no leaks found"
  CI on the new `main` → see the next tracker update
  on-device → **pending, owner** (see the L10N row)
Known issues added/closed: closed — gitleaks CI job red since 2026-10-20.

### 2026-10-27 — L10N — ⏸️ Waiting on the French review
Agent/session: Claude Code (Opus 5.5)
Summary: The app is bilingual (owner, 2026-10-26). Flutter gen-l10n with `lib/core/l10n/app_en.arb` (template, 200 keys, each described) and `app_fr.arb`; `context.l10n` everywhere, no string literal left in a widget except brand names, the currency code and the placeholder screens' tab names (also localized). Domain code no longer produces English: `AuthError` carries an `AuthErrorReason`, validators return a `FieldError`, `SetupFailed` has no message, the auth-link error is a flag; presentation words them (`authErrorText`, `fieldErrorText`, `setup_labels.dart`, cuisine names by slug with the server name as fallback). Plurals via ICU (people, budget advice per period). New `features/language/`: `appLanguageProvider` (pick saved in SharedPreferences `smartmeal.language`, null = follow the phone), `resolveAppLocale` (French phones → French, else English), `LanguageSwitch` EN | FR (onboarding top-left, sign-in header). `MaterialApp` gets the delegates, so Material's own text (back tooltip, dialogs) is French too. iOS `Info.plist` declares `CFBundleLocalizations` en, fr. `intl` constraint lowered to `^0.20.2` (pinned by `flutter_localizations`). English copy unchanged; the new-password and sign-in "missing password" messages stay distinct as approved.
Commits: on branch `l10n-bilingual`.
Verification:
  `dart format` → 0 changed; `flutter analyze --fatal-infos --fatal-warnings` → No issues found; `flutter test` → 333 passed
  on-device → **pending, owner**: switch EN | FR on onboarding and sign-in, run sign-up and setup in French, read every French line
Inputs consumed: language choice (phone + switch), French by agent with owner review, scope all app screens
New inputs or decisions needed: French review (`COPY_APPROVALS`); later: French auth emails and deletion page; Profile gets the switch in T1
Known issues added/closed: closed — English-only app (French drafted; review pending). Added — auth emails and the public deletion page are English only.

### 2026-10-26 — P16 — ⏸️ Deployed; waiting on the owner's phone check
Agent/session: Claude Code (Opus 5.5)
Summary: Owner answers (2026-10-26): commit and merge; setup copy approved; monthly budget suggestion 30 000 FCFA (was 25 000, which was below the daily 1 000 per day); make the app bilingual now (next task). Applied the budget change (`budget_advice.dart`, tests). Also added the data types P16 owed the iOS privacy manifest: Health (allergies, diet, goals) and Other Data Types (household, budget, cooking, food likes), both linked, no tracking, app functionality only. Committed, pushed `p16-setup-flow` and `p15-setup-gate`, fast-forwarded `main` to `5971120` and pushed, so the GitHub integration applied migration `20261024073206` to production.
Commits: `5971120` P16 (on `main` with P15 `99fbe35` `d02ae8b`) · tracker commit.
Verification:
  `dart format` → 0 changed; `flutter analyze` → No issues found; `flutter test` → 315 passed
  `db push --dry-run --linked` → could not run (it waits for the database password); the diff to production is one migration, `20261024073206_setup_flow.sql`, and its cuisine insert is `on conflict do nothing`
  production after the push, publishable key: `rpc/complete_setup` with all arguments → 401 `42501 permission denied for function complete_setup` (the function exists; anon refused); `cuisines` → 401 `42501` (anon has no access)
  CI run 40411930364 (`5971120`): quality gate + debug APK ✅, OSV ✅, **gitleaks ❌**. Not caused by P16: gitleaks has failed on every `main` push since run 39508795850 (`8e53480`, 2026-10-20, P06–P08); last green 38788496280 (`caa1b55`). The diff since then holds no secret-like value I could find (searches for JWT, `sb_secret_`, `AIza`, private keys, credential assignments); the job log needs a GitHub login. Running the pinned gitleaks locally was blocked by this session's permission policy. Logged as a known issue
  on-device → **pending, owner**
Inputs consumed: `COPY_APPROVALS` (P16 approved), budget figures (monthly 30 000)
New inputs or decisions needed: owner phone check; the gitleaks job log (or permission to run gitleaks locally); bilingual app decisions (next task)
Known issues added/closed: added — gitleaks CI job red since 2026-10-20. Closed — budget figure inconsistency; P16 privacy-manifest data types.

### 2026-10-24 — P16 — ⏸️ Waiting (owner: commit + production deploy, phone check, copy)
Agent/session: Claude Code (Opus 5.5)
Summary: Setup flow in the app's style (owner, no Figma), one question per step (9 steps, progress bar, Back/Continue pinned). Server: migration `20261024073206_setup_flow.sql` adds the six cuisines as reference data (plain names, e.g. "Cameroonian food"; seed no longer inserts them) and `complete_setup(...)` — security invoker, validates every input (budget 1–10 000 000, household 1–20, cook time 5–480, closed vocabularies, cuisines exist, no like+dislike), requires consent (S6), and in one transaction upserts `user_preferences` (allergens_declared = true), replaces cuisine likes/dislikes and sets `profiles.setup_completed_at`. App: `features/setup/` — `SetupDraft` (immutable, in memory only), `SetupNotifier` (sealed editing/submitting/completed/failed; resets on user change), `SetupRepository` (reusable by Profile), `setup_vocabulary.dart` (DB values) vs `setup_labels.dart` (plain Cameroonian words with familiar examples — owner feedback), `budget_advice.dart` (owner figures as per-person suggestions, +70 % per extra person, integer math, advice only), `core/formatting/fcfa.dart` ("2 500 FCFA", no-break space, input formatter). Screens: `SetupQuestionsScreen` (both routes), `SetupProcessingScreen` (atomic save, 2.1 s minimum, retry). Found and fixed a race: a setup-status check started before `complete_setup` committed could overwrite `markComplete` and bounce the user back into setup; `SetupStatusNotifier` now ignores answers older than the newest fact (generation counter) — regression test added.
Commits: none yet — owner to authorize (merges with P15).
Verification:
  `npx supabase@2.121.0 db reset` → 3 migrations + seed applied; `test db` → 7 files, 152 assertions, PASS; `db lint` → No schema errors found
  `dart format` → 0 changed; `flutter analyze --fatal-infos` → No issues found; `flutter test` → 315 passed
  local end to end (scratchpad `p16_e2e.sh`): signup → 6 cuisines → complete_setup without consent 400 (gate closed) → with full answers 200 → gate open, preferences/consent/cuisines stored → cleanup cascades
  on-device → **pending, owner**
Inputs consumed: `SETUP_LAYOUT`, `CONSENT_POLICY`, `CUISINE_REFERENCE_DATA`, `SETUP_QUESTIONS` (reworded to plain local language on owner feedback), `CONSENT_COPY`, budget advice figures
New inputs or decisions needed: commit + production deploy; approval of the setup copy (`COPY_APPROVALS`); confirm or adjust the monthly budget figure (25 000 vs daily 1 000); French localisation timing
Known issues added/closed: added — English only (French follow-up); budget figure inconsistency; Profile must reuse complete_setup. Closed — users stuck at the setup placeholder (once P15+P16 merge).

### 2026-10-24 — P15 — ⏸️ Waiting (owner: commit authorization, phone check)
Agent/session: Claude Code (Opus 5.5)
Summary: Setup gate on top of P10's launch routing. `features/setup/data/setup_status_repository.dart` reads `profiles.setup_completed_at` (RLS: own row) and keeps a per-user boolean `smartmeal.setup_complete.<uid>`; `features/setup/domain/setup_status.dart` (`SetupStatus`: signedOut, checking, incomplete, complete, unavailable) starts from the cache, confirms with the server on sign-in, app resume (`AppLifecycleListener`) and retry, keeps the cache when offline, and clears the departing user's cache on sign-out (S12). `LaunchSnapshot.isSetupComplete` + `resolveRedirect` implement the prompt's table: unfinished or unknown → `/setup/loading`, finished → `/home`, `/setup/*` and public routes → `/home` when finished, recovery first. `_RouterRefreshNotifier` listens to `setupStatusProvider` (no second mechanism). `SetupLoadingScreen` (app style, owner decision): spinner "Getting things ready…", offline with no cache → "No connection…" + Try again + Sign out, unfinished → `/setup/lifestyle`. Splash hold stays 1.6 s (`SPLASH_MIN_DURATION`). Docs: `architecture-context.md` (setup gate), `progress-tracker.md`.
Commits: on branch `p15-setup-gate` (pushed); merged into `main` with P16.
Verification:
  `dart format --output=none --set-exit-if-changed .` → 0 changed
  `flutter analyze --fatal-infos` → No issues found
  `flutter test` → 251 passed (first run: 2 failures from a test assertion — the placeholder shows its title twice — fixed to match the app bar)
  on-device → **pending, owner**
Inputs consumed: `SPLASH_MIN_DURATION` (1.6 s), plan approval
New inputs or decisions needed: owner phone check after P16 (owner, 2026-10-24: commit, push the branch, merge with P16; copy approved)
Known issues added/closed: added — users stop at the lifestyle placeholder until P16.

### 2026-10-23 — P14 — ⏸️ Waiting (owner: commit/deploy authorization, GitHub Pages, copy)
Agent/session: Claude Code (Opus 5.5)
Summary: Edge Function `supabase/functions/delete-account` (TypeScript): `withSupabase({ auth: 'user' })` from `@supabase/server` 1.9.1 verifies the caller's JWT inside the function against the project JWKS (current Supabase guidance; gateway `verify_jwt` stays on as a first layer); logic in `handler.ts` (testable, no clients): POST only → sign-in within 10 min from the token's `amr` timestamps → 5 attempts per user per rolling hour (`public.note_account_deletion_attempt`, service role only, new migration `20261023172323`) → delete `avatars/{uid}/…` (recursive) → push tokens → `auth.admin.deleteUser` (404 counts as done, so retries are idempotent). Stable error codes; logs carry no user id, email or token. Imports pinned in a per-function `deno.json` + `deno.lock` (server 1.9.1, supabase-js 2.117.3, both ≥ 2 weeks old). Flutter: `AuthRepository.deleteAccount()` → `functions.invoke('delete-account')` with typed `AccountDeletionFailure`s, then local sign-out (Google + Supabase `scope: local`); `AuthNotifier.deleteAccount()` → `AuthAccountDeleted` / `AuthReauthenticationRequired` / mapped `AuthError`. No UI (T1-Profile). Web deletion page `site/delete-account.html` (+ redirecting `index.html`) for GitHub Pages. `docs/SECURITY.md` §11 (deletion flow, retention table, data export follow-up), `context/data-model.md` (function + Edge Function). Tooling: Deno 2.9.8 via scoop and the edge-runtime image (owner OK); the linked project's image-version pins in `supabase/.temp` were set aside so the local stack could start on downloaded images.
Commits: see the status row. Owner (2026-10-23) approved everything: commit + production deploy, GitHub Pages, the public contact address and 30-day promise, all new copy.
Verification:
  `deno test --allow-env` (function dir) → 10 passed, 0 failed
  `npx supabase@2.121.0 test db` → 6 files, 130 assertions, PASS; `db lint` → No schema errors found
  `dart format` → 0 changed; `flutter analyze --fatal-infos` → No issues found; `flutter test` → 220 passed
  local end to end (scratchpad `p14_e2e.sh`): Deno-served function → before 1×9 rows + 2 avatar files; no token 401, GET 405, delete 200 `{"status":"deleted"}`, retry 200; after all 0; catalog 12 untouched; log has no user id/email
  same through `supabase functions serve` (edge-runtime 1.77.4) behind the gateway with `verify_jwt = true` → identical results
  `grep` `service_role|sb_secret|SECRET_KEY` in `lib/` → comments and the config guard only
Inputs consumed: `ACCOUNT_DELETION_WEB_URL` (GitHub Pages), `REAUTH_POLICY` (10 min), `DATA_EXPORT` (later)
New inputs or decisions needed: commit + production deploy authorization; owner enables GitHub Pages (Settings → Pages → branch `gh-pages`); approval of new copy (`COPY_APPROVALS`); confirm the 30-day email-deletion promise and the public contact address on the page
Known issues added/closed: added — deletion has no UI yet (T1-Profile, before release); local image versions differ from live; offline deletion error maps to the generic message.

### 2026-10-23 — P13 — ✅ Done (owner: Advisors empty; old accounts deleted by the owner)
Agent/session: Claude Code (Opus 5.5)
Summary: Owner confirmed the Dashboard Security and Performance Advisors list nothing, and that the live project has no users because the owner deleted the old accounts. All P13 acceptance criteria met: schema approval recorded, pgTAP green (121), no table without RLS, anon has no table access, live deploy after approval.
Commits: tracker commit only.
Verification: owner Dashboard check (Advisors) → empty.
Inputs consumed: none new.
New inputs or decisions needed: none for P13. Owner signs up again on the phone to test (the signup trigger creates the profile).
Known issues added/closed: closed — 0 auth users (owner deleted them).

### 2026-10-23 — P13 (live) — ⏸️ Waiting (owner: Dashboard Advisors, auth users question)
Agent/session: Claude Code (Opus 5.5)
Summary: Owner approved commit and push. `60553db` + `b72a9d1` went to `p13-schema` and `main`. When the owner linked the CLI, `migration list --linked` already showed `20261023102159` applied, though nobody ran `db push`: the project's Supabase GitHub integration (production branch `main`, git branch `main`, created 2026-10-21) applied it when `main` was pushed. Every later migration on `main` deploys the same way, which is now documented (`architecture-context.md`, `SECURITY.md` §9). Read-only checks of the live database match local exactly. The live project has 0 auth users, 0 identities and 0 audit entries although the app's dev env targets this project and the owner signed in on 2026-10-21 — unexplained, raised with the owner; nothing was changed.
Commits: `60553db` `b72a9d1` + this tracker commit (on `main`).
Verification:
  `npx supabase@2.121.0 migration list --linked` → local 20261023102159 = remote 20261023102159
  `npx supabase@2.121.0 branches list` → default branch `main` ↔ git `main`, created 2026-10-21
  `db query --linked` (read-only) vs `--local` → identical: 28 public policies, 4 avatar policies, buckets avatars + recipe-images, signup trigger, 0 tables without RLS, 0 anon grants; live: 0 recipes (seed is local only), 1 cron job
  `db dump --linked` → wrote an empty file (inconclusive; not relied on)
  `db advisors --linked --type all` → exit 0, no output (inconclusive) → owner checks the Dashboard
Inputs consumed: `REMOTE_PUSH_APPROVAL`
New inputs or decisions needed: owner checks Dashboard → Advisors (Security + Performance); owner says whether the live project should have users
Known issues added/closed: added — migrations deploy on push to `main` (SECURITY.md §9).

### 2026-10-23 — P13 — ⏸️ Waiting (owner approval to link + push)
Agent/session: Claude Code (Opus 5.5)
Summary: Schema v1 as one migration (`20261023102159_schema_v1.sql`): the 12 tables of the prompt; enum vocabularies (one `allergen` type shared by recipes and preferences, S11); cuisines as a lookup table; RLS on every table, one policy per operation `to authenticated` with `(select auth.uid())`; column-level grants so `id`/`user_id`/`created_at` never change; no anon access; no client write path to the catalog; insert policies also require a published recipe (a foreign key alone would accept a guessed draft id). S6 is enforced in Postgres: allergy/diet/goal values need `sensitive_data_consent_at`. Meal-plan entries carry the plan's week through a composite key, so the date range is a plain CHECK. Definer functions: `public.register_push_token` (client RPC, caller = `auth.uid()`) and `private.handle_new_user` (signup trigger), both `search_path = ''`, closed to anon. 12-month interaction retention via pg_cron. Storage: public `recipe-images` (no client writes), private `avatars` (`{uid}/…`, jpeg/png/webp, 5 MB). `config.toml` regenerated by `supabase init` (CLI 2.121.0) and merged with P11's redirects plus the §5 targets (confirmations on, 8+ chars with all classes). Seed: 6 cuisines, 12 recipes with allergens checked ingredient by ingredient, prices marked placeholder. Docs: new `context/data-model.md` (ERD, access matrix, functions), `AGENT.md` reading list, `architecture-context.md` backend workflow.
Commits: on `p13-schema` (see status row once committed).
Verification:
  `npx supabase@2.121.0 db reset` → migration + seed applied
  `npx supabase@2.121.0 test db` → 5 files, 121 assertions, Result: PASS (first run caught only a miscounted plan)
  `npx supabase@2.121.0 db lint` → No schema errors found
  `npx supabase@2.121.0 db advisors --local --type all` → No issues found
  local GoTrue: weak password → 422; valid sign-up → 200 and a profile ("Probe User", CM), unconfirmed until the email link
  local REST: anon `GET /recipes` → 401; signed in → 12 recipes, own profile only; `POST /recipes` → 403; `rpc/register_push_token` → 204; deleting the probe user cascaded its token away
Inputs consumed: `SCHEMA_APPROVAL`, `VOCABULARIES`, `INTERACTION_RETENTION`
New inputs or decisions needed: `REMOTE_PUSH_APPROVAL` (link needs the DB password, typed by the owner); seed prices (owner, later)
Known issues added/closed: added — placeholder seed prices; hosted project not yet checked for dashboard-made objects; pgTAP not in CI. Closed — hand-written `config.toml` (now merged with `supabase init` output).

### 2026-10-23 — P11 — ⏸️ Waiting (owner Dashboard settings, device check)
Agent/session: Claude Code (Opus 5.5)
Summary: Password recovery end to end, and email links that open the app. `AuthRepository` sends `redirectTo` / `emailRedirectTo` = `com.ojtech.smartmeal://auth-callback`, and adds `updatePassword` and `signOutOtherSessions`. Forgot-password screen: always the neutral confirmation — including for `over_email_send_rate_limit`, which Supabase raises only for existing accounts — plus a 60 s resend cooldown. Recovery: `AuthSessionNotifier` sets the persisted `passwordRecoveryProvider` flag on `passwordRecovery` before it publishes the session; `resolveRedirect` then allows only `/auth/reset-password` (the restart case is covered). Saving runs `updateUser` → `signOut(scope: others)` → recovery ends → normal routing; back signs out. PKCE stays the flow (the v2 default, not overridden). Failed links (`error=` redirect, missing verifier, rejected code) surface from the auth stream through `isAuthLinkError` as the approved message on a new root `ScaffoldMessenger` (`rootScaffoldMessengerKey`). Android intent filter + iOS `CFBundleURLTypes`; minimal `supabase/config.toml` (site URL + one allow-listed URI); `docs/SECURITY.md` §10 + three §9 rows; `architecture-context.md` routing notes. New shared `AuthScreenHeader` for the two screens.
Commits: see the status row. Branch `p11-password-recovery` (off `main` at `ee4e3e7`), fast-forwarded onto `main` and pushed (owner, 2026-10-23). Owner answers (2026-10-23): commit; Dashboard + templates yes (owner applies; templates drafted in `supabase/templates/`); remaining copy approved; mismatch wording left to the agent → "Passwords don't match" everywhere; device check (item 6) after the Dashboard settings.
Verification:
  `dart format --output=none --set-exit-if-changed .` → 0 changed
  `flutter analyze --fatal-infos` → No issues found
  `flutter test` → 216 passed (was 174)
  grep `e\.message|toString\(\)\.contains|RegExp\(` over `lib/features` → nothing
  `flutter build apk --debug --dart-define-from-file=env/dev.json` → built; merged manifest has the `VIEW`/`DEFAULT`/`BROWSABLE` filter with `scheme="com.ojtech.smartmeal" host="auth-callback"` on `MainActivity`
  on-device end-to-end with a real mailbox and the `adb shell am start … ?code=invalid` check → **pending, owner** (no emulator on this host; needs the Dashboard allow-list first)
Inputs consumed: design decision (no Figma), `AUTH_REDIRECT_URI`, recovery copy, config.toml decision
New inputs or decisions needed: `SUPABASE_REDIRECT_ALLOWLIST` and `SUPABASE_EMAIL_TEMPLATES` (owner applies in the Dashboard), then the device check; `APP_LINK_DOMAIN` (later)
Known issues added/closed: added — custom-scheme links (App Links migration), un-retried revoke of other sessions, duplicated auth header in login/signup, hand-written `config.toml` for P13 to merge. Closed — stale "login 6 vs signup 8" password row (fixed in P10).

### 2026-10-21 — P10 (+ database-free part of P15) — ⏸️ Waiting (owner phone check, copy approval)
Agent/session: Claude Code (Opus 5.5)
Summary: Owner asked for a "smooth and perfect" first-run flow and chose P10 plus launch routing. State model (owner approved the scope in chat): `authSessionProvider` (`auth_session.dart`) holds the signed-in `User?` from the Supabase stream and is all the router reads; `AuthNotifier` keeps only operation state — `AuthIdle`, `AuthLoading`, `AuthError`, `AuthAwaitingEmailConfirmation`, `AuthResetEmailSent`. Google failures are typed in the data layer (`GoogleSignInCancelled` / `GoogleSignInNetworkFailure` / `GoogleSignInFailed`, from `PlatformException.code` via the `GoogleSignIn.k…` constants); a cancel goes back to idle with no snackbar. One mapper, `formatAuthError` (`@visibleForTesting`), covers the 14 codes in the prompt plus network (`AuthRetryableFetchException`, `SocketException`, `TimeoutException`); its default is a generic message and raw errors only reach `AppLogger`. Validators in `lib/core/validation/validators.dart`: email ≤ 254 with plus-addressing and long TLDs; new password 8 chars–72 bytes with lower, upper, digit and Supabase's symbol set (the `docs/SECURITY.md` §5 target); login password non-empty only. Screens no longer navigate to `/home`; signup goes to login after the confirmation message. Sign-out: Supabase clears the local session before the server revoke, so an error shows only when a session is still there (e.g. the Google step failed). Launch routing: the splash only animates; `launchReadyProvider` (1.6 s hold), `onboardingSeenProvider` (`OnboardingRepository`, SharedPreferences `smartmeal.onboarding.seen`, set on Skip and Get started) and the session feed the pure `resolveRedirect(LaunchSnapshot)` in `core/router/launch_redirect.dart` through the existing `_RouterRefreshNotifier`. SharedPreferences loads in `main()` (`sharedPreferencesProvider`). Interim `HomeScreen` greets the user (Google `full_name`, else email) with a Sign out button — P18 replaces it. Apple and Facebook buttons removed from both screens (owner: hide until real); their color tokens and `font_awesome_flutter` stay for P12. Shared `showAppSnackBar` replaces three copies. Docs: `architecture-context.md` (session vs operation state, typed failures, `resolveRedirect`, `core/validation/`), `code-standard.md`, `ui-context.md`, `progress-tracker.md`.
Commits: `b404a0f` code + tests · `65a9e39` context docs · tracker commit. Branch `p10-auth-flow`, fast-forwarded onto `main` and pushed (owner, 2026-10-22).
Verification:
  `flutter analyze --fatal-infos` → No issues found
  `flutter test` → 174 passed (was 78)
  grep `e\.message|toString\(\)\.contains|RegExp\(` over `lib/features` → nothing (no inline regex left in screens)
  on-device run → **owner's phone**: fresh install → onboarding once; relaunch → login; Google sign-in → Home with name; Sign out → login; relaunch while signed in → Home directly; cancel the Google picker → no message
Inputs consumed: owner scope decision; Apple/Facebook hidden until P12 (interim `DECISION_FACEBOOK` / `DECISION_APPLE_ON_ANDROID`); sign-up copy
New inputs or decisions needed: `COPY_APPROVALS` for these new messages — "Something went wrong. Please try again." · "No connection. Check your internet and try again." · "Google sign-in failed. Please try again." · "An account with this email already exists. Try signing in." · "Choose a stronger password: at least 8 characters with upper- and lowercase letters, a number and a symbol." · "Too many attempts. Please wait a moment and try again." · "New sign-ups are paused right now. Please try again later." · "That email address can't be used. Please check it and try again." · "Please check your details and try again." · "Your new password must be different from your current one." · "Your session has expired. Please sign in again." · "This account can't sign in right now." · "Use upper- and lowercase letters, a number and a symbol" · "Password is too long" · Home: "Welcome, {first name}" / "Welcome to Smart Meal", "Signed in as {email}", "Your personalized meals will appear here soon ✨", "Sign out". The owner must also set the Supabase password policy to match (`SECURITY.md` §5); until then the client is the stricter side.
Known issues added/closed: closed — splash always showed onboarding; onboarding "seen" not persisted; raw server text in the UI; red snackbar on Google cancel and string-matched cancel detection; 6-vs-8 password rules and the narrow email regex; duplicate `/home` navigation; "Account created!" possibly untrue; a failed sign-out ejected the user; "coming soon" buttons reachable; no way to sign out. Updated — test coverage (auth notifier and router redirect now tested).

Newest entry first. Copy the template for each entry.

```text
### YYYY-MM-DD — Pxx — <✅ Done | 🔴 Blocked | ⏸️ Waiting>
Agent/session: <tool + model, if known>
Summary: <what changed and why, 2–4 sentences>
Commits: <hashes or "staged, not committed">
Verification: <command → result, one per line>
Inputs consumed: <keys>
New inputs or decisions needed: <keys, or "none">
Known issues added/closed: <list>
```
### 2026-10-21 — P08 — ✅ Done (owner smoke test passed; Xcode step pending a Mac)
Agent/session: Claude Code (Opus 5.5)
Summary: Rebuilt the obfuscated release APK from current `main` (adds P09's `flutter_secure_storage` under R8 and the new splash/photos) with a throwaway key outside the repo, deleted afterwards. The owner installed it and confirmed the splash, photos, email login, Google sign-in and that a restart keeps the session. The Xcode *Target Membership* step for `PrivacyInfo.xcprivacy` stays pending until the owner has a Mac (expected soon); it does not block Android.
Commits: tracker update only (with P10's commits).
Verification:
  `flutter build apk --release --target-platform android-arm64 --dart-define-from-file=env/dev.json --obfuscate --split-debug-info=build/symbols/1.0.0+1` → `app-release.apk` (19.1 MB), no proguard rule needed for `flutter_secure_storage`
  throwaway keystore + `android/key.properties` → deleted; `git status` clean
  owner smoke test on the phone → passed
Inputs consumed: owner smoke-test result; `MACOS_ACCESS` (none yet, expected soon)
New inputs or decisions needed: none for P08; the real upload keystore stays the owner's task (`RELEASE_KEYSTORE`)
Known issues added/closed: none.

### 2026-10-21 — Owner request: first-run redesign (outside the pack) — ⏸️ Waiting (owner sees it on the phone)
Agent/session: Claude Code (Opus 5.5)
Summary: The owner judged the splash, onboarding and auth-hero art (AI-generated in Antigravity) too generic and gave the agent authority to redesign, overriding Figma for these screens. Owner choices: scope = splash + onboarding + auth heroes; photos = real local dishes, no faces; splash = minimal brand, fast. Five free Unsplash License photos (not Unsplash+), cropped server-side to WebP q80 with no faces, brands or signage; credits and exact crops in `design-assets/source/PHOTO-CREDITS.md`. Onboarding was relaid out: photo on top (32 px rounded corners), dark text on cream, fixed dots + `CustomButton`, with no scrim. Auth heroes are rounded 16:10 cover cards. Splash: solid `splashBackground` #05471F (new token; orange "AI" 3.8:1, white 10.9:1), one short entrance, 1.6 s hold (was 5 s with a looping glow and dots); tagline "Your AI food companion", footer "by OJ Tech". Native launch screens now use the same green (Android drawable + API 31+ `windowSplashScreenBackground`, iOS storyboard). Removed the unused `splashGradient*`, `splashGlow` and `onDarkSubtle` tokens. `ui-context.md` gains the Figma exception and an "Imagery" section.
Commits: `5f92766` photos + onboarding + auth heroes · `ca0c36c` splash + tokens + native launch screens · docs/tracker commit. Branch `p09-secure-session`, pushed to `main`.
Verification:
  preview renders of every screen (throwaway test, deleted) → checked visually; copies in the session scratchpad `redesign-previews/`
  `flutter test` → all pass after updating the smoke test's tagline (onboarding layout tests at 360×640/320×568 ×1.3/×2.0 and the pixel contrast test pass on the new layout)
  `tool/verify.sh` → format 0 changed, analyze no issues, 78 tests passed
  owner phone check → pending
Inputs consumed: owner design authority + three choices (AskUserQuestion, 2026-10-21)
New inputs or decisions needed: owner sees it on the phone. (Owner OK to delete, 2026-10-21: the unused `Inter-BlackItalic.ttf` (331 KB) and the five old AI masters in `design-assets/source/` were removed.)
Known issues added/closed: closed — splash contrast (P05 issue, splash part); unused Inter-BlackItalic (deleted). Added — Figma is out of date for these screens.

### 2026-10-21 — P09 — ⏸️ Waiting (owner phone checks)
Agent/session: Claude Code (Opus 5.5)
Summary: Verified in the package source that supabase_flutter 2.15.4 defaults to `SharedPreferencesLocalStorage` under `sb-<ref>-auth-token` and `SharedPreferencesGotrueAsyncStorage` for the PKCE verifier (`supabase.auth.token-code-verifier`), i.e. plaintext. Added `flutter_secure_storage` ^10.0.0 (authorized). v11.2.0 is the latest, but its `win32` dependency needs Dart 3.10, so v10 is the latest compatible with Flutter 3.35.7. `SecureSessionStorage` (a `LocalStorage`) and `SecurePkceStorage` (a `GotrueAsyncStorage`) are passed through `FlutterAuthClientOptions` in `main()`. Android: the package's default Keystore-wrapped AES-GCM (`resetOnError` on); iOS: `first_unlock_this_device`, not synchronizable. `initialize()` migrates a legacy plaintext session (write → read-back → delete plaintext; on mismatch it keeps plaintext for a retry), and on a fresh install with nothing to migrate it clears secure storage (iOS Keychain survives uninstall); a pre-P09 install with a plaintext session but no marker counts as an upgrade, not a fresh install. Any storage error → cleared and signed out, never thrown. Sign-out: supabase_flutter calls `removePersistedSession` on `signedOut` (verified in `supabase_auth.dart`). Docs: SECURITY.md (S7 row, credentials class, threat #1), architecture-context, project-overview stack table.
Commits: `a77233f` adapter + tests · `4f4ad1d` docs · `e63ffbb` regenerated desktop plugin registrants · tracker commit. Branch `p09-secure-session`.
Verification:
  `flutter test test/core/services/secure_session_storage_test.dart` → 12 passed (round-trip + sign-out removal; migration moves + deletes plaintext; upgrade without marker stays signed in; no legacy → no-op; run twice → no-op; legacy PKCE verifier removed; fresh install clears a surviving session; failed read → null + cleared, no throw; failed migration → no throw, plaintext kept; PKCE round-trip; PKCE failed read → null)
  `tool/verify.sh` → format clean, analyze no issues, 78 tests passed
  `flutter build apk --debug --dart-define-from-file=env/dev.json` → built
  owner phone: `adb shell run-as com.ojtech.smartmeal cat shared_prefs/FlutterSharedPreferences.xml` has no token; restart → still signed in; upgrade from the pre-P09 build → still signed in, plaintext gone → **pending**
Inputs consumed: plan approval, `COMMIT_AUTHORIZATION`
New inputs or decisions needed: owner phone checks
Known issues added/closed: none closed until the phone checks pass.

### 2026-10-21 — Owner request (outside the pack) — ⏸️ Waiting (owner sees it on the phone)
Agent/session: Claude Code (Opus 5.5)
Summary: (1) Owner reported a sign-in error showing raw `ClientException with SocketException: Failed host lookup: 'svrelfdfonxwlfcljrag.supabase.co'`. Diagnosis: the free-tier Supabase project had paused; its host returned NXDOMAIN from the local resolver and from 8.8.8.8, while `supabase.co` resolved. The owner restored it; `/auth/v1/health` with the publishable key → HTTP 200. No app change needed. The raw error on screen breaks S5 and is P10's job (error mapping). (2) Owner asked for real brand logos on the social buttons: Google now uses the official multicolor "G" (`assets/images/google_g.png`, cropped unmodified from Google's official sign-in assets, kept in `design-assets/source/google-signin-assets.zip`) instead of a one-color red Font Awesome glyph; Facebook uses official Facebook blue `#0866FF` (was Material blue); Apple's black was already correct. `AppColors.socialGoogle` removed (unused).
Commits: `05a6180` (branch `p09-secure-session`; owner authorized 2026-10-21).
Verification:
  `tool/verify.sh` → format 0 changed, analyze no issues, 66 tests passed (new: social brand colors; `AppAssets` bundle tests cover the new image)
  `flutter build apk --debug` → built; install on the owner's phone → pending (phone disconnected)
Inputs consumed: owner request
New inputs or decisions needed: owner confirms the logos on the phone; commit authorization
Known issues added/closed: added — Supabase free-tier auto-pause (High before launch).

### 2026-10-20 — P08 — ⏸️ Waiting (owner smoke-test results; Xcode step pending)
Agent/session: Claude Code (Opus 5.5)
Summary: Release builds now sign only from `android/key.properties`; without it `:app:preReleaseBuild` fails with instructions (no debug-key fallback). R8 minify + resource shrinking are on for release; `proguard-rules.pro` has no rules yet (none proved necessary). Backup is off (`allowBackup=false`, `fullBackupContent` for API ≤ 30, `dataExtractionRules` excluding cloud backup *and* device transfer for API 31+). Cleartext is off, with a network security config that trusts system CAs only (user CAs in `<debug-overrides>`); its comment notes that Dart's HttpClient does its own TLS. iOS: no ATS exceptions (confirmed); `PrivacyInfo.xcprivacy` declares no tracking + email/name/user ID (P16/P19 add their types). `docs/RELEASE.md` added and linked from the README. Started while P07 was still ⏸️, on the owner's instruction; the owner approved the plan; the throwaway key and privacy-manifest scope were the plan's defaults.
Commits: `d813220` signing + R8 · `cd85d12` backup + network · `a0ea732` privacy manifest · `965474d` RELEASE.md · tracker commit. Pushed to `main` (fast-forward from `caa1b55`, also landing P06 and P07) on the owner's instruction.
Verification:
  release build with no `key.properties` → `Release signing is not configured: android/key.properties not found. Release builds never fall back to the debug key…`
  `flutter build appbundle --release --dart-define-from-file=env/dev.json --obfuscate --split-debug-info=build/symbols/1.0.0+1` (throwaway key) → first try failed downloading Flutter engine jars (network); retry → `app-release.aab` (42.1 MB). No `lintVital` failure this time
  merged release manifest (`build/app/intermediates/packaged_manifests/release/processReleaseManifestForPackage/AndroidManifest.xml`) → allowBackup=false, fullBackupContent, dataExtractionRules, usesCleartextTraffic=false, networkSecurityConfig, no debuggable, targetSdk 36, minSdk 24. Exported: `MainActivity` only among activities; plugin receivers/services exported are each permission-guarded (`c2dm.permission.SEND`, Google sign-in `REVOCATION_NOTIFICATION`, `DUMP`)
  release `libapp.so` → 4 of 5 `AppLogger` messages compiled out; the background-message one survives as an inert constant (`log()` returns in release); `AppLogger` class name obfuscated away
  `flutter build apk --release --target-platform android-arm64 --obfuscate …` → 19.0 MB (two network failures first); `adb install` on the owner's Pixel 6a → Success; launched, process alive, no app crash in logcat
  `tool/verify.sh` → format 0 changed, analyze no issues, 65 tests passed
  throwaway keystore + `android/key.properties` → deleted
  owner smoke test (splash, login, Google button, images, restart) → **pending**
Inputs consumed: plan approval, `COMMIT_AUTHORIZATION` (push to `main`); `RELEASE_KEYSTORE` deferred (throwaway used); `MACOS_ACCESS` none
New inputs or decisions needed: owner smoke-test results; owner creates the real upload keystore before the first Play upload
Known issues added/closed: closed — release signed with the debug key, no shrinking, backup on, no cleartext policy, no privacy manifest, no release runbook. Updated — the local `lintVital` failure did not reproduce. Added — `PrivacyInfo.xcprivacy` needs Xcode target membership (Mac).

### 2026-10-20 — P07 — ⏸️ Waiting (owner review of SECURITY.md + phone run with env/dev.json)
Agent/session: Claude Code (Opus 5.5)
Summary: `lib/core/config/supabase_config.dart` became `app_config.dart`. `AppConfig` reads `SUPABASE_URL`, `SUPABASE_PUBLISHABLE_KEY`, `GOOGLE_WEB_CLIENT_ID`, `GOOGLE_IOS_CLIENT_ID` (optional until P12) and `APP_ENV` (`dev|staging|prod`) from `--dart-define-from-file=env/<env>.json`. `main()` validates them first and throws one `AppConfigException` listing every problem; `sb_secret_`/legacy JWT keys are refused with a rotate warning. `appConfigProvider` (overridden in `main()`) feeds `AuthRepository`. `env/example.json` is committed with placeholders; `/env/*.json` is gitignored. The owner's local `env/dev.json` holds the current values (not committed). Also: `.vscode/launch.json`, README *Run locally*, and CI builds with `env/example.json`. The gitleaks allow-list is unchanged (full-history scan still sees the old values) with updated comments. `docs/SECURITY.md` added and put on the AGENT.md reading list. The iOS `Info.plist` per-env xcconfig is specified for P12 in SECURITY.md §2, not built (no Mac; owner agreed).
Commits: `887db90` config · `5908e50` SECURITY.md + context docs · `dd7e815` tooling · tracker commit. Branch `p07-env-config`.
Verification:
  `tool/verify.sh` → format 0 changed, `flutter analyze --fatal-infos` no issues, 65 tests passed → "All checks passed."
  `flutter build apk --debug --dart-define-from-file=env/example.json` → `Built build\app\outputs\flutter-apk\app-debug.apk` (205 s)
  `AppConfig.parse` on `env/dev.json` → valid (env=dev); on `env/example.json` → 3 "still holds the env/example.json placeholder" errors
  `AppConfig.fromEnvironment()` with no defines (scratch `dart run`, same call as `main()`) →
    AppConfigException: SmartMeal build configuration is invalid.
      - SUPABASE_URL is empty.
      - SUPABASE_PUBLISHABLE_KEY is empty.
      - GOOGLE_WEB_CLIENT_ID is empty.
      - APP_ENV must be one of: dev, staging, prod.
    Run with --dart-define-from-file=env/<env>.json: copy env/example.json to env/dev.json and fill in real values (README → "Run locally").
  same call with the four `env/dev.json` values as `-D` defines → OK
  prompt's grep `supabase.co|sb_publishable|apps.googleusercontent` over `lib/` → 2 lines, neither a value: the `sb_publishable_` prefix check (it refuses secret keys) and a client-ID format hint in an error message. Value grep `https://[a-z0-9]+\.supabase\.co|sb_publishable_[A-Za-z0-9]{6,}|[0-9]+-[a-z0-9]{8,}\.apps\.googleusercontent` → none
  `git check-ignore env/dev.json` → ignored by `.gitignore:53`; `env/example.json` → tracked
  on-device run with `env/dev.json` → **owner's phone** (no usable emulator)
Inputs consumed: `SUPABASE_ENVIRONMENTS` (one project), `LAUNCH_MARKETS` (Cameroon), disclosure contact (owner email), `COMMIT_AUTHORIZATION`
New inputs or decisions needed: `SECURITY_DOC_REVIEW`, `SECURITY_DOC_PLACEHOLDERS`, `SUPABASE_AUTH_HARDENING`
Known issues added/closed: closed — config hardcoded in source / no threat model (audit #31). Added — one Supabase project for every env (High before launch); Auth checklist not applied (High); SECURITY.md placeholders (Medium); iOS per-env xcconfig for P12 (Low).

### 2026-10-20 — P06 — ✅ Done
Agent/session: Claude Code (Opus 5.5)
Summary: The owner confirmed on their phone that the P06 build works under `com.ojtech.smartmeal`, which closes the last acceptance check. `flutter build ios --no-codesign` stays pending until a Mac is available (`MACOS_ACCESS`); it does not block Android work.
Commits: tracker-only commit on `p06-app-identity`.
Verification: owner phone check → works (2026-10-20).
Inputs consumed: none new
New inputs or decisions needed: none
Known issues added/closed: none

### 2026-10-16 — P06 — ⏸️ Waiting (superseded by the entry above)
Agent/session: Claude Code (Opus 5.5)
Summary: Owner chose `APP_ID` = `com.ojtech.smartmeal`, display name "Smart Meal", portrait-only on phones; no Mac. Android `namespace`/`applicationId` and `MainActivity` (moved to `kotlin/com/ojtech/smartmeal/`) now use the new ID, and the template `TODO` above `applicationId` is gone. The 6 iOS `PRODUCT_BUNDLE_IDENTIFIER` lines (Runner ×3, RunnerTests ×3) were edited surgically. Launcher name "Smart Meal" on Android (`android:label`) and iOS (`CFBundleName`; `CFBundleDisplayName` and `MaterialApp.title` already matched; the splash wordmark is untouched). Portrait lock: the activity has `screenOrientation="portrait"` and the iPhone list is portrait only; the iPad list is unchanged.
Commits: `c8474ac` identity · tracker commit. Branch `p06-app-identity`.
Verification:
  `tool/verify.sh` (after `flutter clean`) → format 0 changed, analyze No issues found, 48 tests passed → "All checks passed."
  `flutter build apk --debug` → first try failed downloading Gradle artifacts (flaky network); retry → `Built build\app\outputs\flutter-apk\app-debug.apk`
  `aapt dump badging` → `package: name='com.ojtech.smartmeal'`, `application-label:'Smart Meal'`, `launchable-activity: com.ojtech.smartmeal.MainActivity`; `aapt dump xmltree` → `screenOrientation=0x1` (portrait)
  `git grep -n "com\.example\|smartMeal"` in `android/` `ios/` → none (only `linux/`, `macos/`, `windows/` scaffolds, which are out of scope per §0.3)
  install + launch on a device → **owner's phone** (no usable emulator here); `flutter build ios --no-codesign` → **pending** (no Mac)
Inputs consumed: `APP_ID`, `APP_DISPLAY_NAME`, `ORIENTATION_POLICY`, `MACOS_ACCESS` (none), `COMMIT_AUTHORIZATION`
New inputs or decisions needed: owner phone confirmation; whether to delete the unused `linux/` `macos/` `windows/` scaffolds
Known issues added/closed: closed — placeholder `com.example` app ID. Added — desktop scaffolds still carry `com.example`; Android 16+ ignores the portrait lock on large screens (tablet landscape unchecked). Downstream re-registrations (P11/P12/P19) recorded under `APP_ID` in the Inputs register.

### 2026-10-15 — P03 + P04 — ✅ Done
Agent/session: Claude Code (Opus 5.5)
Summary: On the owner's instruction `p05-ui-a11y` (a linear superset of main + P01–P05) was fast-forwarded onto `main` (`cb325bf..67b1fa0`) instead of going through stacked PRs. The first CI run on `main` passed every job. The owner confirmed on their phone that everything works, which closes P04's device spot check.
Commits: tracker-only commit after `67b1fa0`
Verification:
  CI run https://github.com/ojrandy/smart_meal/actions/runs/38766137427 (head `67b1fa0`) → "Format, analyze, test, build" success (incl. `tool/verify.sh` and the debug APK), "Secret scan (gitleaks, full history)" success, "Dependency vulnerabilities (OSV-Scanner)" success (still non-blocking until 2026-11-14)
  owner phone check (2026-10-15) → all fine
Inputs consumed: `COMMIT_AUTHORIZATION` (push to `main`)
New inputs or decisions needed: none
Known issues added/closed: closed — "first CI run on a PR still pending".

### 2026-10-15 — P05 — ✅ Done
Agent/session: Claude Code (Opus 5.5)
Summary: Owner answers: commit and push to `main`; the 4 screen-reader labels are approved, and the "built-in back" must give a perfect UI; contrast is to be fixed with overlays; the main button's loading spinner must be visible; all phone checks pass. Follow-up changes:
- **System back:** `PopScope` on login/signup makes the Android back button/gesture behave like the on-screen back (signup → login → onboarding) instead of closing the app.
- **Onboarding overlays:** the full-screen scrim became a text-anchored `_TextScrim` (120 dp fade, then black 60 % → 85 % behind the text and CTA), and Skip got a black 55 % pill.
- **Primary loading:** the primary `CustomButton` keeps its green fill while loading.
- **Test harness:** the P04 offline-render test now hosts screens in a GoRouter, because the auth screens read the router during build.
Commits: `3b429c5` widgets/theme · `f279b00` splash + onboarding · `3615750` auth screens + docs commit (branch `p05-ui-a11y`); pushed to `origin/p05-ui-a11y` and `origin/main` — see the status board.
Verification:
  `tool/verify.sh` → format 0 changed, analyze No issues found, 48 tests passed, coverage 64.6 % → "All checks passed."
  `onboarding_contrast_test.dart` (renders the real artwork with transparent glyphs, checks every visible pixel under each text box): pass at 393×873 ×1.0, 360×640 ×1.3, 320×568 ×1.3; worst pixels — title ≥ 5.97:1, subtitle ≥ 4.71:1, Skip ≥ 5.11:1. Against the previous scrim it fails on the first slide at every size
  system-back tests (platform `popRoute` message): fail without `PopScope` (app would exit), pass with it
  primary loading: fill = `primary`, spinner `onPrimary` (5.32:1); a disabled non-loading button keeps the theme's disabled look
  owner: all P05 checks fine on their phone (2026-10-15)
Inputs consumed: `COMMIT_AUTHORIZATION` (P05), `COPY_APPROVALS` (P05 labels)
New inputs or decisions needed: splash contrast (orange "AI"/"TECH" on green 1.27:1, white subtitle 2.33:1 — needs a color change, not an overlay) and `textHint` meta icons (2.54:1)
Known issues added/closed: closed — onboarding contrast, primary loading spinner, system back exiting the app from auth screens. Still open — splash/`textHint` contrast, text-field tap target, synthesized bold, prompt enforcement regex.

### 2026-10-15 — P05 — ⏸️ Waiting (superseded by the entry above)
Agent/session: Claude Code (Opus 5.5)
Summary: The listed inline colors became `AppColors` tokens with unchanged values (`splashGradient*`, `splashGlow`, `brandAccent`, `onPrimary`, `onDark`/`onDarkMuted`/`onDarkSubtle`, `scrim`, `shadow`, `favorite`, `placeholderIcon`, `social*`). Onboarding now uses a private `_OnboardingSlide` class, has an image `errorBuilder`, places Skip at `max(60, top inset + 8)`, and puts the bottom block in a bottom-anchored scroll view (same look at 1.0×, scrolls when it doesn't fit). Auth hero fallbacks are a plain grey box; back goes to onboarding (login) or login (signup) when nothing can pop. The outline spinner uses primary. `RichText` was replaced by `Text.rich` on the splash and auth screens. The back, password and favorite icon controls are labelled 48 dp targets (the password toggle is an `IconButton` overlaid on its old slot, so the field keeps its height), and decorative images are excluded from semantics.
Commits: none — not authorized in this session. Proposed (branch `p05-ui-a11y`): (1) "Move inline colors into AppColors tokens with identical values, so screens follow the design-system rule and an audit grep stays empty" — app_colors, app_theme, splash/onboarding/auth color lines, widgets, `app_colors_test`; (2) "Fix the outline spinner, dead back button, developer-facing image fallbacks and onboarding layout on small screens, without changing the default look" — custom_button, onboarding, auth back/fallback + tests; (3) "Make text scale and screen readers work: Text.rich for scaled titles, labelled 48 dp icon controls, decorative images hidden" — the remaining a11y edits + tests; (4) trackers/context docs. (Splitting (1) from (2)/(3) needs `git add -p` because the same files carry both.)
Verification:
  `tool/verify.sh` → format 0 changed, `analyze --fatal-infos --fatal-warnings` No issues found, 41 tests passed, coverage 62.8 % (455/724) → "All checks passed."
  enforcement: `grep -rnE "Color\(0x|(^|[^A-Za-z])Colors\." lib/features lib/core/widgets | grep -v Colors.transparent` → nothing (the prompt's literal pattern matches `AppColors.` too)
  screenshots (engine render, before = `p04-diet` HEAD, after = working tree, 2×): splash, onboarding 1–3 → pixel-identical; login/signup → rows below the title identical (max channel delta 1) after a 34 dp upward shift. The title now inherits Inter instead of the platform font; under `RichText` it fell back to the test font. Widgets sheet → only the outline spinner changed (now visible); RecipeCard and the password field are pixel-identical after placing the toggle at `right: 5.5` (accounts for the 1.5 dp border). Files: P05 session scratchpad `before/` and `after/`
  red-first: against the old onboarding/button code, 5 of the new tests fail (320×568 @1.3 and 360×640 @2.0 readability, Skip below a 72 dp inset, decorative images, outline spinner color)
  note: the old onboarding did *not* overflow at the prompt's 360×640 @1.3 (title at 152 dp, below Skip). It broke at 320×568 @1.3 (title under Skip) and @2.0 (title at −287 dp, off screen); the test covers all three
  device run → **not done** (no phone or usable emulator here)
WCAG AA contrast (reported, not changed — owner decision): primary on background 5.10:1 ✅; onPrimary on primary 5.32:1 ✅; textSecondary on background 4.63:1 ✅; textHint on surface 2.54:1 ❌ (used for RecipeCard meta icons, below 3:1 for non-text). Splash: brandAccent "AI" on the green gradient 1.27:1 ❌ (large text needs 3:1); white on `splashGradientEnd` 2.33:1 ❌ (the 13 px subtitle and "BY OJ" lie where the gradient lightens); white on `splashGradientStart` 4.87:1 ✅. Onboarding (image + scrim measured under each text box; worst / 10th percentile / median): slide 1 title 1.47/3.58/6.97, subtitle (white 70 %) 1.59/1.97/7.25, Skip 1.15/1.61/2.41; slide 2 title 1.82/2.47/11.24, subtitle 1.62/3.82/7.26, Skip 6.39/19.1/19.3; slide 3 title 1.22/1.50/6.57, subtitle 1.55/3.73/5.03, Skip 1.13/1.13/1.13 (white on cream, effectively invisible). The scrim does not guarantee AA anywhere; the fix (stronger/taller scrim, text shadow, or a dark Skip on light art) is a design decision.
Inputs consumed: none (`COMMIT_AUTHORIZATION` not given)
New inputs or decisions needed: `COMMIT_AUTHORIZATION` for P05; `COPY_APPROVALS` (4 screen-reader labels); contrast decision (onboarding scrim/Skip, splash accent/subtitle, `textHint` icons); primary `CustomButton` loading state (see Known issues)
Known issues added/closed: closed — hardcoded colors; onboarding `errorBuilder`, Skip safe area, small-screen layout; outline spinner; dead back button; `RichText` text scaling and platform font in the auth titles; unlabeled icon-only controls; developer text in image fallbacks. Added — contrast failures; the primary `CustomButton` loading state shows a white spinner on the disabled grey fill (≈ invisible; the fix changes the loading look, so it needs the owner); `CustomTextField`'s tappable input is 24 dp tall (the field box is 56 dp but taps outside the text line do nothing); the prompt's enforcement regex. Still open (not P05: visible change) — synthesized bold from plain `TextStyle` weights.

### 2026-10-15 — P04 — ⏸️ Waiting (push + CI + phone spot check) — WebP applied
Agent/session: Claude Code (Opus 5.5)
Summary: Owner approved the WebP proposal. The 5 hero PNGs moved to `design-assets/source/` (lossless masters, unbundled) and their WebP q85 encodes ship in `assets/images/`, byte-identical to the reviewed `compare.html` set. `AppAssets` points at the `.webp` files; the image-decode test enforces the 1440 px budget. Added `test/features/offline_render_test.dart` (onboarding/login/signup rendered at phone size with fetching off: every image decodes, every requested Inter variant loads from assets). Owner asked for the on-device offline check: no phone is attached (`adb devices` empty) and the emulator is unusable, so engine-rendered offline screenshots of splash/onboarding/login/signup were produced instead (P04 session scratchpad `screenshots/`). The owner's "merge the PR" can't be done from this session: there are no GitHub credentials, so no push, PR or merge.
Commits: `257f81c` WebP · `ac3f30a` offline render test + `test/helpers/fake_auth_repository.dart` · tracker commit. Not pushed.
Verification:
  `tool/verify.sh` → format 0 changed, analyze No issues found, 18 tests passed → "All checks passed."
  mutation: truncated `auth_login_hero.webp` → `app_assets_test` (decode) and `offline_render_test` (login) both fail; restored byte-identical
  screenshots: splash shows Inter Bold/Medium/Black Italic; onboarding and the auth heroes render from WebP
  release arm64 APK (clean tree) 35,074,878 → 20,873,226 B (−40.5 %); images 14.66 MB → 0.90 MB
Inputs consumed: `IMAGE_RECOMPRESSION_APPROVAL`
New inputs or decisions needed: owner pushes the branches / authenticates GitHub; merge strategy for the P01–P04 stack
Known issues added/closed: closed — WebP pending sign-off. Added — login/signup headline `RichText` ignores the theme, so it renders in the platform font, not Inter (found in the offline screenshots; pre-existing) — P05.

### 2026-10-15 — P04 — ⏸️ Waiting (owner: WebP sign-off + offline-font phone check)
Agent/session: Claude Code (Opus 5.5)
Summary: Removed 5 unused packages (24 left the lockfile). Moved 16 unused images to unbundled `design-assets/` and renamed the 6 bundled ones to snake_case behind `lib/core/constants/app_assets.dart`. Bundled the 5 Inter variants the code uses (400/500/600/700, 900 italic), fetched from the exact `fonts.gstatic.com/s/a/<sha256>.ttf` URLs `google_fonts` 8.1.0 uses and verified against its pinned hashes. `AppFonts.configure()` in `main()` disables runtime fetching and registers the OFL. WebP conversion prepared (official libwebp 1.5.0, GPG signature verified against key 6B0E6B70…F9C3D6BDB8232B5D) but not applied.
Commits: `6698dbf` packages · `cfa83ff` assets + AppAssets · `53e03c1` fonts + AppFonts · tracker commit. Branch `p04-diet` (on top of `p03-ci-gates`); push failed in-session (no GitHub credential prompt) — owner pushes.
Verification:
  `tool/verify.sh` → pub get, format, analyze (No issues found), test --coverage (14 passed) → "All checks passed."
  `app_assets_test` red against the stale old-name bundle, green after rebuild; `app_fonts_test`: 5 bundled variants load with fetching off, w800 fails with "not found in the application assets", OFL registered
  `pubspec.lock` diff → 192 deletions, 0 version additions; grep old asset names in `lib/` → none
  release arm64 APK 35,074,878 → 30,253,533 B (clean tree, both built the same way; libapp.so hashes differ, so Dart was rebuilt)
  `flutter build apk --release --analyze-size` → fails twice in `:<plugin>:lintVitalAnalyzeRelease` (`ClassNotFoundException: com.android.tools.lint.Main`, then `IssueRegistry` / `CoreApplicationEnvironment` after `--refresh-dependencies`): local tooling, not project code
  offline Inter from a fresh install → **not verified here** (no emulator) — owner's phone
  iOS: no `Podfile.lock` exists, so no pod refresh is needed
Inputs consumed: `COMMIT_AUTHORIZATION`
New inputs or decisions needed: `IMAGE_RECOMPRESSION_APPROVAL` (proposal recorded in the Inputs register)
Known issues added/closed: closed — unused Firebase deps, unused packages, asset naming, runtime Inter fetch. Added — fake bold from plain `TextStyle` weights (P05), developer text in image `errorBuilder`s (P05), WebP pending sign-off, local Android lint broken. Note for every agent: Flutter's build cache does not notice file changes inside an asset directory — after moving/renaming assets, delete `build/unit_test_assets` (tests) or run `flutter clean` with Gradle stopped (APK) before trusting results.

### 2026-10-14 — P03 — ⏸️ Waiting (CI run on a PR)
Agent/session: Claude Code (Opus 5.5)
Summary: Added the local gate `tool/verify.sh`, a README, and GitHub Actions CI. CI runs the same gate plus a debug APK build and a coverage artifact, a gitleaks full-history scan using the official binary with a pinned checksum, and a non-blocking OSV scan of `pubspec.lock`. Analysis now uses strict-casts/inference/raw-types and 9 extra lints. The 12 pre-existing unformatted files were formatted in their own commit, and the placeholder test became a real app-shell smoke test with a hand-written `FakeAuthRepository`; no `test/helpers/` harness was needed.
Commits: `d8b11cf` format-only · `766049f` strict analysis + fixes + code-standard rationale · `15c260a` smoke test · `55a3f16` `tool/verify.sh` + README · `41da534` CI + `.gitleaks.toml` · tracker commit. Branch `p03-ci-gates` (on top of `p02-repo-hygiene`), pushed.
Verification:
  `tool/verify.sh` → pub get, format, `analyze --fatal-infos --fatal-warnings` (No issues found), `test --coverage` (5 passed) → "All checks passed."
  unformatted `lib/main.dart` → `Changed lib\main.dart` … exit 1 at the format step; file reverted
  stricter lints before fixes → 35 infos (24 `prefer_single_quotes`, 11 `prefer_const_constructors`); `dart fix --apply` → 27 fixes; after `dart format` → 0 issues (no hand fixes needed)
  gitleaks 8.30.1 (Windows zip, sha256 verified) `git` mode, `--log-opts=--all`, 11 commits → no leaks (default rules and `.gitleaks.toml`). `dir` mode on the working tree → 16 hits, all in gitignored compiled kernels (`.dart_tool/**/app.dill`, `build/*.dill`) bundling dependency code; not in git, not project secrets
  Action pins (releases ≥ 2 weeks old): checkout v7.0.1 `3d3c42e5`, flutter-action v2.23.0 `1a449444`, upload-artifact v7.0.1 `043fb46d`, osv-scanner-action v2.6.0 `a345acff`
  CI on a PR → **not yet run** (needs the PR)
Inputs consumed: `COMMIT_AUTHORIZATION`, `GIT_HOST`
New inputs or decisions needed: owner opens PR https://github.com/ojrandy/smart_meal/compare/p02-repo-hygiene...p03-ci-gates?expand=1
Known issues added/closed: closed — 12 unformatted files. Added — OSV job non-blocking until 2026-11-14. Added — osv-scanner-action runs a Docker image by tag (`ghcr.io/google/osv-scanner-action:v2.6.0`), not by digest (residual supply-chain risk, Low).

### 2026-10-14 — P02 — ✅ Done
Agent/session: Claude Code (Opus 5.5)
Summary: Split the uncommitted work into commits that each compile, and made `AGENT.md` + `context/` agree with the code. Main changes: committed the release `INTERNET` permission, `AppNetworkImage` + `RecipeCard` together, and the Supabase config, with `main.dart` switched to `publishableKey:` (the deprecated `anonKey:` and its `ignore` are gone). Removed the stray "Design System Implementation Plan" block and the circular overview↔AGENT pointer; rewrote the Firebase caveat and the key policy; reconciled progress-tracker. Also deleted `analyze_output.txt`, added `.gitattributes`, and tracked the shared agent skills.
Commits: `d15bcc0` INTERNET permission · `b02c05b` AppNetworkImage + RecipeCard · `e35da6a` Supabase config + publishableKey · `0705187` AGENT.md + context/ · `6a9e90d` remove analyze_output.txt, ignore `.claude/*.lock` + `.claude/skills/` · `84805b8` `.agents/skills/` + `skills-lock.json` · `019c014` `.gitattributes` · docs commit (this tracker + `prompt.md`). Branch `p02-repo-hygiene` (off `p01-push-bootstrap`), pushed.
Verification:
  clean `git worktree` at `d15bcc0`, `b02c05b`, `e35da6a` → `flutter analyze`: No issues found (each)
  `flutter test` at `e35da6a` → 5 passed
  `git diff e35da6a HEAD -- '*.dart' pubspec.* analysis_options.yaml` → empty (later commits change no code)
  `git add --renormalize .` → 0 files changed (index was already LF), so no renormalize commit
  `dart format --set-exit-if-changed lib test` → 12 pre-existing files would change (Known issue; was 13)
  grep `anonKey|placeholder values|superpowers|Full detail lives` in AGENT.md, context/, lib/ → only the historical note in progress-tracker
Inputs consumed: `COMMIT_AUTHORIZATION`, `AGENT_SKILLS_IN_GIT`
New inputs or decisions needed: none
Known issues added/closed: closed — missing release `INTERNET` permission. Updated — dart-format count 13 → 12. Docs contradictions resolved: INTERNET issue, Supabase "provisioned" row (project yes, schema no — P13), `anon` key rule, config header, overview↔AGENT pointer, Firebase caveat, stray workflow block, AGENT.md read-list.

### 2026-10-14 — P01 — ✅ Done
Owner confirmed on a physical phone that the app works. Committed `4274bbc` on branch `p01-push-bootstrap` and pushed to `origin` (code + test only; tracker/context docs remain untracked for P02). Inputs consumed: `COMMIT_AUTHORIZATION`.

### 2026-10-14 — P01 — ⏸️ Waiting (superseded by the entry above)
Agent/session: Claude Code (Opus 5.5)
Summary: `PushNotificationService` no longer touches Firebase at construction; `FirebaseMessaging` is obtained only after `Firebase.initializeApp()` succeeds. `initialize()` never throws or prompts and sets `isAvailable`; permission + token moved to `requestPermissionAndRegisterToken()` (no caller — P19); `dispose()` cancels all subscriptions. `main()` starts push init with `unawaited(...)` so the first frame never waits on it; Supabase init unchanged. New debug-only `AppLogger`; no token values are logged.
Commits: staged, not committed (no commit authorization given). Proposed: one commit — "Defer Firebase access until initialization succeeds so an unconfigured project cannot crash startup or block the first frame" — covering `lib/core/services/app_logger.dart`, `lib/core/services/push_notification_service.dart`, the push lines of `lib/main.dart`, `test/core/services/push_notification_service_test.dart`. Note: `push_notification_service.dart` and the push lines in `main.dart` were never committed before P01; P02's commit-split plan should account for that.
Verification:
  regression test before fix → FAILED: `threw FirebaseException:<[core/no-app] No Firebase App '[DEFAULT]' has been created>`
  `flutter test test/core/services/push_notification_service_test.dart` after fix → 4 passed
  `flutter test` → 5 passed
  `flutter analyze` → No issues found
  `dart format --set-exit-if-changed` on touched files → 0 changed; repo-wide → 13 pre-existing files fail (Known issue)
  grep `requestPermission` in lib/ → only inside `requestPermissionAndRegisterToken()`, which has no caller
  grep token interpolation in lib/ logs → none
  Android emulator (Pixel_9_Pro AVD, 2 cold starts) → APK built and launched; "Supabase init completed" logged; process stayed alive; no `[core/no-app]` or other non-font startup exception. Inconclusive: the emulator display froze (24 s frames, ANR dump) so the splash could not be seen, and the Firebase log did not arrive within a 40 s VM-service Logging-stream capture. Runtime check handed to the owner's phone.
Inputs consumed: none
New inputs or decisions needed: owner on-device confirmation (see status board)
Known issues added/closed: added — permission never requested (P19); push receive-only scaffolding (P19); Firebase deps note rewritten; 13 unformatted files. Logged as resolved — startup crash in push bootstrap.

### 2026-10-14 — Prompt pack created — ✅ Done
Agent/session: Claude Code (Opus 5.5)
Summary: Full-system audit of `main` plus the working copy. Wrote `docs/prompt.md` (P01–P20 + template T1, with a traceability matrix covering 33 findings) and this tracker. No application code was changed.
Commits: none (files left uncommitted for owner review)
Verification: `flutter analyze` → no issues; `flutter test` → 1 passed (placeholder); probe test → `PushNotificationService()` throws `[core/no-app] No Firebase App '[DEFAULT]' has been created`
Inputs consumed: none
New inputs or decisions needed: see the Inputs register (all ⬜)
Known issues added/closed: none yet. Each prompt updates `context/progress-tracker.md` as it runs; P02 reconciles the stale entries there.
