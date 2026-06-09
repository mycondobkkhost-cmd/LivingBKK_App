-- LivingBKK seed data (run after migrations)
-- Usage: supabase db reset  OR  psql -f supabase/seed.sql

CREATE EXTENSION IF NOT EXISTS pgcrypto;

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

-- Demo owner for local testing (password: demo12345)
-- Email: demo-owner@livingbkk.local
INSERT INTO auth.users (
  instance_id,
  id,
  aud,
  role,
  email,
  encrypted_password,
  email_confirmed_at,
  raw_app_meta_data,
  raw_user_meta_data,
  created_at,
  updated_at
)
VALUES (
  '00000000-0000-0000-0000-000000000000',
  '11111111-1111-1111-1111-111111111111',
  'authenticated',
  'authenticated',
  'demo-owner@livingbkk.local',
  crypt('demo12345', gen_salt('bf')),
  now(),
  '{"provider":"email","providers":["email"]}',
  '{"role":"owner","display_name":"LivingBKK Demo Owner"}',
  now(),
  now()
)
ON CONFLICT (id) DO NOTHING;

-- Profile row (trigger may exist; ensure role)
INSERT INTO public.profiles (id, role, display_name)
VALUES (
  '11111111-1111-1111-1111-111111111111',
  'owner',
  'LivingBKK Demo Owner'
)
ON CONFLICT (id) DO UPDATE SET
  role = EXCLUDED.role,
  display_name = EXCLUDED.display_name;

-- Demo admin (password: demo12345)
-- Email: demo-admin@livingbkk.local
INSERT INTO auth.users (
  instance_id,
  id,
  aud,
  role,
  email,
  encrypted_password,
  email_confirmed_at,
  raw_app_meta_data,
  raw_user_meta_data,
  created_at,
  updated_at
)
VALUES (
  '00000000-0000-0000-0000-000000000000',
  '22222222-2222-2222-2222-222222222222',
  'authenticated',
  'authenticated',
  'demo-admin@livingbkk.local',
  crypt('demo12345', gen_salt('bf')),
  now(),
  '{"provider":"email","providers":["email"]}',
  '{"role":"admin","display_name":"LivingBKK Demo Admin"}',
  now(),
  now()
)
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.profiles (id, role, display_name, admin_tier)
VALUES (
  '22222222-2222-2222-2222-222222222222',
  'admin',
  'LivingBKK Demo Admin',
  'ceo'
)
ON CONFLICT (id) DO UPDATE SET
  role = 'admin',
  display_name = EXCLUDED.display_name,
  admin_tier = 'ceo';
