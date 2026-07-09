-- Harden admin-facing views and profile role bootstrap.
-- Views must run with the caller's RLS and return rows only to real admins.

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.profiles (id, display_name, role)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data ->> 'display_name', NEW.email),
    'seeker'::public.user_role
  );
  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.profiles_role_guard()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF current_setting('role', true) = 'authenticated' AND NOT public.is_admin() THEN
    IF NEW.role IN ('admin'::public.user_role, 'viewing_staff'::public.user_role)
      AND (OLD.role IS NULL OR OLD.role IS DISTINCT FROM NEW.role) THEN
      RAISE EXCEPTION 'cannot_self_assign_privileged_role'
        USING HINT = 'ติดต่อทีมงานเพื่อตั้ง role admin/viewing_staff ใน Supabase';
    END IF;

    IF NEW.staff_slug IS DISTINCT FROM OLD.staff_slug THEN
      RAISE EXCEPTION 'cannot_self_assign_staff_slug'
        USING HINT = 'ติดต่อทีมงานเพื่อตั้ง staff_slug ใน Supabase';
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS profiles_role_guard_trigger ON public.profiles;
CREATE TRIGGER profiles_role_guard_trigger
  BEFORE UPDATE OF role, staff_slug ON public.profiles
  FOR EACH ROW
  EXECUTE FUNCTION public.profiles_role_guard();

CREATE OR REPLACE VIEW public.chat_admin_inbox
WITH (security_invoker = true)
AS
SELECT
  t.id,
  t.user_id,
  t.room_kind,
  t.listing_id,
  t.listing_code,
  t.listing_title,
  t.project_name,
  t.category,
  t.status,
  t.priority,
  t.assigned_admin_id,
  t.assigned_at,
  t.viewing_submitted,
  t.admin_escalated,
  t.admin_reply_done,
  t.unclear_streak,
  t.sla_notified_at,
  t.last_message_at,
  t.created_at,
  t.customer_requirement_id,
  p.display_name AS assigned_admin_name,
  (
    SELECT m.text
    FROM public.chat_messages m
    WHERE m.thread_id = t.id
    ORDER BY m.created_at DESC
    LIMIT 1
  ) AS last_message_text,
  (
    SELECT m.role::text
    FROM public.chat_messages m
    WHERE m.thread_id = t.id
    ORDER BY m.created_at DESC
    LIMIT 1
  ) AS last_message_role
FROM public.chat_threads t
LEFT JOIN public.profiles p ON p.id = t.assigned_admin_id
WHERE public.is_admin()
  AND EXISTS (
    SELECT 1 FROM public.chat_messages um
    WHERE um.thread_id = t.id AND um.role = 'user'
  )
  AND NOT t.admin_reply_done
  AND (
    (t.viewing_submitted AND NOT t.admin_reply_done)
    OR t.category IN (
      'escalation',
      'viewing_request',
      'demand_offer',
      'customer_requirement',
      'discovery',
      'booking_interest'
    )
    OR (t.category = 'staff_support' AND t.status = 'waiting_admin')
    OR (t.status = 'waiting_admin')
    OR t.admin_escalated
  );

CREATE OR REPLACE VIEW public.lead_stats_daily
WITH (security_invoker = true)
AS
SELECT
  date_trunc('day', l.created_at)::date AS stat_date,
  count(*) AS lead_count,
  count(*) FILTER (WHERE l.status = 'accepted') AS accepted_count,
  count(*) FILTER (WHERE l.status = 'new') AS new_count
FROM public.leads l
WHERE public.is_admin()
GROUP BY 1;

CREATE OR REPLACE VIEW public.appointment_stats_daily
WITH (security_invoker = true)
AS
SELECT
  date_trunc('day', a.scheduled_date)::date AS stat_date,
  count(*)::int AS appointment_count,
  count(*) FILTER (WHERE a.status = 'confirmed')::int AS confirmed_count,
  count(*) FILTER (WHERE a.status = 'completed')::int AS completed_count,
  count(*) FILTER (WHERE a.status = 'cancelled')::int AS cancelled_count
FROM public.appointments a
WHERE public.is_admin()
GROUP BY 1;

CREATE OR REPLACE VIEW public.platform_stats_daily
WITH (security_invoker = true)
AS
SELECT
  COALESCE(l.stat_date, ap.stat_date) AS stat_date,
  COALESCE(l.lead_count, 0)::int AS lead_count,
  COALESCE(l.accepted_count, 0)::int AS accepted_count,
  COALESCE(l.new_count, 0)::int AS new_count,
  COALESCE(ap.appointment_count, 0)::int AS appointment_count,
  COALESCE(ap.confirmed_count, 0)::int AS appointment_confirmed_count,
  COALESCE(ap.completed_count, 0)::int AS appointment_completed_count
FROM public.lead_stats_daily l
FULL OUTER JOIN public.appointment_stats_daily ap ON l.stat_date = ap.stat_date
WHERE public.is_admin();

CREATE OR REPLACE VIEW public.analytics_platform_stats
WITH (security_invoker = true)
AS
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
FROM public.analytics_platform_daily
WHERE public.is_admin()
ORDER BY stat_date DESC;

CREATE OR REPLACE VIEW public.client_error_summary
WITH (security_invoker = true)
AS
SELECT
  error_key,
  count(*)::bigint AS occurrence_count,
  max(occurred_at) AS last_seen_at,
  count(DISTINCT session_hash) FILTER (WHERE session_hash IS NOT NULL) AS affected_sessions,
  mode() WITHIN GROUP (ORDER BY platform) AS top_platform
FROM public.client_error_reports
WHERE public.is_admin()
  AND occurred_at >= (now() - interval '30 days')
GROUP BY error_key
ORDER BY occurrence_count DESC;

GRANT SELECT ON public.chat_admin_inbox TO authenticated;
GRANT SELECT ON public.lead_stats_daily TO authenticated;
GRANT SELECT ON public.appointment_stats_daily TO authenticated;
GRANT SELECT ON public.platform_stats_daily TO authenticated;
GRANT SELECT ON public.analytics_platform_stats TO authenticated;
GRANT SELECT ON public.client_error_summary TO authenticated;
