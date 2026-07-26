-- Fix import-captures storage RLS (use objects.name — avoids Storage 503 DatabaseInvalidObjectDefinition)

DROP POLICY IF EXISTS import_captures_storage_select ON storage.objects;
DROP POLICY IF EXISTS import_captures_storage_insert ON storage.objects;
DROP POLICY IF EXISTS import_captures_storage_delete ON storage.objects;

CREATE POLICY import_captures_storage_select ON storage.objects
  FOR SELECT TO authenticated
  USING (
    bucket_id = 'import-captures'
    AND (
      public.is_admin()
      OR (storage.foldername(objects.name))[1] = auth.uid()::text
    )
  );

CREATE POLICY import_captures_storage_insert ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (
    bucket_id = 'import-captures'
    AND (
      public.is_admin()
      OR (storage.foldername(objects.name))[1] = auth.uid()::text
    )
  );

CREATE POLICY import_captures_storage_delete ON storage.objects
  FOR DELETE TO authenticated
  USING (
    bucket_id = 'import-captures'
    AND (
      public.is_admin()
      OR (storage.foldername(objects.name))[1] = auth.uid()::text
    )
  );
