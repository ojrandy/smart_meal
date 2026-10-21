# SmartMeal — Project Overview

> Source of truth for product identity. `AGENT.md` at the repo root is the
> entry point (role, non-negotiables, reading order); this file and the rest
> of `context/` hold the detail.

## What it is

SmartMeal is a mobile-first, AI-powered food recommendation and meal-planning
app. Not a recipe list — a personalization engine that learns a user's
budget, lifestyle, and taste to recommend meals and explain *why* each
recommendation fits ("Eru — 94% match because it fits your budget, cooking
preference, and previous meal choices").

- **Platforms:** Android + iOS only. No web target — ever. Keep the
  architecture platform-agnostic in principle, but do not spend time on
  responsive/web edge cases.
- **Personality:** friendly, intelligent, modern, helpful, premium,
  human-centered. Never robotic or complicated. The AI Chef persona explains
  recommendations, it doesn't just display results.
- **Target users:** students, families, working professionals — broad
  consumer audience, not a single demographic. Nothing in copy or UI should
  feel niche.

## Vision & mission

Vision: become an intelligent personal food assistant that understands
users' lifestyles, preferences, budgets, and food habits. The bar for every
feature is whether the user feels *"the app understands what I need to
eat."*

Mission — SmartMeal helps users:
- Discover meals they will enjoy
- Receive AI-powered recommendations
- Plan meals according to budget
- Manage recipes
- Improve food decision making
- Discover African and international cuisine

Product goals, in priority order:
1. Understand users through onboarding questions
2. Analyze user preferences and behavior
3. Generate personalized meal recommendations
4. Help users plan meals within financial limits
5. Provide complete recipe information
6. Learn from user interactions over time
7. Provide an enjoyable food discovery experience

Product philosophy — prioritize personalization, simplicity, intelligence,
trust, user engagement, and high-quality execution over feature count. Every
feature should be able to answer: *"How does this improve the user's food
decision process?"* If it can't, it doesn't belong in this phase.

Categories this product sits in (useful for scoping comparisons/competitors):
AI, Food Technology, Recommendation Systems, Meal Planning, Recipe
Management, Personalized Nutrition.

## Development mindset

Build as a production-quality startup product — not a demo, not a classroom
prototype, not throwaway code. Every piece shipped should be scalable,
maintainable, secure, tested, and ready for real users. When a shortcut is
taken anyway, it must be logged in `progress-tracker.md`, not left silent.

## Core product loop

1. Onboarding introduces the value prop (3-slide carousel).
2. User signs up / signs in.
3. User completes a lifestyle + budget + preferences setup flow.
4. AI Chef generates personalized recommendations with explanations.
5. User browses, favorites, and plans meals around a budget (XAF currency).
6. The app learns from interactions over time and improves recommendations.

## Tech stack (confirmed — do not add major libraries without strong reason)

| Concern | Package |
|---|---|
| Language / framework | Dart, Flutter |
| State management | `flutter_riverpod` (Notifier + Provider pattern) |
| Navigation | `go_router` (StatefulShellRoute + auth redirect guard) |
| Backend (primary) | `supabase_flutter` — auth, Postgres, storage, realtime |
| OAuth | `google_sign_in`, routed through Supabase `signInWithIdToken` |
| Push notifications only | `firebase_core`, `firebase_messaging` |
| Typography | `google_fonts` (Inter, bundled in `assets/fonts/` — no runtime download) |
| Animation | `flutter_animate`; `lottie` *planned — first use wherever Figma calls for an animation* |
| Loading states | `shimmer` |
| Images | `cached_network_image`; `image_picker` *removed in P04 — re-added with iOS purpose strings in the avatar-upload task (T1-Profile)* |
| Icons | `iconsax` (primary), `font_awesome_flutter` (social auth only) |
| Local KV storage | `shared_preferences` for non-sensitive flags only (P09's `smartmeal.installed` marker; P15's onboarding-seen flag); never for credentials (S7) |
| Secure storage | `flutter_secure_storage` ^10 (P09). **Why:** supabase_flutter's default keeps the access and refresh tokens (and the PKCE verifier) in plaintext SharedPreferences, readable on rooted/jailbroken devices and from unencrypted backups. Keystore-wrapped AES-GCM on Android, a this-device-only Keychain item on iOS. v11 needs Dart 3.10 (via `win32`), so v10 is the latest compatible with Flutter 3.35 |
| Formatting | `intl` *planned — first use in P16/P18 (dates + XAF currency)* |

**Firebase caveat:** Firebase is used for push notifications only
(`firebase_core`, `firebase_messaging`). `PushNotificationService` exists and
`main()` starts it, but there is no `google-services.json` /
`GoogleService-Info.plist` yet, so `Firebase.initializeApp()` fails safely and
push stays inert until P19 (`docs/prompt.md`). P04 removed the unused
`firebase_auth`, `cloud_firestore` and `firebase_storage`. Supabase is the
system of record, so don't build features against Firebase.

## Current build status (high level — see `progress-tracker.md` for detail)

Built: splash, onboarding carousel, email/password + Google auth, app shell
routing with bottom nav (5 tabs), design system (colors/theme/shared
widgets).

Not built: setup/preferences flow, AI recommendation engine, all 5 main tab
screens (currently placeholders), Supabase schema/tables, any backend logic.

## Long-term (not current priority — don't build for these yet)

Food ordering, payments, delivery tracking, restaurant partnerships,
nutrition tracking, AI food conversations, smart kitchen integrations.
Architecture should not actively block these, but no code should be written
in anticipation of them.

## Source of truth hierarchy

1. Figma design system
2. `AGENT.md` (root) + `context/*.md` (this folder)
3. Product requirements as given directly by the product owner
4. Flutter/Dart architectural best practice

Never redesign a screen without approval. Never substitute a different UX
for the one specified in Figma or in an approved plan.
