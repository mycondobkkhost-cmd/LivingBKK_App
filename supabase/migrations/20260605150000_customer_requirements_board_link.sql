-- Link customer requirements (front-office) → demand board posts (admin publish)

ALTER TABLE public.customer_requirements
  ADD COLUMN IF NOT EXISTS min_price_net numeric(14, 2),
  ADD COLUMN IF NOT EXISTS requester_role text NOT NULL DEFAULT 'direct',
  ADD COLUMN IF NOT EXISTS urgent_rush boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS payload jsonb NOT NULL DEFAULT '{}'::jsonb,
  ADD COLUMN IF NOT EXISTS demand_post_id uuid REFERENCES public.demand_posts (id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_customer_requirements_pending
  ON public.customer_requirements (status, created_at DESC)
  WHERE status = 'pending';
