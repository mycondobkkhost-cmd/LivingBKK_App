-- Phase 7: reporting views (Make.com) + notification support

CREATE OR REPLACE VIEW public.appointment_stats_daily AS
SELECT
  date_trunc('day', a.scheduled_date)::date AS stat_date,
  count(*)::int AS appointment_count,
  count(*) FILTER (WHERE a.status = 'confirmed')::int AS confirmed_count,
  count(*) FILTER (WHERE a.status = 'completed')::int AS completed_count,
  count(*) FILTER (WHERE a.status = 'cancelled')::int AS cancelled_count
FROM public.appointments a
GROUP BY 1;

COMMENT ON VIEW public.appointment_stats_daily IS 'Daily appointment stats — no PII (Make.com / admin)';

CREATE OR REPLACE VIEW public.platform_stats_daily AS
SELECT
  COALESCE(l.stat_date, ap.stat_date) AS stat_date,
  COALESCE(l.lead_count, 0)::int AS lead_count,
  COALESCE(l.accepted_count, 0)::int AS accepted_count,
  COALESCE(l.new_count, 0)::int AS new_count,
  COALESCE(ap.appointment_count, 0)::int AS appointment_count,
  COALESCE(ap.confirmed_count, 0)::int AS appointment_confirmed_count,
  COALESCE(ap.completed_count, 0)::int AS appointment_completed_count
FROM public.lead_stats_daily l
FULL OUTER JOIN public.appointment_stats_daily ap ON l.stat_date = ap.stat_date;

COMMENT ON VIEW public.platform_stats_daily IS 'Combined daily stats for export — no phone/names';

GRANT SELECT ON public.appointment_stats_daily TO authenticated;
GRANT SELECT ON public.platform_stats_daily TO authenticated;
