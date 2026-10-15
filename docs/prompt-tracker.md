# SmartMeal — Prompt Execution Tracker

> Companion to [`prompt.md`](prompt.md). The executing agent updates this file at the end of **every** prompt and whenever it is blocked (protocol: `prompt.md` §0.7). Use absolute dates (`YYYY-MM-DD`). Keep entries honest — 🟡 means actively being worked on in the current session, not "started once".

**Last updated:** 2026-10-15 — P03 ⏸️ (branch `p03-ci-gates`, pushed; waiting on the owner to open the PR so CI can run). P04 ⏸️ (branch `p04-diet`, committed, push pending on the owner; code done, waiting on the owner's WebP sign-off and offline-font phone check).

## Status legend

⬜ Not started · 🟡 In progress · ⏸️ Waiting on owner input · 🔴 Blocked · ✅ Done

## Status board

| ID | Title | Phase | Priority | Depends on | Status | Started | Completed | Commit(s) | Verification evidence | Notes |
|---|---|---|---|---|---|---|---|---|---|---|
| P01 | Make push bootstrap crash-proof and non-blocking | 0 | 🔴 Critical | — | ✅ | 2026-10-14 | 2026-10-14 | `4274bbc` (branch `p01-push-bootstrap`, pushed) | Regression test red before fix (`[core/no-app]`), 4/4 green after; `flutter test` → 5 passed; `flutter analyze` → no issues; `dart format` on touched files → 0 changed; grep: no `requestPermission` reachable from `main()`, no token interpolated in any log; owner confirmed on a physical phone (2026-10-14) that the app works | Android emulator unusable on this host — runtime check done by the owner on a phone. Tracker/context doc updates are not in the commit (`docs/`, `context/` are still untracked — P02's commit plan). Repo-wide `dart format` gate fails on 13 pre-existing files (logged as a Known issue) |
| P02 | Repository hygiene and documentation truth | 0 | 🟠 High | P01 | ✅ | 2026-10-14 | 2026-10-14 | `d15bcc0` `b02c05b` `e35da6a` `0705187` `6a9e90d` `84805b8` `019c014` + docs commit (branch `p02-repo-hygiene`, pushed) | Clean `git worktree` per code commit: `flutter analyze` → no issues at `d15bcc0`, `b02c05b`, `e35da6a`; `flutter test` at `e35da6a` → 5 passed; no Dart/pubspec changes after `e35da6a`; `git add --renormalize .` → 0 files changed; grep for stale claims (`anonKey`, placeholder values, `superpowers`, circular pointer) → none left | Plan approved by owner. Renormalize was a no-op (index already LF), so no renormalize commit. `auth_notifier.dart` cosmetic comment edit reverted on owner instruction. `.claude/skills/` (duplicate of `.agents/skills/`) and `.claude/*.lock` now in `.gitignore` |
| P03 | CI quality and security gates | 0 | 🟠 High | P02 | ⏸️ | 2026-10-14 | | `d8b11cf` `766049f` `15c260a` `55a3f16` `41da534` + tracker commit (branch `p03-ci-gates`, pushed) | `tool/verify.sh` → all checks passed (analyze `--fatal-infos` clean, 5 tests); unformatted `lib/main.dart` → gate exit 1 at format step, then reverted; gitleaks 8.30.1 (checksum-verified) full history, all refs, 11 commits → no leaks, with and without `.gitleaks.toml` | **Waiting:** owner opens PR `p03-ci-gates` → base `p02-repo-hygiene`; then confirm CI green. OSV job non-blocking until **2026-11-14** (remove `continue-on-error` then). Plan approved by owner |
| P04 | Dependency, asset and font diet | 1 | 🟡 Medium | P03 | ⏸️ | 2026-10-14 | | `6698dbf` `cfa83ff` `53e03c1` + tracker commit (branch `p04-diet`, off `p03-ci-gates`; push pending — owner runs `git push -u origin p04-diet`) | `tool/verify.sh` → all checks passed (analyze clean, 14 tests); removed packages absent from `pubspec.lock` (192 lines removed, 0 added); grep `bckimg\|img_login\|img_signup\|app logo` in `lib/` → none; 5 bundled Inter files SHA-256 = `google_fonts` 8.1.0 pins; release arm64 APK 35,074,878 → 30,253,533 B (−13.7 %) | Plan approved by owner 2026-10-14. **Waiting:** (1) owner sign-off on WebP (`compare.html`) — not applied; (2) owner's offline-font check on the phone (fresh install, network off; no emulator here); (3) P03 CI still unrun. Size builds ran Gradle directly with `-x lintVital*` because local Android lint is broken (see Known issues) |
| P05 | UI standards and accessibility cleanup | 1 | 🟡 Medium | P04 | ⬜ | | | | | |
| P06 | Permanent app identity | 1 | 🟠 High | P03 | ⬜ | | | | | Must run before P11, P12 and P19 |
| P07 | Environment config, secrets policy, threat model | 1 | 🟠 High | P06 | ⬜ | | | | | Creates `docs/SECURITY.md` |
| P08 | Android and iOS platform hardening | 1 | 🟠 High | P06, P07 | ⬜ | | | | | Creates `docs/RELEASE.md` |
| P09 | Encrypted session storage | 2 | 🟠 High | P08 | ⬜ | | | | | Authorizes `flutter_secure_storage` |
| P10 | Auth hardening: errors, validation, state model | 2 | 🟠 High | P09 | ⬜ | | | | | Changes the documented auth pattern — plan approval required |
| P11 | Password recovery and auth deep links | 2 | 🟠 High | P10, P06 | ⬜ | | | | | Needs Figma frames |
| P12 | Social sign-in completion | 2 | 🟠 High | P06, P10 | ⬜ | | | | | Authorizes `sign_in_with_apple` (+ `crypto` if needed) |
| P13 | Supabase schema v1, RLS, storage, DB tests | 3 | 🔴 Critical | P07 | ⬜ | | | | | Parallel-safe with P08–P12; owner approves the schema before remote push |
| P14 | Account deletion and data rights | 3 | 🟠 High | P10, P13 | ⬜ | | | | | UI entry point comes with T1-Profile |
| P15 | Launch routing: session, onboarding, setup gates | 4 | 🔴 Critical | P10, P13 | ⬜ | | | | | |
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
| `COMMIT_AUTHORIZATION` | every prompt | Whether agents may create commits in a session | P01, P02, P03, P04: authorized 2026-10-14 — commit and push to its own branch (ask again each prompt) | ✅ |
| `AGENT_SKILLS_IN_GIT` | P02 | Commit `.agents/` + `skills-lock.json`? | Yes (2026-10-14): commit `.agents/skills/` + `skills-lock.json`; ignore the duplicate `.claude/skills/` | ✅ |
| `GIT_HOST` | P03 | Where CI runs (GitHub by default) | GitHub — `origin` is `github.com/ojrandy/smart_meal` (public). PR base for P03: `p02-repo-hygiene` (owner, 2026-10-14) | ✅ |
| `IMAGE_RECOMPRESSION_APPROVAL` | P04 | Sign-off on WebP/resized hero images | Proposal ready: 5 heroes PNG → WebP q85 (no resize; all ≤ 1404 px wide), 10.27 MB → 0.89 MB, YUV PSNR 43–44 dB. Side-by-side page in the P04 session scratchpad (`webp-out/compare.html`); `app_logo.png` stays PNG (alpha, 9 KB). Owner to decide | ⬜ |
| `APP_ID` | P06 → P11, P12, P19 | Permanent reverse-DNS app ID you own (no underscores, for iOS) | | ⬜ |
| `APP_DISPLAY_NAME` | P06 | Launcher name on both platforms | | ⬜ |
| `ORIENTATION_POLICY` | P06 | Default: portrait-only on phones | | ⬜ |
| `MACOS_ACCESS` | P06, P08, P12, P19, P20 | A Mac with Xcode, for iOS steps | | ⬜ |
| `SUPABASE_ENVIRONMENTS` | P07 | Separate dev/staging Supabase project? | | ⬜ |
| `LAUNCH_MARKETS` | P07 | Countries at launch (drives data-protection obligations) | | ⬜ |
| `SECURITY_DOC_REVIEW` | P07 | Owner review of `docs/SECURITY.md` | | ⬜ |
| `RELEASE_KEYSTORE` | P08 | Owner-held upload keystore + `key.properties` values (never in git) | | ⬜ |
| `COPY_APPROVALS` | P10, P11, P16, P17, P18 | Approval of new user-facing messages | | ⬜ |
| `FIGMA_FORGOT_PASSWORD_URL` | P11 | Figma frame(s) | | ⬜ |
| `FIGMA_RESET_PASSWORD_URL` | P11 | Figma frame(s) | | ⬜ |
| `AUTH_REDIRECT_URI` | P11 | e.g. `<APP_ID>://auth-callback` | | ⬜ |
| `APP_LINK_DOMAIN` | P11 (optional) | Domain for App Links / Universal Links | | ⬜ |
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
| Tests | 1 (placeholder `expect(true, isTrue)`) | 14 — 4 `PushNotificationService` + 1 app-shell smoke + 2 `AppAssets` + 7 `AppFonts` (2026-10-15) | P04 |
| Files failing `dart format --set-exit-if-changed` | not measured | 0 (2026-10-14, gated in CI) | P03 |
| Coverage | not measured | 25.4 % lines (156/614, 2026-10-14) | P03 |
| Bundled image assets | 14.7 MB (4.4 MB unused) | 10.28 MB, 6 files, 0 unused (2026-10-15); 0.90 MB if WebP is approved | P04 |
| Packages never imported in `lib/` | 8 | 3 — `lottie`, `intl`, `shared_preferences`, all scheduled (2026-10-15) | P04 |
| Release APK size (arm64) | 35,074,878 B (2026-10-14, pre-P04) | 30,253,533 B, −13.7 % (2026-10-15): images −4.38 MB, dex −1.06 MB, other −0.17 MB, Inter +0.79 MB. Gradle `assembleRelease -Ptarget-platform=android-arm64 -x lintVital*` from a clean tree; `--analyze-size` unavailable (local lint broken) | P04 |
| Cold start on low-end Android | not measured | | P20 |
| Tables with RLS / total tables | 0 / 0 | | P13 |
| pgTAP tests | 0 | | P13 |

## Execution log

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
