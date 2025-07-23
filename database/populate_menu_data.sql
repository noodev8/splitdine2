-- Sample menu data for testing autocomplete
-- This script populates menu_item and menu_synonym tables

-- First, add some menu items
INSERT INTO menu_item (name) VALUES 
('Margherita Pizza'),
('Pepperoni Pizza'),
('Hawaiian Pizza'),
('Vegetarian Pizza'),
('Chicken Wings'),
('Buffalo Wings'),
('French Fries'),
('Onion Rings'),
('Caesar Salad'),
('Greek Salad'),
('Coca Cola'),
('Sprite'),
('Orange Juice'),
('Coffee'),
('Tea')
ON CONFLICT (name) DO NOTHING;

-- Now add synonyms for each item
-- The search looks in menu_synonym, so we need entries here
WITH items AS (
    SELECT id, name FROM menu_item
)
INSERT INTO menu_synonym (menu_item_id, synonym)
SELECT id, UPPER(name) FROM items
ON CONFLICT (menu_item_id, synonym) DO NOTHING;

-- Add additional synonyms for common variations
INSERT INTO menu_synonym (menu_item_id, synonym) VALUES
-- Pizza synonyms
((SELECT id FROM menu_item WHERE name = 'Margherita Pizza'), 'MARGHERITA'),
((SELECT id FROM menu_item WHERE name = 'Margherita Pizza'), 'PIZZA MARGHERITA'),
((SELECT id FROM menu_item WHERE name = 'Margherita Pizza'), 'MARG PIZZA'),
((SELECT id FROM menu_item WHERE name = 'Margherita Pizza'), 'PIZZA'),
((SELECT id FROM menu_item WHERE name = 'Pepperoni Pizza'), 'PEPPERONI'),
((SELECT id FROM menu_item WHERE name = 'Pepperoni Pizza'), 'PEP PIZZA'),
((SELECT id FROM menu_item WHERE name = 'Pepperoni Pizza'), 'PIZZA'),
((SELECT id FROM menu_item WHERE name = 'Hawaiian Pizza'), 'HAWAIIAN'),
((SELECT id FROM menu_item WHERE name = 'Hawaiian Pizza'), 'PINEAPPLE PIZZA'),
((SELECT id FROM menu_item WHERE name = 'Hawaiian Pizza'), 'PIZZA'),
((SELECT id FROM menu_item WHERE name = 'Vegetarian Pizza'), 'VEGGIE PIZZA'),
((SELECT id FROM menu_item WHERE name = 'Vegetarian Pizza'), 'VEG PIZZA'),
((SELECT id FROM menu_item WHERE name = 'Vegetarian Pizza'), 'PIZZA'),

-- Wings synonyms
((SELECT id FROM menu_item WHERE name = 'Chicken Wings'), 'WINGS'),
((SELECT id FROM menu_item WHERE name = 'Chicken Wings'), 'CHICKEN'),
((SELECT id FROM menu_item WHERE name = 'Buffalo Wings'), 'WINGS'),
((SELECT id FROM menu_item WHERE name = 'Buffalo Wings'), 'BUFFALO'),
((SELECT id FROM menu_item WHERE name = 'Buffalo Wings'), 'HOT WINGS'),

-- Sides synonyms
((SELECT id FROM menu_item WHERE name = 'French Fries'), 'FRIES'),
((SELECT id FROM menu_item WHERE name = 'French Fries'), 'CHIPS'),
((SELECT id FROM menu_item WHERE name = 'Onion Rings'), 'RINGS'),
((SELECT id FROM menu_item WHERE name = 'Onion Rings'), 'ONION'),

-- Salad synonyms
((SELECT id FROM menu_item WHERE name = 'Caesar Salad'), 'CAESAR'),
((SELECT id FROM menu_item WHERE name = 'Caesar Salad'), 'SALAD'),
((SELECT id FROM menu_item WHERE name = 'Greek Salad'), 'GREEK'),
((SELECT id FROM menu_item WHERE name = 'Greek Salad'), 'SALAD'),

-- Drinks synonyms
((SELECT id FROM menu_item WHERE name = 'Coca Cola'), 'COKE'),
((SELECT id FROM menu_item WHERE name = 'Coca Cola'), 'COLA'),
((SELECT id FROM menu_item WHERE name = 'Coca Cola'), 'SODA'),
((SELECT id FROM menu_item WHERE name = 'Orange Juice'), 'OJ'),
((SELECT id FROM menu_item WHERE name = 'Orange Juice'), 'JUICE')
ON CONFLICT (menu_item_id, synonym) DO NOTHING;

-- Verify the data
SELECT 'Menu items:' as info, COUNT(*) as count FROM menu_item
UNION ALL
SELECT 'Synonyms:', COUNT(*) FROM menu_synonym;

-- Test the search query for "pizz"
SELECT 'Search results for "pizz":' as info;
SELECT DISTINCT ON (mi.id) mi.id, mi.name
FROM menu_synonym ms
JOIN menu_item mi ON mi.id = ms.menu_item_id
WHERE
  ms.synonym LIKE 'pizz' || '%'           -- fast prefix match
  OR ms.synonym LIKE '%' || 'pizz' || '%' -- substring match
  OR (ms.synonym % 'pizz')                -- fuzzy match
ORDER BY mi.id, similarity(ms.synonym, 'pizz') DESC
LIMIT 3;