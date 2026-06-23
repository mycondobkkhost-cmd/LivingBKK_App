-- Fix production auth/listing/chat risks found during QA.

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  requested_role text := NEW.raw_user_meta_data ->> 'role';
BEGIN
  INSERT INTO public.profiles (id, display_name, role)
  VALUES (
    NEW.id,
    COALESCE(NULLIF(NEW.raw_user_meta_data ->> 'display_name', ''), NEW.email),
    CASE
      WHEN requested_role IN ('seeker', 'owner', 'agent') THEN requested_role::public.user_role
      ELSE 'seeker'::public.user_role
    END
  );
  RETURN NEW;
END;
$$;

DROP POLICY IF EXISTS listings_insert ON public.listings;
CREATE POLICY listings_insert ON public.listings
  FOR INSERT TO authenticated
  WITH CHECK (
    public.is_admin()
    OR (
      owner_id = auth.uid()
      AND created_by_id = auth.uid()
    )
  );

ALTER VIEW public.chat_admin_inbox SET (security_invoker = true);
