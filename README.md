# SmartMeal

SmartMeal is an AI-powered meal-planning app for Android and iOS. It learns a
user's budget, lifestyle and taste, recommends meals, and explains why each
one fits. Product detail is in
[`context/project-overview.md`](context/project-overview.md).

## Prerequisites

- Flutter **3.35.7** (stable). CI pins the same version in
  [`.github/workflows/ci.yml`](.github/workflows/ci.yml).
- Android SDK for Android builds; a Mac with Xcode for iOS builds.

## Run

```sh
flutter pub get
flutter run
```

The app uses the Supabase project configured in
`lib/core/config/supabase_config.dart`. Push notifications stay disabled
until a Firebase project is configured (P19 in `docs/prompt.md`).

## Verify

Run the local quality gate before every push. It runs the same checks as CI:
`pub get` → format check → `flutter analyze --fatal-infos --fatal-warnings`
→ `flutter test --coverage`.

```sh
tool/verify.sh        # Git Bash on Windows, or any shell on macOS/Linux
```

Secret scan over the full git history, using the config CI uses
([gitleaks](https://github.com/gitleaks/gitleaks) v8.30.1):

```sh
gitleaks git . --config .gitleaks.toml --redact
```

## Docs

| Where | What |
|---|---|
| [`AGENT.md`](AGENT.md) | Entry point for contributors and AI agents: reading order and non-negotiables |
| [`context/`](context/) | Architecture, UI system, code standard, workflow rules, progress tracker |
| [`docs/prompt.md`](docs/prompt.md) | Remediation plan, task by task (P01–P20) |
| [`docs/prompt-tracker.md`](docs/prompt-tracker.md) | Status of each remediation task |
