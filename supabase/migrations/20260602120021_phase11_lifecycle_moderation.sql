-- Phase 11: listing lifecycle + geo_zone_slug on public view + admin moderation helpers

CREATE OR REPLACE FUNCTION public.apply_listing_lifecycle()
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  n_expired int := 0;
  n_hidden int := 0;
BEGIN
  UPDATE public.listings
  SET status = 'expired', updated_at = now()
  WHERE status IN ('published', 'hidden')
    AND expires_at IS NOT NULL
    AND expires_at < now();
  GET DIAGNOSTICS n_expired = ROW_COUNT;

  UPDATE public.listings
  SET status = 'hidden', updated_at = now()
  WHERE status = 'published'
    AND (
      (last_bump_at IS NULL AND published_at < now() - interval '30 days')
      OR (last_bump_at IS NOT NULL AND last_bump_at < now() - interval '30 days')
    );
  GET DIAGNOSTICS n_hidden = ROW_COUNT;

  RETURN jsonb_build_object(
    'expired', n_expired,
    'hidden_stale', n_hidden,
    'ran_at', now()
  );
END;
$$;

REVOKE ALL ON FUNCTION public.apply_listing_lifecycle() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.apply_listing_lifecycle() TO service_role;

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
  l.project_name,
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
WHERE l.status = 'published'
  AND (l.expires_at IS NULL OR l.expires_at > now());
