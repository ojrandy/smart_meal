# Photo credits

Real photographs used in the app since the 2026-10-21 redesign. They replace
the earlier AI-generated artwork (its masters were deleted on 2026-10-21,
with the owner's OK; they remain in git history).

**License:** every photo here is free under the
[Unsplash License](https://unsplash.com/license): free for commercial use,
no permission or attribution required. It does not allow selling unaltered
copies, or compiling the photos into a competing photo service. We credit
the photographers anyway.

**Rules for adding photos:**
- Free Unsplash License only, never **Unsplash+**.
- Food, ingredients and hands. No identifiable faces, because free stock
  photos come without model releases.
- No visible brands, alcohol, signage or text.
- Record each photo here, with the exact crop.

All crops were rendered by Unsplash's image service from the original
(`images.unsplash.com/photo-<id>?rect=x,y,w,h&w=…&h=…&fit=crop&fm=webp&q=80`).
To re-export, reuse the parameters below.

| Asset | Photo | Photographer | Original | Crop (`rect`) → output |
|---|---|---|---|---|
| `assets/images/onboarding_discover.webp` | [Jollof rice with chicken, salad and plantains](https://unsplash.com/photos/a-plate-of-food-b4Ht8TQ1JGo) | Keesha's Kitchen ([@keeshasskitchen](https://unsplash.com/@keeshasskitchen)) | `photo-1664993101841-036f189719b6`, 4480×6720 | `0,540,4480,5600` → 1080×1350 |
| `assets/images/onboarding_plan.webp` | [Hands holding a bowl of egusi soup](https://unsplash.com/photos/hands-holding-a-bowl-of-egusi-soup-with-assorted-meats-0A03YQqU4CU) | Tosan Dudun ([@babadudu19](https://unsplash.com/@babadudu19)) | `photo-1763048443535-1243379234e2`, 4816×4160 | `936,0,3328,4160` → 1080×1350 |
| `assets/images/onboarding_decide.webp` | [Grilled fish with fried plantains, red onions and lime](https://unsplash.com/photos/grilled-fish-with-fried-plantains-red-onions-and-lime-a5MP_o7xy54) | Emmanuel M ([@e4xtream](https://unsplash.com/@e4xtream)) | `photo-1783408356251-f4953f943bb2`, 3072×3543 | `119,0,2834,3543` → 1080×1350 |
| `assets/images/auth_login_hero.webp` | [Tomato and pepper seller, Bodija Market, Ibadan](https://unsplash.com/photos/a-group-of-people-standing-around-a-table-filled-with-tomatoes-cnVn4Gg4b00) | Tunde Buremo ([@tundeburemo](https://unsplash.com/@tundeburemo)) | `photo-1734255026082-82fdc81991f0`, 2705×3380 | `270,2030,2160,1350` → 1440×900 (produce only; vendors and signs cropped out) |
| `assets/images/auth_signup_hero.webp` | [Jollof rice with chicken skewers](https://unsplash.com/photos/a-bowl-of-food-woC24wGXsQ8) | Keesha's Kitchen ([@keeshasskitchen](https://unsplash.com/@keeshasskitchen)) | `photo-1664992960082-0ea299a9c53e`, 4284×2856 | `0,89,4284,2677` → 1440×900 |

The official Google "G" (`assets/images/google_g.png`) comes from Google's
own sign-in branding assets in `google-signin-assets.zip`; it is not a
stock photo.
