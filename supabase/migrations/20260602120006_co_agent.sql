-- LivingBKK: co-agent requests

CREATE TABLE public.co_agent_requests (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  listing_id uuid NOT NULL REFERENCES public.listings (id) ON DELETE CASCADE,
  requesting_agent_id uuid NOT NULL REFERENCES public.profiles (id),
  status public.co_agent_request_status NOT NULL DEFAULT 'pending',
  message text,
  reviewed_by uuid REFERENCES public.profiles (id),
  reviewed_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX co_agent_requests_listing_idx ON public.co_agent_requests (listing_id);
CREATE INDEX co_agent_requests_agent_idx ON public.co_agent_requests (requesting_agent_id);

-- One pending request per agent per listing
CREATE UNIQUE INDEX co_agent_requests_pending_unique
  ON public.co_agent_requests (listing_id, requesting_agent_id)
  WHERE status = 'pending';
