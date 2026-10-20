# SmartMeal

SmartMeal is an AI-powered meal-planning app for Android and iOS. It learns a
user's budget, lifestyle and taste, recommends meals, and explains why each
one fits. Product detail is in
[`context/project-overview.md`](context/project-overview.md).

## Prerequisites

- Flutter **3.35.7** (stable). CI pins the same version in
  [`.github/workflows/ci.yml`](.github/workflows/ci.yml).
- Android SDK for Android builds; a Mac with Xcode for iOS builds.

## Run locally

Configuration comes from a per-environment JSON file passed as build
defines; nothing environment-specific lives in source.

1. Copy the template and fill in real values. `env/*.json` is gitignored,
   except the template.

   ```sh
   cp env/example.json env/dev.json
   ```

   | Key | Where to find it | Required |
   |---|---|---|
   | `APP_ENV` | `dev`, `staging` or `prod` | yes |
   | `SUPABASE_URL` | Supabase Dashboard → Settings → API (`https://…`) | yes |
   | `SUPABASE_PUBLISHABLE_KEY` | Supabase Dashboard → Settings → API Keys (`sb_publishable_…`) | yes |
   | `GOOGLE_WEB_CLIENT_ID` | Google Cloud Console → Credentials → Web client | yes |
   | `GOOGLE_IOS_CLIENT_ID` | Google Cloud Console → Credentials → iOS client | empty until P12 |

2. Run with that file, or pick **SmartMeal (dev)** in VS Code's Run and
   Debug panel (`.vscode/launch.json`):

   ```sh
   flutter pub get
   flutter run --dart-define-from-file=env/dev.json
   ```

Without a valid file the app stops at startup with an `AppConfigException`
that lists each missing or malformed key.

**Only public identifiers go in these files.** Build defines are compiled
into the app and can be extracted from it. Secret or service-role keys never
go here; see [`docs/SECURITY.md`](docs/SECURITY.md).

Push notifications stay disabled until a Firebase project is configured
(P19 in `docs/prompt.md`).

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
