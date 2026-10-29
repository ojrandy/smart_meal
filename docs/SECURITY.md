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
10. [Auth deep links and password recovery](#10-auth-deep-links-and-password-recovery)
11. [Account deletion and retention](#11-account-deletion-and-retention)

---

## 1. System context and trust boundaries

```text
 ┌──────────────── user's device (UNTRUSTED) ────────────────┐
 │  SmartMeal app (Flutter, Android + iOS)                   │
 │  · build defines: public identifiers only (§2)            │
 │  · session tokens: platform secure storage (P09, done)    │
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
| Session credentials (S7) | Supabase access + refresh tokens, PKCE verifier | On the device **only** in platform secure storage through `SecureSessionStorage` / `SecurePkceStorage` (Keychain / Keystore). Never `shared_preferences`, files or logs | **Never** |
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
| **Public** | Recipe catalog, images, nutrition facts; the food catalog (`ingredients`: estimated market prices, nutrients per 100 g, allergens; LF01) and the derived `recipe_costs` / `recipe_nutrition` views | Postgres + Storage (public bucket or read-only RLS). Food catalog: reference data shipped by migration from `docs/reference/ingredient-*.csv`; signed-in users read active foods only (anon: nothing) | Indefinite | Everyone, read-only. Writes are admin-only (service role in Edge Functions / migrations) | Admin removal (a food used by a recipe cannot be deleted) |
| **Personal** | Email, display name, avatar, push (FCM) tokens, favorites, meal plans, recipe interactions (kept 12 months, then purged daily by pg_cron — owner, 2026-10-23) | Supabase Auth (`auth.users`), owner-scoped tables, private Storage bucket; push token on device + `push_tokens` table (P19) | While the account exists. Push tokens are removed on sign-out (S12) and when FCM reports them invalid (*proposed*) | Owner only (RLS `user_id = (select auth.uid())`) | Account deletion (P14) cascades; tokens are cleared on sign-out (P15/P19) |
| **Sensitive personal** (S6) | Allergies, dietary restrictions, health goals, household size, budget | Owner-scoped tables, RLS, explicit consent recorded (P16) | While the account exists; deleted on account deletion or consent withdrawal (*proposed*) | Owner only. Used server-side only for the owner's recommendations (P17). Never logged (S4), never in analytics, never shared with third parties | Account deletion (P14); consent withdrawal clears the data (P16/P14) |
| **Credentials** | Supabase access + refresh tokens, OAuth ID tokens (transient) | Platform secure storage only, via `SecureSessionStorage` (`lib/core/services/secure_session_storage.dart`, P09): Android Keystore-wrapped AES-GCM; iOS Keychain `first_unlock_this_device` (no iCloud sync). The PKCE verifier too. Legacy plaintext sessions are migrated and deleted; a session surviving an iOS reinstall is cleared; storage errors mean signed out (S7). ID tokens are held in memory only, for the exchange | Access JWT ≤ 1 h; refresh tokens rotate (§5) | The device holder; Supabase Auth | Sign-out revokes the session and wipes storage (P15); account deletion revokes all sessions (P14) |
| **Secrets** | Server keys (§2) | Edge Function secrets, CI secret store | Rotate on any suspected exposure, and at least yearly (*proposed*) | Owner and deploy pipeline only | Rotation + revocation at the provider |

Logs, crash reports and analytics may carry **no** credentials, emails,
push tokens or sensitive personal data (S4). Release builds log nothing
through `AppLogger`.

## 4. Threat model (STRIDE)

S = Spoofing · T = Tampering · R = Repudiation · I = Information disclosure ·
D = Denial of service · E = Elevation of privilege.

| # | STRIDE | Threat | Mitigation | Owner prompt |
|---|---|---|---|---|
| 1 | I, S | Token theft from the device (backup, rooted device, other app) | Encrypted session storage (Keychain / Keystore) — **done in P09**; no tokens in `shared_preferences`, files or logs; backup and device transfer excluded — **done in P08** | P09, P08 |
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

Since P13, `supabase/config.toml` mirrors these for the local stack (confirmations, password policy, token rotation, JWT expiry, redirects, anonymous sign-ins off).
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
| [x] | Redirect URL allow-list | Exact app URIs only, built from `com.ojtech.smartmeal` (P11). **No wildcards** | 2026-10-23 — exactly `com.ojtech.smartmeal://auth-callback` |
| [x] | Site URL | Not a localhost or placeholder value | 2026-10-23 — `com.ojtech.smartmeal://auth-callback` |
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
| Migrations deploy on push to `main` | The Supabase GitHub integration applies every migration that lands on `main` to production, with no dry run or approval step in between | Approve schema changes before they reach `main`; consider a protected `main` with required review (P20) |
| Custom URL scheme for auth links | Another app can claim the scheme and receive a link; the code is useless without the verifier (PKCE), but the link is spent | Move to App Links / Universal Links on `{{APP_LINK_DOMAIN}}` (§10) |
| Reset-password response reveals rate limiting | The app answers neutrally, but a script calling the API directly can tell an existing account by `over_email_send_rate_limit` | CAPTCHA on auth endpoints (§5); accept until then |
| Other sessions after a password reset | If `signOut(scope: others)` fails, other devices keep their sessions | Logged; add a retry or server-side revoke later (Known issues) |

## 10. Auth deep links and password recovery

Written in P11 (2026-10-23).

**Redirect URI.** Confirmation and recovery emails link to
`com.ojtech.smartmeal://auth-callback` (`AuthRepository.authRedirectUri`).
The same value is registered in the Android intent filter on `MainActivity`,
in iOS `CFBundleURLTypes`, and in `supabase/config.toml` as both `site_url`
and the only `additional_redirect_urls` entry. The hosted project must match:
Dashboard → Authentication → URL Configuration, Site URL and Redirect URLs =
exactly this URI, **no wildcards** (§5).

**Flow: PKCE only.** supabase_flutter v2 defaults to PKCE, and `main.dart`
does not override `authFlowType`. Never switch to the implicit flow: it would
put tokens in the link itself. With PKCE the link carries only a one-time
`code`, and the code needs this install's verifier, which is kept in secure
storage (`SecurePkceStorage`, P09). Consequences:

- **Custom schemes can be claimed by other apps.** Any app may declare
  `com.ojtech.smartmeal://`, and the OS may hand it our link. An app that
  intercepts the code cannot turn it into a session without the verifier.
  The residual risk is a denial of service (the user's link is used up), not
  account takeover.
- **A link works only on the device that requested it.** A recovery or
  confirmation link opened on another device, or after reinstalling, fails
  and shows "This link is invalid or has expired. Please request a new one."
- An expired, used or forged link (`error=` / bad `code`) arrives as an
  error on the auth stream; the app shows the same message and logs details
  in debug builds only (S4, S5).

**Recovery session.** Opening a recovery link emits
`AuthChangeEvent.passwordRecovery`. The app then sets a persisted
"recovery pending" flag (a boolean in SharedPreferences; no credential), and
the router allows only `/auth/reset-password` until a new password is set.
A restart cannot reach Home with a recovery session. Going back signs out.
After `updateUser(password)` the app revokes the user's other sessions
(`signOut(scope: others)`); if that call fails the password change still
stands and the failure is logged (open item, §9).

**Anti-enumeration.** "Forgot password" always answers "If an account exists
for that email, we've sent a link to reset your password." Supabase's
per-address email limit (`over_email_send_rate_limit`) applies only to
existing accounts, so the app shows that same neutral answer for it, and a
60 s resend cooldown keeps normal use under the limit. The API response
itself still differs; only a server-side change (CAPTCHA, uniform limits)
closes that, see §9.

**Planned: verified links.** Move from the custom scheme to Android App Links
and iOS Universal Links on `{{APP_LINK_DOMAIN}}` once the owner has a domain:
host `/.well-known/assetlinks.json` (package `com.ojtech.smartmeal` plus the
upload and Play App Signing SHA-256s) and `apple-app-site-association`
(Team ID + bundle ID), add `android:autoVerify="true"` and the Associated
Domains entitlement, put the `https://` URI on the allow-list, and remove the
custom scheme. Tracked as `APP_LINK_DOMAIN` in `docs/prompt-tracker.md`.

**Email templates (owner).** Drafts: `supabase/templates/confirmation.html` and `recovery.html`. Update the Supabase "Confirm signup" and "Reset
password" templates: keep `{{ .ConfirmationURL }}` as the link (it carries
the redirect), and use the brand name "Smart Meal" in a friendly, short
tone. Tracked in `docs/prompt-tracker.md`.

## 11. Account deletion and retention

Written in P14 (2026-10-23). Input for the privacy policy.

**In the app** (entry point: Profile screen, T1-Profile). The app calls the
`delete-account` Edge Function, which:

1. verifies the caller's JWT inside the function (`@supabase/server`
   `withSupabase`, `auth: 'user'`, against the project's JWKS); the gateway's
   `verify_jwt` is only a first layer;
2. requires a sign-in within the last **10 minutes** (owner, 2026-10-23),
   read from the token's `amr` timestamps, which a token refresh does not
   change; otherwise answers `reauthentication_required`;
3. allows **5 attempts per user per rolling hour**
   (`public.note_account_deletion_attempt`, service role only);
4. deletes the user's files in `avatars/{uid}/` (storage does not cascade),
   then their push tokens, then the auth user with the secret key from the
   function environment (never in `lib/`). Deleting the auth user cascades
   to every user row (`supabase/tests/04_account_lifecycle.test.sql`).

It is idempotent (a retry after success answers `deleted`), returns stable
error codes, and logs no user ID, email or token. The app then drops the
local session (secure storage) and the Google sign-in.

**By email** (Google Play's web requirement): the page
`site/delete-account.html`, published with GitHub Pages, tells users to
email the owner from their sign-in address; the owner confirms and deletes
within **30 days** using the Dashboard (Authentication → Users → Delete
user, after removing `avatars/{uid}/` in Storage).

| Data | When deleted |
|---|---|
| Auth account (email, identities, sessions, refresh tokens) | Immediately |
| Profile, preferences (incl. allergies, diet, goals), cuisine likes, favorites, meal plans and entries, recipe interactions, push tokens | Immediately (cascade) |
| Avatar files | Immediately (before the account) |
| Access tokens already issued | Stop working for data at once (the user's rows are gone); they expire within 1 hour (JWT expiry) |
| Rate-limit counter (user ID + count, no other data) | Within 24 hours |
| Provider backups | Overwritten by the provider's backup rotation |

Recipe interactions of active accounts are kept 12 months (P13). **Data
export** (a JSON copy of the user's data) is a follow-up, needed before
serving EU residents (owner, 2026-10-23).
