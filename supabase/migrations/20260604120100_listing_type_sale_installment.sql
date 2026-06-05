-- ขายฝาก (ไม่ใช้ เซ้ง / ขายดาวน์)

ALTER TYPE public.listing_type ADD VALUE IF NOT EXISTS 'sale_installment';

-- ปิดการขาย/ขายฝาก ใช้ flow เดียวกับขาย
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
    AND listing_type IN (
      'sale'::public.listing_type,
      'sale_installment'::public.listing_type
    )
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
