-- Phase 5: listing owners can act on leads for their properties

DROP POLICY IF EXISTS leads_update ON public.leads;

CREATE POLICY leads_update ON public.leads
  FOR UPDATE TO authenticated
  USING (
    public.is_admin()
    OR assigned_to = auth.uid()
    OR EXISTS (
      SELECT 1 FROM public.listings l
      WHERE l.id = listing_id
        AND (l.owner_id = auth.uid() OR l.created_by_id = auth.uid())
    )
  )
  WITH CHECK (
    public.is_admin()
    OR assigned_to = auth.uid()
    OR EXISTS (
      SELECT 1 FROM public.listings l
      WHERE l.id = listing_id
        AND (l.owner_id = auth.uid() OR l.created_by_id = auth.uid())
    )
  );
