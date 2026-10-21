# SmartMeal — UI / Design System Context

Figma is the authoritative design source. This file documents what's already
implemented in code so new screens stay visually consistent without needing
to re-derive values from Figma every time. If Figma and this file disagree,
Figma wins and this file must be updated in the same change.

**Exception (owner decision, 2026-10-21):** the owner judged the splash,
onboarding and auth-hero artwork (AI-generated) too generic and gave the
agent authority to redesign those screens. For **splash, onboarding and the
login/signup hero images**, this file and the code are now the source of
truth, not Figma or `Mockup/`. Update Figma to match when convenient. See
"Imagery" below.

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
| `onPrimary` | `#FFFFFF` | Text/icons/spinner on `primary` fills |
| `brandAccent` | `#FF6B00` | Logo orange; the "AI" in the splash wordmark (large text only: 3.8:1 on `splashBackground`) |
| `onDark` | `#FFFFFF` | Text/icons on photos, gradients, dark fills (apply alpha at the call site, e.g. `0.9`) |
| `onDarkMuted` | `#FFFFFF` @ 70 % (`0xB3FFFFFF`) | Secondary text on photos (onboarding subtitle) |
| `scrim` | `#000000` | Base for photo scrims / dark overlays; alpha at the call site |
| `shadow` | `#000000` | Base for card shadows; alpha at the call site (`0.04`) |
| `favorite` | `#F44336` | Active favorite heart |
| `placeholderIcon` | `#9E9E9E` | Icon in `AppNetworkImage`'s missing-image fallback |
| `socialApple` / `socialFacebook` | `#000000` / `#0866FF` (official Facebook blue) | Brand marks on the social sign-in buttons only. Google's mark is multicolor, so it is the official image `AppAssets.googleLogo`, not a color |
| `splashBackground` | `#05471F` | Splash background, and the Android (`values/colors.xml` `splash_background`, API 31+ `windowSplashScreenBackground`) and iOS (`LaunchScreen.storyboard`) native launch screens, which must match it |

Rule: any new color need gets added to this table + `app_colors.dart`
first. No inline hex values or raw `Colors.*` (except `Colors.transparent`)
in `lib/features/` or `lib/core/widgets/`. Check with
`rg -n "Color\(0x|\bColors\." lib/features lib/core/widgets | rg -v "Colors\.transparent"`
— it must print nothing. `test/core/theme/app_colors_test.dart` pins the
values of tokens that replaced Material constants.

## Typography

- Font: **Inter** via `google_fonts`, applied globally through
  `AppTheme.lightTheme.textTheme`. The files are **bundled** in
  `assets/fonts/` and runtime fetching is off (`AppFonts.configure()` in
  `main()`), so text looks the same offline and startup makes no font request.
- Bundled weights: 400, 500, 600 and 700, listed in
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
  `AppColors.shadow.withValues(alpha: 0.04)`, `blurRadius: 10`,
  `offset: (0, 4)`. Don't use heavier default Material elevation shadows.

## Icons

- **Iconsax** is the primary icon set for all product UI (nav bar, form
  field prefixes, card metadata icons). Use the `_1`/outline pairing
  convention already established in the bottom nav (outline for inactive,
  filled/bold variant for active — see `ScaffoldWithNavBar`).
- **FontAwesome** (`font_awesome_flutter`) is reserved for third-party
  brand logos only (the Apple and Facebook sign-in buttons). Don't use it
  for generic UI icons. Google's "G" is multicolor, so it is the official
  image `AppAssets.googleLogo` instead, from Google's branding assets and
  never recolored or redrawn.
- Material `Icons.*` should only appear where Iconsax has no equivalent
  (e.g. `Icons.arrow_back_ios_new` for the back chevron, `Icons.chevron_right`).

## Component inventory (`lib/core/widgets/`)

| Widget | Purpose | Notes |
|---|---|---|
| `CustomButton` | Primary/outline button with loading + icon states | Use for every primary CTA. `isOutline` for secondary actions. While loading it keeps its normal fill and the spinner uses the variant's foreground (`onPrimary` / `primary`). |
| `CustomTextField` | Labeled input with icon, integrates `Form` validation | Built-in password visibility toggle when `isPassword: true`: a labelled 48 dp `IconButton` laid over the 24 dp icon slot, so the field height does not change. |
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
          // title (Text.rich — never RichText, which ignores the system text size —
          //   two-tone: textPrimary + primary highlight)
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
The fallback is neutral and text-free (e.g. a `surfaceVariant` box, or a
brand-color fill behind text on photos) — never developer text like
"x.png missing".

## Accessibility

Established in P05 (2026-10-15); widget tests in `test/core/widgets/` and
`test/features/` check these.

- **Text scale:** use `Text`/`Text.rich`, never `RichText` (it ignores the
  system text size). Layouts must not clip or hide content at large text:
  onboarding is tested at 360×640 and 320×568 ×1.3 and at ×2.0. Make
  fixed-position blocks bottom-anchored scroll views rather than shrinking
  the default look.
- **Icon-only controls** (back, password toggle, favorite, …) are
  `IconButton`s with a ≥ 48×48 dp touch target and a screen-reader label:
  `tooltip:` for back (use `MaterialLocalizations.backButtonTooltip`),
  `Icon.semanticLabel` otherwise. New label strings need owner copy approval.
  When a 48 dp target would change the layout, lay the button over the old
  icon slot (see `CustomTextField`, `RecipeCard`).
- **Decorative images** (backgrounds, heroes, the logo next to the app name)
  set `excludeFromSemantics: true`.
- **Contrast:** WCAG AA — 4.5:1 for body text, 3:1 for large text (≥ 24 px,
  or ≥ 18.7 px bold) and for icons/controls. `primary` on `background` is
  5.10:1. Known failures are logged in `context/progress-tracker.md`; color
  changes need owner approval.
- **Text and photos:** prefer putting text *next to* a photo, not on it.
  Onboarding (since 2026-10-21) puts dark text on the cream background below
  the photo. When text must sit on a photo, anchor a `scrim` gradient to the
  text, not the screen. A lone control on a photo (Skip) gets a `scrim` 55 %
  pill instead of darkening the photo.
  `test/features/onboarding/presentation/onboarding_contrast_test.dart`
  renders the real screen and fails if any visible text pixel drops below
  AA. Run it whenever artwork, overlays or text colors change.
- **Safe areas:** never position content at a fixed offset from the screen
  edge without accounting for `MediaQuery.paddingOf(context)`.
- **System back:** a screen with an on-screen back button wraps its
  `Scaffold` in `PopScope` so the Android back button/gesture does the same
  thing (see the auth screens) instead of closing the app.
- **Loading buttons:** `CustomButton` keeps its normal fill while
  `isLoading` (it is disabled, but must not turn grey) so the spinner stays
  visible.

## Imagery (owner decision, 2026-10-21)

- **Real photography only**: no AI-generated art, no fake app screenshots
  or logos baked into images. Show local food: Cameroonian / West African
  dishes, ingredients and markets.
- **Source:** free [Unsplash License](https://unsplash.com/license) photos
  (never Unsplash+). Every photo is recorded with its crop in
  `design-assets/source/PHOTO-CREDITS.md`.
- **No identifiable faces** (free stock photos have no model releases), and
  no visible brands, alcohol, signage or text. Hands are fine.
- **Format:** WebP q80, at most 1440 px wide (the `AppAssets` test enforces
  the width). Onboarding photos are 4:5 at 1080×1350; auth heroes are 16:10
  at 1440×900.
- **Patterns:**
  - Onboarding: the photo fills about 72 % of the swipe area with 32 px
    rounded bottom corners; the title and subtitle sit below it on
    `background`, then the page dots (`primary` / `textHint`) and a
    `CustomButton`.
  - Auth heroes: a `ClipRRect` with 24 px radius and a 16:10 `AspectRatio`,
    using `BoxFit.cover`.
- **Splash:** solid `splashBackground` with the logo, the "SmartMeal AI"
  wordmark, the "Your AI food companion" tagline and a "by OJ Tech" footer.
  One entrance of ≤ 500 ms per element, then `/onboarding` after
  `SplashScreen.holdDuration` (1.6 s). No looping animations.

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
- Format: photos/illustrations ship as **WebP q85, max 1440 px wide**
  (owner-approved 2026-10-15); small art with transparency (the logo) stays
  PNG. Keep the lossless master in `design-assets/source/<same_name>.png` and
  re-encode from it, never from a WebP:
  `cwebp -q 85 -metadata none design-assets/source/<name>.png -o assets/images/<name>.webp`
  (official libwebp release, signature-checked). `app_assets_test.dart` also
  decodes every image and enforces the 1440 px limit.
- `design-assets/` (repo root) holds source/unused art that is **not**
  bundled — e.g. the *Premium AI Chef robot illustration* SVG and the
  unused `bckimg4`/`bckImg5` backgrounds. Move a file into `assets/images/`
  (renamed, with a constant) only when a screen uses it. SVGs need
  `flutter_svg`, which is not a dependency.
