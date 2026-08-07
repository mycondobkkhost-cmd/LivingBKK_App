-- Fix public browse + harden ops surfaces that break real users / admin chat.

-- ── 1) Public-safe inventory projection (bypasses invoker RLS) ──
-- listings_public uses security_invoker; property_inventory is admin-only.
-- Joining the base table therefore hides every inventory-linked listing for seekers.

CREATE OR REPLACE VIEW public.property_inventory_public
WITH (security_invoker = false)
AS
SELECT
  id,
  inventory_code,
  member_count,
  display_listing_id
FROM public.property_inventory;

COMMENT ON VIEW public.property_inventory_public IS
  'Public-safe inventory fields for listings_public (no unit/owner internals)';

GRANT SELECT ON public.property_inventory_public TO anon, authenticated;

-- ── 2) Repair listings_public ──
-- Replaces broken refs (inventory_members / listing_images.is_public) and
-- joins the public inventory projection so display_listing_id filter works for everyone.

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
  l.price_internal,
  l.price_sale_net,
  l.price_sale_promo_net,
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
LEFT JOIN public.property_inventory_public inv ON inv.id = l.inventory_id
LEFT JOIN public.property_projects pp ON pp.id = l.project_id
LEFT JOIN public.geo_zones gz ON gz.id = l.geo_zone_id
LEFT JOIN public.geo_zones gz_pp ON gz_pp.id = pp.geo_zone_id
WHERE l.status = 'published'
  AND l.display_contact_clean IS NOT FALSE
  AND (l.expires_at IS NULL OR l.expires_at > now())
  AND (
    l.inventory_id IS NULL
    OR l.id = inv.display_listing_id
  );

COMMENT ON VIEW public.listings_public IS
  'Seeker-facing listings; one published card per inventory via public projection';

GRANT SELECT ON public.listings_public TO anon, authenticated;

-- ── 3) Stop owners from rewriting chat ops fields (blocks admin claim) ──

CREATE OR REPLACE FUNCTION public.chat_threads_protect_ops_fields()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  -- Only lock when an authenticated non-admin user is writing.
  -- service_role / triggers with null uid remain free to update.
  IF auth.uid() IS NOT NULL AND NOT public.is_admin() THEN
    NEW.assigned_admin_id := OLD.assigned_admin_id;
    NEW.assigned_at := OLD.assigned_at;
    NEW.status := OLD.status;
    NEW.priority := OLD.priority;
    NEW.category := OLD.category;
    NEW.admin_escalated := OLD.admin_escalated;
    NEW.admin_reply_done := OLD.admin_reply_done;
    NEW.unclear_streak := OLD.unclear_streak;
    NEW.admin_display_name := OLD.admin_display_name;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS chat_threads_protect_ops ON public.chat_threads;
CREATE TRIGGER chat_threads_protect_ops
  BEFORE UPDATE ON public.chat_threads
  FOR EACH ROW
  EXECUTE FUNCTION public.chat_threads_protect_ops_fields();

-- ── 4) Listing/offer daily counters: block direct client DML ──

CREATE OR REPLACE FUNCTION public.next_pir_listing_code()
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  d date := public.bangkok_today();
  seq int;
  dd text;
BEGIN
  INSERT INTO public.listing_code_daily_seq (stat_date, n)
  VALUES (d, 1)
  ON CONFLICT (stat_date) DO UPDATE
    SET n = public.listing_code_daily_seq.n + 1
  RETURNING n INTO seq;

  IF seq > 9999 THEN
    RAISE EXCEPTION 'Daily PIR listing code limit (9999) exceeded for %', d;
  END IF;

  dd := to_char(d, 'DDMMYY');
  RETURN 'PIR' || dd || '-' || lpad(seq::text, 4, '0');
END;
$$;

CREATE OR REPLACE FUNCTION public.next_offer_code()
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  d date := public.bangkok_today();
  seq int;
  dd text;
BEGIN
  INSERT INTO public.offer_code_daily_seq (stat_date, n)
  VALUES (d, 1)
  ON CONFLICT (stat_date) DO UPDATE
    SET n = public.offer_code_daily_seq.n + 1
  RETURNING n INTO seq;

  IF seq > 9999 THEN
    RAISE EXCEPTION 'Daily offer code limit (9999) exceeded for %', d;
  END IF;

  dd := to_char(d, 'DDMMYY');
  RETURN 'OFR' || dd || '-' || lpad(seq::text, 4, '0');
END;
$$;

ALTER TABLE public.listing_code_daily_seq ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.offer_code_daily_seq ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON TABLE public.listing_code_daily_seq FROM PUBLIC, anon, authenticated;
REVOKE ALL ON TABLE public.offer_code_daily_seq FROM PUBLIC, anon, authenticated;

-- ── 5) Cron / inventory helpers: not callable by arbitrary clients ──

REVOKE ALL ON FUNCTION public.process_exclusive_auto_bumps() FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.process_exclusive_auto_bumps() TO service_role;

REVOKE ALL ON FUNCTION public.refresh_inventory_display_listing(uuid) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.apply_inventory_ownership_priority(uuid) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.assign_listing_to_inventory(uuid) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.sync_inventory_availability_from_listing(uuid) FROM PUBLIC, anon, authenticated;

GRANT EXECUTE ON FUNCTION public.refresh_inventory_display_listing(uuid) TO service_role;
GRANT EXECUTE ON FUNCTION public.apply_inventory_ownership_priority(uuid) TO service_role;
GRANT EXECUTE ON FUNCTION public.assign_listing_to_inventory(uuid) TO service_role;
GRANT EXECUTE ON FUNCTION public.sync_inventory_availability_from_listing(uuid) TO service_role;
