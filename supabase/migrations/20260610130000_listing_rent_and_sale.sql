-- ประกาศเช่า+ขายในครั้งเดียว — ปรากฏทั้งแท็บเช่าและซื้อ

ALTER TYPE public.listing_type ADD VALUE IF NOT EXISTS 'rent_and_sale';

ALTER TABLE public.listings
  ADD COLUMN IF NOT EXISTS price_sale_net numeric(12, 2);

COMMENT ON COLUMN public.listings.price_sale_net IS
  'ราคาขาย Net — ใช้เมื่อ listing_type = rent_and_sale (price_net = เช่า)';

ALTER TABLE public.listings
  DROP CONSTRAINT IF EXISTS listings_price_sale_net_positive;

ALTER TABLE public.listings
  ADD CONSTRAINT listings_price_sale_net_positive CHECK (
    price_sale_net IS NULL OR price_sale_net > 0
  );

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
  l.price_sale_net,
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
LEFT JOIN public.property_projects pp ON pp.id = l.project_id
LEFT JOIN public.geo_zones gz ON gz.id = l.geo_zone_id
LEFT JOIN public.geo_zones gz_pp ON gz_pp.id = pp.geo_zone_id
WHERE l.status = 'published'
  AND l.display_contact_clean = true
  AND (l.expires_at IS NULL OR l.expires_at > now())
  AND (
    l.inventory_id IS NULL
    OR l.id = inv.display_listing_id
  );

GRANT SELECT ON public.listings_public TO anon, authenticated;
