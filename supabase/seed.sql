-- LivingBKK seed data (run after migrations)
-- Usage: supabase db reset  OR  psql -f supabase/seed.sql

-- Commission tiers (example ladder)
INSERT INTO public.commission_tiers (name, min_months, max_months, platform_percent, agent_percent, owner_percent, sort_order)
VALUES
  ('สัญญา 6 เดือน', 0, 6, 40, 30, 30, 1),
  ('สัญญา 12 เดือน', 7, 12, 35, 35, 30, 2),
  ('สัญญา 24 เดือน', 13, 24, 30, 35, 35, 3),
  ('สัญญา 24+ เดือน', 25, NULL, 25, 40, 35, 4);

-- Geo zones (Bangkok + metro — centers approximate; boundaries TBD in admin)
INSERT INTO public.geo_zones (slug, name_th, name_en, zone_type, center, aliases, sort_order)
VALUES
  ('bangkok-all', 'กรุงเทพมหานคร', 'Bangkok', 'metro',
    ST_SetSRID(ST_MakePoint(100.5018, 13.7563), 4326)::geography,
    ARRAY['กทม', 'bangkok'], 0),
  ('thonglor', 'ทองหล่อ', 'Thonglor', 'district',
    ST_SetSRID(ST_MakePoint(100.5794, 13.7234), 4326)::geography,
    ARRAY['ทองหล่อ', 'thong lo'], 10),
  ('asok', 'อโศก', 'Asok', 'district',
    ST_SetSRID(ST_MakePoint(100.5606, 13.7373), 4326)::geography,
    ARRAY['อโศก', 'asoke', 'มศว', 'mrt asok', 'bts asok'], 11),
  ('sukhumvit', 'สุขุมวิท', 'Sukhumvit', 'district',
    ST_SetSRID(ST_MakePoint(100.5695, 13.7300), 4326)::geography,
    ARRAY['สุขุมวิท', 'sukhumvit'], 12),
  ('nonthaburi', 'นนทบุรี', 'Nonthaburi', 'metro',
    ST_SetSRID(ST_MakePoint(100.5150, 13.8621), 4326)::geography,
    ARRAY['นนทบุรี', 'nonthaburi'], 20),
  ('pathum-thani', 'ปทุมธานี', 'Pathum Thani', 'metro',
    ST_SetSRID(ST_MakePoint(100.5250, 14.0208), 4326)::geography,
    ARRAY['ปทุมธานี'], 21),
  ('samut-prakan', 'สมุทรปราการ', 'Samut Prakan', 'metro',
    ST_SetSRID(ST_MakePoint(100.5967, 13.5990), 4326)::geography,
    ARRAY['สมุทรปราการ'], 22)
ON CONFLICT (slug) DO UPDATE SET
  aliases = EXCLUDED.aliases,
  center = EXCLUDED.center;
