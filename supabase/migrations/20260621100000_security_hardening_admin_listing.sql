-- Security hardening for admin-only views, profile role escalation, and listing review gates.

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
DECLARE
  v_db_role text := current_setting('role', true);
  v_trusted_context boolean := auth.uid() IS NULL
    OR v_db_role IN ('service_role', 'supabase_admin', 'postgres');
BEGIN
  IF v_trusted_context THEN
    RETURN NEW;
  END IF;

  IF TG_OP = 'INSERT' THEN
    IF NEW.role = 'admin'::public.user_role THEN
      RAISE EXCEPTION 'cannot_self_assign_admin'
        USING HINT = 'Admin role must be assigned from a trusted server context.';
    END IF;
    RETURN NEW;
  END IF;

  IF NEW.role = 'admin'::public.user_role
    AND OLD.role IS DISTINCT FROM 'admin'::public.user_role
  THEN
    RAISE EXCEPTION 'cannot_self_assign_admin'
      USING HINT = 'Admin role must be assigned from a trusted server context.';
  END IF;

  IF NEW.admin_tier IS DISTINCT FROM OLD.admin_tier THEN
    RAISE EXCEPTION 'cannot_self_assign_admin_tier'
      USING HINT = 'Admin tier must be assigned from a trusted server context.';
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS profiles_role_guard_trigger ON public.profiles;
DROP TRIGGER IF EXISTS profiles_role_guard_insert_trigger ON public.profiles;
DROP TRIGGER IF EXISTS profiles_role_guard_update_trigger ON public.profiles;

CREATE TRIGGER profiles_role_guard_insert_trigger
  BEFORE INSERT ON public.profiles
  FOR EACH ROW
  EXECUTE FUNCTION public.profiles_role_guard();

CREATE TRIGGER profiles_role_guard_update_trigger
  BEFORE UPDATE OF role, admin_tier ON public.profiles
  FOR EACH ROW
  EXECUTE FUNCTION public.profiles_role_guard();

CREATE OR REPLACE FUNCTION public.listings_publish_guard()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_db_role text := current_setting('role', true);
  v_trusted_context boolean := auth.uid() IS NULL
    OR v_db_role IN ('service_role', 'supabase_admin', 'postgres');
BEGIN
  IF v_trusted_context THEN
    RETURN NEW;
  END IF;

  IF NEW.status = 'published'::public.listing_status
    AND OLD.status IS DISTINCT FROM 'published'::public.listing_status
    AND NOT public.is_admin()
  THEN
    RAISE EXCEPTION 'listing_publish_requires_admin_review'
      USING HINT = 'Submit the listing for review and let an admin publish it.';
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS listings_publish_guard_trigger ON public.listings;
CREATE TRIGGER listings_publish_guard_trigger
  BEFORE UPDATE OF status ON public.listings
  FOR EACH ROW
  EXECUTE FUNCTION public.listings_publish_guard();

DROP POLICY IF EXISTS listing_events_insert ON public.listing_events;
CREATE POLICY listing_events_insert ON public.listing_events
  FOR INSERT TO authenticated
  WITH CHECK (
    auth.uid() IS NOT NULL
    AND (user_id IS NULL OR user_id = auth.uid())
  );

CREATE OR REPLACE VIEW public.chat_admin_inbox
WITH (security_invoker = true) AS
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
WITH (security_invoker = true) AS
SELECT
  date_trunc('day', l.created_at)::date AS stat_date,
  count(*) AS lead_count,
  count(*) FILTER (WHERE l.status = 'accepted') AS accepted_count,
  count(*) FILTER (WHERE l.status = 'new') AS new_count
FROM public.leads l
WHERE public.is_admin()
GROUP BY 1;

CREATE OR REPLACE VIEW public.appointment_stats_daily
WITH (security_invoker = true) AS
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
WITH (security_invoker = true) AS
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
WITH (security_invoker = true) AS
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
WITH (security_invoker = true) AS
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
