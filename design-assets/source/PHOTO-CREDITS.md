# Photo credits

Real photographs used in the app since the 2026-10-21 redesign. They replace
the earlier AI-generated artwork (its masters were deleted on 2026-10-21,
with the owner's OK; they remain in git history).

**License:** unless the table says otherwise, a photo here is free under the
[Unsplash License](https://unsplash.com/license): free for commercial use,
no permission or attribution required. It does not allow selling unaltered
copies, or compiling the photos into a competing photo service. We credit
the photographers anyway.

**Cameroonian dishes (2026-10-27, owner request):** the owner asked for real
Cameroonian food in professional quality. Free professional photos of these
dishes barely exist; the best found are used: ndolé (Pexels, mboapictures),
two West African green-vegetable soups with fufu (Unsplash; efo riro, close to
eru in look) and soya with roasted plantains from a Douala street grill (Unsplash). All three
licences are free for commercial use with no credit required. A commissioned shoot in
Cameroon would replace them. Crops made locally with `cwebp` 1.4.0
(`-q 82 -crop x y w h -resize W H`, metadata stripped).

**Rules for adding photos:**
- Free Unsplash License (never **Unsplash+**) or Pexels License, or, with the owner's OK,
  Wikimedia Commons under CC0 / CC BY / CC BY-SA with the credit shown in-app.
- Food, ingredients and hands. No identifiable faces, because free stock
  photos come without model releases.
- No visible brands, alcohol, signage or text.
- Record each photo here, with the exact crop.

All crops were rendered by Unsplash's image service from the original
(`images.unsplash.com/photo-<id>?rect=x,y,w,h&w=…&h=…&fit=crop&fm=webp&q=80`).
To re-export, reuse the parameters below.

| Asset | Photo | Photographer | Original | Crop (`rect`) → output |
|---|---|---|---|---|
| `assets/images/onboarding_discover.webp` | [Street food in Cameroon: soya skewers and roasted plantains](https://unsplash.com/photos/grilled-meat-on-charcoal-grill-4jRyugKbQdw) (Bali, Douala) | Edouard TAMBA ([@edouard_tamba](https://unsplash.com/@edouard_tamba)) | `photo-1594999945795-e570338fdd12`, 3112×3112, Unsplash License | rendered at 1800×1800 by Unsplash, then `120,0,1440,1800` → 1080×1350 |
| `assets/images/onboarding_plan.webp` | [Vegetable soup with fufu, Lagos](https://unsplash.com/photos/a-white-bowl-filled-with-food-next-to-two-plates-of-food-mRRyPqOoxhY) (bowl only) | Seyene Otu ([@seyeneotu](https://unsplash.com/@seyeneotu)) | `photo-1673465580365-b96bef916770`, 5760×3840, Unsplash License | `1805,0,3072,3840` → 1080×1350 |
| `assets/images/onboarding_decide.webp` | [Grilled fish with fried plantains, red onions and lime](https://unsplash.com/photos/grilled-fish-with-fried-plantains-red-onions-and-lime-a5MP_o7xy54) | Emmanuel M ([@e4xtream](https://unsplash.com/@e4xtream)) | `photo-1783408356251-f4953f943bb2`, 3072×3543 | `119,0,2834,3543` → 1080×1350 |
| `assets/images/auth_login_hero.webp` | [Plat de ndolé aux crevettes et bananes plantains](https://www.pexels.com/photo/plat-de-ndole-aux-crevettes-et-bananes-plantains-16538697/) | Ada Mbita (mboapictures) | Pexels 16538697, 4608×3072, [Pexels License](https://www.pexels.com/license/) (free commercial use, no credit required) | `0,150,4608,2880` → 1440×900 |
| `assets/images/auth_signup_hero.webp` | [Efo riro & fufu](https://unsplash.com/photos/white-ceramic-bowl-with-green-vegetable-dish-kn_ANxnwCQ0) | Femoree (Unsplash) | `photo-1604329760661-e71dc83f8f26`, 6000×4000, Unsplash License | `0,200,6000,3750` → 1440×900 |

The official Google "G" (`assets/images/google_g.png`) comes from Google's
own sign-in branding assets in `google-signin-assets.zip`; it is not a
stock photo.

## Setup illustrations

The nine setup step illustrations (`assets/images/setup_*.webp`) are from
[unDraw](https://undraw.co) by Katerina Limpitsouni, under the
[unDraw License](https://undraw.co/license): free for commercial use,
modification allowed, no credit required. (The licence forbids using them to
train AI models, which this app never does.)

Changes made locally: the accent `#6c63ff` became the app green `#0A7C36`,
the light skin tones (`#ffb6b6`, `#ffb8b8`, `#ffb9b9`, `#ffb0b1`, `#ed9da0`)
became `#a86b45` and the darker shades (`#a0616a`, `#9f616a`, `#9e616a`,
`#cf6f80`) became `#6e4128`. Each SVG was rendered 840 px tall (1200 px wide
at most) on a transparent background with headless Chrome, then
`cwebp -q 90 -alpha_q 100 -metadata none`.

| Asset | unDraw illustration |
|---|---|
| `setup_lifestyle.webp` | `work-time_1ogn` |
| `setup_household.webp` | `family_6gj8` |
| `setup_budget.webp` | `wallet_diag` |
| `setup_cooking.webp` | `cooking_j2pu` |
| `setup_cuisines.webp` | `eating-together_mr7m` |
| `setup_consent.webp` | `private-data_934y` |
| `setup_diet.webp` | `healthy-options_ne00` |
| `setup_allergies.webp` | `medicine_hqqg` |
| `setup_goals.webp` | `personal-goals_f9bb` |
