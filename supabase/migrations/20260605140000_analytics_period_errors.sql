-- Phase 21b: รายงานถี่ 12ชม./24ชม. + ติดตั้ง/ถอนแอป + error log (ไม่มี PII)

ALTER TYPE public.analytics_event_type ADD VALUE IF NOT EXISTS 'app_install';
ALTER TYPE public.analytics_event_type ADD VALUE IF NOT EXISTS 'app_uninstall';
ALTER TYPE public.analytics_event_type ADD VALUE IF NOT EXISTS 'app_open';
ALTER TYPE public.analytics_event_type ADD VALUE IF NOT EXISTS 'client_error';

CREATE TABLE public.client_error_reports (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  error_key text NOT NULL,
  raw_message text,
  platform text NOT NULL DEFAULT 'unknown',
  route text,
  session_hash text,
  actor_id uuid REFERENCES public.profiles (id) ON DELETE SET NULL,
  occurred_at timestamptz NOT NULL DEFAULT now(),
  stat_date date NOT NULL DEFAULT ((now() AT TIME ZONE 'Asia/Bangkok')::date),
  metadata jsonb NOT NULL DEFAULT '{}'
);

CREATE INDEX client_error_reports_key_date_idx
  ON public.client_error_reports (error_key, stat_date DESC);
CREATE INDEX client_error_reports_occurred_brin_idx
  ON public.client_error_reports USING BRIN (occurred_at);

COMMENT ON TABLE public.client_error_reports IS
  'Client errors — no phone/email; grouped for admin error center';

CREATE TABLE public.analytics_period_stats (
  bucket_start timestamptz NOT NULL,
  period_hours smallint NOT NULL CHECK (period_hours IN (12, 24)),
  platform text NOT NULL DEFAULT 'all',
  app_installs bigint NOT NULL DEFAULT 0,
  app_uninstalls bigint NOT NULL DEFAULT 0,
  app_opens bigint NOT NULL DEFAULT 0,
  client_errors bigint NOT NULL DEFAULT 0,
  listing_views bigint NOT NULL DEFAULT 0,
  chat_starts bigint NOT NULL DEFAULT 0,
  leads_created bigint NOT NULL DEFAULT 0,
  new_users bigint NOT NULL DEFAULT 0,
  refreshed_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (bucket_start, period_hours, platform)
);

CREATE INDEX analytics_period_stats_period_idx
  ON public.analytics_period_stats (period_hours, bucket_start DESC);

COMMENT ON TABLE public.analytics_period_stats IS
  'Pre-aggregated 12h/24h buckets — Asia/Bangkok aligned';

CREATE OR REPLACE VIEW public.client_error_summary AS
SELECT
  error_key,
  count(*)::bigint AS occurrence_count,
  max(occurred_at) AS last_seen_at,
  count(DISTINCT session_hash) FILTER (WHERE session_hash IS NOT NULL) AS affected_sessions,
  mode() WITHIN GROUP (ORDER BY platform) AS top_platform
FROM public.client_error_reports
WHERE occurred_at >= (now() - interval '30 days')
GROUP BY error_key
ORDER BY occurrence_count DESC;

COMMENT ON VIEW public.client_error_summary IS
  'Admin error center — grouped by error_key (last 30 days)';

CREATE OR REPLACE FUNCTION public.refresh_analytics_period_rollups(
  p_period_hours int DEFAULT 24,
  p_buckets int DEFAULT 14
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_now timestamptz := now() AT TIME ZONE 'Asia/Bangkok';
  v_from timestamptz;
  v_interval interval;
BEGIN
  IF NOT public.is_admin() AND current_setting('role', true) IS DISTINCT FROM 'service_role' THEN
    RAISE EXCEPTION 'admin only';
  END IF;

  IF p_period_hours NOT IN (12, 24) THEN
    RAISE EXCEPTION 'p_period_hours must be 12 or 24';
  END IF;

  v_interval := make_interval(hours => p_period_hours);
  v_from := date_trunc('hour', v_now)
    - (p_buckets * v_interval)
    + (extract(hour from v_now)::int % p_period_hours) * interval '1 hour';

  DELETE FROM analytics_period_stats
  WHERE period_hours = p_period_hours
    AND bucket_start >= v_from;

  INSERT INTO analytics_period_stats (
    bucket_start, period_hours, platform,
    app_installs, app_uninstalls, app_opens, client_errors,
    listing_views, chat_starts, leads_created, new_users, refreshed_at
  )
  SELECT
    b.bucket_start,
    p_period_hours,
    coalesce(ev.platform, 'all'),
    coalesce(ev.app_installs, 0),
    coalesce(ev.app_uninstalls, 0),
    coalesce(ev.app_opens, 0),
    coalesce(ev.client_errors, 0),
    coalesce(ev.listing_views, 0),
    coalesce(ev.chat_starts, 0),
    coalesce(lg.leads_created, 0),
    coalesce(nu.new_users, 0),
    now()
  FROM (
    SELECT generate_series(
      v_from,
      date_trunc('hour', v_now),
      v_interval
    ) AS bucket_start
  ) b
  LEFT JOIN LATERAL (
    SELECT
      coalesce(e.metadata->>'platform', 'unknown') AS platform,
      count(*) FILTER (WHERE e.event_type = 'app_install') AS app_installs,
      count(*) FILTER (WHERE e.event_type = 'app_uninstall') AS app_uninstalls,
      count(*) FILTER (WHERE e.event_type = 'app_open') AS app_opens,
      count(*) FILTER (WHERE e.event_type = 'client_error') AS client_errors,
      count(*) FILTER (WHERE e.event_type = 'listing_view') AS listing_views,
      count(*) FILTER (WHERE e.event_type = 'chat_start') AS chat_starts
    FROM analytics_events e
    WHERE e.occurred_at >= b.bucket_start
      AND e.occurred_at < b.bucket_start + v_interval
    GROUP BY 1
  ) ev ON true
  LEFT JOIN LATERAL (
    SELECT count(*) AS leads_created
    FROM leads ld
    WHERE ld.created_at >= b.bucket_start
      AND ld.created_at < b.bucket_start + v_interval
  ) lg ON true
  LEFT JOIN LATERAL (
    SELECT count(*) AS new_users
    FROM profiles p
    WHERE p.created_at >= b.bucket_start
      AND p.created_at < b.bucket_start + v_interval
  ) nu ON true
  ON CONFLICT (bucket_start, period_hours, platform) DO UPDATE SET
    app_installs = EXCLUDED.app_installs,
    app_uninstalls = EXCLUDED.app_uninstalls,
    app_opens = EXCLUDED.app_opens,
    client_errors = EXCLUDED.client_errors,
    listing_views = EXCLUDED.listing_views,
    chat_starts = EXCLUDED.chat_starts,
    leads_created = EXCLUDED.leads_created,
    new_users = EXCLUDED.new_users,
    refreshed_at = now();

  -- Roll up platform=all
  INSERT INTO analytics_period_stats (
    bucket_start, period_hours, platform,
    app_installs, app_uninstalls, app_opens, client_errors,
    listing_views, chat_starts, leads_created, new_users, refreshed_at
  )
  SELECT
    bucket_start, period_hours, 'all',
    sum(app_installs), sum(app_uninstalls), sum(app_opens), sum(client_errors),
    sum(listing_views), sum(chat_starts), sum(leads_created), sum(new_users),
    now()
  FROM analytics_period_stats
  WHERE period_hours = p_period_hours
    AND platform <> 'all'
    AND bucket_start >= v_from
  GROUP BY bucket_start, period_hours
  ON CONFLICT (bucket_start, period_hours, platform) DO UPDATE SET
    app_installs = EXCLUDED.app_installs,
    app_uninstalls = EXCLUDED.app_uninstalls,
    app_opens = EXCLUDED.app_opens,
    client_errors = EXCLUDED.client_errors,
    listing_views = EXCLUDED.listing_views,
    chat_starts = EXCLUDED.chat_starts,
    leads_created = EXCLUDED.leads_created,
    new_users = EXCLUDED.new_users,
    refreshed_at = now();

  RETURN jsonb_build_object(
    'ok', true,
    'period_hours', p_period_hours,
    'buckets', p_buckets,
    'from', v_from,
    'refreshed_at', now()
  );
END;
$$;

ALTER TABLE public.client_error_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.analytics_period_stats ENABLE ROW LEVEL SECURITY;

CREATE POLICY client_error_reports_admin ON public.client_error_reports
  FOR SELECT USING (public.is_admin());

CREATE POLICY analytics_period_admin ON public.analytics_period_stats
  FOR SELECT USING (public.is_admin());

GRANT SELECT ON public.client_error_summary TO authenticated;
GRANT EXECUTE ON FUNCTION public.refresh_analytics_period_rollups(int, int) TO authenticated;
