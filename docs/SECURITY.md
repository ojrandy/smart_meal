# SmartMeal — Security Model

> **Status:** v1, written in P07 (2026-10-20). Every later task is checked
> against this document (`docs/prompt.md` §0.4). Owner review is recorded
> in `docs/prompt-tracker.md` → `SECURITY_DOC_REVIEW`.
> **Standard:** commerce grade. We hold the app to the bar of a product that
> will later take payments, even before it does.

## Contents

1. [System context and trust boundaries](#1-system-context-and-trust-boundaries)
2. [Configuration and secrets policy](#2-configuration-and-secrets-policy)
3. [Data classification](#3-data-classification)
4. [Threat model (STRIDE)](#4-threat-model-stride)
5. [Supabase Auth hardening checklist](#5-supabase-auth-hardening-checklist-owner)
6. [Commerce-grade baseline](#6-commerce-grade-baseline-requirements-only)
7. [Vulnerability disclosure and incident response](#7-vulnerability-disclosure-and-incident-response)
8. [Compliance pointers](#8-compliance-pointers)
9. [Accepted risks and open items](#9-accepted-risks-and-open-items)

---

## 1. System context and trust boundaries

```text
 ┌──────────────── user's device (UNTRUSTED) ────────────────┐
 │  SmartMeal app (Flutter, Android + iOS)                   │
 │  · build defines: public identifiers only (§2)            │
 │  · session tokens: platform secure storage (P09)          │
 └───────┬───────────────────────┬───────────────────┬───────┘
         │ HTTPS only (S8)       │ native SDKs       │ push
═════════╪═══ trust boundary ════╪═══════════════════╪═════════
         ▼                       ▼                   ▼
 ┌────────────── Supabase ──────────────┐  ┌───────────────┐  ┌──────────┐
 │ Auth (GoTrue)  ── issues JWTs         │  │ Google / Apple│  │ FCM/APNs │
 │ PostgREST      ── RLS on every table  │  │ identity      │  │          │
 │ Storage        ── bucket policies     │  └───────────────┘  └──────────┘
 │ Edge Functions ── hold all secrets    │──▶ (future) payment / mobile-
 │ Postgres       ── CHECK/FK/RLS        │    money providers, webhooks
 └───────────────────────────────────────┘
```

- **The app is an untrusted client.** Anyone can decompile it, read its
  build defines, call our APIs directly with their own JWT, and replay or
  alter requests. Nothing the client sends is trusted: every rule is
  enforced in Postgres (RLS, CHECK, FK, NOT NULL) or an Edge Function (S3).
- **Authorization lives in RLS.** The publishable key grants only what
  RLS allows the `anon` / `authenticated` roles. User-owned rows are
  scoped with `(select auth.uid())` (S2).
- **Edge Functions are the only place with secrets** and the only place
  that talks to third parties on our behalf (FCM sends, payment providers,
  webhooks).
- **Identity providers** (Google, Apple, later Facebook) return ID tokens
  that the app hands to Supabase (`signInWithIdToken`). Supabase verifies
  the audience and signature; the app never trusts token contents itself.

## 2. Configuration and secrets policy

### What goes where

| Kind | Examples | Where it lives | In git? |
|---|---|---|---|
| Public identifiers | Supabase project URL, publishable key (`sb_publishable_…`), Google OAuth client IDs, `APP_ENV` | `env/<env>.json`, passed with `--dart-define-from-file` and read by `AppConfig` (`lib/core/config/app_config.dart`) | Only `env/example.json` (placeholders). Real files are gitignored |
| Secrets | Supabase secret / service-role key, database password, FCM service account, OAuth client **secrets**, Apple Sign in key (`.p8`), APNs key, payment-provider keys, webhook signing secrets | Supabase Edge Function secrets (`supabase secrets set`) or the CI secret store (GitHub Actions encrypted secrets) | **Never** |
| Signing material | Android upload keystore + `key.properties`, iOS certificates/profiles | Owner-held, outside the repo (P08 / `docs/RELEASE.md`) | **Never** |

**Build defines are compiled into the binary and are extractable.** Anyone
with the APK or IPA can read every `--dart-define` value. So `env/*.json`
may hold **only** values that are safe to publish. Keeping a value out of
git does not make it secret once it is in a build.

### Guards in place

- `AppConfig.fromEnvironment()` runs first in `main()` and throws an
  `AppConfigException` listing every missing or malformed define: an empty
  value, a non-`https://` URL, a malformed client ID, an unknown `APP_ENV`,
  or a value still holding the `env/example.json` placeholder.
- It **refuses `sb_secret_…` keys and legacy JWT (`eyJ…`) keys** in
  `SUPABASE_PUBLISHABLE_KEY`, with an instruction to rotate. A legacy
  `service_role` JWT bypasses RLS completely.
- CI runs gitleaks over the full git history on every push and PR
  (`.gitleaks.toml`). Its allow-list holds only exact, known public
  identifiers. Never allow-list a path or a rule.
- CI builds with `env/example.json` (placeholders). No real project value
  or secret is needed or stored in CI today.

### If a secret leaks

Treat it as an incident (§7): **rotate first**, then remove it. Rewriting
git history does not un-leak a secret that was pushed to a public repo.

### Environments

`APP_ENV` is `dev`, `staging` or `prod`. Today there is **one** Supabase
project (`SUPABASE_ENVIRONMENTS`, owner, 2026-10-20) and every environment
file points at it; see §9 for the risk this carries.

### iOS values that must sit in `Info.plist` (spec for P12)

The Google iOS sign-in SDK reads `GIDClientID` and needs the reversed client
ID as a URL scheme in `Info.plist`. Flutter passes dart-defines to Xcode
only as the base64-encoded, comma-separated `DART_DEFINES` build setting,
so P12 must:

1. Add a **Run Script pre-action** to the Runner scheme's *Build* action
   (`ios/Runner.xcodeproj/xcshareddata/xcschemes/Runner.xcscheme`, "Provide
   build settings from: Runner"). It decodes each `DART_DEFINES` entry and
   writes `GOOGLE_IOS_CLIENT_ID=…` and
   `GOOGLE_REVERSED_CLIENT_ID=com.googleusercontent.apps.<id-prefix>` to
   `ios/Flutter/Dart-Defines.xcconfig`. The prefix is the client ID minus
   `.apps.googleusercontent.com`.
2. Gitignore `ios/Flutter/Dart-Defines.xcconfig`. It is generated, and like
   `Generated.xcconfig` it is never committed.
3. Add `#include? "Dart-Defines.xcconfig"` to both `ios/Flutter/Debug.xcconfig`
   and `ios/Flutter/Release.xcconfig`, after the existing `Generated.xcconfig`
   include. `#include?` tolerates the file being absent on the first build.
4. In `ios/Runner/Info.plist`, set `GIDClientID` = `$(GOOGLE_IOS_CLIENT_ID)`
   and add a `CFBundleURLTypes` entry whose scheme is
   `$(GOOGLE_REVERSED_CLIENT_ID)`.
5. Make `GOOGLE_IOS_CLIENT_ID` required in `AppConfig` (today it may be
   empty), and verify on a Mac with `flutter build ios --no-codesign`
   for each env file.

Android needs no equivalent: Google sign-in on Android uses only the web
client ID (`serverClientId`) plus the SHA-1 registered in Google Cloud.

## 3. Data classification

Retention values marked *proposed* are defaults for the owner to confirm.
They become binding when P13/P14 implement them.

| Class | Examples | Storage | Retention | Access | Deletion path |
|---|---|---|---|---|---|
| **Public** | Recipe catalog, images, nutrition facts | Postgres + Storage (public bucket or read-only RLS) | Indefinite | Everyone, read-only. Writes are admin-only (service role in Edge Functions / migrations) | Admin removal |
| **Personal** | Email, display name, avatar, push (FCM) tokens, favorites, meal plans | Supabase Auth (`auth.users`), owner-scoped tables, private Storage bucket; push token on device + `push_tokens` table (P19) | While the account exists. Push tokens are removed on sign-out (S12) and when FCM reports them invalid (*proposed*) | Owner only (RLS `user_id = (select auth.uid())`) | Account deletion (P14) cascades; tokens are cleared on sign-out (P15/P19) |
| **Sensitive personal** (S6) | Allergies, dietary restrictions, health goals, household size, budget | Owner-scoped tables, RLS, explicit consent recorded (P16) | While the account exists; deleted on account deletion or consent withdrawal (*proposed*) | Owner only. Used server-side only for the owner's recommendations (P17). Never logged (S4), never in analytics, never shared with third parties | Account deletion (P14); consent withdrawal clears the data (P16/P14) |
| **Credentials** | Supabase access + refresh tokens, OAuth ID tokens (transient) | Platform secure storage only: Keychain / Android Keystore (P09, S7). ID tokens are held in memory only, for the exchange | Access JWT ≤ 1 h; refresh tokens rotate (§5) | The device holder; Supabase Auth | Sign-out revokes the session and wipes storage (P15); account deletion revokes all sessions (P14) |
| **Secrets** | Server keys (§2) | Edge Function secrets, CI secret store | Rotate on any suspected exposure, and at least yearly (*proposed*) | Owner and deploy pipeline only | Rotation + revocation at the provider |

Logs, crash reports and analytics may carry **no** credentials, emails,
push tokens or sensitive personal data (S4). Release builds log nothing
through `AppLogger`.

## 4. Threat model (STRIDE)

S = Spoofing · T = Tampering · R = Repudiation · I = Information disclosure ·
D = Denial of service · E = Elevation of privilege.

| # | STRIDE | Threat | Mitigation | Owner prompt |
|---|---|---|---|---|
| 1 | I, S | Token theft from the device (backup, rooted device, other app) | Encrypted session storage (Keychain / Keystore); no tokens in `shared_preferences`, files or logs; backup exclusions | P09, P08 |
| 2 | I, E | IDOR through PostgREST: reading or writing another user's rows by changing an ID | RLS on every table in the migration that creates it, scoped by `(select auth.uid())`; pgTAP cross-user isolation tests | P13 |
| 3 | S | Password-reset link interception (another app claims the scheme, or a mail scanner opens the link) | PKCE flow, then verified App Links / Universal Links; exact redirect allow-list (§5) | P11 |
| 4 | I | Account enumeration through sign-up / sign-in / reset responses | Neutral, identical copy whether or not the account exists; rate limits | P10, P11 |
| 5 | T, E | Malicious notification deep link opening an arbitrary route or URL | Route allow-list for notification payloads; never navigate to a URL from a payload | P19 |
| 6 | I | Secret leakage through source, git history or build defines | §2 policy; `AppConfig` rejects secret keys; gitleaks over full history in CI | P03, P07 |
| 7 | I, T | Reverse engineering and repackaging of the app | Obfuscation + split debug info (defense in depth only, never relied on for security); server-side authority | P08 |
| 8 | T | Unsafe recommendation: a recipe containing a declared allergen is shown | Server-side hard allergen filter in the recommendation query; tests per allergen (S11) | P17 |
| 9 | I | Stale session or data after sign-out / account switch | Clear caches, flags, drafts, push token and providers on sign-out (S12) | P15, P19 |
| 10 | S | Credential stuffing / brute force against email sign-in | Supabase Auth rate limits; leaked-password protection; CAPTCHA on sign-up if enabled; MFA on the roadmap (§5) | P10, owner (§5) |
| 11 | T | Client sends out-of-range or malicious input (oversized strings, bad enums, negative budget) | Client validation for UX only; Postgres CHECK/FK/NOT NULL plus Edge Function validation (S3, S9) | P13, P16 |
| 12 | I | Cleartext or intercepted traffic | HTTPS only; Android `usesCleartextTraffic=false` / network security config; iOS ATS with no exceptions; no TLS bypass in any build (S8) | P08 |
| 13 | I | Sensitive data exposed in logs, crash reports or screenshots | Debug-only `AppLogger`; no PII in errors (S4, S5); screen-capture protection on payment screens (future, §6) | P01, P10, §6 |
| 14 | E | Mis-scoped Storage bucket exposes avatars or uploads | Private buckets with per-user path policies; public bucket only for catalog images | P13 |
| 15 | D | Abuse of costly endpoints (recommendations, Edge Functions) | Per-user and per-IP rate limits; bounded query sizes; pagination | P13, P17 |
| 16 | R | A user disputes an account or data action and there is no record | Auth audit log (Supabase); append-only audit log for consent and account deletion events | P14, P16 |
| 17 | S, T | Compromised or malicious dependency (supply chain) | Pinned lockfile; OSV-Scanner in CI; SHA-pinned CI actions; package vetting before adding (S10) | P03 |
| 18 | E | Test accounts or debug data reaching real users, because dev and prod share one Supabase project | Separate prod project before public launch (§9); `APP_ENV` gate on any debug-only behavior | owner, P20 |

## 5. Supabase Auth hardening checklist (owner)

Apply each item in the Supabase Dashboard (Authentication → Sign In /
Providers, Rate Limits, URL Configuration, Attack Protection). P13 mirrors
the settings into `supabase/config.toml` so they are reviewable in git.
Fill in the date when an item is applied.

| ✔ | Setting | Target | Applied |
|---|---|---|---|
| [ ] | Email confirmation | **On** — no session until the email is confirmed | |
| [ ] | Minimum password length + character requirements | ≥ 8 characters, with lowercase, uppercase, digit and symbol requirements. P10's client validators must match exactly | |
| [ ] | Leaked-password protection (HaveIBeenPwned) | On, if the plan offers it | |
| [ ] | Secure email change | On: both the old and the new address confirm | |
| [ ] | Refresh-token rotation | On, with a short reuse interval (default 10 s) | |
| [ ] | JWT expiry | ≤ 3600 s (1 h) | |
| [ ] | Rate limits | Reviewed: email sends, sign-ups/sign-ins per IP, token refreshes, OTP/verify. Record the chosen numbers here | |
| [ ] | Redirect URL allow-list | Exact app URIs only, built from `com.ojtech.smartmeal` (P11). **No wildcards** | |
| [ ] | Site URL | Not a localhost or placeholder value | |
| [ ] | Unused providers | Disabled — keep only Email, Google, and Apple / Facebook once P12 ships them | |
| [ ] | CAPTCHA on sign-up | Owner decision: hCaptcha or Turnstile. Recommended before public launch | |
| [ ] | MFA (TOTP) | On the roadmap; required before any payment feature | |
| [ ] | Anonymous sign-ins | Off, unless a product decision needs them | |

## 6. Commerce-grade baseline (requirements only)

> **No code until commerce is in scope.** These are the requirements any
> payment work must meet. They are listed now so earlier design choices
> don't close them off.

1. **No card data or PINs in our system.** Payments go only through
   provider-hosted or tokenized flows, so card numbers and mobile-money
   PINs never touch the app, our logs or our database. This keeps PCI DSS
   scope minimal (target SAQ A).
2. **Mobile money is server-side only.** MTN MoMo, Orange Money and similar
   integrations run in Edge Functions with provider secrets. The app only
   starts a payment and shows its status.
3. **The server sets every price.** It computes amounts (XAF) from catalog
   and order data and never trusts a client-chosen amount, discount or
   currency.
4. **Idempotency keys** on every payment intent and payment-affecting
   request, so retries cannot double-charge.
5. **Webhooks are verified:** signature checked with the provider's secret,
   timestamp checked against a short tolerance window, and event IDs
   de-duplicated to stop replays.
6. **Order and payment state machines are enforced in Postgres**
   (constraints/triggers allow only legal transitions), never just in the
   client.
7. **An append-only audit log** for orders, payments, refunds and admin
   actions (no UPDATE/DELETE grants).
8. **Rate limits per user and per IP** on payment and order endpoints.
9. **Device integrity attestation** (Play Integrity / App Attest) checked
   server-side on payment endpoints.
10. **Screen-capture protection** on payment screens (Android
    `FLAG_SECURE`; iOS hides content on capture and in the app switcher).
11. **Fraud monitoring and reconciliation jobs:** a daily reconciliation of
    provider settlements against our ledger, with alerts on mismatches and
    velocity anomalies.
12. **Data residency and retention per launch-market law** (§8), including
    transaction-record retention periods. MFA is required for accounts
    that can pay (§5).

## 7. Vulnerability disclosure and incident response

### Reporting a vulnerability

- **Contact:** ojongrandy01@gmail.com (subject: `SECURITY: SmartMeal`).
  Please do not open a public GitHub issue for security problems.
- Include steps to reproduce, the affected version or commit, and the
  impact. Do not access, change or keep other users' data beyond what is
  needed to demonstrate the issue.
- We aim to acknowledge reports within **{{ACK_DAYS}}** business days and to
  share a fix timeline after triage. *(Owner: set the number.)*
- A `/.well-known/security.txt` on the product website should point here
  once a website exists. *(Owner.)*

### Incident response outline

| Phase | Actions | Who |
|---|---|---|
| 1. Detect & triage | Confirm the report or alert; classify severity (data exposure? credentials? payments?); open a private incident note with a timeline | {{INCIDENT_LEAD}} |
| 2. Contain | Rotate exposed secrets and keys; revoke sessions (Supabase → Auth → sign out all users, if needed); disable the affected feature or Edge Function; block abusive IPs | {{INCIDENT_LEAD}} |
| 3. Eradicate & recover | Fix the root cause; add a regression test (RLS/pgTAP for data issues); deploy; verify | Engineering |
| 4. Notify | Assess notification duties to the data-protection authority and affected users within the legal deadline (§8, **verify with counsel**); notify app stores or providers if required | Owner + counsel |
| 5. Learn | Blameless post-incident review within 2 weeks; update this document and the threat table | Owner + engineering |

Keep a contact list (Supabase support, Google Cloud, Apple, Firebase,
future payment providers, counsel) in a private location. **It is not
kept in this repo.** *(Owner: {{INCIDENT_CONTACTS_LOCATION}}.)*

## 8. Compliance pointers

> These are pointers, not legal advice. **Verify every obligation with
> counsel** before launch.

**Launch market:** Cameroon (`LAUNCH_MARKETS`, owner, 2026-10-20).

- **Cameroon personal-data protection law.** Law No. 2024/017 of
  23 December 2024 on the protection of personal data. Areas to confirm
  with counsel:
  - registration or notification duties with the data-protection authority;
  - whether health-related data such as allergies and diet counts as
    sensitive data needing explicit consent;
  - data-subject rights (access, rectification, erasure, objection);
  - breach-notification deadlines;
  - restrictions on cross-border transfers. Supabase hosting sits outside
    Cameroon, so check this against our project's region.
- **Cameroon Law No. 2010/012 on cybersecurity and cybercrime**, and
  **Law No. 2010/021 on electronic commerce**. Both are relevant once the
  app sells anything; confirm current obligations with counsel.
- **GDPR** is **not** in scope for the Cameroon-only launch. Revisit if
  the app is offered to EU residents.
- **App stores:** Google Play Data safety form and Apple privacy nutrition
  labels must match §3. Both stores require in-app account deletion (P14).

**Internal records we must keep:**

- [ ] A **record of processing activities**: purpose, data classes (§3),
  legal basis, recipients (Supabase, Google, Firebase), retention, and
  transfers.
- [ ] **Explicit, separate consent** for allergy and diet data, captured in
  P16 with a timestamp and the policy version. It must be possible to
  withdraw it.
- [ ] A privacy policy that matches §3, linked in-app and in both stores.

## 9. Accepted risks and open items

| Item | Risk | Plan |
|---|---|---|
| One Supabase project for every `APP_ENV` | Development and test accounts, test data and destructive migrations share a database with real users; a mistaken `db reset` or test run could hit production data | Create a separate production (or staging) project before public launch; P13 develops against a local Supabase (Docker), and remote pushes need owner approval |
| Build defines are extractable | Public identifiers are visible to anyone with the binary | Accepted by design: only public identifiers go there (§2); access control is RLS |
| Release-build config errors | A release build made without an env file crashes at startup and shows nothing to the user | Accepted: it is a build mistake that is caught in the first run. P20's release checklist builds from `env/prod.json` |
| Values still pending | `{{ACK_DAYS}}`, `{{INCIDENT_LEAD}}`, `{{INCIDENT_CONTACTS_LOCATION}}` | The owner fills them in; tracked in `docs/prompt-tracker.md` |
