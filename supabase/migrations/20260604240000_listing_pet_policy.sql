-- นโยบายเลี้ยงสัตว์ตอนลงประกาศ

ALTER TABLE public.listings
  ADD COLUMN IF NOT EXISTS pet_policy jsonb;

COMMENT ON COLUMN public.listings.pet_policy IS
  'allowed, max_weight_kg, max_count, dogs_allowed, cats_allowed';

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
WHERE l.status = 'published'
  AND (l.expires_at IS NULL OR l.expires_at > now())
  AND (
    l.inventory_id IS NULL
    OR l.id = inv.display_listing_id
  );

GRANT SELECT ON public.listings_public TO authenticated, anon;
