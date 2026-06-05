-- Phase 18: LI link import queue (admin)

CREATE TYPE public.listing_import_status AS ENUM (
  'queued',
  'fetching',
  'draft_ready',
  'needs_fix',
  'approved',
  'archived',
  'failed'
);

CREATE TABLE public.listing_imports (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  source_url text NOT NULL,
  source_platform text NOT NULL DEFAULT 'livinginsider',
  source_external_id text,
  status public.listing_import_status NOT NULL DEFAULT 'queued',
  error_message text,
  title_preview text,
  project_preview text,
  price_preview numeric(12, 2),
  image_count int NOT NULL DEFAULT 0,
  listing_id uuid REFERENCES public.listings (id) ON DELETE SET NULL,
  raw_payload jsonb NOT NULL DEFAULT '{}'::jsonb,
  parsed jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_by uuid NOT NULL REFERENCES public.profiles (id),
  reviewed_by uuid REFERENCES public.profiles (id),
  reviewed_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX listing_imports_source_url_uidx
  ON public.listing_imports (source_url)
  WHERE status NOT IN ('archived', 'failed');

CREATE UNIQUE INDEX listing_imports_li_web_id_uidx
  ON public.listing_imports (source_external_id)
  WHERE source_external_id IS NOT NULL
    AND status NOT IN ('archived', 'failed');

CREATE INDEX listing_imports_status_idx
  ON public.listing_imports (status, created_at DESC);

CREATE INDEX listing_imports_listing_idx
  ON public.listing_imports (listing_id);

CREATE TRIGGER listing_imports_updated_at
  BEFORE UPDATE ON public.listing_imports
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at();

ALTER TABLE public.listings
  ADD COLUMN IF NOT EXISTS source_platform text,
  ADD COLUMN IF NOT EXISTS source_url text,
  ADD COLUMN IF NOT EXISTS source_external_id text;

CREATE INDEX listings_source_external_idx
  ON public.listings (source_external_id)
  WHERE source_external_id IS NOT NULL;

ALTER TABLE public.listing_imports ENABLE ROW LEVEL SECURITY;

CREATE POLICY listing_imports_admin_all ON public.listing_imports
  FOR ALL TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

ALTER PUBLICATION supabase_realtime ADD TABLE public.listing_imports;
