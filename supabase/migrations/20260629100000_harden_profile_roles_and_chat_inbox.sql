-- Harden profile role assignment and make admin chat inbox respect RLS.

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
  can_manage_role boolean := public.is_admin()
    OR current_setting('role', true) IS NOT DISTINCT FROM 'service_role'
    OR session_user IN ('postgres', 'supabase_admin');
BEGIN
  IF TG_OP = 'INSERT' THEN
    IF NEW.role IS DISTINCT FROM 'seeker'::public.user_role AND NOT can_manage_role THEN
      RAISE EXCEPTION 'cannot_self_assign_role'
        USING HINT = 'ติดต่อทีมงานเพื่อตั้ง role ใน Supabase';
    END IF;
  ELSIF NEW.role IS DISTINCT FROM OLD.role AND NOT can_manage_role THEN
    RAISE EXCEPTION 'cannot_self_assign_role'
      USING HINT = 'ติดต่อทีมงานเพื่อตั้ง role ใน Supabase';
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
  BEFORE UPDATE OF role ON public.profiles
  FOR EACH ROW
  EXECUTE FUNCTION public.profiles_role_guard();

DROP VIEW IF EXISTS public.chat_admin_inbox CASCADE;

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
WHERE EXISTS (
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

GRANT SELECT ON public.chat_admin_inbox TO authenticated;
