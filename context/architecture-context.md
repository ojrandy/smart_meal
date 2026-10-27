# SmartMeal — Architecture Context

## Guiding principle

Feature-first folder structure with a strict three-layer split inside each
feature: **data → domain → presentation**. This is already established by
the `auth` feature — every new feature must follow the same shape. Don't
introduce a different pattern (BLoC, MVC, MVVM-with-controllers, etc.) for a
new feature "because it fits better." Consistency across features matters
more than local optimality.

## Folder structure

```
lib/
  core/                          # Shared across all features
    config/                      # AppConfig: typed, validated build defines from
                                  # env/<env>.json (Supabase URL/key, OAuth client IDs,
                                  # APP_ENV). Built once in main(); read via appConfigProvider.
    constants/                   # Compile-time app constants: AppAssets (every bundled
                                  # image path). Never hard-code an 'assets/...' string elsewhere.
    providers/                   # App-wide Riverpod providers (e.g. supabaseClientProvider;
                                  # appConfigProvider and sharedPreferencesProvider are
                                  # overridden in main()'s ProviderScope)
    router/                      # go_router setup, shell scaffold, nav bar; the guard's
                                  # decision is the pure resolveRedirect in launch_redirect.dart
    services/                    # App-lifecycle bootstrap classes with no reactive state
                                  # to watch (e.g. PushNotificationService) — called directly
                                  # from main(), not exposed via a Riverpod provider. If a
                                  # service later needs to expose reactive state to widgets,
                                  # give it a provider at that point, not preemptively.
                                  # Also holds AppLogger, the debug-only logger (a no-op in
                                  # profile/release builds). Log through it, never through
                                  # print/developer.log, and never log tokens or personal data.
                                  # SecureSessionStorage / SecurePkceStorage: the Supabase
                                  # session and PKCE verifier in Keychain/Keystore (P09),
                                  # passed to Supabase.initialize via FlutterAuthClientOptions.
                                  # They migrate a legacy plaintext session, clear a session
                                  # surviving an iOS reinstall, and treat any storage error
                                  # as signed out. Never persist credentials anywhere else.
    l10n/                        # UI text in English and French (owner, 2026-10-26):
                                  # app_en.arb (template, every key described) and
                                  # app_fr.arb; gen-l10n writes app_localizations*.dart
                                  # here (config: l10n.yaml). Widgets read text through
                                  # context.l10n (l10n.dart) — never a string literal.
    theme/                       # AppColors, AppTheme
    validation/                  # Pure form validators (validateEmail, validateNewPassword,
                                  # ...) returning null or a user-facing message. Every form
                                  # uses these; no inline regex in screens.
    widgets/                     # Reusable, feature-agnostic UI (CustomButton, RecipeCard,
                                  # showAppSnackBar...)
  features/
    <feature_name>/
      data/                      # Repositories — raw SDK/API calls only, no state
      domain/                    # State classes + Notifiers — business logic, no UI
      presentation/
        screens/                 # Full-page widgets, wired to Riverpod
        widgets/                 # Widgets local to this feature only (promote to core/widgets if reused)
  main.dart
```

Reference implementation to copy the pattern from: `lib/features/auth/`.

## Layer responsibilities

### `data/` — Repository layer
- One class per feature wrapping the external SDK (Supabase, etc.).
- **No Riverpod state, no UI logic.** Pure async methods that throw on
  failure (`AuthException` or plain `Exception`) and return plain SDK models
  or DTOs.
- Translate platform failures into **typed** exceptions here (see
  `GoogleSignInFailure` in `auth_repository.dart`: cancelled / network /
  failed, mapped from `PlatformException.code`), so nothing above ever
  matches on error text.
- Exposed via a single `Provider<XRepository>` at the bottom of the file
  (see `authRepositoryProvider` in `auth_repository.dart`).
- Constructor-inject the `SupabaseClient` (via `supabaseClientProvider`),
  never call `Supabase.instance.client` directly outside `core/providers`.

### `domain/` — State + Notifier layer
- Keep **long-lived truth** and **operation progress** in separate
  notifiers. Auth is the reference:
  - `authSessionProvider` (`auth_session.dart`): the signed-in `User?`,
    straight from the Supabase session stream. The router reads this and
    nothing else, so a loading or failed operation never moves the user.
  - `authNotifierProvider` (`auth_notifier.dart`): the operation a screen
    started, as the sealed `SmartMealAuthState` — `AuthIdle`, `AuthLoading`,
    `AuthError`, `AuthAwaitingEmailConfirmation`, `AuthResetEmailSent`.
    Success returns to `AuthIdle`; the session change does the navigating.
- Prefer sealed classes over booleans/enums + nullable fields — it forces
  exhaustive handling in the UI.
- One operation `Notifier<TState>` per feature exposing intent methods
  (`signIn`, `signUp`, ...), each following the pattern:
  1. set `state = Loading`
  2. call the repository
  3. map success/failure to a concrete state
  4. catch typed expected outcomes first (e.g. `GoogleSignInCancelled` →
     idle, no message), then everything else through the feature's one
     error mapper (`formatAuthError`), logging the raw error via `AppLogger`
- Exposed via a single `NotifierProvider` at the bottom of the file.
- Long-lived subscriptions (auth stream, realtime channels) are opened in
  `build()` and cancelled via `ref.onDispose`.

### `presentation/` — UI layer
- Screens are `ConsumerStatefulWidget` when they own `TextEditingController`s
  or a `GlobalKey<FormState>`; `ConsumerWidget` otherwise.
- Screens **read** notifiers via `ref.read(...).notifier` for actions and
  **watch** state via `ref.watch(...)` for rendering.
- Side effects (snackbars, non-gating navigation such as signup → login
  after a confirmation email) go through `ref.listen` in `build()`, never
  inside the state class and never inside `onPressed` callbacks directly —
  see `_onAuthStateChanged` in `signup_screen.dart` as the template. Screens
  never navigate to `/home` after sign-in: that is the router's job.
- Screens must not talk to a repository or Supabase directly — always
  through a notifier.

## Navigation architecture

- Single `GoRouter` instance behind `routerProvider` in
  `core/router/app_router.dart`.
- Auth gating is centralized in one `redirect` callback — do not add
  per-screen auth checks. Routes are classified as public
  (`/splash`, `/onboarding`, `/auth/*`) or protected (everything else).
- The decision itself is the pure `resolveRedirect(LaunchSnapshot)` in
  `core/router/launch_redirect.dart`, table-tested. Its inputs: the session
  (`authSessionProvider`), onboarding seen (`onboardingSeenProvider`,
  persisted in SharedPreferences) and launch readiness (`launchReadyProvider`,
  the splash hold). The splash only animates; the router leaves it for
  `/home`, `/onboarding` or `/auth/login`.
- Password recovery (P11) is one more input: `passwordRecoveryProvider`
  (persisted flag). `AuthSessionNotifier` sets it from
  `AuthChangeEvent.passwordRecovery` *before* publishing the session, so a
  recovery session is never seen without it; while it is set,
  `resolveRedirect` allows only `/auth/reset-password`. Sign-in, sign-out
  and starting without a session clear it.
- Setup gate (P15): `setupStatusProvider` (`features/setup/domain/`) holds
  `signedOut / checking / incomplete / complete / unavailable` for the
  signed-in user. It starts from a per-user cached boolean
  (`smartmeal.setup_complete.<uid>`, cleared on sign-out — S12), then
  confirms `profiles.setup_completed_at` with the server on sign-in, on app
  resume and on retry. Only `complete` opens the main tabs; anything else
  sends the user to `/setup/loading`, which waits, offers a retry (and sign
  out) when offline with nothing cached, and enters the flow when setup is
  unfinished. Setup screens never navigate to `/home`: when P16 marks setup
  complete, the router moves on.
- Setup flow (P16): `SetupNotifier` (sealed `SetupEditing / Submitting /
  Completed / Failed`) holds the answers in an immutable `SetupDraft`,
  **in memory only** (sensitive, S6; reset on sign-out, S12). One question
  per step; `SetupQuestionsScreen` serves `/setup/lifestyle` (steps 1–4)
  and `/setup/preferences` (5–9) and only moves between those two routes
  and `/setup/processing`, which calls the atomic `complete_setup` RPC and
  then `setupStatusProvider.markComplete()`. What users read (plain,
  Cameroonian wording) lives in `setup_labels.dart`; the enums in
  `setup_vocabulary.dart` carry only database values. Budget advice
  (`budget_advice.dart`) advises, never blocks. Money is formatted only
  through `core/formatting/fcfa.dart`.
- Auth deep links: supabase_flutter (`detectSessionInUri`, PKCE) handles
  `com.ojtech.smartmeal://auth-callback` itself — the app adds no link
  parsing. A failed link arrives as an error on the auth stream;
  `isAuthLinkError` picks it out and `SmartMealApp` shows it through
  `rootScaffoldMessengerKey`, which survives route changes. Messages that
  must outlive a redirect use that root messenger.
- `_RouterRefreshNotifier` bridges those providers into GoRouter's
  `refreshListenable` — this is what makes the redirect re-evaluate live
  when they change. Any new global state that should affect routing
  (as the setup gate did in P15) extends this same notifier and
  `LaunchSnapshot` rather than creating a second refresh mechanism.
- The 5-tab shell (`Home`, `Discover`, `Planner`, `Favorites`, `Profile`)
  uses `StatefulShellRoute.indexedStack` so each tab keeps its own
  navigation stack and scroll position. New top-level tabs go here; detail
  screens (e.g. recipe detail) nest as sub-routes of their tab branch, not
  as siblings at the root.
- Replace `PlaceholderScreen` entries one at a time as each screen is built.
  Never leave a route pointing at a placeholder and a real screen
  simultaneously reachable.

## Language (English + French)

- Every user-facing string lives in `lib/core/l10n/app_en.arb` with a
  description, and in `app_fr.arb` with the same key. A new string is
  added to both in the same change; `test/core/l10n/arb_test.dart` fails
  on a missing key, a missing description or French left in English.
  Plurals and counts use ICU (`{count, plural, =1{…} other{…}}`), never
  string concatenation. French uses a no-break space before `? ! : ;`.
- Domain and data layers never produce user-facing text. They report
  typed outcomes (`AuthErrorReason`, `FieldError`, `SetupFailed`, the
  `authLinkErrorProvider` flag) and presentation words them
  (`authErrorText`, `fieldErrorText`, `setup_labels.dart`). Database
  values and server names stay English; the app maps them by key (e.g.
  cuisine slug) with the server name as fallback.
- Language choice: `appLanguageProvider` (`features/language/`) holds
  the user's pick (SharedPreferences `smartmeal.language`) or null to
  follow the phone; `resolveAppLocale` gives French to French phones
  and English to everyone else. `LanguageSwitch` (EN | FR) is on
  onboarding and sign-in; T1-Profile adds it to Profile.
- Money goes through `core/formatting/fcfa.dart` in both languages
  (`3 100 FCFA`).

## State management rules

- Riverpod only. No `setState` for anything that represents app/business
  state — `setState` is acceptable only for pure local UI state that no
  other widget needs (e.g. password-visibility toggle in
  `CustomTextField`, onboarding carousel page index).
- One notifier per feature/concern. Don't merge unrelated state into a
  single giant notifier.
- Providers are declared at the bottom of the file that defines the class
  they provide, not centralized in one giant `providers.dart`.

## Backend architecture (Supabase)

- Supabase is the system of record: Auth, Postgres, Storage, Realtime.
- Every table needs Row Level Security enabled from the moment it's
  created — this app never gets a "add RLS later" pass. Auth-owned tables
  (profiles, preferences, favorites, meal plans) are scoped to
  `auth.uid()`.
- Repository methods map 1:1 to Supabase operations. Business logic
  (scoring, matching, budget math) belongs in the domain layer or a
  Supabase Edge Function — never inline in a repository or a widget.
- The schema is defined (P13): tables, vocabularies and the RLS matrix are
  in `context/data-model.md`; the SQL is in `supabase/migrations/`.
- **Migration workflow.** Every schema change is a new timestamped file
  from `npx supabase@2.121.0 migration new <name>` (the CLI is used through
  npx, pinned; Docker Desktop must be running). Never edit a migration that
  has been applied anywhere; changes are additive. Each new table enables
  RLS, revokes nothing it never granted (default privileges already give
  `anon`/`authenticated` nothing), grants `authenticated` only the columns
  it may write, and adds one policy per operation in the same migration.
- **Local stack and tests.** `npx supabase@2.121.0 start`, then
  `npx supabase@2.121.0 db reset` (migrations + `seed.sql`) and
  `npx supabase@2.121.0 test db` (pgTAP files in `supabase/tests/`).
  `npx supabase@2.121.0 db lint` must be clean. New user tables get
  isolation tests (A vs B, anon) and join the cascade test.
- **Production deploys from git.** The hosted project has Supabase's GitHub
  integration on: its production branch follows git `main`, so **pushing
  `main` applies any new migration to production** (found 2026-10-23, P13).
  A migration therefore reaches `main` only after the owner approves the
  push; run `db push --dry-run --linked` against the linked project first.
- **Remote.** `supabase link`, `db push` and every other remote command
  need the owner's explicit approval; show `db push --dry-run` first.
  `seed.sql` is local only.

## What NOT to do

- Don't create a new state-management approach per feature.
- Don't call `Supabase.instance.client` or `FirebaseAuth.instance` from a
  widget — always go through a repository + provider.
- Don't put navigation logic inside a Notifier — notifiers report state,
  screens react to it via `ref.listen`.
- Don't add a new top-level folder under `lib/` outside `core/` and
  `features/`.
