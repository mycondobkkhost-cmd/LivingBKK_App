-- Listing lifecycle: 7-day bump reminders (FCM via cron) + 30-day archive + owner close/soft-delete

ALTER TYPE public.listing_status ADD VALUE IF NOT EXISTS 'archived';

ALTER TABLE public.listings
  ADD COLUMN IF NOT EXISTS owner_deleted_at timestamptz,
  ADD COLUMN IF NOT EXISTS closed_at timestamptz,
  ADD COLUMN IF NOT EXISTS closed_reason text,
  ADD COLUMN IF NOT EXISTS reuse_blocked boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS last_reminder_at timestamptz;

COMMENT ON COLUMN public.listings.reuse_blocked IS
  'Sale closed by owner — data kept but listing must not be republished as same unit';
COMMENT ON COLUMN public.listings.owner_deleted_at IS
  'Owner hid from My Listings — row retained for platform records';

CREATE OR REPLACE FUNCTION public.apply_listing_lifecycle()
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  n_expired int := 0;
  n_archived int := 0;
BEGIN
  UPDATE public.listings
  SET status = 'expired', updated_at = now()
  WHERE status IN ('published', 'hidden')
    AND owner_deleted_at IS NULL
    AND expires_at IS NOT NULL
    AND expires_at < now();
  GET DIAGNOSTICS n_expired = ROW_COUNT;

  UPDATE public.listings
  SET
    status = 'archived',
    closed_at = now(),
    closed_reason = 'stale_30d',
    updated_at = now()
  WHERE status = 'published'
    AND owner_deleted_at IS NULL
    AND (
      (last_bump_at IS NULL AND published_at < now() - interval '30 days')
      OR (last_bump_at IS NOT NULL AND last_bump_at < now() - interval '30 days')
    );
  GET DIAGNOSTICS n_archived = ROW_COUNT;

  RETURN jsonb_build_object(
    'expired', n_expired,
    'archived_stale', n_archived,
    'ran_at', now()
  );
END;
$$;

-- Owner: ปิดประกาศเช่า — ระบุวันว่างอีกครั้ง แล้วเก็บเข้าคลัง
CREATE OR REPLACE FUNCTION public.owner_close_listing_rent(
  p_listing_id uuid,
  p_available_again date
)
RETURNS public.listings
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  row public.listings;
BEGIN
  IF p_available_again IS NULL THEN
    RAISE EXCEPTION 'available_again required';
  END IF;

  UPDATE public.listings
  SET
    status = 'archived',
    closed_at = now(),
    closed_reason = 'owner_closed_rent',
    available_again = p_available_again,
    updated_at = now()
  WHERE id = p_listing_id
    AND listing_type = 'rent'::public.listing_type
    AND status IN ('published'::public.listing_status, 'hidden'::public.listing_status)
    AND owner_deleted_at IS NULL
    AND (owner_id = auth.uid() OR created_by_id = auth.uid())
  RETURNING * INTO row;

  IF row.id IS NULL THEN
    RAISE EXCEPTION 'Listing not found or not allowed';
  END IF;

  RETURN row;
END;
$$;

-- Owner: ปิดการขาย — ไม่นำกลับมาใช้ใหม่ (ข้อมูลยังอยู่ใน DB)
CREATE OR REPLACE FUNCTION public.owner_close_listing_sale(p_listing_id uuid)
RETURNS public.listings
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  row public.listings;
BEGIN
  UPDATE public.listings
  SET
    status = 'archived',
    closed_at = now(),
    closed_reason = 'owner_closed_sale',
    reuse_blocked = true,
    updated_at = now()
  WHERE id = p_listing_id
    AND listing_type = 'sale'::public.listing_type
    AND status IN ('published'::public.listing_status, 'hidden'::public.listing_status)
    AND owner_deleted_at IS NULL
    AND (owner_id = auth.uid() OR created_by_id = auth.uid())
  RETURNING * INTO row;

  IF row.id IS NULL THEN
    RAISE EXCEPTION 'Listing not found or not allowed';
  END IF;

  RETURN row;
END;
$$;

-- Owner: ลบจากมุมมองตัวเอง (soft delete) — เฉพาะที่ archived แล้ว
CREATE OR REPLACE FUNCTION public.owner_soft_delete_listing(p_listing_id uuid)
RETURNS public.listings
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  row public.listings;
BEGIN
  UPDATE public.listings
  SET owner_deleted_at = now(), updated_at = now()
  WHERE id = p_listing_id
    AND status = 'archived'::public.listing_status
    AND owner_deleted_at IS NULL
    AND (owner_id = auth.uid() OR created_by_id = auth.uid())
  RETURNING * INTO row;

  IF row.id IS NULL THEN
    RAISE EXCEPTION 'Listing not found or not archived';
  END IF;

  RETURN row;
END;
$$;

REVOKE ALL ON FUNCTION public.owner_close_listing_rent(uuid, date) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.owner_close_listing_sale(uuid) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.owner_soft_delete_listing(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.owner_close_listing_rent(uuid, date) TO authenticated;
GRANT EXECUTE ON FUNCTION public.owner_close_listing_sale(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.owner_soft_delete_listing(uuid) TO authenticated;

CREATE INDEX IF NOT EXISTS listings_bump_reminder_idx
  ON public.listings (status, last_bump_at, published_at)
  WHERE status = 'published' AND owner_deleted_at IS NULL;
