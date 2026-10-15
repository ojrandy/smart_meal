# SmartMeal — UI / Design System Context

Figma is the authoritative design source. This file documents what's already
implemented in code so new screens stay visually consistent without needing
to re-derive values from Figma every time. If Figma and this file disagree,
Figma wins and this file must be updated in the same change.

## Color system (`lib/core/theme/app_colors.dart`)

| Token | Value | Usage |
|---|---|---|
| `primary` | `#0A7C36` | Buttons, links, active states, brand green |
| `primaryDark` | `#065C27` | Pressed/emphasis states, text on light green |
| `primaryLight` | `#E6F4EA` | Subtle green backgrounds/badges |
| `background` | `#FCFAF5` | Screen background (off-white/cream, not pure white) |
| `surface` | `#FFFFFF` | Cards, inputs, bottom nav |
| `surfaceVariant` | `#F3F4F6` | Input borders, dividers, image placeholders |
| `textPrimary` | `#111827` | Headlines, primary body text |
| `textSecondary` | `#6B7280` | Subtext, labels, secondary info |
| `textHint` | `#9CA3AF` | Placeholder text, disabled hints |
| `error` | `#EF4444` | Error states, error snackbars |
| `success` | `#10B981` | Success states |
| `warning` | `#F59E0B` | Warnings, also used as a fallback icon color |
| `aiChefGradient` | `#1B5E20 → #F59E0B` diagonal | AI Chef card background only |

Rule: any new color need gets added to this table + `app_colors.dart`
first. No inline hex values in screens.

## Typography

- Font: **Inter** via `google_fonts`, applied globally through
  `AppTheme.lightTheme.textTheme`. The files are **bundled** in
  `assets/fonts/` and runtime fetching is off (`AppFonts.configure()` in
  `main()`), so text looks the same offline and startup makes no font request.
- Bundled weights: 400, 500, 600, 700 and 900 italic (the splash), listed in
  `AppFonts.bundledInterVariants`. **Using any other weight/style needs its
  `Inter-<Weight><Style>.ttf` added first** (same Google Fonts file name, from
  the URL/hash pinned in the `google_fonts` package), or it fails to load;
  `test/core/theme/app_fonts_test.dart` guards this.
- Headings: `bold`/`w700`, `textPrimary`.
- Body: regular weight; `bodyMedium` defaults to `textSecondary` for
  de-emphasized copy, `bodyLarge` for primary reading text.
- Only one dark, saturated theme currently exists — **no dark mode yet**.
  Don't design screens that assume `Theme.of(context).brightness` branching
  works today.

## Spacing & shape conventions

- Screen horizontal padding: `24.0`.
- Standard corner radius: `16` for inputs/buttons, `24` for cards/hero
  containers, `20–30` for pill-shaped chips/badges.
- Primary buttons: full-width, `56` height, `16` radius, no elevation
  (`elevation: 0` — flat, modern look, not material-default shadowed
  buttons).
- Card shadow (see `RecipeCard`): very soft —
  `Colors.black.withValues(alpha: 0.04)`, `blurRadius: 10`,
  `offset: (0, 4)`. Don't use heavier default Material elevation shadows.

## Icons

- **Iconsax** is the primary icon set for all product UI (nav bar, form
  field prefixes, card metadata icons). Use the `_1`/outline pairing
  convention already established in the bottom nav (outline for inactive,
  filled/bold variant for active — see `ScaffoldWithNavBar`).
- **FontAwesome** (`font_awesome_flutter`) is reserved for third-party
  brand logos only (Google, Apple, Facebook sign-in buttons). Don't use it
  for generic UI icons.
- Material `Icons.*` should only appear where Iconsax has no equivalent
  (e.g. `Icons.arrow_back_ios_new` for the back chevron, `Icons.chevron_right`).

## Component inventory (`lib/core/widgets/`)

| Widget | Purpose | Notes |
|---|---|---|
| `CustomButton` | Primary/outline button with loading + icon states | Use for every primary CTA. `isOutline` for secondary actions. |
| `CustomTextField` | Labeled input with icon, integrates `Form` validation | Built-in password visibility toggle when `isPassword: true`. |
| `SocialAuthButton` | Outlined button for OAuth providers | Icon + label row, white/surface background. |
| `AppNetworkImage` | Standard remote-image treatment: shimmer skeleton while loading, icon fallback on missing/failed URL | Wraps `cached_network_image` + `shimmer`. Use for any recipe photo, avatar, or other remote image — don't call `CachedNetworkImage` directly in a screen. |
| `RecipeCard` | 180-wide horizontal-scroll card: image, match %, favorite toggle, price/time/difficulty | Image rendered via `AppNetworkImage`. Still needs a real `imageUrl` feed once recipe data exists (currently only exercised with local/placeholder data). |
| `AiChefCard` | Full-width gradient card for AI recommendation + "See why" CTA | Uses `aiChefGradient`. This is the visual anchor of the AI Chef personality — keep the explanatory copy pattern ("X% match because...") from `project-overview.md`. |

Before building a new screen-specific widget, check this table — extend an
existing component's parameters before creating a near-duplicate.

## Screen composition pattern

Established by `LoginScreen`/`SignupScreen` — new form-based screens should
follow the same skeleton:

```
Scaffold(
  backgroundColor: AppColors.background,
  body: SafeArea(
    child: SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Form(
        key: _formKey,
        child: Column(crossAxisAlignment: start, children: [
          // header row: back button + logo
          // title (RichText, two-tone: textPrimary + primary highlight)
          // subtitle (textSecondary, often with a friendly emoji)
          // hero image (Image.asset with an errorBuilder fallback — never let
          //   a missing asset crash the screen)
          // form fields
          // primary CTA (CustomButton)
          // secondary actions / links
        ]),
      ),
    ),
  ),
)
```

Always provide an `errorBuilder` on `Image.asset` calls for
content/marketing imagery (not for icons) so a missing asset degrades
gracefully instead of crashing — see both auth screens for the pattern.

## Motion

- `flutter_animate` is the animation package — chain `.animate()` with
  `.fade()`, `.scale()`, `.slideY()` etc. rather than hand-rolling
  `AnimationController`s for simple entrance effects (see `SplashScreen`).
- Splash/loading screens: staggered fade-in with `delay` increments of
  ~200–400ms feels right for this app's pacing — don't make entrance
  animations longer than ~800ms per element or the app will feel slow.
- `shimmer` is designated for skeleton loading states on data-driven
  screens (recipe lists, recommendations). Implemented today via
  `AppNetworkImage`'s loading placeholder — reuse that widget rather than
  hand-rolling a new `Shimmer.fromColors` call, and prefer it over a bare
  `CircularProgressIndicator` for list/grid content once real data fetching
  exists.

## Copy tone

- Friendly, occasionally uses a single emoji for warmth ("✨", not more than
  one per line of copy).
- AI Chef copy always explains the *why* behind a recommendation — never a
  bare label. See `project-overview.md` for the good/bad example.
- Error messages are short, actionable, and never expose raw backend/SDK
  error text to the user (see `_formatAuthError`).

## Assets

- Location: `assets/images/`, registered as a directory in `pubspec.yaml`
  (`assets: - assets/images/`), so **everything in it ships in the app**.
  Put only images a screen uses there.
- Names: descriptive `snake_case`, `<screen>_<role>` (e.g.
  `onboarding_discover.png`, `auth_login_hero.png`). No spaces, no
  auto-export names like `SVG (1)`.
- Reference images only through `AppAssets` in
  `lib/core/constants/app_assets.dart`; `test/core/constants/app_assets_test.dart`
  fails if a constant points at a missing file or an image is bundled
  without a constant.
- `design-assets/` (repo root) holds source/unused art that is **not**
  bundled — e.g. the *Premium AI Chef robot illustration* SVG and the
  unused `bckimg4`/`bckImg5` backgrounds. Move a file into `assets/images/`
  (renamed, with a constant) only when a screen uses it. SVGs need
  `flutter_svg`, which is not a dependency.
