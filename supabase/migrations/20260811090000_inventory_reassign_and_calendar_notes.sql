-- 1) Inventory fingerprint: empty unit+floor must not merge distinct listings
-- 2) Re-assign when identity fields change on an already-linked published listing
-- 3) Owner/seeker calendar updates may only touch their notes columns

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
    coalesce(round(l.area_sqm, 1)::text, '') ||
    CASE
      WHEN nullif(trim(coalesce(l.unit_number, '')), '') IS NULL
           AND l.exact_floor IS NULL
      THEN '|' || l.id::text
      ELSE ''
    END
  );
$$;

COMMENT ON FUNCTION public.listing_inventory_fingerprint(public.listings) IS
  'Match key for RXT inventory; incomplete identity (no unit/floor) stays listing-unique';

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
  v_old_inv uuid;
  v_old_fp text;
BEGIN
  SELECT * INTO l FROM public.listings WHERE id = p_listing_id;
  IF NOT FOUND THEN
    RETURN NULL;
  END IF;

  v_fp := public.listing_inventory_fingerprint(l);

  IF l.inventory_id IS NOT NULL THEN
    SELECT match_fingerprint INTO v_old_fp
    FROM public.property_inventory
    WHERE id = l.inventory_id;

    IF v_old_fp IS NOT DISTINCT FROM v_fp THEN
      PERFORM public.apply_inventory_ownership_priority(l.inventory_id);
      RETURN l.inventory_id;
    END IF;

    -- Identity changed: unlink, refresh old inventory, then re-match below.
    v_old_inv := l.inventory_id;
    UPDATE public.listings
    SET
      inventory_id = NULL,
      inventory_linked_at = NULL,
      updated_at = now()
    WHERE id = p_listing_id;

    PERFORM public.refresh_inventory_display_listing(v_old_inv);

    SELECT * INTO l FROM public.listings WHERE id = p_listing_id;
    v_fp := public.listing_inventory_fingerprint(l);
  END IF;

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

CREATE OR REPLACE FUNCTION public.trg_listings_inventory_on_publish()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NEW.status = 'published'
     AND (
       TG_OP = 'INSERT'
       OR OLD.status IS DISTINCT FROM 'published'
       OR NEW.inventory_id IS NULL
       OR OLD.project_id IS DISTINCT FROM NEW.project_id
       OR OLD.project_name IS DISTINCT FROM NEW.project_name
       OR OLD.unit_number IS DISTINCT FROM NEW.unit_number
       OR OLD.exact_floor IS DISTINCT FROM NEW.exact_floor
       OR OLD.area_sqm IS DISTINCT FROM NEW.area_sqm
       OR OLD.listing_type IS DISTINCT FROM NEW.listing_type
       OR OLD.property_type IS DISTINCT FROM NEW.property_type
     ) THEN
    PERFORM public.assign_listing_to_inventory(NEW.id);
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS listings_inventory_on_publish ON public.listings;
CREATE TRIGGER listings_inventory_on_publish
  AFTER INSERT OR UPDATE OF
    status, project_id, project_name, unit_number, exact_floor, area_sqm,
    listing_type, property_type
  ON public.listings
  FOR EACH ROW
  EXECUTE FUNCTION public.trg_listings_inventory_on_publish();

-- Calendar: owner/seeker policies are named for notes but allow full-row UPDATE.
CREATE OR REPLACE FUNCTION public.calendar_events_restrict_party_updates()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
  v_owner_notes text;
  v_seeker_notes text;
BEGIN
  IF auth.uid() IS NULL OR public.is_admin() THEN
    RETURN NEW;
  END IF;

  -- Assigned staff keep full update rights under their policy.
  IF OLD.assigned_to IS NOT NULL AND OLD.assigned_to = auth.uid() THEN
    RETURN NEW;
  END IF;

  IF auth.uid() = OLD.owner_user_id OR auth.uid() = OLD.seeker_user_id THEN
    v_owner_notes := NEW.owner_notes;
    v_seeker_notes := NEW.seeker_notes;
    NEW := OLD;
    IF auth.uid() = OLD.owner_user_id THEN
      NEW.owner_notes := v_owner_notes;
    END IF;
    IF auth.uid() = OLD.seeker_user_id THEN
      NEW.seeker_notes := v_seeker_notes;
    END IF;
    NEW.updated_at := now();
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS calendar_events_restrict_party_updates ON public.calendar_events;
CREATE TRIGGER calendar_events_restrict_party_updates
  BEFORE UPDATE ON public.calendar_events
  FOR EACH ROW
  EXECUTE FUNCTION public.calendar_events_restrict_party_updates();
