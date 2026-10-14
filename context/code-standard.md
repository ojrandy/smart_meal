# SmartMeal — Code Standard

Applies to every Dart file in `lib/`. This is enforced by convention, not
just `flutter_lints` — review against this list before considering any
change done.

## Formatting & analysis

- Run `dart format .` before committing. No manually-aligned columns, no
  trailing whitespace.
- `flutter analyze` must return zero issues before a change is considered
  finished. Don't suppress a lint with `// ignore:` unless there's a
  documented reason in the same comment.
- `analysis_options.yaml` uses the stock `flutter_lints` set — don't loosen
  it without a stated reason.

## Naming

- Files: `snake_case.dart`.
- Classes: `PascalCase`. Widgets end with a role-describing suffix, not a
  layer suffix: `LoginScreen`, `CustomTextField`, `RecipeCard` — not
  `LoginScreenWidget` or `RecipeCardComponent`.
- Riverpod providers: `camelCase` + `Provider` suffix,
  matching the file's primary export: `authRepositoryProvider`,
  `authNotifierProvider`, `routerProvider`.
- Sealed state classes: `<Feature>State` base, concrete states prefixed with
  the feature: `AuthLoading`, `AuthAuthenticated` — not generic `Loading`,
  `Success` (these collide across features and are ambiguous in imports).
- Booleans read as questions: `isLoading`, `isPassword`, `isFavorite`.

## Widget construction rules

- `const` constructors everywhere possible. If a widget's `build()` method
  can be const, mark it const at every call site.
- Every public widget takes a `super.key`.
- Prefer composition over configuration flags spiraling out of control. If a
  widget accumulates more than ~4 boolean flags, it's a sign it should split
  into two widgets (see `CustomButton.isOutline` as the acceptable ceiling —
  don't add a 5th).
- No business logic inside widget `build()` methods beyond simple
  presentation mapping (e.g. `authState is AuthLoading`). Anything more
  belongs in the domain layer.
- Reuse before creation: check `core/widgets/` before writing a new button,
  text field, or card. If an existing widget is *close* but not exact,
  extend its parameters rather than forking a near-duplicate.

## Error handling

- Repository methods let SDK exceptions propagate (`AuthException`, etc.) —
  don't swallow them in the data layer.
- Notifiers catch the specific SDK exception type first, then a generic
  `catch (_)` as a last resort, and always translate to a user-safe message
  string. Never surface a raw exception message to the UI (see
  `_formatAuthError` in `auth_notifier.dart` as the template — extend that
  switch statement per Supabase error code as new ones are hit, don't create
  a second error-formatting helper elsewhere).
- Never let an unhandled exception reach the widget tree from an async
  button callback — every notifier action method must be wrapped in
  try/catch and resolve to a concrete state.

## Comments

- Default to no comments. Code should read clearly from naming and
  structure.
- Write a comment only when it explains *why*, not *what* — a non-obvious
  constraint, a workaround for a specific SDK quirk, or an invariant that
  isn't visible from the code itself (see the `serverClientId` comment in
  `auth_repository.dart` as the right calibration — it explains an Android
  platform requirement that isn't obvious from the code).
- Don't leave commented-out code in commits. Delete it — git history is the
  archive.
- No file-header doc comment blocks restating the filename. Doc comments
  (`///`) on public classes are fine when they clarify usage (see
  `AuthRepository`), but keep them to 1–4 lines.

## Theming & styling

- Never hardcode a `Color(0x...)` or a raw `Colors.*` value in a
  feature/screen file. Always go through `AppColors`. If a needed color
  doesn't exist yet, add it to `app_colors.dart` first.
- Never hardcode font sizes/weights that duplicate an existing `TextTheme`
  entry — extend `AppTheme` instead of overriding ad hoc per screen if the
  same style is used more than once.
- Border radius, spacing, and button heights should match existing values
  already in use (16 for inputs/buttons, 24 for cards, 56 height for
  primary buttons) rather than inventing new ones per screen.

## Async & state

- No `setState` for anything beyond trivial local UI toggles (see
  `architecture-context.md`).
- Always `mounted` check after an `await` before touching `context` or
  calling `setState` inside a `State`/`ConsumerState`.
- Dispose every `TextEditingController`, `PageController`,
  `AnimationController`, and stream subscription. No exceptions.

## Imports

- Relative imports within `lib/` (matches existing convention — see any
  screen file). Don't mix relative and `package:smart_meal/...` imports in
  the same file.
- Group imports: Flutter/Dart SDK → third-party packages → local project
  imports, each group separated by a blank line (matches current files).

## Testing expectations

- Pure functions (error mapping, formatters, matching/scoring logic once it
  exists) get a unit test in `test/`, mirroring the `lib/` path.
- Widget tests are added per screen as it's built past placeholder status —
  don't leave `test/widget_test.dart` as the only test once real screens
  exist.
- A feature is not "done" if `flutter analyze` and `flutter test` haven't
  both been run clean.

## Git / commits

- Commit messages describe *why*, one or two sentences, present tense.
- Don't bundle unrelated changes (e.g. a UI fix and a schema change) into
  one commit.
