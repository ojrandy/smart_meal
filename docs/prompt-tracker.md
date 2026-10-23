# SmartMeal — Prompt Execution Tracker

> Companion to [`prompt.md`](prompt.md). The executing agent updates this file at the end of **every** prompt and whenever it is blocked (protocol: `prompt.md` §0.7). Use absolute dates (`YYYY-MM-DD`). Keep entries honest — 🟡 means actively being worked on in the current session, not "started once".

**Last updated:** 2026-10-23 — P11 ⏸️ on `p11-password-recovery` (password recovery + auth deep links; uncommitted until the owner authorizes; waiting on the Dashboard allow-list, email templates and a device check). P10 ⏸️ on `p10-auth-flow` (auth hardening + the launch-routing part of P15 that needs no database; owner phone check and copy approval pending; on `main`). P08 ✅ (owner smoke-tested the obfuscated release APK; the Xcode step waits for the owner's Mac). P06–P08 on `main` (fast-forward on the owner's instruction). P07 ⏸️: env config + `docs/SECURITY.md` done, waiting on owner review and a phone run. P01–P05 ✅, all on `main` (fast-forwarded to `67b1fa0` on the owner's instruction; CI run 38766137427 green: quality gate + debug APK, gitleaks, OSV). P06 ✅ on `p06-app-identity` (owner phone check 2026-10-20; iOS build pending, no Mac).

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
| P11 | Password recovery and auth deep links | 2 | 🟠 High | P10, P06 | ⏸️ | 2026-10-23 | | `66cdf44` code + tests · `27189c0` Supabase config, templates, SECURITY.md · `c13a75a` + tracker commit (branch `p11-password-recovery`, fast-forwarded onto `main` and pushed) | `dart format` → 0 changed; `flutter analyze --fatal-infos` → no issues; `flutter test` → 216 passed (was 174: redirect table for recovery, recovery notifier + persisted flag, rate-limit neutrality, `isAuthLinkError`, both screens, whole-app recovery routing and link-error snackbar); grep `e\.message`, `toString().contains`, `RegExp(` in `lib/features` → nothing | Owner (2026-10-23): screens in the login style instead of Figma, redirect `com.ojtech.smartmeal://auth-callback`, copy approved, minimal `supabase/config.toml`. P10 still ⏸️ (owner phone check) — P11 started on the owner's instruction. **Waiting:** owner Dashboard allow-list + email templates, end-to-end check with a real mailbox, `adb` invalid-code check |
| P12 | Social sign-in completion | 2 | 🟠 High | P06, P10 | ⬜ | | | | | Authorizes `sign_in_with_apple` (+ `crypto` if needed) |
| P13 | Supabase schema v1, RLS, storage, DB tests | 3 | 🔴 Critical | P07 | ⬜ | | | | | Parallel-safe with P08–P12; owner approves the schema before remote push |
| P14 | Account deletion and data rights | 3 | 🟠 High | P10, P13 | ⬜ | | | | | UI entry point comes with T1-Profile |
| P15 | Launch routing: session, onboarding, setup gates | 4 | 🔴 Critical | P10, P13 | ⬜ | | | | | Part done in P10 (owner, 2026-10-21): onboarding persistence, splash without navigation, `resolveRedirect` + `LaunchSnapshot` with session / onboarding / ready. Left: setup status (`profiles.setup_completed_at`), the recovery row (P11), the setup gate and its table rows |
| P16 | Setup / preferences flow | 4 | 🔴 Critical | P15 | ⬜ | | | | | Needs Figma frames and confirmed questions |
| P17 | Recommendation engine v1 (explainable) | 4 | 🔴 Critical | P13, P16 | ⬜ | | | | | Decision gate: engine placement and weights |
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
| T1-Profile | Profile | `/profile` | P14, P16 | ⬜ | | | | | Delete-account entry; avatar upload re-adds `image_picker` |
| T1-RecipeDetail | Recipe detail | `/home/recipe/:id` | P18 | ⬜ | | | | | |

## Inputs register (owner supplies — agents must never guess)

| Key | Needed by | What it is | Value / decision | Status |
|---|---|---|---|---|
| `COMMIT_AUTHORIZATION` | every prompt | Whether agents may create commits in a session | P01, P02, P03, P04: authorized 2026-10-14 — commit and push to its own branch (ask again each prompt). P05: authorized 2026-10-15 — commit and push to `main`. P06: authorized 2026-10-15 — commit and push branch `p06-app-identity`. P07: authorized 2026-10-20 — commit and push branch `p07-env-config`. P08: authorized 2026-10-20 — commit and push to `main` (fast-forward, which also lands P06 and P07). Logo change + P09: authorized 2026-10-21 — commit and push to `main`. P10: authorized 2026-10-22 — commit and push to `main`. P11: authorized 2026-10-23 — commit and push (fast-forward onto `main`, as P10) | ✅ |
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
| `COPY_APPROVALS` | P10, P11, P16, P17, P18 | Approval of new user-facing messages | P05 screen-reader labels "Show password", "Hide password", "Add to favorites", "Remove from favorites": approved by owner 2026-10-15. P10: sign-up confirmation "Almost there! We've sent a confirmation link to your email." approved 2026-10-21; the other P10 messages (log 2026-10-21) pending. P11 (owner, 2026-10-23) approved: "If an account exists for that email, we've sent a link to reset your password." · "Resend link" / "Resend in {s}s" · "Set a new password" · "Confirm password" · "Your password has been updated." · "This link is invalid or has expired. Please request a new one."; also approved 2026-10-23: "Forgot your password?" (title), "Enter your account email and we'll send you a link to set a new password.", "Send reset link", "New password", "Save password"; mismatch message: owner left the choice to the agent → "Passwords don't match" on sign-up and reset (contractions match the rest of the app). Other prompts: pending | ⬜ |
| `FIGMA_FORGOT_PASSWORD_URL` | P11 | Figma frame(s) | Not used: owner chose screens built in the existing login style (2026-10-23); the code is the source of truth for them | ✅ |
| `FIGMA_RESET_PASSWORD_URL` | P11 | Figma frame(s) | Not used: same decision (2026-10-23) | ✅ |
| `AUTH_REDIRECT_URI` | P11 | e.g. `<APP_ID>://auth-callback` | **`com.ojtech.smartmeal://auth-callback`** (owner, 2026-10-23). In `AuthRepository.authRedirectUri`, the Android intent filter, iOS `CFBundleURLTypes` and `supabase/config.toml` | ✅ |
| `APP_LINK_DOMAIN` | P11 (optional) → later | Domain for App Links / Universal Links | None yet; migration planned in `docs/SECURITY.md` §10 | ⬜ |
| `SUPABASE_REDIRECT_ALLOWLIST` | P11 | Owner sets Dashboard → Authentication → URL Configuration: Site URL and Redirect URLs = exactly `com.ojtech.smartmeal://auth-callback`, no wildcards. Until then Supabase falls back to the current Site URL and links will not open the app | Owner said yes (2026-10-23); the session has no Supabase CLI or access token, so the owner applies it in the Dashboard | ⏸️ |
| `SUPABASE_EMAIL_TEMPLATES` | P11 | Owner updates the "Confirm signup" and "Reset password" templates: keep `{{ .ConfirmationURL }}` as the link, brand "Smart Meal", short friendly tone (`docs/SECURITY.md` §10) | Owner said yes (2026-10-23). Drafted in `supabase/templates/confirmation.html` + `recovery.html` (subjects in `supabase/config.toml`); owner pastes them into Dashboard → Authentication → Emails (no CLI access from the session) | ⏸️ |
| `GOOGLE_CLOUD_ACCESS` + SHA-1s | P12 | Debug, upload and Play App Signing fingerprints for `APP_ID` | | ⬜ |
| `GOOGLE_IOS_CLIENT_ID` | P12 | iOS OAuth client for the bundle ID | | ⬜ |
| `APPLE_TEAM_ID` | P12 | Apple Developer Program membership | | ⬜ |
| `DECISION_APPLE_ON_ANDROID` | P12 | Show Apple sign-in on Android? (recommendation: iOS only) | | ⬜ |
| `DECISION_FACEBOOK` | P12 | Implement now or hide? (recommendation: hide until built) | | ⬜ |
| `SCHEMA_APPROVAL` | P13 | Owner approval of the proposed schema | | ⬜ |
| `VOCABULARIES` | P13 | Allergens, dietary tags, health goals, cuisines, lifestyle types | | ⬜ |
| `REMOTE_PUSH_APPROVAL` | P13 | Approval to run `supabase db push` on the remote project | | ⬜ |
| `ACCOUNT_DELETION_WEB_URL` | P14 | Web page for deletion requests (Google Play) | | ⬜ |
| `REAUTH_POLICY` | P14 | Default: sign-in within the last 10 minutes | | ⬜ |
| `SPLASH_MIN_DURATION` | P15 | Currently 5 s; recommendation ≤ 2 s | | ⬜ |
| `FIGMA_SETUP_FLOW_URL` | P16 | All setup frames and states | | ⬜ |
| `SETUP_QUESTIONS` | P16 | Confirmed questions and answer options | | ⬜ |
| `CONSENT_COPY` | P16 | Consent text for allergy/diet data | | ⬜ |
| `ENGINE_DECISION` | P17 | A (Edge Function, recommended) / B (Dart) | | ⬜ |
| `SCORING_WEIGHTS` | P17 | Default 30 / 25 / 20 / 15 / 10 | | ⬜ |
| `EXPLANATION_COPY` | P17 | Approved "X% match because…" templates | | ⬜ |
| `FIGMA_HOME_URL` | P18 | Home frames, including empty/error states | | ⬜ |
| `CURRENCY_DISPLAY` | P18 | "FCFA" vs "XAF" | | ⬜ |
| `FIREBASE_PROJECT` | P19 | Android + iOS apps registered for `APP_ID` | | ⬜ |
| `APNS_KEY` | P19 | Uploaded to Firebase | | ⬜ |
| `NOTIFICATION_USE_CASES` | P19 | Use cases, copy, and the moment to ask for permission | | ⬜ |
| `PRIVACY_POLICY_URL` | P20 | Live URL | | ⬜ |
| `CRASH_REPORTING_DECISION` | P20 | Crashlytics / Sentry / none (a new dependency if chosen) | | ⬜ |

## Baseline metrics

| Metric | Baseline (2026-10-14) | Latest | Updated by |
|---|---|---|---|
| `flutter analyze` issues | 0 (stock `flutter_lints`) | 0 under strict modes + 9 extra lints, `--fatal-infos` (2026-10-14) | P03 |
| Tests | 1 (placeholder `expect(true, isTrue)`) | 65 (2026-10-20): P07 adds 17 `AppConfig` tests; earlier 48 (2026-10-15): P04's 18 + 2 `AppColors` + 3 `CustomButton` + 2 `CustomTextField` + 1 `RecipeCard` + 7 onboarding + 3 onboarding contrast + 12 auth-screen a11y/navigation | P07 |
| Files failing `dart format --set-exit-if-changed` | not measured | 0 (2026-10-14, gated in CI) | P03 |
| Coverage | not measured | 64.6 % lines (484/749, 2026-10-15; was 25.4 % on 2026-10-14) | P05 |
| Bundled image assets | 14.7 MB (4.4 MB unused) | 0.90 MB, 6 files (5 WebP + logo PNG), 0 unused (2026-10-15) | P04 |
| Packages never imported in `lib/` | 8 | 3 — `lottie`, `intl`, `shared_preferences`, all scheduled (2026-10-15) | P04 |
| Release APK size (arm64) | 35,074,878 B (2026-10-14, pre-P04) | 20,873,226 B, −40.5 % (2026-10-15): images −13.76 MB, dex −1.06 MB, other −0.17 MB, Inter +0.79 MB (intermediate, before WebP: 30,253,533 B). Gradle `assembleRelease -Ptarget-platform=android-arm64 -x lintVital*` from a clean tree; `--analyze-size` unavailable (local lint broken) | P04 |
| Cold start on low-end Android | not measured | | P20 |
| Tables with RLS / total tables | 0 / 0 | | P13 |
| pgTAP tests | 0 | | P13 |

## Execution log
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
