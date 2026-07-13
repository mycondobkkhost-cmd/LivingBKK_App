-- Fix production RLS/access edge cases found during the mobile + Supabase audit.

-- New app signups start as seeker, but the listing flow lets any signed-in
-- user post from the owner/agent perspective. Require row ownership instead
-- of a persistent profile role so real users can create their own drafts.
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

-- Never trust role metadata from client signups. Admin/viewing-staff accounts
-- are provisioned by migrations or admins, while public signups begin as seeker.
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.profiles (id, display_name, phone, role)
  VALUES (
    NEW.id,
    COALESCE(NULLIF(NEW.raw_user_meta_data ->> 'display_name', ''), NEW.email),
    NULLIF(NEW.raw_user_meta_data ->> 'phone', ''),
    'seeker'::public.user_role
  )
  ON CONFLICT (id) DO UPDATE SET
    display_name = COALESCE(public.profiles.display_name, EXCLUDED.display_name),
    phone = COALESCE(public.profiles.phone, EXCLUDED.phone);

  RETURN NEW;
END;
$$;

-- These broadly granted views sit on RLS-protected tables. security_invoker
-- keeps their existing shape while making them obey the caller's RLS policies.
ALTER VIEW IF EXISTS public.chat_admin_inbox SET (security_invoker = true);
ALTER VIEW IF EXISTS public.analytics_platform_stats SET (security_invoker = true);
ALTER VIEW IF EXISTS public.client_error_summary SET (security_invoker = true);

-- Users can upload and update their listing images, so they also need to be
-- able to remove files under their own Storage folder when replacing images.
DROP POLICY IF EXISTS listing_images_storage_delete ON storage.objects;
CREATE POLICY listing_images_storage_delete ON storage.objects
  FOR DELETE TO authenticated
  USING (
    bucket_id = 'listing-images'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );
