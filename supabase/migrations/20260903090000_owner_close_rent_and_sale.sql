-- ปิดประกาศเช่า+ขาย: RPC เดิมกรองแค่ rent หรือ sale/sale_installment
-- ทำให้ปุ่มปิดในประกาศของฉัน / ดูแลทรัพย์ error "Listing not found or not allowed"

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
    AND listing_type IN (
      'rent'::public.listing_type,
      'rent_and_sale'::public.listing_type
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
      'sale_installment'::public.listing_type,
      'rent_and_sale'::public.listing_type
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
