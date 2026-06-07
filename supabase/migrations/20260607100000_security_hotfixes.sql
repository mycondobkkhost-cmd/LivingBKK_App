-- PROPPITER security hotfixes for posting and admin-only surfaces.

DROP POLICY IF EXISTS listings_insert ON public.listings;
CREATE POLICY listings_insert ON public.listings
  FOR INSERT TO authenticated
  WITH CHECK (
    public.is_admin()
    OR (
      created_by_id = auth.uid()
      AND owner_id = auth.uid()
    )
  );

CREATE OR REPLACE FUNCTION public.prevent_non_admin_publish()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NEW.status = 'published'
     AND OLD.status IS DISTINCT FROM NEW.status
     AND NOT public.is_admin() THEN
    RAISE EXCEPTION 'Only admins can publish listings';
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS listings_prevent_non_admin_publish ON public.listings;
CREATE TRIGGER listings_prevent_non_admin_publish
  BEFORE UPDATE OF status ON public.listings
  FOR EACH ROW
  EXECUTE FUNCTION public.prevent_non_admin_publish();

ALTER VIEW public.chat_admin_inbox SET (security_invoker = true);
