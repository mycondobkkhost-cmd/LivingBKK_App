-- Phase 17: Property project registry (LI-style naming + canonical pins)

CREATE TABLE public.property_projects (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  slug text NOT NULL UNIQUE,
  name_th text NOT NULL,
  name_en text NOT NULL,
  district text NOT NULL,
  bts_station text,
  property_type text NOT NULL DEFAULT 'condo',
  lat double precision NOT NULL,
  lng double precision NOT NULL,
  location geography(POINT, 4326) NOT NULL,
  aliases text[] NOT NULL DEFAULT '{}',
  year_built int,
  facilities text[] NOT NULL DEFAULT '{}',
  geo_zone_id uuid REFERENCES public.geo_zones (id),
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX property_projects_name_th_idx ON public.property_projects (name_th);
CREATE INDEX property_projects_district_idx ON public.property_projects (district);
CREATE INDEX property_projects_geo_idx ON public.property_projects USING GIST (location);

ALTER TABLE public.listings
  ADD COLUMN IF NOT EXISTS project_id uuid REFERENCES public.property_projects (id);

CREATE INDEX listings_project_id_idx ON public.listings (project_id);

ALTER TABLE public.property_projects ENABLE ROW LEVEL SECURITY;

CREATE POLICY property_projects_read ON public.property_projects
  FOR SELECT TO authenticated, anon
  USING (is_active = true);

CREATE POLICY property_projects_admin_write ON public.property_projects
  FOR ALL TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

DROP VIEW IF EXISTS public.listings_public CASCADE;

CREATE OR REPLACE VIEW public.listings_public
WITH (security_invoker = true)
AS
SELECT
  l.id,
  l.listing_code,
  l.listing_type,
  l.status,
  l.property_type,
  l.title,
  l.description_public,
  l.price_net,
  l.co_agent_listing_type,
  l.investor_category,
  l.yield_percent,
  l.pet_allowed,
  l.smoking_allowed,
  l.furnished,
  l.bedrooms,
  l.bathrooms,
  l.area_sqm,
  l.floor_range,
  l.district,
  l.subdistrict,
  COALESCE(l.project_name, pp.name_th) AS project_name,
  pp.name_en AS project_name_en,
  pp.slug AS project_slug,
  pp.bts_station AS project_bts,
  l.geo_zone_id,
  gz.slug AS geo_zone_slug,
  l.max_distance_bts_km,
  l.location_public,
  CASE WHEN l.location_public IS NOT NULL
    THEN ST_Y(l.location_public::geometry)::double precision END AS lat,
  CASE WHEN l.location_public IS NOT NULL
    THEN ST_X(l.location_public::geometry)::double precision END AS lng,
  l.co_agent_eligible,
  l.co_agent_listing_type AS co_agent_status_display,
  l.available_from,
  l.available_again,
  l.last_bump_at,
  l.published_at,
  l.created_at,
  l.updated_at,
  COALESCE(
    (
      SELECT json_agg(li.public_url ORDER BY li.sort_order)
      FROM public.listing_images li
      WHERE li.listing_id = l.id
        AND li.public_url IS NOT NULL
        AND li.moderation_status IN ('approved', 'pending')
    ),
    '[]'::json
  ) AS image_urls
FROM public.listings l
LEFT JOIN public.geo_zones gz ON gz.id = l.geo_zone_id
LEFT JOIN public.property_projects pp ON pp.id = l.project_id
WHERE l.status = 'published'
  AND (l.expires_at IS NULL OR l.expires_at > now());

-- Seed 24 Bangkok metro projects (generated from mobile/lib/data/bangkok_projects.dart)
INSERT INTO public.property_projects (
  slug, name_th, name_en, district, bts_station, property_type,
  lat, lng, location, aliases, year_built, facilities, geo_zone_id
)
SELECT
  'true-thonglor',
  'ทรู ทองหล่อ',
  'The Trendy / True Thonglor',
  'วัฒนา',
  'BTS ทองหล่อ',
  'condo',
  13.7242,
  100.5805,
  ST_SetSRID(ST_MakePoint(100.5805, 13.7242), 4326)::geography,
  ARRAY['ทรู', 'ทองหล่อ', 'thonglor', 'trendy'],
  2014,
  ARRAY['สระว่ายน้ำ', 'ฟิตเนส', 'Co-working', 'ที่จอดรถ'],
  gz.id
FROM public.geo_zones gz
WHERE gz.slug = 'thonglor'
ON CONFLICT (slug) DO UPDATE SET
  name_th = EXCLUDED.name_th,
  name_en = EXCLUDED.name_en,
  district = EXCLUDED.district,
  bts_station = EXCLUDED.bts_station,
  property_type = EXCLUDED.property_type,
  lat = EXCLUDED.lat,
  lng = EXCLUDED.lng,
  location = EXCLUDED.location,
  aliases = EXCLUDED.aliases,
  year_built = EXCLUDED.year_built,
  facilities = EXCLUDED.facilities,
  geo_zone_id = EXCLUDED.geo_zone_id,
  updated_at = now();

INSERT INTO public.property_projects (
  slug, name_th, name_en, district, bts_station, property_type,
  lat, lng, location, aliases, year_built, facilities, geo_zone_id
)
SELECT
  'the-line-sukhumvit-101',
  'เดอะไลน์ สุขุมวิท 101',
  'The Line Sukhumvit 101',
  'วัฒนา',
  'BTS บางจาก',
  'condo',
  13.6898,
  100.6072,
  ST_SetSRID(ST_MakePoint(100.6072, 13.6898), 4326)::geography,
  ARRAY['line 101', 'เดอะไลน์'],
  2017,
  ARRAY['สระว่ายน้ำ', 'ฟิตเนส', 'Co-working', 'รปภ. 24 ชม.'],
  gz.id
FROM public.geo_zones gz
WHERE gz.slug = 'sukhumvit'
ON CONFLICT (slug) DO UPDATE SET
  name_th = EXCLUDED.name_th,
  name_en = EXCLUDED.name_en,
  district = EXCLUDED.district,
  bts_station = EXCLUDED.bts_station,
  property_type = EXCLUDED.property_type,
  lat = EXCLUDED.lat,
  lng = EXCLUDED.lng,
  location = EXCLUDED.location,
  aliases = EXCLUDED.aliases,
  year_built = EXCLUDED.year_built,
  facilities = EXCLUDED.facilities,
  geo_zone_id = EXCLUDED.geo_zone_id,
  updated_at = now();

INSERT INTO public.property_projects (
  slug, name_th, name_en, district, bts_station, property_type,
  lat, lng, location, aliases, year_built, facilities, geo_zone_id
)
SELECT
  'noble-remix-thonglor',
  'โนเบิล รีมิกซ์ ทองหล่อ',
  'Noble Remix Thonglor',
  'วัฒนา',
  'BTS ทองหล่อ',
  'condo',
  13.7265,
  100.5828,
  ST_SetSRID(ST_MakePoint(100.5828, 13.7265), 4326)::geography,
  ARRAY['noble remix', 'โนเบิล'],
  2014,
  ARRAY['สระว่ายน้ำ', 'ฟิตเนส', 'Co-working', 'ที่จอดรถ'],
  gz.id
FROM public.geo_zones gz
WHERE gz.slug = 'thonglor'
ON CONFLICT (slug) DO UPDATE SET
  name_th = EXCLUDED.name_th,
  name_en = EXCLUDED.name_en,
  district = EXCLUDED.district,
  bts_station = EXCLUDED.bts_station,
  property_type = EXCLUDED.property_type,
  lat = EXCLUDED.lat,
  lng = EXCLUDED.lng,
  location = EXCLUDED.location,
  aliases = EXCLUDED.aliases,
  year_built = EXCLUDED.year_built,
  facilities = EXCLUDED.facilities,
  geo_zone_id = EXCLUDED.geo_zone_id,
  updated_at = now();

INSERT INTO public.property_projects (
  slug, name_th, name_en, district, bts_station, property_type,
  lat, lng, location, aliases, year_built, facilities, geo_zone_id
)
SELECT
  'rhythm-sukhumvit-36',
  'ริธึม สุขุมวิท 36',
  'Rhythm Sukhumvit 36',
  'คลองเตย',
  'BTS ทองหล่อ',
  'condo',
  13.7358,
  100.5712,
  ST_SetSRID(ST_MakePoint(100.5712, 13.7358), 4326)::geography,
  ARRAY['rhythm 36', 'ริธึม'],
  2016,
  ARRAY['สระว่ายน้ำ', 'ฟิตเนส', 'ที่จอดรถ', 'Sky Lounge', 'รปภ. 24 ชม.'],
  gz.id
FROM public.geo_zones gz
WHERE gz.slug = 'thonglor'
ON CONFLICT (slug) DO UPDATE SET
  name_th = EXCLUDED.name_th,
  name_en = EXCLUDED.name_en,
  district = EXCLUDED.district,
  bts_station = EXCLUDED.bts_station,
  property_type = EXCLUDED.property_type,
  lat = EXCLUDED.lat,
  lng = EXCLUDED.lng,
  location = EXCLUDED.location,
  aliases = EXCLUDED.aliases,
  year_built = EXCLUDED.year_built,
  facilities = EXCLUDED.facilities,
  geo_zone_id = EXCLUDED.geo_zone_id,
  updated_at = now();

INSERT INTO public.property_projects (
  slug, name_th, name_en, district, bts_station, property_type,
  lat, lng, location, aliases, year_built, facilities, geo_zone_id
)
SELECT
  'ashton-asoke',
  'แอสตัน อโศก',
  'Ashton Asoke',
  'วัฒนา',
  'BTS อโศก / MRT สุขุมวิท',
  'condo',
  13.7395,
  100.5635,
  ST_SetSRID(ST_MakePoint(100.5635, 13.7395), 4326)::geography,
  ARRAY['ashton', 'อโศก', 'asok'],
  2018,
  ARRAY['สระว่ายน้ำ', 'ฟิตเนส', 'Sky garden', 'ที่จอดรถ', 'Lobby'],
  gz.id
FROM public.geo_zones gz
WHERE gz.slug = 'asok'
ON CONFLICT (slug) DO UPDATE SET
  name_th = EXCLUDED.name_th,
  name_en = EXCLUDED.name_en,
  district = EXCLUDED.district,
  bts_station = EXCLUDED.bts_station,
  property_type = EXCLUDED.property_type,
  lat = EXCLUDED.lat,
  lng = EXCLUDED.lng,
  location = EXCLUDED.location,
  aliases = EXCLUDED.aliases,
  year_built = EXCLUDED.year_built,
  facilities = EXCLUDED.facilities,
  geo_zone_id = EXCLUDED.geo_zone_id,
  updated_at = now();

INSERT INTO public.property_projects (
  slug, name_th, name_en, district, bts_station, property_type,
  lat, lng, location, aliases, year_built, facilities, geo_zone_id
)
SELECT
  'life-asoke-hype',
  'ไลฟ์ อโศก ไฮป์',
  'Life Asoke Hype',
  'วัฒนา',
  'BTS อโศก',
  'condo',
  13.7412,
  100.5618,
  ST_SetSRID(ST_MakePoint(100.5618, 13.7412), 4326)::geography,
  ARRAY['life asoke', 'ไลฟ์ อโศก'],
  2018,
  ARRAY['สระว่ายน้ำ', 'ฟิตเนส', 'Sky garden', 'ที่จอดรถ', 'Lobby'],
  gz.id
FROM public.geo_zones gz
WHERE gz.slug = 'asok'
ON CONFLICT (slug) DO UPDATE SET
  name_th = EXCLUDED.name_th,
  name_en = EXCLUDED.name_en,
  district = EXCLUDED.district,
  bts_station = EXCLUDED.bts_station,
  property_type = EXCLUDED.property_type,
  lat = EXCLUDED.lat,
  lng = EXCLUDED.lng,
  location = EXCLUDED.location,
  aliases = EXCLUDED.aliases,
  year_built = EXCLUDED.year_built,
  facilities = EXCLUDED.facilities,
  geo_zone_id = EXCLUDED.geo_zone_id,
  updated_at = now();

INSERT INTO public.property_projects (
  slug, name_th, name_en, district, bts_station, property_type,
  lat, lng, location, aliases, year_built, facilities, geo_zone_id
)
SELECT
  'the-lofts-ekkamai',
  'เดอะ ลอฟท์ เอกมัย',
  'The Lofts Ekkamai',
  'วัฒนา',
  'BTS เอกมัย',
  'condo',
  13.7195,
  100.5855,
  ST_SetSRID(ST_MakePoint(100.5855, 13.7195), 4326)::geography,
  ARRAY['lofts ekkamai', 'เอกมัย', 'ekkamai'],
  2014,
  ARRAY['สระว่ายน้ำ', 'ฟิตเนส', 'ที่จอดรถ', 'รปภ. 24 ชม.', 'Lobby'],
  gz.id
FROM public.geo_zones gz
WHERE gz.slug = 'thonglor'
ON CONFLICT (slug) DO UPDATE SET
  name_th = EXCLUDED.name_th,
  name_en = EXCLUDED.name_en,
  district = EXCLUDED.district,
  bts_station = EXCLUDED.bts_station,
  property_type = EXCLUDED.property_type,
  lat = EXCLUDED.lat,
  lng = EXCLUDED.lng,
  location = EXCLUDED.location,
  aliases = EXCLUDED.aliases,
  year_built = EXCLUDED.year_built,
  facilities = EXCLUDED.facilities,
  geo_zone_id = EXCLUDED.geo_zone_id,
  updated_at = now();

INSERT INTO public.property_projects (
  slug, name_th, name_en, district, bts_station, property_type,
  lat, lng, location, aliases, year_built, facilities, geo_zone_id
)
SELECT
  'hq-sukhumvit-101',
  'HQ สุขุมวิท 101',
  'HQ Sukhumvit 101',
  'วัฒนา',
  'BTS บางจาก',
  'condo',
  13.6912,
  100.6058,
  ST_SetSRID(ST_MakePoint(100.6058, 13.6912), 4326)::geography,
  ARRAY['hq 101'],
  2017,
  ARRAY['สระว่ายน้ำ', 'ฟิตเนส', 'ที่จอดรถ', 'รปภ. 24 ชม.', 'Lobby'],
  gz.id
FROM public.geo_zones gz
WHERE gz.slug = 'sukhumvit'
ON CONFLICT (slug) DO UPDATE SET
  name_th = EXCLUDED.name_th,
  name_en = EXCLUDED.name_en,
  district = EXCLUDED.district,
  bts_station = EXCLUDED.bts_station,
  property_type = EXCLUDED.property_type,
  lat = EXCLUDED.lat,
  lng = EXCLUDED.lng,
  location = EXCLUDED.location,
  aliases = EXCLUDED.aliases,
  year_built = EXCLUDED.year_built,
  facilities = EXCLUDED.facilities,
  geo_zone_id = EXCLUDED.geo_zone_id,
  updated_at = now();

INSERT INTO public.property_projects (
  slug, name_th, name_en, district, bts_station, property_type,
  lat, lng, location, aliases, year_built, facilities, geo_zone_id
)
SELECT
  'tela-thonglor',
  'เทล่า ทองหล่อ',
  'Tela Thonglor',
  'วัฒนา',
  'BTS ทองหล่อ',
  'condo',
  13.7258,
  100.5778,
  ST_SetSRID(ST_MakePoint(100.5778, 13.7258), 4326)::geography,
  ARRAY['tela'],
  2014,
  ARRAY['สระว่ายน้ำ', 'ฟิตเนส', 'Co-working', 'ที่จอดรถ'],
  gz.id
FROM public.geo_zones gz
WHERE gz.slug = 'thonglor'
ON CONFLICT (slug) DO UPDATE SET
  name_th = EXCLUDED.name_th,
  name_en = EXCLUDED.name_en,
  district = EXCLUDED.district,
  bts_station = EXCLUDED.bts_station,
  property_type = EXCLUDED.property_type,
  lat = EXCLUDED.lat,
  lng = EXCLUDED.lng,
  location = EXCLUDED.location,
  aliases = EXCLUDED.aliases,
  year_built = EXCLUDED.year_built,
  facilities = EXCLUDED.facilities,
  geo_zone_id = EXCLUDED.geo_zone_id,
  updated_at = now();

INSERT INTO public.property_projects (
  slug, name_th, name_en, district, bts_station, property_type,
  lat, lng, location, aliases, year_built, facilities, geo_zone_id
)
SELECT
  'beatniq-sukhumvit-32',
  'บีทนิค สุขุมวิท 32',
  'Beatniq Sukhumvit 32',
  'คลองเตย',
  'BTS ทองหล่อ',
  'condo',
  13.7382,
  100.5675,
  ST_SetSRID(ST_MakePoint(100.5675, 13.7382), 4326)::geography,
  ARRAY['beatniq'],
  2021,
  ARRAY['สระว่ายน้ำ', 'ฟิตเนส', 'ที่จอดรถ', 'รปภ. 24 ชม.', 'Lobby'],
  gz.id
FROM public.geo_zones gz
WHERE gz.slug = 'thonglor'
ON CONFLICT (slug) DO UPDATE SET
  name_th = EXCLUDED.name_th,
  name_en = EXCLUDED.name_en,
  district = EXCLUDED.district,
  bts_station = EXCLUDED.bts_station,
  property_type = EXCLUDED.property_type,
  lat = EXCLUDED.lat,
  lng = EXCLUDED.lng,
  location = EXCLUDED.location,
  aliases = EXCLUDED.aliases,
  year_built = EXCLUDED.year_built,
  facilities = EXCLUDED.facilities,
  geo_zone_id = EXCLUDED.geo_zone_id,
  updated_at = now();

INSERT INTO public.property_projects (
  slug, name_th, name_en, district, bts_station, property_type,
  lat, lng, location, aliases, year_built, facilities, geo_zone_id
)
SELECT
  'ideo-q-sukhumvit-36',
  'ไอดีโอ คิว สุขุมวิท 36',
  'Ideo Q Sukhumvit 36',
  'คลองเตย',
  'BTS ทองหล่อ',
  'condo',
  13.7345,
  100.5725,
  ST_SetSRID(ST_MakePoint(100.5725, 13.7345), 4326)::geography,
  ARRAY['ideo q', 'ไอดีโอ'],
  2012,
  ARRAY['สระว่ายน้ำ', 'ฟิตเนส', 'ที่จอดรถ', 'รปภ. 24 ชม.', 'Lobby'],
  gz.id
FROM public.geo_zones gz
WHERE gz.slug = 'thonglor'
ON CONFLICT (slug) DO UPDATE SET
  name_th = EXCLUDED.name_th,
  name_en = EXCLUDED.name_en,
  district = EXCLUDED.district,
  bts_station = EXCLUDED.bts_station,
  property_type = EXCLUDED.property_type,
  lat = EXCLUDED.lat,
  lng = EXCLUDED.lng,
  location = EXCLUDED.location,
  aliases = EXCLUDED.aliases,
  year_built = EXCLUDED.year_built,
  facilities = EXCLUDED.facilities,
  geo_zone_id = EXCLUDED.geo_zone_id,
  updated_at = now();

INSERT INTO public.property_projects (
  slug, name_th, name_en, district, bts_station, property_type,
  lat, lng, location, aliases, year_built, facilities, geo_zone_id
)
SELECT
  'hyde-sukhumvit-11',
  'ไฮด์ สุขุมวิท 11',
  'Hyde Sukhumvit 11',
  'วัฒนา',
  'BTS นานา',
  'condo',
  13.7448,
  100.5562,
  ST_SetSRID(ST_MakePoint(100.5562, 13.7448), 4326)::geography,
  ARRAY['hyde 11', 'นานา', 'nana'],
  2012,
  ARRAY['สระว่ายน้ำ', 'ฟิตเนส', 'ที่จอดรถ', 'รปภ. 24 ชม.', 'Lobby'],
  gz.id
FROM public.geo_zones gz
WHERE gz.slug = 'sukhumvit'
ON CONFLICT (slug) DO UPDATE SET
  name_th = EXCLUDED.name_th,
  name_en = EXCLUDED.name_en,
  district = EXCLUDED.district,
  bts_station = EXCLUDED.bts_station,
  property_type = EXCLUDED.property_type,
  lat = EXCLUDED.lat,
  lng = EXCLUDED.lng,
  location = EXCLUDED.location,
  aliases = EXCLUDED.aliases,
  year_built = EXCLUDED.year_built,
  facilities = EXCLUDED.facilities,
  geo_zone_id = EXCLUDED.geo_zone_id,
  updated_at = now();

INSERT INTO public.property_projects (
  slug, name_th, name_en, district, bts_station, property_type,
  lat, lng, location, aliases, year_built, facilities, geo_zone_id
)
SELECT
  'the-room-sukhumvit-38',
  'เดอะ รูม สุขุมวิท 38',
  'The Room Sukhumvit 38',
  'คลองเตย',
  'BTS ทองหล่อ',
  'condo',
  13.7328,
  100.5742,
  ST_SetSRID(ST_MakePoint(100.5742, 13.7328), 4326)::geography,
  ARRAY['the room 38'],
  2016,
  ARRAY['สระว่ายน้ำ', 'ฟิตเนส', 'ที่จอดรถ', 'รปภ. 24 ชม.', 'Lobby'],
  gz.id
FROM public.geo_zones gz
WHERE gz.slug = 'thonglor'
ON CONFLICT (slug) DO UPDATE SET
  name_th = EXCLUDED.name_th,
  name_en = EXCLUDED.name_en,
  district = EXCLUDED.district,
  bts_station = EXCLUDED.bts_station,
  property_type = EXCLUDED.property_type,
  lat = EXCLUDED.lat,
  lng = EXCLUDED.lng,
  location = EXCLUDED.location,
  aliases = EXCLUDED.aliases,
  year_built = EXCLUDED.year_built,
  facilities = EXCLUDED.facilities,
  geo_zone_id = EXCLUDED.geo_zone_id,
  updated_at = now();

INSERT INTO public.property_projects (
  slug, name_th, name_en, district, bts_station, property_type,
  lat, lng, location, aliases, year_built, facilities, geo_zone_id
)
SELECT
  'aspire-sukhumvit-48',
  'แอสไพร์ สุขุมวิท 48',
  'Aspire Sukhumvit 48',
  'คลองเตย',
  'BTS พร้อมพงษ์',
  'condo',
  13.7285,
  100.5788,
  ST_SetSRID(ST_MakePoint(100.5788, 13.7285), 4326)::geography,
  ARRAY['aspire 48', 'พร้อมพงษ์'],
  2016,
  ARRAY['สระว่ายน้ำ', 'ฟิตเนส', 'ที่จอดรถ', 'รปภ. 24 ชม.', 'Lobby'],
  gz.id
FROM public.geo_zones gz
WHERE gz.slug = 'sukhumvit'
ON CONFLICT (slug) DO UPDATE SET
  name_th = EXCLUDED.name_th,
  name_en = EXCLUDED.name_en,
  district = EXCLUDED.district,
  bts_station = EXCLUDED.bts_station,
  property_type = EXCLUDED.property_type,
  lat = EXCLUDED.lat,
  lng = EXCLUDED.lng,
  location = EXCLUDED.location,
  aliases = EXCLUDED.aliases,
  year_built = EXCLUDED.year_built,
  facilities = EXCLUDED.facilities,
  geo_zone_id = EXCLUDED.geo_zone_id,
  updated_at = now();

INSERT INTO public.property_projects (
  slug, name_th, name_en, district, bts_station, property_type,
  lat, lng, location, aliases, year_built, facilities, geo_zone_id
)
SELECT
  'lumpini-place-rama9',
  'ลุมพินี เพลส พระราม 9',
  'Lumpini Place Rama 9',
  'ห้วยขวาง',
  'MRT พระราม 9',
  'condo',
  13.7585,
  100.5652,
  ST_SetSRID(ST_MakePoint(100.5652, 13.7585), 4326)::geography,
  ARRAY['ลุมพินี พระราม 9', 'rama 9'],
  2019,
  ARRAY['สระว่ายน้ำ', 'ฟิตเนส', 'ที่จอดรถ', 'รปภ. 24 ชม.', 'Lobby'],
  gz.id
FROM public.geo_zones gz
WHERE gz.slug = 'bangkok-all'
ON CONFLICT (slug) DO UPDATE SET
  name_th = EXCLUDED.name_th,
  name_en = EXCLUDED.name_en,
  district = EXCLUDED.district,
  bts_station = EXCLUDED.bts_station,
  property_type = EXCLUDED.property_type,
  lat = EXCLUDED.lat,
  lng = EXCLUDED.lng,
  location = EXCLUDED.location,
  aliases = EXCLUDED.aliases,
  year_built = EXCLUDED.year_built,
  facilities = EXCLUDED.facilities,
  geo_zone_id = EXCLUDED.geo_zone_id,
  updated_at = now();

INSERT INTO public.property_projects (
  slug, name_th, name_en, district, bts_station, property_type,
  lat, lng, location, aliases, year_built, facilities, geo_zone_id
)
SELECT
  'siamese-exclusive-queens',
  'ไซมิส เอ็กซ์คลูซีฟ ควีนส์',
  'Siamese Exclusive Queens',
  'คลองเตย',
  'BTS ทองหล่อ',
  'condo',
  13.7315,
  100.5765,
  ST_SetSRID(ST_MakePoint(100.5765, 13.7315), 4326)::geography,
  ARRAY['siamese queens'],
  2013,
  ARRAY['สระว่ายน้ำ', 'ฟิตเนส', 'ที่จอดรถ', 'รปภ. 24 ชม.', 'Lobby'],
  gz.id
FROM public.geo_zones gz
WHERE gz.slug = 'thonglor'
ON CONFLICT (slug) DO UPDATE SET
  name_th = EXCLUDED.name_th,
  name_en = EXCLUDED.name_en,
  district = EXCLUDED.district,
  bts_station = EXCLUDED.bts_station,
  property_type = EXCLUDED.property_type,
  lat = EXCLUDED.lat,
  lng = EXCLUDED.lng,
  location = EXCLUDED.location,
  aliases = EXCLUDED.aliases,
  year_built = EXCLUDED.year_built,
  facilities = EXCLUDED.facilities,
  geo_zone_id = EXCLUDED.geo_zone_id,
  updated_at = now();

INSERT INTO public.property_projects (
  slug, name_th, name_en, district, bts_station, property_type,
  lat, lng, location, aliases, year_built, facilities, geo_zone_id
)
SELECT
  'the-tree-sukhumvit-71',
  'เดอะ ทรี สุขุมวิท 71',
  'The Tree Sukhumvit 71',
  'วัฒนา',
  'BTS บางจาก',
  'condo',
  13.6985,
  100.6012,
  ST_SetSRID(ST_MakePoint(100.6012, 13.6985), 4326)::geography,
  ARRAY['the tree 71'],
  2014,
  ARRAY['สระว่ายน้ำ', 'ฟิตเนส', 'ที่จอดรถ', 'รปภ. 24 ชม.', 'Lobby'],
  gz.id
FROM public.geo_zones gz
WHERE gz.slug = 'sukhumvit'
ON CONFLICT (slug) DO UPDATE SET
  name_th = EXCLUDED.name_th,
  name_en = EXCLUDED.name_en,
  district = EXCLUDED.district,
  bts_station = EXCLUDED.bts_station,
  property_type = EXCLUDED.property_type,
  lat = EXCLUDED.lat,
  lng = EXCLUDED.lng,
  location = EXCLUDED.location,
  aliases = EXCLUDED.aliases,
  year_built = EXCLUDED.year_built,
  facilities = EXCLUDED.facilities,
  geo_zone_id = EXCLUDED.geo_zone_id,
  updated_at = now();

INSERT INTO public.property_projects (
  slug, name_th, name_en, district, bts_station, property_type,
  lat, lng, location, aliases, year_built, facilities, geo_zone_id
)
SELECT
  'u-delight-bangna',
  'ยู ดีไลท์ บางนา',
  'U Delight Bangna',
  'บางนา',
  'BTS บางนา',
  'condo',
  13.6702,
  100.6045,
  ST_SetSRID(ST_MakePoint(100.6045, 13.6702), 4326)::geography,
  ARRAY['u delight', 'บางนา', 'bangna'],
  2012,
  ARRAY['สระว่ายน้ำ', 'ฟิตเนส', 'ที่จอดรถ', 'รปภ. 24 ชม.', 'Lobby'],
  gz.id
FROM public.geo_zones gz
WHERE gz.slug = 'samut-prakan'
ON CONFLICT (slug) DO UPDATE SET
  name_th = EXCLUDED.name_th,
  name_en = EXCLUDED.name_en,
  district = EXCLUDED.district,
  bts_station = EXCLUDED.bts_station,
  property_type = EXCLUDED.property_type,
  lat = EXCLUDED.lat,
  lng = EXCLUDED.lng,
  location = EXCLUDED.location,
  aliases = EXCLUDED.aliases,
  year_built = EXCLUDED.year_built,
  facilities = EXCLUDED.facilities,
  geo_zone_id = EXCLUDED.geo_zone_id,
  updated_at = now();

INSERT INTO public.property_projects (
  slug, name_th, name_en, district, bts_station, property_type,
  lat, lng, location, aliases, year_built, facilities, geo_zone_id
)
SELECT
  'the-key-wutthakat',
  'เดอะ คีย์ BTS วุฒากาศ',
  'The Key BTS Wutthakat',
  'บางบอน',
  'BTS วุฒากาศ',
  'condo',
  13.6635,
  100.5452,
  ST_SetSRID(ST_MakePoint(100.5452, 13.6635), 4326)::geography,
  ARRAY['the key wutthakat'],
  2014,
  ARRAY['สระว่ายน้ำ', 'ฟิตเนส', 'ที่จอดรถ', 'รปภ. 24 ชม.', 'Lobby'],
  gz.id
FROM public.geo_zones gz
WHERE gz.slug = 'bangkok-all'
ON CONFLICT (slug) DO UPDATE SET
  name_th = EXCLUDED.name_th,
  name_en = EXCLUDED.name_en,
  district = EXCLUDED.district,
  bts_station = EXCLUDED.bts_station,
  property_type = EXCLUDED.property_type,
  lat = EXCLUDED.lat,
  lng = EXCLUDED.lng,
  location = EXCLUDED.location,
  aliases = EXCLUDED.aliases,
  year_built = EXCLUDED.year_built,
  facilities = EXCLUDED.facilities,
  geo_zone_id = EXCLUDED.geo_zone_id,
  updated_at = now();

INSERT INTO public.property_projects (
  slug, name_th, name_en, district, bts_station, property_type,
  lat, lng, location, aliases, year_built, facilities, geo_zone_id
)
SELECT
  'ideo-mobi-sukhumvit-81',
  'ไอดีโอ โมบิ สุขุมวิท 81',
  'Ideo Mobi Sukhumvit 81',
  'บางนา',
  'BTS บางจาก',
  'condo',
  13.6855,
  100.6095,
  ST_SetSRID(ST_MakePoint(100.6095, 13.6855), 4326)::geography,
  ARRAY['ideo mobi 81'],
  2012,
  ARRAY['สระว่ายน้ำ', 'ฟิตเนส', 'ที่จอดรถ', 'รปภ. 24 ชม.', 'Lobby'],
  gz.id
FROM public.geo_zones gz
WHERE gz.slug = 'samut-prakan'
ON CONFLICT (slug) DO UPDATE SET
  name_th = EXCLUDED.name_th,
  name_en = EXCLUDED.name_en,
  district = EXCLUDED.district,
  bts_station = EXCLUDED.bts_station,
  property_type = EXCLUDED.property_type,
  lat = EXCLUDED.lat,
  lng = EXCLUDED.lng,
  location = EXCLUDED.location,
  aliases = EXCLUDED.aliases,
  year_built = EXCLUDED.year_built,
  facilities = EXCLUDED.facilities,
  geo_zone_id = EXCLUDED.geo_zone_id,
  updated_at = now();

INSERT INTO public.property_projects (
  slug, name_th, name_en, district, bts_station, property_type,
  lat, lng, location, aliases, year_built, facilities, geo_zone_id
)
SELECT
  'the-address-asoke',
  'ดิ แอดเดรส อโศก',
  'The Address Asoke',
  'วัฒนา',
  'BTS อโศก',
  'condo',
  13.7378,
  100.5625,
  ST_SetSRID(ST_MakePoint(100.5625, 13.7378), 4326)::geography,
  ARRAY['address asoke', 'แอดเดรส'],
  2018,
  ARRAY['สระว่ายน้ำ', 'ฟิตเนส', 'Sky garden', 'ที่จอดรถ', 'Lobby'],
  gz.id
FROM public.geo_zones gz
WHERE gz.slug = 'asok'
ON CONFLICT (slug) DO UPDATE SET
  name_th = EXCLUDED.name_th,
  name_en = EXCLUDED.name_en,
  district = EXCLUDED.district,
  bts_station = EXCLUDED.bts_station,
  property_type = EXCLUDED.property_type,
  lat = EXCLUDED.lat,
  lng = EXCLUDED.lng,
  location = EXCLUDED.location,
  aliases = EXCLUDED.aliases,
  year_built = EXCLUDED.year_built,
  facilities = EXCLUDED.facilities,
  geo_zone_id = EXCLUDED.geo_zone_id,
  updated_at = now();

INSERT INTO public.property_projects (
  slug, name_th, name_en, district, bts_station, property_type,
  lat, lng, location, aliases, year_built, facilities, geo_zone_id
)
SELECT
  'm-neighborhood-ari',
  'เอ็ม นีโบฮู้ด อารีย์',
  'M Neighborhood Ari',
  'พญาไท',
  'BTS อารีย์',
  'condo',
  13.7795,
  100.5448,
  ST_SetSRID(ST_MakePoint(100.5448, 13.7795), 4326)::geography,
  ARRAY['ari', 'อารีย์', 'm neighborhood'],
  2012,
  ARRAY['สระว่ายน้ำ', 'ฟิตเนส', 'ที่จอดรถ', 'รปภ. 24 ชม.', 'Lobby'],
  gz.id
FROM public.geo_zones gz
WHERE gz.slug = 'bangkok-all'
ON CONFLICT (slug) DO UPDATE SET
  name_th = EXCLUDED.name_th,
  name_en = EXCLUDED.name_en,
  district = EXCLUDED.district,
  bts_station = EXCLUDED.bts_station,
  property_type = EXCLUDED.property_type,
  lat = EXCLUDED.lat,
  lng = EXCLUDED.lng,
  location = EXCLUDED.location,
  aliases = EXCLUDED.aliases,
  year_built = EXCLUDED.year_built,
  facilities = EXCLUDED.facilities,
  geo_zone_id = EXCLUDED.geo_zone_id,
  updated_at = now();

INSERT INTO public.property_projects (
  slug, name_th, name_en, district, bts_station, property_type,
  lat, lng, location, aliases, year_built, facilities, geo_zone_id
)
SELECT
  'villa-bangna-townhome',
  'วิลล่า บางนา',
  'Villa Bangna Townhome',
  'บางนา',
  'BTS บางนา',
  'townhome',
  13.6688,
  100.6068,
  ST_SetSRID(ST_MakePoint(100.6068, 13.6688), 4326)::geography,
  ARRAY['วิลล่า บางนา'],
  2012,
  ARRAY['สระว่ายน้ำ', 'ฟิตเนส', 'ที่จอดรถ', 'รปภ. 24 ชม.', 'Lobby'],
  gz.id
FROM public.geo_zones gz
WHERE gz.slug = 'samut-prakan'
ON CONFLICT (slug) DO UPDATE SET
  name_th = EXCLUDED.name_th,
  name_en = EXCLUDED.name_en,
  district = EXCLUDED.district,
  bts_station = EXCLUDED.bts_station,
  property_type = EXCLUDED.property_type,
  lat = EXCLUDED.lat,
  lng = EXCLUDED.lng,
  location = EXCLUDED.location,
  aliases = EXCLUDED.aliases,
  year_built = EXCLUDED.year_built,
  facilities = EXCLUDED.facilities,
  geo_zone_id = EXCLUDED.geo_zone_id,
  updated_at = now();

INSERT INTO public.property_projects (
  slug, name_th, name_en, district, bts_station, property_type,
  lat, lng, location, aliases, year_built, facilities, geo_zone_id
)
SELECT
  'sansiri-house-onnut',
  'บ้านเดี่ยว อ่อนนุช',
  'Detached House On Nut',
  'สวนหลวง',
  'BTS อ่อนนุช',
  'house',
  13.7055,
  100.6285,
  ST_SetSRID(ST_MakePoint(100.6285, 13.7055), 4326)::geography,
  ARRAY['บ้าน', 'onnut', 'อ่อนนุช'],
  2015,
  ARRAY['สระว่ายน้ำ', 'ฟิตเนส', 'ที่จอดรถ', 'รปภ. 24 ชม.', 'Lobby'],
  gz.id
FROM public.geo_zones gz
WHERE gz.slug = 'samut-prakan'
ON CONFLICT (slug) DO UPDATE SET
  name_th = EXCLUDED.name_th,
  name_en = EXCLUDED.name_en,
  district = EXCLUDED.district,
  bts_station = EXCLUDED.bts_station,
  property_type = EXCLUDED.property_type,
  lat = EXCLUDED.lat,
  lng = EXCLUDED.lng,
  location = EXCLUDED.location,
  aliases = EXCLUDED.aliases,
  year_built = EXCLUDED.year_built,
  facilities = EXCLUDED.facilities,
  geo_zone_id = EXCLUDED.geo_zone_id,
  updated_at = now();


-- Link existing listings by Thai project name
UPDATE public.listings l
SET project_id = p.id,
    geo_zone_id = COALESCE(l.geo_zone_id, p.geo_zone_id)
FROM public.property_projects p
WHERE l.project_id IS NULL
  AND l.project_name IS NOT NULL
  AND l.project_name = p.name_th;
