-- Phase: manual capture import (Facebook screenshot + paste + AI draft)

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES
  ('import-captures', 'import-captures', false, 52428800,
    ARRAY['image/jpeg', 'image/png', 'image/webp'])
ON CONFLICT (id) DO NOTHING;

-- Admin-only evidence screenshots (not listing photos)
CREATE POLICY import_captures_storage_select ON storage.objects
  FOR SELECT TO authenticated
  USING (
    bucket_id = 'import-captures'
    AND (
      (storage.foldername(name))[1] = auth.uid()::text
      OR public.is_admin()
    )
  );

CREATE POLICY import_captures_storage_insert ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (
    bucket_id = 'import-captures'
    AND (
      (storage.foldername(name))[1] = auth.uid()::text
      OR public.is_admin()
    )
  );

CREATE POLICY import_captures_storage_delete ON storage.objects
  FOR DELETE TO authenticated
  USING (
    bucket_id = 'import-captures'
    AND (
      (storage.foldername(name))[1] = auth.uid()::text
      OR public.is_admin()
    )
  );

COMMENT ON COLUMN public.listing_imports.raw_payload IS
  'Includes capture {source_text_original, post_url, owner_profile_url, evidence_images}, ai_draft, contact_private';
