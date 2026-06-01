-- LivingBKK: storage buckets

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES
  ('listing-images', 'listing-images', true, 52428800,
    ARRAY['image/jpeg', 'image/png', 'image/webp']),
  ('demand-offers', 'demand-offers', false, 52428800,
    ARRAY['image/jpeg', 'image/png', 'image/webp'])
ON CONFLICT (id) DO NOTHING;

-- Listing images: public read, owner write
CREATE POLICY listing_images_storage_select ON storage.objects
  FOR SELECT TO public
  USING (bucket_id = 'listing-images');

CREATE POLICY listing_images_storage_insert ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (
    bucket_id = 'listing-images'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

CREATE POLICY listing_images_storage_update ON storage.objects
  FOR UPDATE TO authenticated
  USING (
    bucket_id = 'listing-images'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

-- Demand offers: private bucket
CREATE POLICY demand_offers_storage_select ON storage.objects
  FOR SELECT TO authenticated
  USING (
    bucket_id = 'demand-offers'
    AND (
      (storage.foldername(name))[1] = auth.uid()::text
      OR public.is_admin()
    )
  );

CREATE POLICY demand_offers_storage_insert ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (
    bucket_id = 'demand-offers'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );
