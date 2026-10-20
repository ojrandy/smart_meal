# SmartMeal — Progress Tracker

> Update this file every time a feature's status changes. Keep entries
> honest — "in progress" means actively being worked on, not "started once."

Last reviewed: **2026-10-20** (P06 — permanent app identity `com.ojtech.smartmeal`, ✅ on `p06-app-identity`, owner phone check passed; P01–P05 on `main`, CI green; P05 — UI standards and accessibility cleanup, ✅ on `p05-ui-a11y`; P04 — dependency, asset and font diet; earlier: P01–P03 on 2026-10-14)

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
| Supabase client bootstrap | ✅ | `Supabase.initialize(url:, publishableKey:)` in `main.dart`; real project URL + publishable key in `supabase_config.dart` (2026-07-20; switched from the deprecated `anonKey:` parameter in P02, 2026-10-14) |
| Firebase (push notifications) | 🟡 | `PushNotificationService` (`lib/core/services/push_notification_service.dart`). `main()` starts `initialize()` without awaiting it, so push can never delay or block the first frame. `initialize()` touches no Firebase API until `Firebase.initializeApp()` succeeds, never throws and never prompts; it registers the background handler, attaches the foreground/opened-app listeners and sets `isAvailable`. With no Firebase config (today) it logs "Firebase not configured — push notifications disabled." in debug only and leaves `isAvailable` false. `requestPermissionAndRegisterToken()` (permission prompt + token fetch + refresh listener) exists but **nothing calls it** — P19 wires it to a contextual moment. `dispose()` cancels all subscriptions. Logging goes through the debug-only `AppLogger`; token values are never logged. Covered by `test/core/services/push_notification_service_test.dart` (2026-10-14). **Still blocked on external setup**: real Firebase project, `google-services.json` + Google Services Gradle plugin (Android), `GoogleService-Info.plist` via Xcode (iOS), and ideally `flutterfire configure` for `firebase_options.dart`. Exact steps are in the class doc comment. Deliberately did *not* touch Android/iOS build files — applying the Gradle plugin without a real `google-services.json` breaks the build for everyone. |
| Quality + security gates | ✅ | `tool/verify.sh` (format → analyze `--fatal-infos` → test --coverage) and `.github/workflows/ci.yml` (same gate + debug APK + gitleaks full history + OSV) added in P03, 2026-10-14. Passes locally and in CI: first run on `main` 2026-10-15 (run 38766137427), all jobs green |

## Feature: Splash

| Item | Status | Notes |
|---|---|---|
| Splash screen UI/animation | ✅ | `flutter_animate` entrance sequence |
| Session-aware routing | ⬜ | Currently *always* routes to `/onboarding` after 5s regardless of an existing session — needs a `shared_preferences` "onboarding seen" flag + auth-state check to skip straight to `/home` for returning users |

## Feature: Onboarding

| Item | Status | Notes |
|---|---|---|
| 3-slide carousel UI | ✅ | |
| Skip / Next / Get Started actions | ✅ | Routes to `/auth/login` |
| "Seen onboarding" persistence | ⬜ | Not implemented — see Splash issue above, same root cause |

## Feature: Authentication

| Item | Status | Notes |
|---|---|---|
| Repository layer (`AuthRepository`) | ✅ | Email/password, Google, sign-out, password reset |
| State + Notifier (`AuthNotifier`, `SmartMealAuthState`) | ✅ | Sealed state, live Supabase stream subscription |
| Login screen | ✅ | Email/password + Google; Apple/Facebook are UI-only stubs |
| Signup screen | ✅ | Handles both "email confirmation off" and "on" paths |
| Router auth guard | ✅ | Centralized `redirect` in `app_router.dart` |
| Forgot password screen | ⬜ | Route exists (`/auth/forgot-password`), points at `PlaceholderScreen` |
| Apple Sign-In | ⬜ | Button present, shows "coming soon" snackbar; needs Apple Developer account |
| Facebook Sign-In | ⬜ | Button present, shows "coming soon" snackbar |
| Password rule consistency | 🟡 | Login requires 6 chars min, signup requires 8 — should match |

## Feature: Setup / Preferences flow

| Item | Status | Notes |
|---|---|---|
| `/setup/loading` | ⬜ | Placeholder |
| `/setup/lifestyle` | ⬜ | Placeholder |
| `/setup/preferences` | ⬜ | Placeholder |
| `/setup/processing` (AI processing experience) | ⬜ | Placeholder |
| Supabase `preferences` table | ⬜ | Schema not designed yet |

## Main tab shell

| Tab | Status | Notes |
|---|---|---|
| Home | ⬜ | Placeholder screen |
| Discover | ⬜ | Placeholder screen |
| Planner | ⬜ | Placeholder screen |
| Favorites | ⬜ | Placeholder screen |
| Profile | ⬜ | Placeholder screen |

## Backend / data

| Item | Status | Notes |
|---|---|---|
| Real Supabase project provisioned | ✅ | Project `svrelfdfonxwlfcljrag` exists and the app points at it. The project is provisioned; the schema is not (no tables, RLS or migrations yet — P13) |
| `profiles` table + RLS | ⬜ | |
| `preferences` table + RLS | ⬜ | |
| `recipes` table + RLS | ⬜ | |
| `favorites` table + RLS | ⬜ | |
| `meal_plans` table + RLS | ⬜ | |
| AI recommendation logic | ⬜ | Not started — no scoring/matching engine, no Edge Functions |
| Google OAuth client configured (Supabase + Cloud Console) | 🟡 | Web Client ID set in `supabase_config.dart` (2026-07-20). Still needed: (1) enable Google provider in Supabase Dashboard → Auth → Providers → Google with this Client ID; (2) Android OAuth Client ID in Google Cloud Console keyed to **`com.ojtech.smartmeal`** (P06, 2026-10-15) + the debug SHA-1, then the upload and Play App Signing SHA-1s (P12). Any client created earlier for `com.example.smart_meal` (debug SHA-1 `A3:AA:68:7E:A6:86:B6:78:3E:75:E3:59:AF:8C:8F:16:4D:F2:08:DD`) no longer matches the app — delete it and create a new one; (3) iOS OAuth Client ID keyed to bundle ID `com.ojtech.smartmeal` + reversed-client-id URL scheme added to `ios/Runner/Info.plist`. |

## Known issues (open)

| Issue | Severity | Where |
|---|---|---|
| Splash always shows onboarding, even for returning authenticated users | Medium | `lib/features/splash/presentation/splash_screen.dart` |
| Desktop scaffolds (`linux/`, `macos/`, `windows/`) are still in the repo with `com.example` identifiers. The app is Android + iOS only (§0.3), so P06 left them alone; deleting them needs the owner's OK | Low | `linux/`, `macos/`, `windows/` |
| Android 16+ ignores `screenOrientation="portrait"` on large screens (smallest width ≥ 600 dp: tablets, unfolded foldables) for apps targeting SDK 36, so the app can appear in landscape there; the portrait-only layouts have not been checked in landscape on a tablet | Low | `android/app/src/main/AndroidManifest.xml`, all screens |
| Password min length mismatch (login 6 vs signup 8) | Low | `login_screen.dart`, `signup_screen.dart` |
| Plain `TextStyle(fontWeight: …)` without `GoogleFonts.inter(...)` inherits the theme's per-variant family (`Inter_regular`), so the engine fakes the weight from Regular instead of using the bundled Medium/SemiBold/Bold file (found in P04 by code reading; e.g. onboarding, auth screens, `AiChefCard`, `RecipeCard`) — not fixed in P05: using the real weight files visibly changes glyphs, so it needs the owner's sign-off (fix in `AppTheme`, e.g. a pubspec `Inter` family with weights) | Low | `lib/core/theme/app_theme.dart`, screens/widgets |
| Release build on this dev machine fails in Android lint (`lintVital*`: `ClassNotFoundException: com.android.tools.lint.Main` / `UastEnvironment`) — environment issue, not project code; P04 size builds ran Gradle directly with `-x lintVital*`. CI's Linux runner is unaffected (it builds debug). Repair the local Gradle cache or reinstall before P08/P20 release work | Low (dev env) | local `~/.gradle` |
| Test coverage 62.8 % lines (2026-10-15): auth notifier/repository and router redirect logic are still untested | Low | `test/` |
| WCAG AA contrast failures left after P05 (onboarding fixed): splash "AI"/"TECH" orange (`brandAccent`) on the green gradient 1.27:1 and white subtitle/"BY OJ" on the light end of the gradient 2.33:1 — an overlay can't fix orange-on-green, so this needs a color decision; `textHint` (2.54:1 on surface) used for `RecipeCard` meta icons (non-text needs 3:1) | Medium | `splash_screen.dart`, `app_colors.dart`, `recipe_card.dart` |
| `CustomTextField`: only the 24 dp text line is tappable; taps on the rest of the 56 dp box (label, padding) do not focus the input (fails the 48 dp tap-target guideline) | Low | `lib/core/widgets/custom_text_field.dart` |
| `docs/prompt.md` P05 enforcement command: its `Colors\.` alternative has no word boundary, so it also matches every `AppColors.`; use `\bColors\.` | Low (docs) | `docs/prompt.md` |
| OSV-Scanner CI job is non-blocking (`continue-on-error`) — make it blocking on 2026-11-14 after triaging findings | Medium | `.github/workflows/ci.yml` |
| `osv-scanner-action` runs its Docker image by tag, not digest — residual supply-chain risk | Low | `.github/workflows/ci.yml` |
| Notification permission is never requested — wired in P19 | Medium | `lib/core/services/push_notification_service.dart` (`requestPermissionAndRegisterToken` has no caller) |
| Push is receive-only scaffolding: FCM token is fetched but not stored, foreground messages show no UI, notification taps do not navigate, and taps that cold-start the app (`getInitialMessage`) are not handled — P19 | Medium | `lib/core/services/push_notification_service.dart` |

## Resolved issues

| Date | Issue | Fix |
|---|---|---|
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
