-- ชั้นข้อความประกาศ: ดิบ (เจ้าของ) vs แสดงผล (หน้าบ้าน) — เบอร์/ไลน์ไม่ขึ้นหน้าบ้าน

ALTER TABLE public.listings
  ADD COLUMN IF NOT EXISTS title_owner text,
  ADD COLUMN IF NOT EXISTS description_owner text,
  ADD COLUMN IF NOT EXISTS title_display text,
  ADD COLUMN IF NOT EXISTS description_display text,
  ADD COLUMN IF NOT EXISTS display_contact_clean boolean NOT NULL DEFAULT true,
  ADD COLUMN IF NOT EXISTS display_moderation_flags jsonb NOT NULL DEFAULT '[]'::jsonb,
  ADD COLUMN IF NOT EXISTS owner_data_status text NOT NULL DEFAULT 'not_required'
    CHECK (owner_data_status IN ('not_required', 'pending', 'complete'));

COMMENT ON COLUMN public.listings.title_owner IS
  'หัวข้อต้นฉบับจากเจ้าของ/เอเจนต์/นำเข้า — หลังบ้าน';
COMMENT ON COLUMN public.listings.description_owner IS
  'รายละเอียดดิบ — หลังบ้าน (อาจมีเบอร์/ไลน์ ย้ายไป vault ตอน sync)';
COMMENT ON COLUMN public.listings.title_display IS
  'หัวข้อที่ลูกค้าเห็น — ไม่มีข้อมูลติดต่อ';
COMMENT ON COLUMN public.listings.description_display IS
  'รายละเอียดที่ลูกค้าเห็น — ปรับจากดิบ/AI';
COMMENT ON COLUMN public.listings.display_contact_clean IS
  'false = มีเบอร์/ไลน์/ลิงก์ในข้อความแสดงผล — ห้ามเผยแพร่จนกว่าจะ sync';
COMMENT ON COLUMN public.listings.owner_data_status IS
  'not_required | pending (รอเจ้าของเติม) | complete';

-- ย้ายข้อมูลเดิม → ชั้นดิบ + แสดงผล
UPDATE public.listings
SET
  title_owner = COALESCE(NULLIF(trim(title_owner), ''), title),
  description_owner = COALESCE(NULLIF(trim(description_owner), ''), description_public),
  title_display = COALESCE(NULLIF(trim(title_display), ''), title),
  description_display = COALESCE(NULLIF(trim(description_display), ''), description_public)
WHERE title IS NOT NULL;

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
  COALESCE(NULLIF(trim(l.title_display), ''), NULLIF(trim(l.title_owner), ''), l.title) AS title,
  COALESCE(
    NULLIF(trim(l.description_display), ''),
    NULLIF(trim(l.description_owner), ''),
    l.description_public
  ) AS description,
  l.price_net,
  l.co_agent_listing_type,
  l.investor_category,
  l.yield_percent,
  l.monthly_rent_for_yield,
  l.pet_allowed,
  l.pet_policy,
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
  pp.nearby_transit AS project_nearby_transit,
  pp.search_tag_slugs AS project_search_tags,
  l.geo_zone_id,
  gz.slug AS geo_zone_slug,
  COALESCE(gz.slug, gz_pp.slug) AS project_geo_zone_slug,
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
  l.occupancy_status,
  l.viewing_allowed_during,
  l.last_bump_at,
  l.published_at,
  l.created_at,
  l.updated_at,
  l.owner_exclusive_mandate,
  l.owner_exclusive_contract_days,
  l.agent_exclusive,
  inv.inventory_code,
  inv.id AS inventory_id,
  inv.member_count AS inventory_member_count,
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
LEFT JOIN public.property_inventory inv ON inv.id = l.inventory_id
LEFT JOIN public.geo_zones gz ON gz.id = l.geo_zone_id
LEFT JOIN public.property_projects pp ON pp.id = l.project_id
LEFT JOIN public.geo_zones gz_pp ON gz_pp.id = pp.geo_zone_id
WHERE l.status = 'published'
  AND l.display_contact_clean = true
  AND (l.expires_at IS NULL OR l.expires_at > now())
  AND (
    l.inventory_id IS NULL
    OR l.id = inv.display_listing_id
  );

COMMENT ON VIEW public.listings_public IS
  'หน้าบ้าน — title/description จากชั้นแสดงผลเท่านั้น · ไม่โชว์ถ้า display_contact_clean=false';

GRANT SELECT ON public.listings_public TO authenticated, anon;
