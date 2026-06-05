-- Phase 14: LI-inspired features (no credit/boost model)

-- Customer requirements (Looking to Match)
CREATE TABLE IF NOT EXISTS public.customer_requirements (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
  transaction_type text NOT NULL CHECK (transaction_type IN ('rent', 'sale')),
  property_type text NOT NULL DEFAULT 'condo',
  zone text NOT NULL,
  max_price_net numeric(14, 2),
  min_area_sqm numeric(10, 2),
  furnishing text DEFAULT 'any',
  notes text,
  title text,
  status text NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending', 'published', 'closed', 'matched')),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_customer_requirements_user
  ON public.customer_requirements (user_id, created_at DESC);

-- Saved searches (Notify Me — free)
CREATE TABLE IF NOT EXISTS public.saved_searches (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  name text NOT NULL,
  filters jsonb NOT NULL DEFAULT '{}',
  notify_enabled boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  last_notified_at timestamptz
);

CREATE INDEX IF NOT EXISTS idx_saved_searches_user
  ON public.saved_searches (user_id, created_at DESC);

-- Agent preferred stock watchlist
CREATE TABLE IF NOT EXISTS public.agent_preferred_listings (
  agent_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  listing_id uuid NOT NULL REFERENCES public.listings(id) ON DELETE CASCADE,
  note text,
  created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (agent_id, listing_id)
);

-- Listing analytics events
CREATE TABLE IF NOT EXISTS public.listing_events (
  id bigserial PRIMARY KEY,
  listing_id uuid NOT NULL REFERENCES public.listings(id) ON DELETE CASCADE,
  event_type text NOT NULL CHECK (event_type IN ('view', 'share', 'chat_start', 'favorite')),
  user_id uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_listing_events_listing
  ON public.listing_events (listing_id, created_at DESC);

-- User favorites
CREATE TABLE IF NOT EXISTS public.user_favorites (
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  listing_id uuid NOT NULL REFERENCES public.listings(id) ON DELETE CASCADE,
  created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, listing_id)
);

-- Listing video URL (My Stock enrichment)
ALTER TABLE public.listings
  ADD COLUMN IF NOT EXISTS video_url text;

-- Image captions
ALTER TABLE public.listing_images
  ADD COLUMN IF NOT EXISTS caption text;

-- RLS (basic — owner/agent read own data)
ALTER TABLE public.customer_requirements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.saved_searches ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.agent_preferred_listings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.listing_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_favorites ENABLE ROW LEVEL SECURITY;

CREATE POLICY customer_requirements_own ON public.customer_requirements
  FOR ALL USING (auth.uid() = user_id OR public.is_admin());

CREATE POLICY saved_searches_own ON public.saved_searches
  FOR ALL USING (auth.uid() = user_id);

CREATE POLICY agent_preferred_own ON public.agent_preferred_listings
  FOR ALL USING (auth.uid() = agent_id);

CREATE POLICY user_favorites_own ON public.user_favorites
  FOR ALL USING (auth.uid() = user_id);

CREATE POLICY listing_events_insert ON public.listing_events
  FOR INSERT WITH CHECK (true);

CREATE POLICY listing_events_read ON public.listing_events
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.listings l
      WHERE l.id = listing_id
        AND (l.owner_id = auth.uid() OR l.created_by_id = auth.uid() OR public.is_admin())
    )
  );
