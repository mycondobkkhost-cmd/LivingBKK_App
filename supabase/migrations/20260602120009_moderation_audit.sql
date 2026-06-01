-- LivingBKK: moderation and audit

CREATE TABLE public.moderation_flags (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  listing_id uuid REFERENCES public.listings (id) ON DELETE CASCADE,
  demand_offer_id uuid REFERENCES public.demand_offers (id) ON DELETE CASCADE,
  flag_type public.moderation_flag_type NOT NULL,
  raw_match text,
  resolved_at timestamptz,
  resolved_by uuid REFERENCES public.profiles (id),
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE public.admin_audit_log (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  actor_id uuid REFERENCES public.profiles (id),
  action text NOT NULL,
  entity_type text NOT NULL,
  entity_id uuid,
  payload jsonb DEFAULT '{}',
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX admin_audit_log_created_idx ON public.admin_audit_log (created_at DESC);

-- Stats view for Make.com / admin (no PII)
CREATE OR REPLACE VIEW public.lead_stats_daily AS
SELECT
  date_trunc('day', l.created_at)::date AS stat_date,
  count(*) AS lead_count,
  count(*) FILTER (WHERE l.status = 'accepted') AS accepted_count,
  count(*) FILTER (WHERE l.status = 'new') AS new_count
FROM public.leads l
GROUP BY 1;
