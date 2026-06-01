-- LivingBKK: listing images

CREATE TABLE public.listing_images (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  listing_id uuid NOT NULL REFERENCES public.listings (id) ON DELETE CASCADE,
  storage_path text NOT NULL,
  public_url text,
  sort_order int NOT NULL DEFAULT 0,
  perceptual_hash text,
  moderation_status public.moderation_status NOT NULL DEFAULT 'pending',
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX listing_images_listing_idx ON public.listing_images (listing_id);
