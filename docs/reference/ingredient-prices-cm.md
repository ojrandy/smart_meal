# Ingredient price list — Cameroon

> **Data:** [`ingredient-prices-cm.csv`](ingredient-prices-cm.csv) (prices) · [`ingredient-catalog-cm.csv`](ingredient-catalog-cm.csv) (nutrient codes, conversions, allergens, local names) · [`ingredient-nutrients-cm.csv`](ingredient-nutrients-cm.csv) (generated nutrients) · **Raw observations:** [`wfp-observations-cm-2025-09_2026-08.csv`](wfp-observations-cm-2025-09_2026-08.csv) · **Tools:** [`tool/wfp_prices.sh`](../../tool/wfp_prices.sh), [`tool/food_catalog.dart`](../../tool/food_catalog.dart)
> **Compiled** 2026-10-29, owner quotes and activations added the same day · **Used by** LF01 in [`../promptLoginFlow.md`](../promptLoginFlow.md) (inputs `INGREDIENT_PRICE_LIST`, `NUTRIENT_SOURCE`)

These are **estimates** of what a household pays at a city market. They are not live prices. Cameroon has no public real-time price feed. The closest thing is WFP's monthly market survey, published about six weeks after the month ends. So the app shows every cost as "about X FCFA", and this list is refreshed every month (see *Refresh*).

## What the list contains

70 foods: **43 ready**, **27 still missing**. The first list had 45 foods (27 ready, 6 to check, 12 missing). On 2026-10-29 the owner activated the 6 `field_check` rows and gave retail prices for ndolé, eru, crayfish, smoked fish, pepper, spaghetti, green spices (celery, spring onions) and bottled water, then plantain per finger (a heap of 5–8 fingers from 1 000 FCFA, big ones about 4 000 FCFA). 22 foods that the seed recipes need were added; 21 of them have no reliable source yet.

| Status | Meaning | What LF01 does with it |
|---|---|---|
| `ready` | Price backed by measured data, an official / shelf price, or an owner market quote | Loaded and active |
| `field_check` | A price exists, but sources disagree or come from a different region | Loaded **inactive** until the owner confirms or corrects it at a market (none at the moment) |
| `missing` | No reliable source found; no price was guessed | Loaded inactive, without a price, until the owner records one |

Inactive foods are never shown to users and never used in a cost. A recipe that needs one cannot be published (the publishing guard in LF01), so no estimate in the app rests on a guessed price. The local seed gives the missing foods that the seed recipes need a **DEV PLACEHOLDER** price (local database only, labelled in `price_source`), so development has 12 recipes. Production never gets those numbers.

**Retail units (owner, 2026-10-29).** Foods sold by the ball, bundle, heap or pack are priced the way they are retailed, per piece, with an estimated weight per piece (`grams_per_piece` in `ingredient-catalog-cm.csv`) so recipes and nutrients still convert to grams. Those weights are estimates until someone weighs one (see the market check).

## Method

**Reference market.** The southern urban markets where most users shop: Yaoundé (Mfoundi), Douala (Marché Central), Buea, Limbé, Kumba, Bamenda, Mamfé, Tiko, Mutengene and Muea. The list leaves out:
- **rural producer markets** (Kumbo, Nkambe, Ndop…), which sell well below city prices;
- **northern markets**, which have different supply (e.g. onions: about 275 FCFA/kg in the north against 900 FCFA/kg in the south).

**Price.** The median of the monthly retail prices in those markets over the 12 months to the newest observation (Sep 2025 – Aug 2026), rounded to the nearest 25 FCFA. Twelve months covers the seasonal swings. `range_low_xaf` and `range_high_xaf` are the 25th and 75th percentiles: the typical spread between markets and months, not the extremes.

**Source tiers.**

| Tier | Source | Confidence |
|---|---|---|
| A | WFP market survey, southern urban markets, observed in 2026 | high (≥ 20 observations) or medium |
| B | WFP market survey, but the latest observation is from 2025, or only from other markets | medium or low |
| C | Official ceilings (MINCOMMERCE), supermarket shelf prices, dated press reports | medium or low |
| O | Owner market quote ("from 1 000 FCFA"), dated | low, or medium when the owner gave several pack sizes |
| D | No reliable source: price left empty | — |

**Units.** Per kg, per litre for palm oil and vegetable oil (owner decision D1), and per piece where the market sells by the piece (eggs, cubes, sachets, plantain fingers). LF01 converts every unit to grams for nutrition.

## Known limits

- **Prices have moved since late 2025.** For tier B rows last observed in Dec 2025, the INS reports food prices up 5.6 % year on year (May 2026) and inflation of 3.4 % in July 2026. Expect those rows to sit a few percent below today's prices until the next refresh.
- **Frozen fish is volatile.** The Congelcam import quota was halved for 2026. Cartons rose from 25 000 to 29 000–32 000 FCFA in Oct 2026, and a shortage is expected from late November. The mackerel row is `field_check` for that reason.
- **Markets sell above official ceilings.** Beef sells at 3 800–4 000 FCFA/kg boneless against a 3 000 FCFA ceiling. The list uses what people actually pay.
- **One national price.** Prices differ between cities. A per-city price is out of scope for this phase (`promptLoginFlow.md` §0.4).

## Owner market check (one visit)

For each item below, record **price, quantity, market and date**. For items sold in heaps, balls or bundles, weigh one or ask the trader.

- **Weigh one** (the price is known, the weight is an estimate): ndolé ball (500 g?), eru bundle (400 g?), crayfish 100 FCFA pack (25 g?), smoked fish 500 FCFA piece (150 g?), pepper heap (100 g?), celery bunch (50 g?), spring-onion bunch (100 g?), and the spaghetti pack size behind 250 / 500 FCFA. Also a plantain finger from a 1 000 FCFA heap and from a big 4 000 FCFA heap (250 g?).
- **Check:** cocoyam (macabo), sweet potatoes, maize flour, beef with bone, frozen mackerel, garlic (activated on the owner's word; sources disagree), and the price of one bouillon cube at the market (the list uses the 100-cube pack price).
- **Record:** egusi, njansang, stockfish, ginger, tomato paste (70 g sachet), prawns, waterleaf, beef skin (kanda), limestone (nikki), achu spice, mbongo spice, banana leaves, carrots, green beans, fresh fish, sweet peppers, dried yeast, tinned tomatoes, parmesan, UHT milk, butter, tinned chickpeas, coconut milk, mustard seeds, curry powder, soy sauce, sesame oil.

## Nutrients

Values are per 100 g **edible portion**, in [`ingredient-nutrients-cm.csv`](ingredient-nutrients-cm.csv), generated by `tool/food_catalog.dart nutrients` from the codes in [`ingredient-catalog-cm.csv`](ingredient-catalog-cm.csv).

1. **FAO/INFOODS Food Composition Table for Western Africa (WAFCT 2019)** is the primary source: about 1 000 West African foods, including ndolé (bitter vernonia), waterleaf, egusi, gari, cocoyam, dried crayfish and dried fish, with an edible-portion coefficient per food. It has no sugars. Free Excel file: <https://www.fao.org/fileadmin/user_upload/faoweb/2020/WAFCT_2019.xlsx>. Citation: Vincent A., Grande F., Compaoré E. et al. (2020), *FAO/INFOODS Food Composition Table for Western Africa (2019)*, FAO, Rome.
2. **USDA FoodData Central, SR Legacy** fills the gaps, always for sugars, and covers imported shop foods WAFCT lacks (parmesan, soy sauce, sesame oil, tinned chickpeas, celery, spring onions, bouillon). Public domain (CC0). Bulk CSV: <https://fdc.nal.usda.gov/fdc-datasets/FoodData_Central_sr_legacy_food_csv_2018-04.zip>.
3. Rules: a missing value stays **unknown** (never 0), WAFCT "tr" = 0, a part never exceeds its whole (sugars ≤ carbohydrate, saturated ≤ total fat). Each food records which source gave which value, plus the WAFCT code and USDA id for refreshes.
4. **No data found** (left unknown, so the health rules fail closed for recipes that use them): eru (gnetum), njansang, beef skin (kanda), limestone (nikki), achu spice, mbongo spice. Banana leaves are wrapping only (edible portion 0). Sugars are also unknown for maize grain, cassava chips, gari, cocoyam, egusi, leafy greens, ndolé leaves, waterleaf, prawns and coconut milk. A Cameroonian or African analysis (e.g. published studies of gnetum) can fill these later.
5. Proxies to know about: bouillon cube = USDA "beef bouillon powder, dry" (sodium 26 g/100 g; the low-sodium entry would understate salt 25-fold); spaghetti = WAFCT macaroni; refined vegetable oil = refined palm oil (most Cameroonian brands are palm olein); smoked fish and stockfish = WAFCT "fish, whole, dried".

## Refresh

Monthly, after WFP publishes on HDX:

1. Run `tool/wfp_prices.sh` (it downloads the latest file and prints the new medians).
2. Update the changed tier A/B rows in the CSV, and their `observed_to` and `observations`.
3. Re-check tier C rows against news and official announcements, and tier O rows with the owner.
4. Ship the change as a new data migration: `npx supabase@2.121.0 migration new food_prices_<yyyy_mm>`, paste the two `BEGIN/END GENERATED` marker lines into it, run `dart run tool/food_catalog.dart sql <that file>` (an upsert by slug), then `flutter test test/tool` and `npx supabase@2.121.0 test db`.

## Sources

- WFP — *Cameroon – Food Prices*, HDX, updated 2026-10-04, data to 2026-08-15. Compiled from MINCOMMERCE, INS, MINADER, FAO GIEWS, FEWS NET and WFP. Licence **CC BY-IGO**: reuse allowed with attribution. <https://data.humdata.org/dataset/wfp-food-prices-for-cameroon>
- FAO GIEWS — Cameroon country brief (Apr 2026). <https://www.fao.org/giews/countrybrief/country/CMR/pdf/CMR.pdf>
- INS Cameroun — monthly consumer price notes, May and July 2026. <https://ins-cameroun.cm/statistique/note-mensuelle-sur-levolution-des-prix-a-la-consommation-finale-des-menages-au-cameroun-en-mai-2026/>
- MINCOMMERCE rice prices of 11 Apr 2024 (via 237actu). <https://237actu.com/cameroun-le-gouvernement-annonce-la-baisse-des-prix-du-riz-apres-celle-de-l-huile-raffinee/>
- Refined oil prices (Le Financier d'Afrique; Carrefour Cameroun). <https://lefinancierdafrique.com/13155/le-prix-du-litre-dhuile-raffinee-passe-de-1500-a-1100-fcfa/> · <https://carrefour.cm/promotions/huile-oleo-5l/>
- Beef ceilings and market prices (Camerounlink, June 2025; 237online; DataCameroon, 15 May 2026). <https://www.camerounlink.com/news/2025/6/24/viande-de-boeuf-le-gouvernement-plafonne-les-prix-a-yaounde-152118-grpe-1-seite-129/> · <https://www.237online.com/viande-boeuf-prix-yaounde-marche/> · <https://datacameroon.com/yaounde-le-prix-de-la-viande-de-boeuf-flambe-a-nouveau/>
- Chicken (Carrefour Cameroun; Investir au Cameroun on IPAVIC farm-gate prices). <https://carrefour.cm/promotions/poulet-entier-le-kg/> · <https://www.investiraucameroun.com/agriculture/2211-20007-poulet-des-producteurs-proposent-a-l-ipavic-d-ajuster-le-prix-sortie-ferme-a-3000-fcfa-au-lieu-de-2300-fcfa>
- Eggs (Glotelho; Carrefour Cameroun). <https://glotelho.cm/product/une-alveole-d-oeufs-de-qualite-59131> · <https://carrefour.cm/promotions/oeufs-plateau-de-30/>
- Frozen fish (KOACI, 15 Oct 2026; Cameroun Actuel). <https://www.koaci.com/article/2026/10/15/cameroun/politique/cameroun-poisson-cher-et-rare-congelcam-crie-a-la-persecution-les-menageres-denoncent-la-speculation_201652.html> · <https://camerounactuel.com/cameroun-le-prix-du-carton-de-maquereau-passe-de-25-000-a-32-000-fcfa/>
- Crayfish (Cameroon News Agency, May 2026). <https://cameroonnewsagency.com/douala-crayfish-prices-surge-squeezing-traders-and-households/>
- Sugar (Glotelho, Sosucam 1 kg). <https://glotelho.cm/product/sucre-blanc-en-poudre-sosucam-1kg-41232>
- Tomato season (KOACI, 9 Mar 2026). <https://www.koaci.com/article/2026/03/09/cameroun/societe/cameroun-tomates-entre-2500-et-1-000-fcfa-le-cageot-quand-labondance-ruine-le-paysan_194954.html>
- Seasoning powders (Business in Cameroon, Aug 2026). <https://www.businessincameroon.com/business-environment/0409-16676-nestle-adds-locally-made-powders-to-cameroon-s-seasoning-market>

**Rejected:** price aggregators that cite no primary source and disagree with measured data (e.g. one gave plantain at 1 220–3 050 FCFA/kg against WFP's measured 310–550), and wholesale listings with no date.
