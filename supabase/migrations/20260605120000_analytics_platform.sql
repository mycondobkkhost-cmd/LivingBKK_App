-- Phase 21: Analytics platform — events + rollups (scale to 100k+ users)
-- หลักการ: append-only events → pre-aggregate rollups → admin/owner อ่าน rollups เท่านั้น

CREATE TYPE public.analytics_event_type AS ENUM (
  'listing_impression',
  'listing_view',
  'listing_share',
  'map_marker_tap',
  'search_performed',
  'chat_start',
  'chat_escalated',
  'chat_claimed',
  'chat_resolved'
);

CREATE TABLE public.analytics_events (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  event_type public.analytics_event_type NOT NULL,
  occurred_at timestamptz NOT NULL DEFAULT now(),
  stat_date date NOT NULL DEFAULT ((now() AT TIME ZONE 'Asia/Bangkok')::date),
  listing_id uuid REFERENCES public.listings (id) ON DELETE SET NULL,
  owner_id uuid REFERENCES public.profiles (id) ON DELETE SET NULL,
  actor_id uuid REFERENCES public.profiles (id) ON DELETE SET NULL,
  district text,
  geo_zone_slug text,
  listing_type text,
  property_type text,
  source text,
  session_hash text,
  metadata jsonb NOT NULL DEFAULT '{}',
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX analytics_events_stat_date_idx ON public.analytics_events (stat_date DESC);
CREATE INDEX analytics_events_type_date_idx ON public.analytics_events (event_type, stat_date DESC);
CREATE INDEX analytics_events_listing_date_idx ON public.analytics_events (listing_id, stat_date DESC)
  WHERE listing_id IS NOT NULL;
CREATE INDEX analytics_events_occurred_brin_idx ON public.analytics_events
  USING BRIN (occurred_at);

COMMENT ON TABLE public.analytics_events IS
  'Append-only product events — no phone/email; roll up via refresh_analytics_rollups()';

-- ── Daily rollups (fast reads for admin / owner) ──

CREATE TABLE public.analytics_platform_daily (
  stat_date date PRIMARY KEY,
  listing_impressions bigint NOT NULL DEFAULT 0,
  listing_views bigint NOT NULL DEFAULT 0,
  listing_shares bigint NOT NULL DEFAULT 0,
  map_marker_taps bigint NOT NULL DEFAULT 0,
  searches bigint NOT NULL DEFAULT 0,
  chat_starts bigint NOT NULL DEFAULT 0,
  chat_escalations bigint NOT NULL DEFAULT 0,
  chat_claimed bigint NOT NULL DEFAULT 0,
  chat_resolved bigint NOT NULL DEFAULT 0,
  chat_sla_breaches bigint NOT NULL DEFAULT 0,
  chat_avg_claim_minutes numeric(10, 2),
  leads_created bigint NOT NULL DEFAULT 0,
  leads_new bigint NOT NULL DEFAULT 0,
  leads_accepted bigint NOT NULL DEFAULT 0,
  leads_declined bigint NOT NULL DEFAULT 0,
  e_contracts_signed bigint NOT NULL DEFAULT 0,
  appointments_created bigint NOT NULL DEFAULT 0,
  appointments_confirmed bigint NOT NULL DEFAULT 0,
  appointments_completed bigint NOT NULL DEFAULT 0,
  appointments_cancelled bigint NOT NULL DEFAULT 0,
  listings_published bigint NOT NULL DEFAULT 0,
  listings_archived bigint NOT NULL DEFAULT 0,
  new_users bigint NOT NULL DEFAULT 0,
  demand_posts_opened bigint NOT NULL DEFAULT 0,
  offers_submitted bigint NOT NULL DEFAULT 0,
  deals_closed bigint NOT NULL DEFAULT 0,
  gmv_closed numeric(14, 2) NOT NULL DEFAULT 0,
  refreshed_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE public.analytics_district_daily (
  stat_date date NOT NULL,
  district text NOT NULL,
  listing_views bigint NOT NULL DEFAULT 0,
  leads_created bigint NOT NULL DEFAULT 0,
  appointments_created bigint NOT NULL DEFAULT 0,
  PRIMARY KEY (stat_date, district)
);

CREATE INDEX analytics_district_daily_district_idx
  ON public.analytics_district_daily (district, stat_date DESC);

CREATE TABLE public.analytics_listing_daily (
  stat_date date NOT NULL,
  listing_id uuid NOT NULL REFERENCES public.listings (id) ON DELETE CASCADE,
  owner_id uuid REFERENCES public.profiles (id) ON DELETE SET NULL,
  listing_code text,
  views bigint NOT NULL DEFAULT 0,
  shares bigint NOT NULL DEFAULT 0,
  chat_starts bigint NOT NULL DEFAULT 0,
  leads_created bigint NOT NULL DEFAULT 0,
  PRIMARY KEY (stat_date, listing_id)
);

CREATE INDEX analytics_listing_daily_owner_idx
  ON public.analytics_listing_daily (owner_id, stat_date DESC);

CREATE TABLE public.analytics_chat_daily (
  stat_date date NOT NULL,
  category text NOT NULL DEFAULT 'other',
  volume bigint NOT NULL DEFAULT 0,
  claimed bigint NOT NULL DEFAULT 0,
  resolved bigint NOT NULL DEFAULT 0,
  sla_breaches bigint NOT NULL DEFAULT 0,
  avg_claim_minutes numeric(10, 2),
  PRIMARY KEY (stat_date, category)
);

-- ── Refresh rollups from events + OLTP (SECURITY DEFINER — cron / admin) ──

CREATE OR REPLACE FUNCTION public.refresh_analytics_rollups(
  p_from date DEFAULT ((now() AT TIME ZONE 'Asia/Bangkok')::date - 30),
  p_to date DEFAULT ((now() AT TIME ZONE 'Asia/Bangkok')::date)
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_days int;
BEGIN
  IF NOT public.is_admin() AND current_setting('role', true) IS DISTINCT FROM 'service_role' THEN
    RAISE EXCEPTION 'admin only';
  END IF;

  IF p_from > p_to THEN
    RAISE EXCEPTION 'p_from must be <= p_to';
  END IF;

  v_days := (p_to - p_from) + 1;

  INSERT INTO analytics_platform_daily (
    stat_date,
    listing_impressions, listing_views, listing_shares, map_marker_taps, searches,
    chat_starts, chat_escalations, chat_claimed, chat_resolved,
    leads_created, leads_new, leads_accepted, leads_declined,
    e_contracts_signed,
    appointments_created, appointments_confirmed, appointments_completed, appointments_cancelled,
    listings_published, listings_archived, new_users,
    demand_posts_opened, offers_submitted,
    deals_closed, gmv_closed,
    refreshed_at
  )
  SELECT
    d.stat_date,
    coalesce(ev.listing_impressions, 0),
    coalesce(ev.listing_views, 0),
    coalesce(ev.listing_shares, 0),
    coalesce(ev.map_marker_taps, 0),
    coalesce(ev.searches, 0),
    coalesce(ev.chat_starts, 0),
    coalesce(ev.chat_escalations, 0),
    coalesce(ev.chat_claimed, 0),
    coalesce(ev.chat_resolved, 0),
    coalesce(ch.sla_breaches, 0),
    ch.avg_claim_minutes,
    coalesce(lg.leads_created, 0),
    coalesce(lg.leads_new, 0),
    coalesce(lg.leads_accepted, 0),
    coalesce(lg.leads_declined, 0),
    coalesce(ec.e_contracts_signed, 0),
    coalesce(ap.appointments_created, 0),
    coalesce(ap.appointments_confirmed, 0),
    coalesce(ap.appointments_completed, 0),
    coalesce(ap.appointments_cancelled, 0),
    coalesce(pub.listings_published, 0),
    coalesce(arc.listings_archived, 0),
    coalesce(nu.new_users, 0),
    coalesce(dp.demand_posts_opened, 0),
    coalesce(ofr.offers_submitted, 0),
    coalesce(dc.deals_closed, 0),
    coalesce(dc.gmv_closed, 0),
    now()
  FROM (
    SELECT generate_series(p_from, p_to, interval '1 day')::date AS stat_date
  ) d
  LEFT JOIN LATERAL (
    SELECT
      count(*) FILTER (WHERE event_type = 'listing_impression') AS listing_impressions,
      count(*) FILTER (WHERE event_type = 'listing_view') AS listing_views,
      count(*) FILTER (WHERE event_type = 'listing_share') AS listing_shares,
      count(*) FILTER (WHERE event_type = 'map_marker_tap') AS map_marker_taps,
      count(*) FILTER (WHERE event_type = 'search_performed') AS searches,
      count(*) FILTER (WHERE event_type = 'chat_start') AS chat_starts,
      count(*) FILTER (WHERE event_type = 'chat_escalated') AS chat_escalations,
      count(*) FILTER (WHERE event_type = 'chat_claimed') AS chat_claimed,
      count(*) FILTER (WHERE event_type = 'chat_resolved') AS chat_resolved
    FROM analytics_events e
    WHERE e.stat_date = d.stat_date
  ) ev ON true
  LEFT JOIN LATERAL (
    SELECT
      count(*) AS leads_created,
      count(*) FILTER (WHERE status = 'new') AS leads_new,
      count(*) FILTER (WHERE status = 'accepted') AS leads_accepted,
      count(*) FILTER (WHERE status = 'declined') AS leads_declined
    FROM leads
    WHERE (created_at AT TIME ZONE 'Asia/Bangkok')::date = d.stat_date
  ) lg ON true
  LEFT JOIN LATERAL (
    SELECT count(*) AS e_contracts_signed
    FROM e_contracts
    WHERE (signed_at AT TIME ZONE 'Asia/Bangkok')::date = d.stat_date
  ) ec ON true
  LEFT JOIN LATERAL (
    SELECT
      count(*) AS appointments_created,
      count(*) FILTER (WHERE status = 'confirmed') AS appointments_confirmed,
      count(*) FILTER (WHERE status = 'completed') AS appointments_completed,
      count(*) FILTER (WHERE status = 'cancelled') AS appointments_cancelled
    FROM appointments
    WHERE (created_at AT TIME ZONE 'Asia/Bangkok')::date = d.stat_date
  ) ap ON true
  LEFT JOIN LATERAL (
    SELECT count(*) AS listings_published
    FROM listings
    WHERE (published_at AT TIME ZONE 'Asia/Bangkok')::date = d.stat_date
      AND status = 'published'
  ) pub ON true
  LEFT JOIN LATERAL (
    SELECT count(*) AS listings_archived
    FROM listings
    WHERE (updated_at AT TIME ZONE 'Asia/Bangkok')::date = d.stat_date
      AND status = 'archived'
  ) arc ON true
  LEFT JOIN LATERAL (
    SELECT count(*) AS new_users
    FROM profiles
    WHERE (created_at AT TIME ZONE 'Asia/Bangkok')::date = d.stat_date
  ) nu ON true
  LEFT JOIN LATERAL (
    SELECT count(*) AS demand_posts_opened
    FROM demand_posts
    WHERE (created_at AT TIME ZONE 'Asia/Bangkok')::date = d.stat_date
  ) dp ON true
  LEFT JOIN LATERAL (
    SELECT count(*) AS offers_submitted
    FROM demand_offers
    WHERE (created_at AT TIME ZONE 'Asia/Bangkok')::date = d.stat_date
  ) ofr ON true
  LEFT JOIN LATERAL (
    SELECT
      count(*) AS deals_closed,
      coalesce(sum(l.price_net), 0) AS gmv_closed
    FROM listings l
    WHERE (l.updated_at AT TIME ZONE 'Asia/Bangkok')::date = d.stat_date
      AND l.status = 'archived'
      AND l.listing_type IN ('sale', 'rent')
  ) dc ON true
  LEFT JOIN LATERAL (
    SELECT
      count(*) FILTER (WHERE sla_notified_at IS NOT NULL) AS sla_breaches,
      avg(
        EXTRACT(EPOCH FROM (assigned_at - created_at)) / 60.0
      ) FILTER (WHERE assigned_at IS NOT NULL) AS avg_claim_minutes
    FROM chat_threads t
    WHERE (t.created_at AT TIME ZONE 'Asia/Bangkok')::date = d.stat_date
  ) ch ON true
  ON CONFLICT (stat_date) DO UPDATE SET
    listing_impressions = EXCLUDED.listing_impressions,
    listing_views = EXCLUDED.listing_views,
    listing_shares = EXCLUDED.listing_shares,
    map_marker_taps = EXCLUDED.map_marker_taps,
    searches = EXCLUDED.searches,
    chat_starts = EXCLUDED.chat_starts,
    chat_escalations = EXCLUDED.chat_escalations,
    chat_claimed = EXCLUDED.chat_claimed,
    chat_resolved = EXCLUDED.chat_resolved,
    chat_sla_breaches = EXCLUDED.chat_sla_breaches,
    chat_avg_claim_minutes = EXCLUDED.chat_avg_claim_minutes,
    leads_created = EXCLUDED.leads_created,
    leads_new = EXCLUDED.leads_new,
    leads_accepted = EXCLUDED.leads_accepted,
    leads_declined = EXCLUDED.leads_declined,
    e_contracts_signed = EXCLUDED.e_contracts_signed,
    appointments_created = EXCLUDED.appointments_created,
    appointments_confirmed = EXCLUDED.appointments_confirmed,
    appointments_completed = EXCLUDED.appointments_completed,
    appointments_cancelled = EXCLUDED.appointments_cancelled,
    listings_published = EXCLUDED.listings_published,
    listings_archived = EXCLUDED.listings_archived,
    new_users = EXCLUDED.new_users,
    demand_posts_opened = EXCLUDED.demand_posts_opened,
    offers_submitted = EXCLUDED.offers_submitted,
    deals_closed = EXCLUDED.deals_closed,
    gmv_closed = EXCLUDED.gmv_closed,
    refreshed_at = now();

  -- District breakdown
  DELETE FROM analytics_district_daily
  WHERE stat_date BETWEEN p_from AND p_to;

  INSERT INTO analytics_district_daily (stat_date, district, listing_views, leads_created, appointments_created)
  SELECT
    combined.stat_date,
    combined.district,
    sum(combined.views)::bigint,
    sum(combined.leads)::bigint,
    sum(combined.appts)::bigint
  FROM (
    SELECT
      e.stat_date,
      coalesce(nullif(trim(e.district), ''), 'ไม่ระบุ') AS district,
      count(*) AS views,
      0::bigint AS leads,
      0::bigint AS appts
    FROM analytics_events e
    WHERE e.stat_date BETWEEN p_from AND p_to
      AND e.event_type = 'listing_view'
    GROUP BY e.stat_date, 2
    UNION ALL
    SELECT
      (ld.created_at AT TIME ZONE 'Asia/Bangkok')::date,
      coalesce(nullif(trim(li.district), ''), 'ไม่ระบุ'),
      0,
      count(*),
      0
    FROM leads ld
    LEFT JOIN listings li ON li.id = ld.listing_id
    WHERE (ld.created_at AT TIME ZONE 'Asia/Bangkok')::date BETWEEN p_from AND p_to
    GROUP BY 1, 2
    UNION ALL
    SELECT
      (a.created_at AT TIME ZONE 'Asia/Bangkok')::date,
      coalesce(nullif(trim(li.district), ''), 'ไม่ระบุ'),
      0,
      0,
      count(*)
    FROM appointments a
    LEFT JOIN listings li ON li.id = a.listing_id
    WHERE (a.created_at AT TIME ZONE 'Asia/Bangkok')::date BETWEEN p_from AND p_to
    GROUP BY 1, 2
  ) combined
  GROUP BY combined.stat_date, combined.district;

  -- Listing daily from events + leads
  DELETE FROM analytics_listing_daily
  WHERE stat_date BETWEEN p_from AND p_to;

  INSERT INTO analytics_listing_daily (
    stat_date, listing_id, owner_id, listing_code, views, shares, chat_starts, leads_created
  )
  SELECT
    e.stat_date,
    e.listing_id,
    li.owner_id,
    li.listing_code,
    count(*) FILTER (WHERE e.event_type = 'listing_view'),
    count(*) FILTER (WHERE e.event_type = 'listing_share'),
    count(*) FILTER (WHERE e.event_type = 'chat_start'),
    0
  FROM analytics_events e
  JOIN listings li ON li.id = e.listing_id
  WHERE e.stat_date BETWEEN p_from AND p_to
    AND e.listing_id IS NOT NULL
  GROUP BY e.stat_date, e.listing_id, li.owner_id, li.listing_code
  ON CONFLICT (stat_date, listing_id) DO UPDATE SET
    views = EXCLUDED.views,
    shares = EXCLUDED.shares,
    chat_starts = EXCLUDED.chat_starts;

  INSERT INTO analytics_listing_daily (
    stat_date, listing_id, owner_id, listing_code, views, shares, chat_starts, leads_created
  )
  SELECT
    (ld.created_at AT TIME ZONE 'Asia/Bangkok')::date,
    ld.listing_id,
    li.owner_id,
    coalesce(ld.listing_code, li.listing_code),
    0, 0, 0,
    count(*)
  FROM leads ld
  JOIN listings li ON li.id = ld.listing_id
  WHERE (ld.created_at AT TIME ZONE 'Asia/Bangkok')::date BETWEEN p_from AND p_to
  GROUP BY 1, 2, 3, 4
  ON CONFLICT (stat_date, listing_id) DO UPDATE SET
    leads_created = EXCLUDED.leads_created;

  -- Chat by category
  DELETE FROM analytics_chat_daily
  WHERE stat_date BETWEEN p_from AND p_to;

  INSERT INTO analytics_chat_daily (stat_date, category, volume, claimed, resolved, sla_breaches, avg_claim_minutes)
  SELECT
    (t.created_at AT TIME ZONE 'Asia/Bangkok')::date,
    coalesce(nullif(trim(t.category), ''), 'other'),
    count(*),
    count(*) FILTER (WHERE t.assigned_at IS NOT NULL),
    count(*) FILTER (WHERE t.status = 'resolved'),
    count(*) FILTER (WHERE t.sla_notified_at IS NOT NULL),
    avg(EXTRACT(EPOCH FROM (t.assigned_at - t.created_at)) / 60.0)
      FILTER (WHERE t.assigned_at IS NOT NULL)
  FROM chat_threads t
  WHERE (t.created_at AT TIME ZONE 'Asia/Bangkok')::date BETWEEN p_from AND p_to
  GROUP BY 1, 2;

  RETURN jsonb_build_object(
    'ok', true,
    'from', p_from,
    'to', p_to,
    'days', v_days,
    'refreshed_at', now()
  );
END;
$$;

-- Extended view (backward compatible with platform_stats_daily)
CREATE OR REPLACE VIEW public.analytics_platform_stats AS
SELECT
  stat_date,
  leads_created AS lead_count,
  leads_accepted AS accepted_count,
  leads_new AS new_count,
  appointments_created AS appointment_count,
  appointments_confirmed AS appointment_confirmed_count,
  appointments_completed AS appointment_completed_count,
  listing_views,
  listing_shares,
  chat_starts,
  e_contracts_signed,
  deals_closed,
  gmv_closed,
  new_users,
  refreshed_at
FROM analytics_platform_daily
ORDER BY stat_date DESC;

COMMENT ON VIEW public.analytics_platform_stats IS
  'Admin analytics — pre-aggregated daily metrics (no PII)';

-- RLS
ALTER TABLE public.analytics_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.analytics_platform_daily ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.analytics_district_daily ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.analytics_listing_daily ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.analytics_chat_daily ENABLE ROW LEVEL SECURITY;

CREATE POLICY analytics_events_service ON public.analytics_events
  FOR ALL USING (false);

CREATE POLICY analytics_platform_admin ON public.analytics_platform_daily
  FOR SELECT USING (public.is_admin());

CREATE POLICY analytics_district_admin ON public.analytics_district_daily
  FOR SELECT USING (public.is_admin());

CREATE POLICY analytics_chat_admin ON public.analytics_chat_daily
  FOR SELECT USING (public.is_admin());

CREATE POLICY analytics_listing_owner ON public.analytics_listing_daily
  FOR SELECT USING (
    public.is_admin()
    OR owner_id = auth.uid()
  );

GRANT SELECT ON public.analytics_platform_stats TO authenticated;
GRANT EXECUTE ON FUNCTION public.refresh_analytics_rollups(date, date) TO authenticated;
