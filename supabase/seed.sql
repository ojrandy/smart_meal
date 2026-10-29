-- SmartMeal seed data — LOCAL DEVELOPMENT ONLY (`supabase db reset`).
-- Never run against the hosted project.
--
-- Cuisines and the food catalog are reference data in the migrations
-- (20261024073206_setup_flow.sql, 20261029015243_food_catalog.sql). Every
-- recipe line points at a catalog food, so costs and nutrients come from
-- the catalog (LF01). Allergens are listed per recipe from its foods; the
-- publishing guard refuses a recipe whose list misses one (S11).

-- ── DEV PLACEHOLDER prices ──────────────────────────────────────────────────
-- Foods the seed recipes need that have no market price yet (inactive in
-- production). Local only, so the 12 recipes can be published for P17/P18
-- work. Never copy these to production: the owner's market check replaces
-- them (docs/reference/ingredient-prices-cm.md). Real prices are never
-- overwritten (`price_xaf is null`).
update public.ingredients i
set price_xaf = d.price,
    price_low_xaf = d.price,
    price_high_xaf = d.price,
    price_confidence = 'low',
    price_source = 'DEV PLACEHOLDER (supabase/seed.sql, local only): not a market price',
    is_active = true
from (values
  ('prawns', 5000), ('waterleaf', 500), ('beef-skin-kanda', 2500),
  ('limestone-kanwa', 2000), ('achu-spice', 5000), ('mbongo-spice', 5000),
  ('banana-leaves', 100), ('carrot', 800), ('green-beans', 1000),
  ('fish-fresh', 2500), ('bell-pepper', 1500), ('yeast-dry', 10000),
  ('tomato-tinned', 600), ('parmesan', 20000), ('milk-uht', 1500),
  ('butter', 6000), ('chickpeas-tinned', 1000), ('coconut-milk', 1200),
  ('mustard-seeds', 8000), ('curry-powder', 10000), ('soy-sauce', 5000),
  ('sesame-oil', 10000)
) as d (slug, price)
where i.slug = d.slug and i.price_xaf is null;

-- ── Recipes ─────────────────────────────────────────────────────────────────
-- Inserted unpublished and published at the end, once every line exists.

insert into public.recipes (
  id, slug, title, summary, cuisine_slug, image_path, prep_minutes,
  cook_minutes, difficulty, servings, dietary_tags, allergens, is_published
) values
  ('00000000-0000-4000-8000-000000000001', 'ndole', 'Ndolé',
   'Bitterleaf stewed with groundnut paste, beef and prawns.',
   'cameroonian', null, 40, 90, 'hard', 6,
   '{gluten_free,dairy_free}', '{peanuts,crustaceans}', false),
  ('00000000-0000-4000-8000-000000000002', 'eru', 'Eru',
   'Eru and waterleaf cooked in palm oil with smoked fish and crayfish.',
   'cameroonian', null, 30, 60, 'medium', 6,
   '{gluten_free,dairy_free}', '{fish,crustaceans}', false),
  ('00000000-0000-4000-8000-000000000003', 'achu-yellow-soup', 'Achu with yellow soup',
   'Pounded cocoyam with a spiced palm-oil soup and beef.',
   'cameroonian', null, 30, 120, 'hard', 4,
   '{gluten_free,dairy_free}', '{}', false),
  ('00000000-0000-4000-8000-000000000004', 'koki', 'Koki',
   'Steamed black-eyed bean pudding with palm oil and greens.',
   'cameroonian', null, 60, 90, 'medium', 6,
   '{vegan,vegetarian,gluten_free,dairy_free}', '{}', false),
  ('00000000-0000-4000-8000-000000000005', 'poulet-dg', 'Poulet DG',
   'Chicken with fried ripe plantains and vegetables.',
   'cameroonian', null, 30, 60, 'medium', 4,
   '{gluten_free,dairy_free}', '{}', false),
  ('00000000-0000-4000-8000-000000000006', 'mbongo-tchobi', 'Mbongo tchobi',
   'Fish in a black sauce of roasted mbongo spice.',
   'cameroonian', null, 25, 45, 'medium', 4,
   '{pescatarian,gluten_free,dairy_free}', '{fish}', false),
  ('00000000-0000-4000-8000-000000000007', 'vegetable-jollof-rice', 'Vegetable jollof rice',
   'Rice cooked in a spiced tomato and pepper base.',
   'west_african', null, 20, 45, 'easy', 4,
   '{vegan,vegetarian,gluten_free,dairy_free}', '{}', false),
  ('00000000-0000-4000-8000-000000000008', 'puff-puff', 'Puff-puff',
   'Sweet fried dough balls.',
   'west_african', null, 70, 20, 'easy', 6,
   '{vegan,vegetarian,dairy_free}', '{gluten}', false),
  ('00000000-0000-4000-8000-000000000009', 'spaghetti-bolognese', 'Spaghetti bolognese',
   'Spaghetti with a slow-cooked beef and tomato sauce.',
   'italian', null, 15, 60, 'easy', 4,
   '{}', '{gluten,celery,milk}', false),
  ('00000000-0000-4000-8000-000000000010', 'vegetable-omelette', 'Vegetable omelette',
   'Eggs folded over onions and peppers.',
   'french', null, 10, 10, 'easy', 2,
   '{vegetarian,gluten_free}', '{eggs,milk}', false),
  -- Curry powder usually holds celery as well as mustard (owner, 2026-10-29).
  ('00000000-0000-4000-8000-000000000011', 'chickpea-curry', 'Chickpea curry',
   'Chickpeas in a tomato and coconut sauce with mustard seeds.',
   'indian', null, 15, 35, 'easy', 4,
   '{vegan,vegetarian,gluten_free,dairy_free}', '{mustard,celery}', false),
  ('00000000-0000-4000-8000-000000000012', 'egg-fried-rice', 'Egg fried rice',
   'Day-old rice stir-fried with egg, soy sauce and sesame oil.',
   'chinese', null, 10, 15, 'easy', 2,
   '{vegetarian,dairy_free}', '{eggs,soy,gluten,sesame}', false);

-- name / quantity / unit: what the cook reads. food + amount: what the
-- recipe consumes, in the food's pricing unit (kg, litre or piece). Piece
-- weights and "1 onion ≈ 100 g" are estimates noted in
-- docs/reference/ingredient-catalog-cm.csv. Frying oil counts only the oil
-- the food absorbs (owner, 2026-10-29); the rest stays in the kitchen.
insert into public.recipe_ingredients (recipe_id, position, name, quantity, unit, ingredient_id, amount)
select v.recipe_id::uuid, v.position, v.name, v.quantity, v.unit, i.id, v.amount
from (values
  ('00000000-0000-4000-8000-000000000001', 1, 'Washed bitterleaf', 500, 'g', 'ndole-leaves', 1),
  ('00000000-0000-4000-8000-000000000001', 2, 'Raw groundnuts (peanuts)', 500, 'g', 'groundnuts', 0.5),
  ('00000000-0000-4000-8000-000000000001', 3, 'Beef', 600, 'g', 'beef-boneless', 0.6),
  ('00000000-0000-4000-8000-000000000001', 4, 'Prawns', 250, 'g', 'prawns', 0.25),
  ('00000000-0000-4000-8000-000000000001', 5, 'Onion', 2, null, 'onion', 0.2),
  ('00000000-0000-4000-8000-000000000001', 6, 'Vegetable oil', 100, 'ml', 'vegetable-oil', 0.1),
  ('00000000-0000-4000-8000-000000000002', 1, 'Eru (okazi), finely sliced', 300, 'g', 'eru-leaves', 0.75),
  ('00000000-0000-4000-8000-000000000002', 2, 'Waterleaf', 500, 'g', 'waterleaf', 0.5),
  ('00000000-0000-4000-8000-000000000002', 3, 'Palm oil', 250, 'ml', 'palm-oil', 0.25),
  ('00000000-0000-4000-8000-000000000002', 4, 'Smoked fish', 200, 'g', 'fish-smoked', 1.333),
  ('00000000-0000-4000-8000-000000000002', 5, 'Ground dried crayfish', 50, 'g', 'crayfish-dried', 2),
  ('00000000-0000-4000-8000-000000000002', 6, 'Beef skin (kanda)', 300, 'g', 'beef-skin-kanda', 0.3),
  ('00000000-0000-4000-8000-000000000003', 1, 'Cocoyams', 1500, 'g', 'taro', 1.5),
  ('00000000-0000-4000-8000-000000000003', 2, 'Palm oil', 200, 'ml', 'palm-oil', 0.2),
  ('00000000-0000-4000-8000-000000000003', 3, 'Limestone (nikki)', 1, 'tsp', 'limestone-kanwa', 0.005),
  ('00000000-0000-4000-8000-000000000003', 4, 'Achu spices', 2, 'tbsp', 'achu-spice', 0.014),
  ('00000000-0000-4000-8000-000000000003', 5, 'Beef', 500, 'g', 'beef-boneless', 0.5),
  ('00000000-0000-4000-8000-000000000004', 1, 'Black-eyed beans', 500, 'g', 'cowpeas', 0.5),
  ('00000000-0000-4000-8000-000000000004', 2, 'Red palm oil', 150, 'ml', 'palm-oil', 0.15),
  ('00000000-0000-4000-8000-000000000004', 3, 'Cocoyam leaves or spinach', 200, 'g', 'leafy-greens', 0.2),
  ('00000000-0000-4000-8000-000000000004', 4, 'Scotch bonnet pepper', 1, null, 'pepper-fresh', 0.1),
  ('00000000-0000-4000-8000-000000000004', 5, 'Banana leaves for wrapping', 6, null, 'banana-leaves', 0.6),
  ('00000000-0000-4000-8000-000000000005', 1, 'Chicken pieces', 1200, 'g', 'chicken', 1.2),
  ('00000000-0000-4000-8000-000000000005', 2, 'Ripe plantains', 3, null, 'plantain', 3),
  ('00000000-0000-4000-8000-000000000005', 3, 'Carrots', 2, null, 'carrot', 0.15),
  ('00000000-0000-4000-8000-000000000005', 4, 'Green beans', 150, 'g', 'green-beans', 0.15),
  ('00000000-0000-4000-8000-000000000005', 5, 'Tomatoes', 3, null, 'tomato', 0.3),
  ('00000000-0000-4000-8000-000000000005', 6, 'Vegetable oil', 300, 'ml', 'vegetable-oil', 0.1),
  ('00000000-0000-4000-8000-000000000006', 1, 'Whole fish (e.g. carp)', 1000, 'g', 'fish-fresh', 1),
  ('00000000-0000-4000-8000-000000000006', 2, 'Mbongo spice, roasted', 50, 'g', 'mbongo-spice', 0.05),
  ('00000000-0000-4000-8000-000000000006', 3, 'Tomatoes', 2, null, 'tomato', 0.2),
  ('00000000-0000-4000-8000-000000000006', 4, 'Onion', 1, null, 'onion', 0.1),
  -- "To taste": no quantity shown; about 5 g counted so sodium is known.
  ('00000000-0000-4000-8000-000000000006', 5, 'Salt', null, null, 'salt', 0.005),
  ('00000000-0000-4000-8000-000000000007', 1, 'Long-grain rice', 400, 'g', 'rice-imported', 0.4),
  ('00000000-0000-4000-8000-000000000007', 2, 'Tomatoes', 4, null, 'tomato', 0.4),
  ('00000000-0000-4000-8000-000000000007', 3, 'Red bell peppers', 2, null, 'bell-pepper', 0.3),
  ('00000000-0000-4000-8000-000000000007', 4, 'Onion', 2, null, 'onion', 0.2),
  ('00000000-0000-4000-8000-000000000007', 5, 'Water', 600, 'ml', 'drinking-water', 0.6),
  ('00000000-0000-4000-8000-000000000007', 6, 'Vegetable oil', 60, 'ml', 'vegetable-oil', 0.06),
  ('00000000-0000-4000-8000-000000000008', 1, 'Wheat flour', 500, 'g', 'wheat-flour', 0.5),
  ('00000000-0000-4000-8000-000000000008', 2, 'Sugar', 100, 'g', 'sugar', 0.1),
  ('00000000-0000-4000-8000-000000000008', 3, 'Dry yeast', 7, 'g', 'yeast-dry', 0.007),
  ('00000000-0000-4000-8000-000000000008', 4, 'Warm water', 400, 'ml', 'drinking-water', 0.4),
  ('00000000-0000-4000-8000-000000000008', 5, 'Oil for frying', 1000, 'ml', 'vegetable-oil', 0.15),
  ('00000000-0000-4000-8000-000000000009', 1, 'Spaghetti (durum wheat)', 400, 'g', 'pasta-spaghetti', 0.8),
  ('00000000-0000-4000-8000-000000000009', 2, 'Minced beef', 500, 'g', 'beef-boneless', 0.5),
  ('00000000-0000-4000-8000-000000000009', 3, 'Celery stick', 1, null, 'celery', 0.8),
  ('00000000-0000-4000-8000-000000000009', 4, 'Carrot', 1, null, 'carrot', 0.075),
  ('00000000-0000-4000-8000-000000000009', 5, 'Tinned tomatoes', 800, 'g', 'tomato-tinned', 2),
  ('00000000-0000-4000-8000-000000000009', 6, 'Parmesan', 40, 'g', 'parmesan', 0.04),
  ('00000000-0000-4000-8000-000000000010', 1, 'Eggs', 4, null, 'eggs', 4),
  ('00000000-0000-4000-8000-000000000010', 2, 'Milk', 30, 'ml', 'milk-uht', 0.03),
  ('00000000-0000-4000-8000-000000000010', 3, 'Onion', 1, null, 'onion', 0.1),
  ('00000000-0000-4000-8000-000000000010', 4, 'Green bell pepper', 1, null, 'bell-pepper', 0.15),
  ('00000000-0000-4000-8000-000000000010', 5, 'Butter', 15, 'g', 'butter', 0.015),
  ('00000000-0000-4000-8000-000000000011', 1, 'Cooked chickpeas', 800, 'g', 'chickpeas-tinned', 3.333),
  ('00000000-0000-4000-8000-000000000011', 2, 'Coconut milk', 400, 'ml', 'coconut-milk', 1),
  ('00000000-0000-4000-8000-000000000011', 3, 'Tomatoes', 3, null, 'tomato', 0.3),
  ('00000000-0000-4000-8000-000000000011', 4, 'Mustard seeds', 1, 'tsp', 'mustard-seeds', 0.004),
  ('00000000-0000-4000-8000-000000000011', 5, 'Curry powder', 2, 'tbsp', 'curry-powder', 0.013),
  -- 500 g of cooked rice is about 200 g raw.
  ('00000000-0000-4000-8000-000000000012', 1, 'Cooked rice, cold', 500, 'g', 'rice-imported', 0.2),
  ('00000000-0000-4000-8000-000000000012', 2, 'Eggs', 2, null, 'eggs', 2),
  ('00000000-0000-4000-8000-000000000012', 3, 'Soy sauce (contains wheat)', 2, 'tbsp', 'soy-sauce', 0.03),
  ('00000000-0000-4000-8000-000000000012', 4, 'Sesame oil', 1, 'tsp', 'sesame-oil', 0.005),
  ('00000000-0000-4000-8000-000000000012', 5, 'Spring onions', 3, null, 'spring-onion', 0.3)
) as v (recipe_id, position, name, quantity, unit, slug, amount)
left join public.ingredients i on i.slug = v.slug;

insert into public.recipe_steps (recipe_id, position, instruction) values
  ('00000000-0000-4000-8000-000000000001', 1, 'Boil the groundnuts, peel them and blend into a smooth paste.'),
  ('00000000-0000-4000-8000-000000000001', 2, 'Cook the beef with onion and salt until tender.'),
  ('00000000-0000-4000-8000-000000000001', 3, 'Stir in the groundnut paste and simmer for 20 minutes, then add the bitterleaf.'),
  ('00000000-0000-4000-8000-000000000001', 4, 'Fry the prawns with onion in the oil and fold them in before serving.'),
  ('00000000-0000-4000-8000-000000000002', 1, 'Cook the beef skin until soft.'),
  ('00000000-0000-4000-8000-000000000002', 2, 'Add the waterleaf and let its water cook off.'),
  ('00000000-0000-4000-8000-000000000002', 3, 'Add palm oil, smoked fish and crayfish, then the eru; simmer 10 minutes.'),
  ('00000000-0000-4000-8000-000000000003', 1, 'Boil the cocoyams, peel and pound them until smooth.'),
  ('00000000-0000-4000-8000-000000000003', 2, 'Cook the beef with salt and keep the stock.'),
  ('00000000-0000-4000-8000-000000000003', 3, 'Dissolve the limestone in a little stock, add the spices, then whisk in the palm oil until it turns yellow.'),
  ('00000000-0000-4000-8000-000000000004', 1, 'Soak and peel the beans, then blend with a little water.'),
  ('00000000-0000-4000-8000-000000000004', 2, 'Mix in warm palm oil, the chopped leaves, pepper and salt.'),
  ('00000000-0000-4000-8000-000000000004', 3, 'Wrap portions in banana leaves and steam for 90 minutes.'),
  ('00000000-0000-4000-8000-000000000005', 1, 'Season and fry the chicken until golden.'),
  ('00000000-0000-4000-8000-000000000005', 2, 'Fry the sliced plantains.'),
  ('00000000-0000-4000-8000-000000000005', 3, 'Cook the vegetables with the tomatoes, add the chicken, then fold in the plantains.'),
  ('00000000-0000-4000-8000-000000000006', 1, 'Clean and cut the fish.'),
  ('00000000-0000-4000-8000-000000000006', 2, 'Blend the roasted mbongo with tomato and onion.'),
  ('00000000-0000-4000-8000-000000000006', 3, 'Simmer the fish in the black sauce for 20 minutes.'),
  ('00000000-0000-4000-8000-000000000007', 1, 'Blend the tomatoes, peppers and one onion.'),
  ('00000000-0000-4000-8000-000000000007', 2, 'Fry the other onion, add the blend and cook until thick.'),
  ('00000000-0000-4000-8000-000000000007', 3, 'Add the washed rice and water, cover and cook on low heat.'),
  ('00000000-0000-4000-8000-000000000008', 1, 'Mix the flour, sugar, yeast and water into a sticky batter.'),
  ('00000000-0000-4000-8000-000000000008', 2, 'Let it rise for one hour.'),
  ('00000000-0000-4000-8000-000000000008', 3, 'Fry spoonfuls in hot oil until golden.'),
  ('00000000-0000-4000-8000-000000000009', 1, 'Brown the beef, then add the chopped celery and carrot.'),
  ('00000000-0000-4000-8000-000000000009', 2, 'Add the tomatoes and simmer for 45 minutes.'),
  ('00000000-0000-4000-8000-000000000009', 3, 'Cook the spaghetti and serve with the sauce and parmesan.'),
  ('00000000-0000-4000-8000-000000000010', 1, 'Soften the onion and pepper in butter.'),
  ('00000000-0000-4000-8000-000000000010', 2, 'Beat the eggs with the milk, pour over and cook gently.'),
  ('00000000-0000-4000-8000-000000000010', 3, 'Fold in half and serve.'),
  ('00000000-0000-4000-8000-000000000011', 1, 'Pop the mustard seeds in hot oil.'),
  ('00000000-0000-4000-8000-000000000011', 2, 'Add the curry powder and tomatoes and cook down.'),
  ('00000000-0000-4000-8000-000000000011', 3, 'Add the chickpeas and coconut milk and simmer 15 minutes.'),
  ('00000000-0000-4000-8000-000000000012', 1, 'Scramble the eggs in a hot pan and set aside.'),
  ('00000000-0000-4000-8000-000000000012', 2, 'Stir-fry the rice until hot.'),
  ('00000000-0000-4000-8000-000000000012', 3, 'Add the soy sauce, sesame oil, eggs and spring onions.');

-- Publishing runs the guard on each recipe (at commit): any unlinked line,
-- inactive food or missing allergen fails the whole seed.
update public.recipes set is_published = true
where id::text like '00000000-0000-4000-8000-0000000000%';
