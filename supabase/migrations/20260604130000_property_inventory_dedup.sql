-- Phase 20: Property inventory — dedupe public cards, multi-agent backend, owner priority

CREATE SEQUENCE IF NOT EXISTS public.property_inventory_seq START 1;

CREATE TYPE public.inventory_availability AS ENUM (
  'available',
  'occupied',
  'withdrawn'
);

CREATE TABLE IF NOT EXISTS public.property_inventory (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  inventory_code text NOT NULL UNIQUE,
  listing_type public.listing_type NOT NULL,
  property_type public.property_type NOT NULL DEFAULT 'condo',
  project_id uuid REFERENCES public.property_projects (id),
  project_name text,
  district text,
  unit_number text,
  exact_floor int,
  area_sqm numeric(8, 2),
  match_fingerprint text NOT NULL,
  availability public.inventory_availability NOT NULL DEFAULT 'available',
  contract_occupied_until date,
  available_again date,
  display_listing_id uuid REFERENCES public.listings (id) ON DELETE SET NULL,
  primary_contact_listing_id uuid REFERENCES public.listings (id) ON DELETE SET NULL,
  owner_profile_id uuid REFERENCES public.profiles (id),
  ownership_remark text,
  member_count int NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX property_inventory_fingerprint_idx
  ON public.property_inventory (match_fingerprint, listing_type);
CREATE INDEX property_inventory_display_idx
  ON public.property_inventory (display_listing_id);

ALTER TABLE public.listings
  ADD COLUMN IF NOT EXISTS inventory_id uuid REFERENCES public.property_inventory (id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS inventory_contact_priority int NOT NULL DEFAULT 100,
  ADD COLUMN IF NOT EXISTS inventory_role_note text,
  ADD COLUMN IF NOT EXISTS inventory_linked_at timestamptz,
  ADD COLUMN IF NOT EXISTS inventory_sync_remark text;

CREATE INDEX listings_inventory_id_idx ON public.listings (inventory_id);

CREATE TABLE IF NOT EXISTS public.property_inventory_alerts (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  inventory_id uuid NOT NULL REFERENCES public.property_inventory (id) ON DELETE CASCADE,
  listing_id uuid REFERENCES public.listings (id) ON DELETE SET NULL,
  alert_type text NOT NULL,
  message text NOT NULL,
  acknowledged_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX property_inventory_alerts_open_idx
  ON public.property_inventory_alerts (inventory_id)
  WHERE acknowledged_at IS NULL;

-- ── Helpers ──

CREATE OR REPLACE FUNCTION public.generate_inventory_code()
RETURNS text
LANGUAGE plpgsql
AS $$
DECLARE
  n bigint;
BEGIN
  SELECT nextval('public.property_inventory_seq') INTO n;
  RETURN 'PPTR-' || to_char(now(), 'YYYY') || '-' || lpad(n::text, 6, '0');
END;
$$;

CREATE OR REPLACE FUNCTION public.listing_inventory_fingerprint(l public.listings)
RETURNS text
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT lower(
    coalesce(l.listing_type::text, '') || '|' ||
    coalesce(l.property_type::text, '') || '|' ||
    coalesce(l.project_id::text, '') || '|' ||
    coalesce(trim(l.project_name), '') || '|' ||
    coalesce(trim(l.unit_number), '') || '|' ||
    coalesce(l.exact_floor::text, '') || '|' ||
    coalesce(round(l.area_sqm, 1)::text, '')
  );
$$;

CREATE OR REPLACE FUNCTION public.refresh_inventory_display_listing(p_inventory_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_display uuid;
  v_primary uuid;
BEGIN
  SELECT l.id INTO v_display
  FROM public.listings l
  WHERE l.inventory_id = p_inventory_id
    AND l.status = 'published'
  ORDER BY l.inventory_contact_priority ASC, l.price_net ASC, l.last_bump_at DESC NULLS LAST
  LIMIT 1;

  IF v_display IS NULL THEN
    SELECT l.id INTO v_display
    FROM public.listings l
    WHERE l.inventory_id = p_inventory_id
    ORDER BY l.inventory_contact_priority ASC, l.created_at ASC
    LIMIT 1;
  END IF;

  SELECT l.id INTO v_primary
  FROM public.listings l
  WHERE l.inventory_id = p_inventory_id
    AND l.status IN ('published', 'hidden', 'draft')
  ORDER BY l.inventory_contact_priority ASC, l.published_at DESC NULLS LAST
  LIMIT 1;

  UPDATE public.property_inventory
  SET
    display_listing_id = v_display,
    primary_contact_listing_id = v_primary,
    member_count = (
      SELECT count(*)::int FROM public.listings WHERE inventory_id = p_inventory_id
    ),
    updated_at = now()
  WHERE id = p_inventory_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.apply_inventory_ownership_priority(p_inventory_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_owner_listing uuid;
  v_had_agent boolean;
  v_owner_profile uuid;
  v_has_owner boolean;
BEGIN
  SELECT EXISTS (
    SELECT 1 FROM public.listings
    WHERE inventory_id = p_inventory_id
      AND listed_by_role = 'agent'
      AND status IN ('published', 'hidden', 'draft', 'expired')
  ) INTO v_had_agent;

  SELECT l.id, l.owner_id INTO v_owner_listing, v_owner_profile
  FROM public.listings l
  WHERE l.inventory_id = p_inventory_id
    AND l.listed_by_role = 'owner'
  ORDER BY l.published_at DESC NULLS LAST, l.created_at DESC
  LIMIT 1;

  v_has_owner := v_owner_listing IS NOT NULL;

  UPDATE public.listings
  SET
    inventory_contact_priority = CASE
      WHEN listed_by_role = 'owner' THEN 1
      WHEN listed_by_role = 'agent' THEN 50
      ELSE 75
    END,
    inventory_role_note = CASE
      WHEN listed_by_role = 'owner' AND v_had_agent THEN 'เจ้าของตรง — ลำดับความสำคัญ 1'
      WHEN listed_by_role = 'owner' THEN 'เจ้าของตรง — ลำดับความสำคัญ 1'
      WHEN listed_by_role = 'agent' AND v_has_owner THEN 'เอเจ้นท์ — โพสต์ก่อนเจ้าของ'
      WHEN listed_by_role = 'agent' THEN 'เอเจ้นท์'
      ELSE inventory_role_note
    END
  WHERE inventory_id = p_inventory_id;

  IF v_has_owner AND v_had_agent THEN
    UPDATE public.property_inventory
    SET
      owner_profile_id = v_owner_profile,
      ownership_remark = 'เจ้าของตรง — ลำดับความสำคัญ 1 (โพสต์หลังเอเจ้นท์)',
      updated_at = now()
    WHERE id = p_inventory_id;

    INSERT INTO public.property_inventory_alerts (
      inventory_id, listing_id, alert_type, message
    )
    SELECT
      p_inventory_id,
      v_owner_listing,
      'owner_claim_after_agent',
      'เจ้าของลงประกาศทรัพย์เดียวกับเอเจ้นท์ที่โพสต์ก่อน — ตั้งลำดับติดต่อเจ้าของเป็น 1 แล้ว'
    WHERE NOT EXISTS (
      SELECT 1 FROM public.property_inventory_alerts a
      WHERE a.inventory_id = p_inventory_id
        AND a.alert_type = 'owner_claim_after_agent'
        AND a.acknowledged_at IS NULL
    );
  ELSIF v_owner_listing IS NOT NULL THEN
    UPDATE public.property_inventory
    SET
      owner_profile_id = v_owner_profile,
      ownership_remark = 'เจ้าของตรง',
      updated_at = now()
    WHERE id = p_inventory_id;
  END IF;

  PERFORM public.refresh_inventory_display_listing(p_inventory_id);
END;
$$;

CREATE OR REPLACE FUNCTION public.assign_listing_to_inventory(p_listing_id uuid)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  l public.listings%ROWTYPE;
  v_inv_id uuid;
  v_fp text;
BEGIN
  SELECT * INTO l FROM public.listings WHERE id = p_listing_id;
  IF NOT FOUND THEN
    RETURN NULL;
  END IF;

  IF l.inventory_id IS NOT NULL THEN
    PERFORM public.apply_inventory_ownership_priority(l.inventory_id);
    RETURN l.inventory_id;
  END IF;

  v_fp := public.listing_inventory_fingerprint(l);

  SELECT id INTO v_inv_id
  FROM public.property_inventory
  WHERE match_fingerprint = v_fp
    AND listing_type = l.listing_type
  LIMIT 1;

  IF v_inv_id IS NULL THEN
    INSERT INTO public.property_inventory (
      inventory_code,
      listing_type,
      property_type,
      project_id,
      project_name,
      district,
      unit_number,
      exact_floor,
      area_sqm,
      match_fingerprint,
      member_count
    ) VALUES (
      public.generate_inventory_code(),
      l.listing_type,
      l.property_type,
      l.project_id,
      l.project_name,
      l.district,
      l.unit_number,
      l.exact_floor,
      l.area_sqm,
      v_fp,
      0
    )
    RETURNING id INTO v_inv_id;
  END IF;

  UPDATE public.listings
  SET
    inventory_id = v_inv_id,
    inventory_linked_at = now(),
    inventory_sync_remark = NULL
  WHERE id = p_listing_id;

  PERFORM public.apply_inventory_ownership_priority(v_inv_id);
  RETURN v_inv_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.sync_inventory_availability_from_listing(p_listing_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  l public.listings%ROWTYPE;
  v_remark text;
BEGIN
  SELECT * INTO l FROM public.listings WHERE id = p_listing_id;
  IF NOT FOUND OR l.inventory_id IS NULL THEN
    RETURN;
  END IF;

  IF l.status IN ('hidden', 'expired') OR l.contract_occupied_until IS NOT NULL THEN
    v_remark := coalesce(
      l.closed_reason,
      'ซิงค์จากประกาศ ' || l.listing_code || ' — ไม่ว่าง/ปิดแล้ว'
    );

    UPDATE public.property_inventory
    SET
      availability = CASE
        WHEN l.available_again IS NOT NULL AND l.available_again > current_date THEN 'occupied'
        ELSE 'withdrawn'
      END,
      contract_occupied_until = l.contract_occupied_until,
      available_again = l.available_again,
      updated_at = now()
    WHERE id = l.inventory_id;

    UPDATE public.listings
    SET
      status = CASE
        WHEN status = 'published' THEN 'hidden'::public.listing_status
        ELSE status
      END,
      inventory_sync_remark = v_remark,
      updated_at = now()
    WHERE inventory_id = l.inventory_id
      AND id <> l.id
      AND status = 'published';

    PERFORM public.refresh_inventory_display_listing(l.inventory_id);
  END IF;
END;
$$;

-- ── Triggers ──

CREATE OR REPLACE FUNCTION public.trg_listings_inventory_on_publish()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NEW.status = 'published'
     AND (TG_OP = 'INSERT' OR OLD.status IS DISTINCT FROM 'published' OR NEW.inventory_id IS NULL) THEN
    PERFORM public.assign_listing_to_inventory(NEW.id);
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS listings_inventory_on_publish ON public.listings;
CREATE TRIGGER listings_inventory_on_publish
  AFTER INSERT OR UPDATE OF status, project_id, project_name, unit_number, exact_floor, area_sqm
  ON public.listings
  FOR EACH ROW
  EXECUTE FUNCTION public.trg_listings_inventory_on_publish();

CREATE OR REPLACE FUNCTION public.trg_listings_inventory_on_availability()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NEW.inventory_id IS NOT NULL
     AND (
       OLD.status IS DISTINCT FROM NEW.status
       OR OLD.contract_occupied_until IS DISTINCT FROM NEW.contract_occupied_until
       OR OLD.available_again IS DISTINCT FROM NEW.available_again
       OR OLD.closed_reason IS DISTINCT FROM NEW.closed_reason
     ) THEN
    PERFORM public.sync_inventory_availability_from_listing(NEW.id);
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS listings_inventory_on_availability ON public.listings;
CREATE TRIGGER listings_inventory_on_availability
  AFTER UPDATE OF status, contract_occupied_until, available_again, closed_reason
  ON public.listings
  FOR EACH ROW
  EXECUTE FUNCTION public.trg_listings_inventory_on_availability();

-- Backfill published listings
DO $$
DECLARE
  r record;
BEGIN
  FOR r IN
    SELECT id FROM public.listings
    WHERE status = 'published' AND inventory_id IS NULL
  LOOP
    PERFORM public.assign_listing_to_inventory(r.id);
  END LOOP;
END;
$$;

-- ── Public view: one card per inventory ──

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

COMMENT ON VIEW public.listings_public IS
  'Seeker-facing listings; at most one published row per property_inventory (display_listing_id)';

-- ── Admin views ──

CREATE OR REPLACE VIEW public.inventory_admin_roster
WITH (security_invoker = true)
AS
SELECT
  inv.id,
  inv.inventory_code,
  inv.listing_type,
  inv.property_type,
  inv.project_name,
  inv.district,
  inv.unit_number,
  inv.exact_floor,
  inv.area_sqm,
  inv.availability,
  inv.contract_occupied_until,
  inv.available_again,
  inv.ownership_remark,
  inv.member_count,
  inv.display_listing_id,
  inv.primary_contact_listing_id,
  inv.updated_at,
  dl.listing_code AS display_listing_code,
  (
    SELECT count(*)::int
    FROM public.property_inventory_alerts a
    WHERE a.inventory_id = inv.id AND a.acknowledged_at IS NULL
  ) AS open_alerts
FROM public.property_inventory inv
LEFT JOIN public.listings dl ON dl.id = inv.display_listing_id;

CREATE OR REPLACE VIEW public.inventory_admin_members
WITH (security_invoker = true)
AS
SELECT
  l.inventory_id,
  l.id AS listing_id,
  l.listing_code,
  l.status,
  l.listed_by_role,
  l.inventory_contact_priority,
  l.inventory_role_note,
  l.inventory_sync_remark,
  l.price_net,
  l.published_at,
  l.created_at,
  p.display_name AS poster_name,
  p.role AS poster_role
FROM public.listings l
LEFT JOIN public.profiles p ON p.id = l.created_by_id
WHERE l.inventory_id IS NOT NULL
ORDER BY l.inventory_contact_priority, l.published_at DESC;

-- ── Admin RPCs ──

CREATE OR REPLACE FUNCTION public.admin_set_inventory_primary_contact(
  p_inventory_id uuid,
  p_listing_id uuid
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'admin only';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM public.listings
    WHERE id = p_listing_id AND inventory_id = p_inventory_id
  ) THEN
    RAISE EXCEPTION 'listing not in inventory';
  END IF;

  UPDATE public.listings
  SET inventory_contact_priority = 1
  WHERE id = p_listing_id;

  UPDATE public.listings
  SET inventory_contact_priority = inventory_contact_priority + 10
  WHERE inventory_id = p_inventory_id AND id <> p_listing_id;

  PERFORM public.refresh_inventory_display_listing(p_inventory_id);
END;
$$;

CREATE OR REPLACE FUNCTION public.admin_ack_inventory_alert(p_alert_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'admin only';
  END IF;
  UPDATE public.property_inventory_alerts
  SET acknowledged_at = now()
  WHERE id = p_alert_id;
END;
$$;

REVOKE ALL ON FUNCTION public.admin_set_inventory_primary_contact(uuid, uuid) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.admin_ack_inventory_alert(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.admin_set_inventory_primary_contact(uuid, uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.admin_ack_inventory_alert(uuid) TO authenticated;

-- RLS
ALTER TABLE public.property_inventory ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.property_inventory_alerts ENABLE ROW LEVEL SECURITY;

CREATE POLICY property_inventory_admin ON public.property_inventory
  FOR ALL TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

CREATE POLICY property_inventory_alerts_admin ON public.property_inventory_alerts
  FOR ALL TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

GRANT SELECT ON public.inventory_admin_roster TO authenticated;
GRANT SELECT ON public.inventory_admin_members TO authenticated;
GRANT SELECT ON public.listings_public TO authenticated, anon;
