-- RealXtate Smart Search Engine
-- PostgreSQL + PostGIS (geo) + pgvector (semantic, optional)
-- รองรับ Hybrid Search: Hard SQL filters + Radius + Soft ranking

-- ---------------------------------------------------------------------------
-- Extensions (pg_trgm ต้องมาก่อน GIN trgm index)
-- ---------------------------------------------------------------------------
CREATE EXTENSION IF NOT EXISTS vector;
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- ---------------------------------------------------------------------------
-- 1) Cache พิกัดจาก Google Maps — ลด quota และ latency (Data imputation layer)
--    ใช้เมื่อ geo_zones / property_projects ไม่มีข้อมูลครบ
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.search_location_cache (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  query_normalized text NOT NULL,
  location_type text NOT NULL CHECK (
    location_type IN ('neighborhood', 'transit_station', 'project_name', 'district', 'other')
  ),
  raw_text text NOT NULL,
  display_name text,
  formatted_address text,
  lat double precision NOT NULL,
  lng double precision NOT NULL,
  location geography(POINT, 4326),
  place_id text,
  source text NOT NULL DEFAULT 'google_places',
  hit_count int NOT NULL DEFAULT 1,
  created_at timestamptz NOT NULL DEFAULT now(),
  last_used_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT search_location_cache_coords CHECK (
    lat BETWEEN 5 AND 21 AND lng BETWEEN 97 AND 106
  )
);

CREATE UNIQUE INDEX IF NOT EXISTS search_location_cache_query_type_uidx
  ON public.search_location_cache (query_normalized, location_type);

CREATE INDEX IF NOT EXISTS search_location_cache_location_gix
  ON public.search_location_cache USING GIST (location);

CREATE INDEX IF NOT EXISTS search_location_cache_place_id_idx
  ON public.search_location_cache (place_id)
  WHERE place_id IS NOT NULL;

COMMENT ON TABLE public.search_location_cache IS
  'Cache ผล Google Places/Geocoding — เติมพิกัดเมื่อ catalog ภายในไม่ครบ';

-- ---------------------------------------------------------------------------
-- 2) สถานีรถไฟฟ้า — ขยายจาก static list ใน Edge Functions
--    ยังไม่ครบทุกสาย แต่ใช้ radius search ได้โดยตรงจาก DB
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.transit_stations (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  slug text NOT NULL UNIQUE,
  system text NOT NULL,
  name_th text NOT NULL,
  name_en text NOT NULL,
  lat double precision NOT NULL,
  lng double precision NOT NULL,
  location geography(POINT, 4326) NOT NULL,
  geo_zone_id uuid REFERENCES public.geo_zones (id),
  aliases text[] NOT NULL DEFAULT '{}',
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS transit_stations_location_gix
  ON public.transit_stations USING GIST (location);

CREATE INDEX IF NOT EXISTS transit_stations_name_th_trgm_idx
  ON public.transit_stations USING GIN (name_th gin_trgm_ops);

CREATE INDEX IF NOT EXISTS transit_stations_name_en_trgm_idx
  ON public.transit_stations USING GIN (name_en gin_trgm_ops);

-- Seed BTS/MRT หลัก (subset — ที่เหลือ enrich ผ่าน Google ได้)
INSERT INTO public.transit_stations (slug, system, name_th, name_en, lat, lng, location, aliases)
VALUES
  ('bts-asok', 'BTS', 'อโศก', 'Asok', 13.7373, 100.5606,
   ST_SetSRID(ST_MakePoint(100.5606, 13.7373), 4326)::geography, ARRAY['BTS อโศก', 'asoke']),
  ('bts-thong-lo', 'BTS', 'ทองหล่อ', 'Thong Lo', 13.7242, 100.5784,
   ST_SetSRID(ST_MakePoint(100.5784, 13.7242), 4326)::geography, ARRAY['BTS ทองหล่อ', 'thonglor']),
  ('bts-ekkamai', 'BTS', 'เอกมัย', 'Ekkamai', 13.7195, 100.5851,
   ST_SetSRID(ST_MakePoint(100.5851, 13.7195), 4326)::geography, ARRAY['BTS เอกมัย']),
  ('bts-phrom-phong', 'BTS', 'พร้อมพงษ์', 'Phrom Phong', 13.7305, 100.5693,
   ST_SetSRID(ST_MakePoint(100.5693, 13.7305), 4326)::geography, ARRAY['BTS พร้อมพงษ์']),
  ('bts-nana', 'BTS', 'นานา', 'Nana', 13.7405, 100.5553,
   ST_SetSRID(ST_MakePoint(100.5553, 13.7405), 4326)::geography, ARRAY['BTS นานา']),
  ('bts-bang-na', 'BTS', 'บางนา', 'Bang Na', 13.6687, 100.6018,
   ST_SetSRID(ST_MakePoint(100.6018, 13.6687), 4326)::geography, ARRAY['BTS บางนา', 'bangna']),
  ('bts-ari', 'BTS', 'อารีย์', 'Ari', 13.7797, 100.5448,
   ST_SetSRID(ST_MakePoint(100.5448, 13.7797), 4326)::geography, ARRAY['BTS อารีย์']),
  ('mrt-sukhumvit', 'MRT', 'สุขุมวิท', 'Sukhumvit', 13.7386, 100.5613,
   ST_SetSRID(ST_MakePoint(100.5613, 13.7386), 4326)::geography, ARRAY['MRT สุขุมวิท']),
  ('mrt-phra-ram-9', 'MRT', 'พระราม 9', 'Phra Ram 9', 13.7587, 100.5650,
   ST_SetSRID(ST_MakePoint(100.5650, 13.7587), 4326)::geography, ARRAY['MRT พระราม 9', 'rama 9'])
ON CONFLICT (slug) DO UPDATE SET
  name_th = EXCLUDED.name_th,
  name_en = EXCLUDED.name_en,
  lat = EXCLUDED.lat,
  lng = EXCLUDED.lng,
  location = EXCLUDED.location,
  aliases = EXCLUDED.aliases;

ALTER TABLE public.transit_stations ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS transit_stations_read ON public.transit_stations;
CREATE POLICY transit_stations_read ON public.transit_stations
  FOR SELECT TO authenticated, anon
  USING (is_active = true);

-- ---------------------------------------------------------------------------
-- 3) pgvector — embedding ประกาศ (optional semantic re-rank)
--    backfill แยกต่างหาก; ค้นหายังทำงานได้แม้ไม่มี embedding
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.listing_search_embeddings (
  listing_id uuid PRIMARY KEY REFERENCES public.listings (id) ON DELETE CASCADE,
  content_hash text NOT NULL,
  embedding vector(1536) NOT NULL,
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- สร้าง index หลัง backfill embedding ครั้งแรก:
-- CREATE INDEX listing_search_embeddings_hnsw_idx
--   ON public.listing_search_embeddings USING hnsw (embedding vector_cosine_ops);

COMMENT ON TABLE public.listing_search_embeddings IS
  'OpenAI text-embedding-3-small — ใช้ semantic boost เมื่อมี soft constraint ที่ไม่ map เป็น column';

-- ---------------------------------------------------------------------------
-- 4) RPC: Hybrid geo + hard filter + soft ranking
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.smart_search_listings(
  p_property_type text DEFAULT NULL,
  p_listing_type text DEFAULT NULL,
  p_price_min numeric DEFAULT NULL,
  p_price_max numeric DEFAULT NULL,
  p_bedrooms int DEFAULT NULL,
  p_center_lat double precision DEFAULT NULL,
  p_center_lng double precision DEFAULT NULL,
  p_radius_km double precision DEFAULT 3.0,
  p_geo_zone_slugs text[] DEFAULT NULL,
  p_project_slug text DEFAULT NULL,
  p_investor_category text DEFAULT NULL,
  p_min_yield numeric DEFAULT NULL,
  p_pet_allowed boolean DEFAULT NULL,
  p_co_agent_eligible boolean DEFAULT NULL,
  p_soft_constraints text[] DEFAULT NULL,
  p_query_embedding vector(1536) DEFAULT NULL,
  p_limit int DEFAULT 50,
  p_offset int DEFAULT 0
)
RETURNS TABLE (
  id uuid,
  listing_code text,
  listing_type text,
  property_type text,
  title text,
  price_net numeric,
  price_sale_net numeric,
  bedrooms int,
  yield_percent numeric,
  investor_category text,
  project_name text,
  project_slug text,
  district text,
  geo_zone_slug text,
  lat double precision,
  lng double precision,
  distance_km double precision,
  rank_score double precision,
  semantic_score double precision
)
LANGUAGE plpgsql
STABLE
SECURITY INVOKER
SET search_path = public
AS $$
DECLARE
  v_center geography;
  v_radius_m double precision;
BEGIN
  IF p_center_lat IS NOT NULL AND p_center_lng IS NOT NULL THEN
    v_center := ST_SetSRID(ST_MakePoint(p_center_lng, p_center_lat), 4326)::geography;
    v_radius_m := GREATEST(COALESCE(p_radius_km, 3.0), 0.1) * 1000.0;
  END IF;

  RETURN QUERY
  WITH base AS (
    SELECT
      lp.*,
      CASE
        WHEN v_center IS NOT NULL AND lp.location_public IS NOT NULL THEN
          ST_Distance(lp.location_public, v_center) / 1000.0
        ELSE NULL
      END AS dist_km,
      CASE
        WHEN p_query_embedding IS NOT NULL THEN
          (
            SELECT 1.0 - (lse.embedding <=> p_query_embedding)
            FROM public.listing_search_embeddings lse
            WHERE lse.listing_id = lp.id
          )
        ELSE NULL
      END AS sem_score
    FROM public.listings_public lp
    WHERE
      -- Hard filters
      (p_property_type IS NULL OR lp.property_type::text = p_property_type)
      AND (
        p_listing_type IS NULL
        OR lp.listing_type::text = p_listing_type
        OR (p_listing_type = 'rent' AND lp.listing_type::text IN ('rent', 'rent_and_sale'))
        OR (p_listing_type = 'sale' AND lp.listing_type::text IN ('sale', 'sale_installment', 'rent_and_sale'))
      )
      AND (p_price_min IS NULL OR lp.price_net >= p_price_min)
      AND (p_price_max IS NULL OR lp.price_net <= p_price_max)
      AND (p_bedrooms IS NULL OR lp.bedrooms >= p_bedrooms)
      AND (p_investor_category IS NULL OR lp.investor_category::text = p_investor_category)
      AND (p_min_yield IS NULL OR COALESCE(lp.yield_percent, 0) >= p_min_yield)
      AND (p_pet_allowed IS NULL OR lp.pet_allowed = p_pet_allowed)
      AND (p_co_agent_eligible IS NULL OR lp.co_agent_eligible = p_co_agent_eligible)
      AND (p_project_slug IS NULL OR lp.project_slug = p_project_slug)
      -- Geo: radius OR zone slug OR no geo constraint
      AND (
        v_center IS NULL
        OR lp.location_public IS NULL
        OR ST_DWithin(lp.location_public, v_center, v_radius_m)
      )
      AND (
        p_geo_zone_slugs IS NULL
        OR cardinality(p_geo_zone_slugs) = 0
        OR lp.geo_zone_slug = ANY (p_geo_zone_slugs)
        OR lp.project_geo_zone_slug = ANY (p_geo_zone_slugs)
      )
  ),
  scored AS (
    SELECT
      b.*,
      (
        -- ระยะทาง: ใกล้ = คะแนนสูง (max ~15)
        COALESCE(GREATEST(0.0, 15.0 - COALESCE(b.dist_km, 15.0)), 0.0)
        -- high_yield soft constraint
        + CASE
            WHEN p_soft_constraints IS NOT NULL
              AND 'high_yield' = ANY (p_soft_constraints) THEN
              LEAST(COALESCE(b.yield_percent, 0) * 1.5, 30.0)
            ELSE 0.0
          END
        -- below_market_value (BMV)
        + CASE
            WHEN p_soft_constraints IS NOT NULL
              AND 'below_market_value' = ANY (p_soft_constraints)
              AND b.investor_category::text = 'bmv' THEN 25.0
            ELSE 0.0
          END
        -- with_tenant
        + CASE
            WHEN p_soft_constraints IS NOT NULL
              AND 'with_tenant' = ANY (p_soft_constraints)
              AND b.investor_category::text = 'with_tenant' THEN 20.0
            ELSE 0.0
          END
        -- recency bump
        + CASE WHEN b.last_bump_at > now() - interval '7 days' THEN 3.0 ELSE 0.0 END
        -- semantic boost (optional)
        + COALESCE(b.sem_score * 20.0, 0.0)
      )::double precision AS calc_rank
    FROM base b
  )
  SELECT
    s.id,
    s.listing_code,
    s.listing_type::text,
    s.property_type::text,
    s.title,
    s.price_net,
    s.price_sale_net,
    s.bedrooms,
    s.yield_percent,
    s.investor_category::text,
    s.project_name,
    s.project_slug,
    s.district,
    s.geo_zone_slug,
    s.lat,
    s.lng,
    s.dist_km,
    s.calc_rank,
    s.sem_score
  FROM scored s
  ORDER BY s.calc_rank DESC, s.dist_km ASC NULLS LAST, s.last_bump_at DESC NULLS LAST
  LIMIT GREATEST(LEAST(COALESCE(p_limit, 50), 200), 1)
  OFFSET GREATEST(COALESCE(p_offset, 0), 0);
END;
$$;

GRANT EXECUTE ON FUNCTION public.smart_search_listings TO anon, authenticated;

COMMENT ON FUNCTION public.smart_search_listings IS
  'Hybrid search: hard SQL filters + PostGIS radius + soft investor/yield ranking';

-- ---------------------------------------------------------------------------
-- 5) Autocomplete helpers — ค้นหาใน catalog ภายใน (ไม่ต้อง Google)
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.smart_search_autocomplete_local(
  p_query text,
  p_limit int DEFAULT 10
)
RETURNS TABLE (
  kind text,
  title text,
  subtitle text,
  slug text,
  lat double precision,
  lng double precision,
  source text
)
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = public
AS $$
  WITH q AS (
    SELECT trim(lower(p_query)) AS term
  ),
  guard AS (
    SELECT length((SELECT term FROM q)) >= 1 AS ok
  ),
  projects AS (
    SELECT
      'project'::text AS kind,
      pp.name_th AS title,
      COALESCE(pp.bts_station, pp.district) AS subtitle,
      pp.slug,
      pp.lat,
      pp.lng,
      'catalog'::text AS source,
      similarity(lower(pp.name_th), (SELECT term FROM q)) AS sim
    FROM public.property_projects pp, q, guard
    WHERE guard.ok
      AND pp.is_active
      AND (
        lower(pp.name_th) LIKE '%' || q.term || '%'
        OR lower(pp.name_en) LIKE '%' || q.term || '%'
        OR q.term = ANY (SELECT lower(a) FROM unnest(pp.aliases) AS a)
      )
    ORDER BY sim DESC
    LIMIT LEAST(p_limit, 20)
  ),
  zones AS (
    SELECT
      'neighborhood'::text AS kind,
      gz.name_th AS title,
      COALESCE(gz.name_en, gz.zone_type) AS subtitle,
      gz.slug,
      ST_Y(gz.center::geometry)::double precision AS lat,
      ST_X(gz.center::geometry)::double precision AS lng,
      'geo_zone'::text AS source,
      0.5::real AS sim
    FROM public.geo_zones gz, q, guard
    WHERE guard.ok
      AND gz.is_active
      AND gz.center IS NOT NULL
      AND (
        lower(gz.name_th) LIKE '%' || q.term || '%'
        OR lower(COALESCE(gz.name_en, '')) LIKE '%' || q.term || '%'
        OR q.term = ANY (SELECT lower(a) FROM unnest(gz.aliases) AS a)
      )
    LIMIT LEAST(p_limit, 10)
  ),
  transit AS (
    SELECT
      'transit_station'::text AS kind,
      ts.system || ' ' || ts.name_th AS title,
      ts.name_en AS subtitle,
      ts.slug,
      ts.lat,
      ts.lng,
      'transit_db'::text AS source,
      similarity(lower(ts.name_th), (SELECT term FROM q)) AS sim
    FROM public.transit_stations ts, q, guard
    WHERE guard.ok
      AND ts.is_active
      AND (
        lower(ts.name_th) LIKE '%' || q.term || '%'
        OR lower(ts.name_en) LIKE '%' || q.term || '%'
        OR q.term = ANY (SELECT lower(a) FROM unnest(ts.aliases) AS a)
      )
    ORDER BY sim DESC
    LIMIT LEAST(p_limit, 10)
  )
  SELECT kind, title, subtitle, slug, lat, lng, source FROM projects
  UNION ALL
  SELECT kind, title, subtitle, slug, lat, lng, source FROM zones
  UNION ALL
  SELECT kind, title, subtitle, slug, lat, lng, source FROM transit
  LIMIT LEAST(GREATEST(p_limit, 1), 30);
$$;

GRANT EXECUTE ON FUNCTION public.smart_search_autocomplete_local TO anon, authenticated;

-- แปลง geography → lat/lng สำหรับ Edge Functions
CREATE OR REPLACE FUNCTION public.geography_to_latlng(g geography)
RETURNS TABLE(lat double precision, lng double precision)
LANGUAGE sql
IMMUTABLE
STRICT
AS $$
  SELECT
    ST_Y(g::geometry)::double precision,
    ST_X(g::geometry)::double precision;
$$;

GRANT EXECUTE ON FUNCTION public.geography_to_latlng TO anon, authenticated;

-- Auto-set location จาก lat/lng ใน cache
CREATE OR REPLACE FUNCTION public.search_location_cache_set_location()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.location := ST_SetSRID(ST_MakePoint(NEW.lng, NEW.lat), 4326)::geography;
  NEW.query_normalized := trim(lower(NEW.raw_text));
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS search_location_cache_set_location_trg
  ON public.search_location_cache;
CREATE TRIGGER search_location_cache_set_location_trg
  BEFORE INSERT OR UPDATE ON public.search_location_cache
  FOR EACH ROW
  EXECUTE FUNCTION public.search_location_cache_set_location();

-- RLS: cache เขียนได้เฉพาะ service role (Edge Functions)
ALTER TABLE public.search_location_cache ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS search_location_cache_read ON public.search_location_cache;
CREATE POLICY search_location_cache_read ON public.search_location_cache
  FOR SELECT TO authenticated, anon
  USING (true);
