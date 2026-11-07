-- ==============================================================================
-- UPAJO (उपजो) - Seed Master Data (Categories, Crops, Store Items)
-- ==============================================================================

-- 1. SEED CATEGORIES
INSERT INTO public.categories (slug, name_hi, name_en, icon_name, sort_order) VALUES
  ('grains', 'अनाज व खाद्यान्न', 'Grains & Cereals', 'grain', 1),
  ('pulses', 'दालें व दलहन', 'Pulses & Lentils', 'soup', 2),
  ('vegetables', 'ताज़ी सब्जियां', 'Fresh Vegetables', 'carrot', 3),
  ('spices', 'देसी मसाले', 'Spices & Condiments', 'sparkles', 4),
  ('fruits', 'बागवानी फल', 'Fresh Fruits', 'apple', 5),
  ('oilseeds', 'तिलहन व तेल', 'Oilseeds & Oils', 'droplets', 6)
ON CONFLICT (slug) DO UPDATE SET
  name_hi = EXCLUDED.name_hi,
  name_en = EXCLUDED.name_en,
  icon_name = EXCLUDED.icon_name,
  sort_order = EXCLUDED.sort_order;

-- 2. SEED MASTER CROPS (For Crop Advisor Engine)
INSERT INTO public.crops (name_hi, name_en, scientific_name, season, soil_types, water_requirement, duration_days, avg_yield_per_acre, ideal_temperature_min, ideal_temperature_max) VALUES
  ('शरबती गेहूं (Sharbati Wheat)', 'Sharbati Wheat', 'Triticum aestivum', 'rabi', '{"black", "clay_loam", "alluvial"}', 'Medium (3-4 Irrigations)', 135, 18.5, 12.0, 26.0),
  ('सोना मसूरी धान (Paddy)', 'Sona Masoori Rice', 'Oryza sativa', 'kharif', '{"clay", "clay_loam"}', 'High (Continuous Moisture)', 140, 24.0, 20.0, 35.0),
  ('देसी चना (Bengal Gram)', 'Desi Chickpea', 'Cicer arietinum', 'rabi', '{"sandy_loam", "black_soil"}', 'Low (1-2 Irrigations)', 110, 8.5, 10.0, 25.0),
  ('पीला सोयाबीन (Yellow Soybean)', 'Yellow Soybean', 'Glycine max', 'kharif', '{"black_soil", "loam"}', 'Medium (Rainfed / 2 Irrigations)', 95, 10.0, 18.0, 32.0),
  ('पीली सरसों (Yellow Mustard)', 'Mustard', 'Brassica juncea', 'rabi', '{"alluvial", "loam"}', 'Low (2 Irrigations)', 115, 9.0, 10.0, 22.0),
  ('कुफरी ज्योति आलू (Potato)', 'Potato', 'Solanum tuberosum', 'rabi', '{"sandy_loam"}', 'Medium (Frequent light irrigation)', 90, 110.0, 15.0, 24.0),
  ('नासिक लाल प्याज (Red Onion)', 'Red Onion', 'Allium cepa', 'rabi', '{"loam", "sandy_loam"}', 'Medium (Regular intervals)', 125, 95.0, 15.0, 30.0)
ON CONFLICT DO NOTHING;

-- 3. SEED STORE ITEMS (Certified Seeds, Bio-Fertilizers & Tools)
INSERT INTO public.store_items (title_hi, title_en, item_type, brand, price, pack_size, stock_quantity, description_hi, description_en) VALUES
  ('प्रमाणित शरबती गेहूं बीज C-306', 'Certified Sharbati Wheat Seeds C-306', 'seed', 'NSC (National Seeds Corp)', 1450.00, '40 kg Bag', 200, 'उच्च चमक, मीठा स्वाद और 100% अंकुरण क्षमता वाला शुद्ध बीज।', 'High sheen, sweet taste, certified pure foundation seed.'),
  ('जैविक नीम-खली खाद (Neem Cake)', 'Organic Neem Cake Fertilizer', 'fertilizer', 'IFFCO Organic', 680.00, '25 kg Bag', 150, 'दीमक व सफेद लट से सुरक्षा और जमीन में नाइट्रोजन की धीमी पूर्ति।', 'Natural pest repellent and organic nitrogen source.'),
  ('ट्राइकोडर्मा विरिडी जैव-फफूंदनाशक', 'Trichoderma Viride Bio-Fungicide', 'bio_nutrient', 'KRIBHCO', 220.00, '1 kg Pack', 500, 'जड़ गलन और उकठा (Wilt) रोग से बीज एवं भूमि उपचार के लिए उत्तम।', 'Effective bio-control agent against seed & soil-borne pathogens.'),
  ('मैनुअल हस्तचालित स्प्रेयर (16L)', 'Knapsack Manual Sprayer 16L', 'farm_tool', 'Kisan Kraft', 1850.00, '1 Unit', 80, 'टिकाऊ पीतल की नोजल, मजबूत प्लास्टिक टंकी, 3 साल वारंटी।', 'Durable brass nozzle with high pressure chamber.')
ON CONFLICT DO NOTHING;

