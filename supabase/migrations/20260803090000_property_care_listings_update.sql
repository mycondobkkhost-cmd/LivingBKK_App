-- Allow active property-care caretakers to update listings they care for.
-- Without this, customer/co-agent caretakers hit listings_update RLS, the
-- client update affects 0 rows, and the UI still reported success.

CREATE OR REPLACE FUNCTION public.has_property_care_listing_edit(p_listing_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.listings l
    JOIN public.property_care_rights r
      ON r.status = 'active'
     AND r.user_id = auth.uid()
     AND r.care_role IN (
       'primary_caretaker',
       'customer_caretaker',
       'co_agent_caretaker',
       'team_steward'
     )
     AND (
       (r.listing_id IS NOT NULL AND r.listing_id = l.id)
       OR (r.inventory_id IS NOT NULL AND r.inventory_id = l.inventory_id)
     )
    WHERE l.id = p_listing_id
  );
$$;

REVOKE ALL ON FUNCTION public.has_property_care_listing_edit(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.has_property_care_listing_edit(uuid) TO authenticated;

DROP POLICY IF EXISTS listings_update ON public.listings;

CREATE POLICY listings_update ON public.listings
  FOR UPDATE TO authenticated
  USING (
    public.is_admin()
    OR owner_id = auth.uid()
    OR created_by_id = auth.uid()
    OR public.has_property_care_listing_edit(id)
  )
  WITH CHECK (
    public.is_admin()
    OR owner_id = auth.uid()
    OR created_by_id = auth.uid()
    OR public.has_property_care_listing_edit(id)
  );

COMMENT ON FUNCTION public.has_property_care_listing_edit(uuid) IS
  'True when the current user has an active property-care right on the listing or its inventory';
