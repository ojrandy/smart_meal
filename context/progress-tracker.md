# SmartMeal — Progress Tracker

> Update this file every time a feature's status changes. Keep entries
> honest — "in progress" means actively being worked on, not "started once."

Last reviewed: **2026-10-24** (P15 — setup gate on `p15-setup-gate`; P14 ✅ — account deletion live; P13 ✅ — schema v1 live, Advisors empty; P11 — password recovery + auth deep links, on `p11-password-recovery`, owner device check pending; P10 — auth flow + launch routing, on `p10-auth-flow`, owner phone check pending; P08 — release hardening ✅, owner smoke-tested the release APK, Xcode step waits for a Mac; P07 — env config + `docs/SECURITY.md`, on `p07-env-config`; P06 — permanent app identity `com.ojtech.smartmeal`, ✅ on `p06-app-identity`, owner phone check passed; P01–P05 on `main`, CI green; P05 — UI standards and accessibility cleanup, ✅ on `p05-ui-a11y`; P04 — dependency, asset and font diet; earlier: P01–P03 on 2026-10-14)

> **Remediation plan:** `docs/prompt.md` (instructions, P01–P20 + template T1)
> and `docs/prompt-tracker.md` (status per prompt). Check them before picking
> the next task.

## Status legend

✅ Done &nbsp;&nbsp; 🟡 In progress / partial &nbsp;&nbsp; ⬜ Not started

## Foundation

| Item | Status | Notes |
|---|---|---|
| Project scaffold (Flutter, Android + iOS) | ✅ | |
| Riverpod + go_router wired up | ✅ | `StatefulShellRoute` shell with 5 tabs |
| Design system (`AppColors`, `AppTheme`) | ✅ | Light theme only, no dark mode |
| Shared widget library | ✅ | `CustomButton`, `CustomTextField`, `SocialAuthButton`, `RecipeCard`, `AiChefCard`, `AppNetworkImage` exist. `RecipeCard` now renders real network images via `AppNetworkImage` (shimmer while loading, icon fallback on error) instead of a static placeholder tile. `flutter analyze` clean. |
| Supabase client bootstrap | ✅ | `Supabase.initialize(url:, publishableKey:)` in `main.dart` (switched from the deprecated `anonKey:` parameter in P02, 2026-10-14). URL and key come from `AppConfig` since P07 (2026-10-20) |
| Environment configuration | ✅ | P07 (2026-10-20). `AppConfig` (`lib/core/config/app_config.dart`) reads `SUPABASE_URL`, `SUPABASE_PUBLISHABLE_KEY`, `GOOGLE_WEB_CLIENT_ID`, `GOOGLE_IOS_CLIENT_ID` (empty until P12) and `APP_ENV` from `--dart-define-from-file=env/<env>.json`. `main()` validates them before anything else and throws `AppConfigException` listing every bad key; secret/legacy-JWT keys are rejected. Exposed via `appConfigProvider` (overridden in `main()`). `env/example.json` is committed with placeholders; real files are gitignored. VS Code configs in `.vscode/launch.json`; CI builds with `env/example.json`. Tests: `test/core/config/app_config_test.dart` |
| Release hardening (Android + iOS) | ✅ | P08 (2026-10-20). Release signs only from `android/key.properties` (fails clearly without it, no debug fallback); R8 minify + resource shrinking; backup and device transfer off; cleartext off, system CAs only; obfuscated builds with split debug info; iOS `PrivacyInfo.xcprivacy` (no tracking; email, name, user ID). Runbook: `docs/RELEASE.md`. Owner smoke-tested the obfuscated release APK (2026-10-21). Pending: the real upload keystore (owner) and Xcode target membership for the privacy manifest (when the owner has a Mac) |
| Security model | ✅ | `docs/SECURITY.md` (P07, 2026-10-20): trust boundaries, secrets policy, data classification, STRIDE table with owning prompts, Supabase Auth checklist (owner applies), commerce baseline, disclosure + incident response, Cameroon compliance pointers. Owner review pending (`SECURITY_DOC_REVIEW`) |
| Firebase (push notifications) | 🟡 | `PushNotificationService` (`lib/core/services/push_notification_service.dart`). `main()` starts `initialize()` without awaiting it, so push can never delay or block the first frame. `initialize()` touches no Firebase API until `Firebase.initializeApp()` succeeds, never throws and never prompts; it registers the background handler, attaches the foreground/opened-app listeners and sets `isAvailable`. With no Firebase config (today) it logs "Firebase not configured — push notifications disabled." in debug only and leaves `isAvailable` false. `requestPermissionAndRegisterToken()` (permission prompt + token fetch + refresh listener) exists but **nothing calls it** — P19 wires it to a contextual moment. `dispose()` cancels all subscriptions. Logging goes through the debug-only `AppLogger`; token values are never logged. Covered by `test/core/services/push_notification_service_test.dart` (2026-10-14). **Still blocked on external setup**: real Firebase project, `google-services.json` + Google Services Gradle plugin (Android), `GoogleService-Info.plist` via Xcode (iOS), and ideally `flutterfire configure` for `firebase_options.dart`. Exact steps are in the class doc comment. Deliberately did *not* touch Android/iOS build files — applying the Gradle plugin without a real `google-services.json` breaks the build for everyone. |
| Quality + security gates | ✅ | `tool/verify.sh` (format → analyze `--fatal-infos` → test --coverage) and `.github/workflows/ci.yml` (same gate + debug APK + gitleaks full history + OSV) added in P03, 2026-10-14. Passes locally and in CI: first run on `main` 2026-10-15 (run 38766137427), all jobs green |

## Feature: Splash

| Item | Status | Notes |
|---|---|---|
| Splash screen UI/animation | ✅ | Redesigned 2026-10-21 (owner authority): solid `splashBackground` #05471F, logo + "SmartMeal AI" wordmark + "Your AI food companion" + "by OJ Tech", one ≤ 500 ms entrance, `LaunchReadyNotifier.splashHold` 1.6 s (was 5 s with a looping glow and dots). Native launch screens use the same green (Android `launch_background`, API 31+ `windowSplashScreenBackground`; iOS `LaunchScreen.storyboard`, unverified without a Mac) |
| Session-aware routing | 🟡 | P15 (2026-10-24): setup gate added — signed-in users go to `/home` only when setup is complete (server `profiles.setup_completed_at`, cached per user), otherwise to `/setup/loading`; table-tested; pending owner phone check. P10 (2026-10-21): the splash only animates; the router (`resolveRedirect`) sends signed-in users to `/home`, returning signed-out users to `/auth/login` and new devices to `/onboarding`. The setup gate comes with P15 (needs P13) |

## Feature: Onboarding

| Item | Status | Notes |
|---|---|---|
| 3-slide carousel UI | ✅ | Redesigned 2026-10-21 (owner authority): real Unsplash food photos (jollof, egusi, grilled fish + plantains; credits in `design-assets/source/PHOTO-CREDITS.md`) on top with 32 px rounded corners, dark text on cream below, fixed dots + `CustomButton`. Replaces the AI full-bleed art and its scrim |
| Skip / Next / Get Started actions | ✅ | Skip and Get started mark onboarding seen, then `/auth/login` |
| "Seen onboarding" persistence | ✅ | P10: `OnboardingRepository` (SharedPreferences `smartmeal.onboarding.seen`) + `onboardingSeenProvider` |

## Feature: Authentication

| Item | Status | Notes |
|---|---|---|
| Repository layer (`AuthRepository`) | ✅ | Email/password, Google, sign-out, password reset + new password (P11). Every email link uses `AuthRepository.authRedirectUri` = `com.ojtech.smartmeal://auth-callback` |
| State + Notifier (`AuthNotifier`, `SmartMealAuthState`) | ✅ | P10: session in `authSessionProvider` (Supabase stream; all the router reads); operation state in `AuthNotifier` (idle / loading / error / awaiting confirmation / reset sent); typed Google failures; one error mapper `formatAuthError` |
| Login screen | ✅ | Email/password + Google; shared validators (login password: non-empty only). Apple/Facebook hidden until P12 (owner, 2026-10-21) |
| Signup screen | ✅ | Session → the router goes home; no session → "Almost there! We've sent a confirmation link to your email." (true even for an already-registered email), then login |
| Router auth guard | ✅ | Centralized `redirect` → pure `resolveRedirect` in `launch_redirect.dart`, table-tested |
| Account deletion (server + domain) | ✅ | P14 (2026-10-23): Edge Function `delete-account` (re-auth ≤ 10 min, 5 attempts/h, avatars → push tokens → auth user, cascade), `AuthRepository.deleteAccount` + `AuthNotifier.deleteAccount` (states: account deleted, re-authentication required). Verified end to end locally. No UI yet: entry point comes with T1-Profile. Web deletion page `site/delete-account.html` (GitHub Pages) |
| Encrypted session storage | 🟡 | P09 (2026-10-21): `SecureSessionStorage` + `SecurePkceStorage` (`lib/core/services/secure_session_storage.dart`) keep the Supabase session and PKCE verifier in Keychain/Keystore via `flutter_secure_storage` ^10. Migrates a legacy plaintext session (read-back verified, then deleted); clears a session surviving an iOS reinstall (`smartmeal.installed` marker); storage errors → signed out. 12 tests. Pending: owner phone checks (no token in `shared_prefs`, restart keeps the session, upgrade from the pre-P09 build keeps the session) |
| Social button brand marks | ✅ | Official multicolor Google "G" image (`AppAssets.googleLogo`), Facebook blue `#0866FF`, Apple black (owner request, 2026-10-21). Owner still to see it on the phone |
| Forgot password screen | 🟡 | P11 (2026-10-23): `forgot_password_screen.dart`, built in the login style (owner: no Figma). Always the neutral "If an account exists…" answer, also for `over_email_send_rate_limit`; 60 s resend cooldown. Pending: owner end-to-end check with a real mailbox |
| Reset password screen + recovery routing | 🟡 | P11: `/auth/reset-password`; `passwordRecoveryProvider` (persisted flag `smartmeal.auth.recovery_pending`) set from `AuthChangeEvent.passwordRecovery` before the session is published; the router forces the reset screen until `updatePassword` (then `signOut(scope: others)`); back = sign out. Pending: owner device check |
| Auth deep links | 🟡 | P11: Android `VIEW/BROWSABLE` intent filter + iOS `CFBundleURLTypes` for `com.ojtech.smartmeal://auth-callback`; PKCE (default, never implicit); bad/expired links → "This link is invalid or has expired…" on the root snackbar (`authLinkErrorProvider`). Allow-list in `supabase/config.toml`; the owner mirrors it in the Dashboard. Plan: App Links / Universal Links (`SECURITY.md` §10) |
| Apple Sign-In | ⬜ | Button hidden (P10, owner 2026-10-21) until P12; needs the Apple Developer Program and a Mac |
| Facebook Sign-In | ⬜ | Button hidden (P10, owner 2026-10-21) until implemented (P12 decision) |
| Password rule consistency | ✅ | P10: `core/validation/validators.dart` — sign-up 8 chars–72 bytes with lower, upper, digit, symbol (`SECURITY.md` §5 target); login non-empty only. The Supabase project must be set to the same policy (owner, §5) |

## Feature: Setup / Preferences flow

| Item | Status | Notes |
|---|---|---|
| `/setup/loading` | 🟡 | P15: `SetupLoadingScreen` — waits for the setup check, offline with nothing cached → "No connection…" + Try again + Sign out, unfinished → `/setup/lifestyle`. Built in app style (owner); final look may change in P16 |
| `/setup/lifestyle` | ⬜ | Placeholder |
| `/setup/preferences` | ⬜ | Placeholder |
| `/setup/processing` (AI processing experience) | ⬜ | Placeholder |
| Supabase `user_preferences` table | ✅ | P13 schema (live); written by P16's `complete_setup` RPC |
| Setup status gate | 🟡 | P15: `SetupStatusRepository` + `setupStatusProvider`; refresh on sign-in, resume, retry; per-user cache cleared on sign-out |

## Main tab shell

| Tab | Status | Notes |
|---|---|---|
| Home | 🟡 | Interim `HomeScreen` (P10): greets the user by name or email, Sign out. P18 replaces it with live data |
| Discover | ⬜ | Placeholder screen |
| Planner | ⬜ | Placeholder screen |
| Favorites | ⬜ | Placeholder screen |
| Profile | ⬜ | Placeholder screen |

## Backend / data

| Item | Status | Notes |
|---|---|---|
| Real Supabase project provisioned | ✅ | Project `svrelfdfonxwlfcljrag` exists and the app points at it. Schema v1 is live (P13, 2026-10-23), applied by the Supabase GitHub integration when `main` was pushed |
| Schema v1 (12 tables, enums, storage, pgTAP) | ✅ | P13 (2026-10-23): `supabase/migrations/20261023102159_schema_v1.sql`; see `context/data-model.md`. Local: `db reset` clean, `test db` 5 files / 121 assertions pass, `db lint` and `db advisors` clean, real sign-up through local GoTrue creates the profile. Live: identical to local (read-only checks); no seed; Dashboard Advisors empty (owner, 2026-10-23) |
| AI recommendation logic | ⬜ | Not started — no scoring/matching engine, no Edge Functions |
| Google OAuth client configured (Supabase + Cloud Console) | 🟡 | Web Client ID set (2026-07-20); since P07 it comes from `GOOGLE_WEB_CLIENT_ID` in `env/<env>.json`. Still needed: (1) enable Google provider in Supabase Dashboard → Auth → Providers → Google with this Client ID; (2) Android OAuth Client ID in Google Cloud Console keyed to **`com.ojtech.smartmeal`** (P06, 2026-10-15) + the debug SHA-1, then the upload and Play App Signing SHA-1s (P12). Any client created earlier for `com.example.smart_meal` (debug SHA-1 `A3:AA:68:7E:A6:86:B6:78:3E:75:E3:59:AF:8C:8F:16:4D:F2:08:DD`) no longer matches the app — delete it and create a new one; (3) iOS OAuth Client ID keyed to bundle ID `com.ojtech.smartmeal` + reversed-client-id URL scheme added to `ios/Runner/Info.plist`. |

## Known issues (open)

| Issue | Severity | Where |
|---|---|---|
| Desktop scaffolds (`linux/`, `macos/`, `windows/`) are still in the repo with `com.example` identifiers. The app is Android + iOS only (§0.3), so P06 left them alone; deleting them needs the owner's OK | Low | `linux/`, `macos/`, `windows/` |
| Android 16+ ignores `screenOrientation="portrait"` on large screens (smallest width ≥ 600 dp: tablets, unfolded foldables) for apps targeting SDK 36, so the app can appear in landscape there; the portrait-only layouts have not been checked in landscape on a tablet | Low | `android/app/src/main/AndroidManifest.xml`, all screens |
| Plain `TextStyle(fontWeight: …)` without `GoogleFonts.inter(...)` inherits the theme's per-variant family (`Inter_regular`), so the engine fakes the weight from Regular instead of using the bundled Medium/SemiBold/Bold file (found in P04 by code reading; e.g. onboarding, auth screens, `AiChefCard`, `RecipeCard`) — not fixed in P05: using the real weight files visibly changes glyphs, so it needs the owner's sign-off (fix in `AppTheme`, e.g. a pubspec `Inter` family with weights) | Low | `lib/core/theme/app_theme.dart`, screens/widgets |
| Release build on this dev machine fails in Android lint (`lintVital*`: `ClassNotFoundException: com.android.tools.lint.Main` / `UastEnvironment`) — environment issue, not project code; P04 size builds ran Gradle directly with `-x lintVital*`. CI's Linux runner is unaffected (it builds debug). Did **not** reproduce in P08 (2026-10-20): `flutter build appbundle --release` and `flutter build apk --release` both passed. Keep the workaround in `docs/RELEASE.md` §3 in case it returns. Release downloads also time out often on this network; re-run |  Low (dev env) | local `~/.gradle` |
| Test coverage 62.8 % lines (2026-10-15). Auth notifier and router redirect are tested since P10; `AuthRepository` (SDK wrapper) still is not | Low | `test/` |
| `textHint` (2.54:1 on surface) used for `RecipeCard` meta icons (non-text needs 3:1). (The splash contrast failures logged in P05 are fixed by the 2026-10-21 redesign: deep `splashBackground`, orange "AI" 3.8:1 as large text, white 10.9:1; pinned by `app_colors_test.dart`.) | Low | `recipe_card.dart` |
| `CustomTextField`: only the 24 dp text line is tappable; taps on the rest of the 56 dp box (label, padding) do not focus the input (fails the 48 dp tap-target guideline) | Low | `lib/core/widgets/custom_text_field.dart` |
| `docs/prompt.md` P05 enforcement command: its `Colors\.` alternative has no word boundary, so it also matches every `AppColors.`; use `\bColors\.` | Low (docs) | `docs/prompt.md` |
| Figma / `Mockup/` still show the old AI artwork for splash, onboarding and the auth heroes; the code is the source of truth for those since 2026-10-21 (`ui-context.md`). Update Figma when convenient | Low | Figma |
| `ios/Runner/PrivacyInfo.xcprivacy` exists but is not yet in the Runner target, so it does not ship until added in Xcode (*Target Membership*). P16 and P19 must add their data types | Medium (before App Store) | `ios/Runner/PrivacyInfo.xcprivacy` |
| No real upload keystore yet: P08 was verified with a throwaway key. The owner creates it per `docs/RELEASE.md` §2 (outside the repo, two backups) before the first Play upload, then registers its SHA-1 and the Play App Signing SHA-1 for Google Sign-In (P12) | Medium (before first upload) | owner; `android/key.properties` |
| The Supabase project is on the free tier and **paused itself** after inactivity (found 2026-10-21: the host stopped resolving, so every sign-in failed with `SocketException: Failed host lookup`; the owner restored it). It will pause again after ~7 idle days. Before launch: paid plan or a production project that never idles | High (before launch) | Supabase Dashboard; `docs/SECURITY.md` §9 |
| One Supabase project serves every `APP_ENV` (owner, 2026-10-20): dev/test accounts, test data and any mistaken destructive command share a database with real users. Create a separate prod (or staging) project before public launch; until then P13 works against a local Supabase | High (before launch) | Supabase; `env/*.json`; `docs/SECURITY.md` §9 |
| Supabase Auth hardening checklist not applied yet (email confirmation, password policy, token rotation, JWT expiry, rate limits, redirect allow-list, CAPTCHA decision…) | High | Supabase Dashboard; `docs/SECURITY.md` §5 (owner) |
| `docs/SECURITY.md` owner placeholders unfilled: `{{ACK_DAYS}}`, `{{INCIDENT_LEAD}}`, `{{INCIDENT_CONTACTS_LOCATION}}`; owner review pending | Medium | `docs/SECURITY.md` §7 |
| iOS `GIDClientID` / reversed-client-ID URL scheme need the per-env xcconfig mechanism specified in `docs/SECURITY.md` §2 — build it in P12 on a Mac | Low (until P12) | `ios/Runner/Info.plist`, `ios/Flutter/*.xcconfig`, Runner scheme |
| Auth links use a custom URL scheme, which any app can claim (PKCE keeps an intercepted code useless, but the link is spent). Move to App Links / Universal Links once the owner has a domain (`APP_LINK_DOMAIN`, `SECURITY.md` §10) | Medium | `AndroidManifest.xml`, `Info.plist`, `AuthRepository.authRedirectUri` |
| After a password reset, a failed `signOut(scope: others)` is only logged: other devices keep their sessions. Add a retry or a server-side revoke | Low | `auth_notifier.dart` → `updatePassword` |
| Login and signup still carry their own copy of the header (back + logo + title) that `AuthScreenHeader` now provides for the P11 screens; switch them over in a later UI pass | Low | `login_screen.dart`, `signup_screen.dart` |
| Seed recipe prices (`supabase/seed.sql`) are placeholders, marked `-- PLACEHOLDER`; the owner validates them before any real catalog is loaded | Low | `supabase/seed.sql` |
| Pushing `main` deploys migrations to production (Supabase GitHub integration); there is no dry-run or approval gate between a merge and production. Approve schema changes before they reach `main`; protect `main` with required review (P20) | High | Supabase GitHub integration; GitHub branch protection |
| CI does not run the pgTAP suite yet (needs Docker + the Supabase CLI in the workflow) | Medium | `.github/workflows/ci.yml` |
| The local stack runs CLI-default image versions (Postgres 17.11) instead of the live project's (Postgres 17.6.1.147, PostgREST v14.5, storage v1.80.2): their images would not download on this network, so the version pins written by `supabase link` were set aside (scratchpad, not deleted; `link` rewrites them). Re-link and pull those images when the network allows | Low | `supabase/.temp/*-version` |
| Account deletion has no UI yet; Google Play and the App Store need the in-app entry point before release (T1-Profile). The web page already describes Profile → Delete account | High (before release) | Profile screen (T1) |
| Account-deletion errors through `functions.invoke` when offline arrive as an HTTP client exception, which maps to the generic "couldn't delete" message rather than the connection message | Low | `auth_notifier.dart` → `formatAuthError` |
| Until P16 ships, every signed-in user without a finished setup stops at the `/setup/lifestyle` placeholder (no way back except reinstall or the offline sign-out). Merge P15 to `main` together with P16, or test P15 only on a device | Medium (until P16) | `/setup/*` placeholders |
| OSV-Scanner CI job is non-blocking (`continue-on-error`) — make it blocking on 2026-11-14 after triaging findings | Medium | `.github/workflows/ci.yml` |
| `osv-scanner-action` runs its Docker image by tag, not digest — residual supply-chain risk | Low | `.github/workflows/ci.yml` |
| Notification permission is never requested — wired in P19 | Medium | `lib/core/services/push_notification_service.dart` (`requestPermissionAndRegisterToken` has no caller) |
| Push is receive-only scaffolding: FCM token is fetched but not stored, foreground messages show no UI, notification taps do not navigate, and taps that cold-start the app (`getInitialMessage`) are not handled — P19 | Medium | `lib/core/services/push_notification_service.dart` |

## Resolved issues

| Date | Issue | Fix |
|---|---|---|
| 2026-10-21 | Splash always showed onboarding (even signed in) and "seen" was never stored; screens navigated to `/home` themselves; a failed sign-out ejected the user; no way to sign out | P10: `resolveRedirect` from session + onboarding seen + splash hold; `authSessionProvider` as the router's only session input; interim Home with Sign out |
| 2026-10-21 | Raw server/developer text in auth errors; red snackbar and string matching on Google cancel; 6-vs-8 password rules; email regex rejecting `a+b@x.company`; "Account created!" possibly untrue; "coming soon" Apple/Facebook buttons | P10: typed Google failures, one `formatAuthError` with a generic default, shared validators, neutral confirmation copy, Apple/Facebook hidden until P12 |
| 2026-10-20 | Release build signed with the debug key; no R8 shrinking; backup on (plaintext session eligible for cloud/device transfer); no cleartext policy; no iOS privacy manifest; no release runbook | P08: `key.properties`-only release signing with a clear failure; R8 on; `allowBackup=false` + backup/data-extraction rules; `usesCleartextTraffic=false` + network security config; `PrivacyInfo.xcprivacy`; `docs/RELEASE.md` |
| 2026-10-20 | Config hardcoded in source (`supabase_config.dart`), no environment separation, no threat model | P07: `AppConfig` from `env/<env>.json` build defines with fail-fast validation; `docs/SECURITY.md` with secrets policy, data classification and STRIDE table |
| 2026-10-15 | Placeholder identity: Android `com.example.smart_meal`, iOS `com.example.smartMeal`, launcher name `smart_meal`, iPhone allowed landscape | P06: Android namespace/applicationId and iOS bundle IDs (Runner + `.RunnerTests`) are `com.ojtech.smartmeal`; `MainActivity` moved to that package; launcher name "Smart Meal" on both platforms (= `MaterialApp.title`); portrait-only on phones (Android activity lock, iPhone `Info.plist`; iPad unchanged) |
| 2026-10-15 | Onboarding white text failed WCAG AA over the photos (worst pixel 1.1–1.8:1; slide 3 Skip ≈ 1.13:1) | P05 (owner chose overlays): text-anchored `_TextScrim` + 55 % pill behind Skip → worst visible pixel ≥ 4.7:1 (subtitle), ≥ 5.1:1 (Skip), ≥ 6:1 (title) on all slides at 393×873, 360×640 and 320×568 (×1.0/×1.3); `onboarding_contrast_test.dart` guards it |
| 2026-10-15 | Primary `CustomButton` loading: white spinner on the disabled grey fill (invisible) | P05 (owner OK): keeps `primary` fill while `isLoading`; a disabled non-loading button still uses the theme's disabled look |
| 2026-10-15 | Android back button/gesture closed the app from login/signup reached via `context.go` | P05: `PopScope` routes it like the on-screen back (signup → login → onboarding) |
| 2026-10-15 | Hardcoded hex/`Colors.*` in splash, onboarding, auth brand icons and shared widgets | P05: named `AppColors` tokens with identical values (`app_colors_test.dart` pins them); enforcement grep in `lib/features` + `lib/core/widgets` returns nothing |
| 2026-10-15 | Onboarding: no image `errorBuilder`, Skip at a fixed `top: 60`, bottom text pushed off screen/under Skip on small screens or large text, `List<Map>` slide data | P05: `errorBuilder`, Skip at `max(60, inset + 8)`, bottom-anchored scroll view (same look at 1.0×), `_OnboardingSlide` class; tests at 360×640/320×568 ×1.3 and ×2.0 |
| 2026-10-15 | Outline `CustomButton` spinner white on the light background (invisible) | P05: spinner uses the variant foreground (`primary`) |
| 2026-10-15 | Auth back button did nothing after `context.go` | P05: falls back to onboarding (login) / login (signup) |
| 2026-10-15 | Auth titles/links and splash wordmark used `RichText` (ignored system text scale; auth titles rendered in the platform font, not Inter); icon-only controls unlabeled and < 48 dp; image fallbacks showed developer text | P05: `Text.rich`; back (platform "Back" tooltip), password toggle (`IconButton`) and favorite are labelled 48 dp targets; decorative images excluded from semantics; neutral grey fallbacks |
| 2026-10-15 | Hero images shipped as 1.8–2.4 MB PNGs (10.27 MB total) | P04 `257f81c`: owner-approved WebP q85 (0.89 MB total), masters kept in `design-assets/source/`; release APK 35.07 → 20.87 MB |
| 2026-10-15 | 8 packages never imported; `firebase_auth`, `cloud_firestore`, `firebase_storage`, `form_validator`, `image_picker` shipped unused native code (and camera/photo APIs → iOS ITMS-90683 risk) | P04 `6698dbf`: the 5 removed (24 packages left the lockfile); `lottie`, `intl`, `shared_preferences` kept and marked *planned* in `project-overview.md`. `image_picker` returns with iOS purpose strings in T1-Profile |
| 2026-10-15 | 4.4 MB of unused images bundled; filenames with spaces/mixed casing | P04 `cfa83ff`: 16 files moved to unbundled `design-assets/`; bundled images renamed to snake_case behind `AppAssets`; `app_assets_test.dart` guards it |
| 2026-10-15 | Inter downloaded at runtime — fallback font offline, network call at startup | P04 `53e03c1`: 5 used weights bundled (hash-identical to `google_fonts`' pins), runtime fetching off, OFL registered; `app_fonts_test.dart` guards it. Offline check on a fresh install is the owner's (no emulator) |
| 2026-10-14 | 12 pre-existing files failed `dart format --set-exit-if-changed` | P03: formatted in commit `d8b11cf`; the gate now runs in `tool/verify.sh` and CI. |
| 2026-10-14 | Missing `INTERNET` permission in the release `AndroidManifest.xml` — release/profile builds could not reach the network | P02: verified `<uses-permission android:name="android.permission.INTERNET"/>` in `android/app/src/main/AndroidManifest.xml` and committed it. |
| 2026-10-14 | Startup crash in push bootstrap — found and fixed 2026-10-14. `PushNotificationService` read `FirebaseMessaging.instance` in a field initializer, which threw `[core/no-app]` at construction (outside `initialize()`'s try/catch), escaping `main()` before `runApp`. It would also have shown the iOS permission prompt before the first frame once Firebase was configured. | P01: Firebase is touched only after `initializeApp()` succeeds; permission moved to an uncalled `requestPermissionAndRegisterToken()`; `main()` no longer awaits push init. Regression test in `test/core/services/push_notification_service_test.dart`. |

## Next up (recommended order)

1. Fix the remaining bug that blocks real-device testing
   (splash session-skip — P15).
2. Design and provision the Supabase schema (profiles, preferences,
   recipes, favorites, meal plans) with RLS from day one.
3. Build the `/setup/*` flow (lifestyle → preferences → AI processing),
   since it's the natural continuation of auth and the first thing that
   needs the new schema.
4. Build the Home tab against real (or seeded) recipe data — `RecipeCard`
   already renders real image URLs via `AppNetworkImage`, it just needs a
   live data source to feed it.
