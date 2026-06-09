-- แท็กมาตรฐานสำหรับค้นหา (slug ตรง SearchZoneCatalog) + สถานะ enrich

ALTER TABLE public.property_projects
  ADD COLUMN IF NOT EXISTS search_tag_slugs text[] NOT NULL DEFAULT '{}',
  ADD COLUMN IF NOT EXISTS tag_enrich_status text NOT NULL DEFAULT 'pending',
  ADD COLUMN IF NOT EXISTS tag_enrich_meta jsonb NOT NULL DEFAULT '{}';

CREATE INDEX IF NOT EXISTS property_projects_search_tag_slugs_idx
  ON public.property_projects USING GIN (search_tag_slugs);

CREATE INDEX IF NOT EXISTS property_projects_tag_enrich_status_idx
  ON public.property_projects (tag_enrich_status);

COMMENT ON COLUMN public.property_projects.search_tag_slugs IS
  'Catalog entry ids: transit-*, geo zone slugs, edu-*, landmark-* — ใช้ค้นหาประกาศผ่าน project';
COMMENT ON COLUMN public.property_projects.tag_enrich_status IS
  'auto_ok | needs_review | missing_coords | pending';
COMMENT ON COLUMN public.property_projects.tag_enrich_meta IS
  'sources, distances_m, mismatches — audit ไม่ใช้ AI';

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
  AND (l.expires_at IS NULL OR l.expires_at > now())
  AND (
    l.inventory_id IS NULL
    OR l.id = inv.display_listing_id
  );

GRANT SELECT ON public.listings_public TO authenticated, anon;
