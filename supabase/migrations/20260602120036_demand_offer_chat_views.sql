-- Demand offer chat views (separate migration — enum value must exist in prior commit)

DROP VIEW IF EXISTS public.chat_admin_inbox CASCADE;

CREATE OR REPLACE VIEW public.chat_admin_inbox AS
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
AND (
  (t.viewing_submitted AND NOT t.admin_reply_done)
  OR t.category IN ('escalation', 'viewing_request', 'demand_offer')
  OR (t.category = 'staff_support' AND t.status = 'waiting_admin')
  OR (t.status = 'waiting_admin' AND t.priority = 'high')
  OR (t.status = 'waiting_admin' AND t.unclear_streak >= 2)
);

CREATE UNIQUE INDEX IF NOT EXISTS chat_threads_user_demand_offer_uidx
  ON public.chat_threads (user_id)
  WHERE category = 'demand_offer';

CREATE OR REPLACE FUNCTION public.chat_sla_minutes(
  p_priority public.chat_thread_priority,
  p_category public.chat_thread_category,
  p_viewing_submitted boolean
)
RETURNS int
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT CASE
    WHEN p_viewing_submitted OR p_category = 'viewing_request'::public.chat_thread_category THEN 30
    WHEN p_priority = 'high'::public.chat_thread_priority THEN 30
    WHEN p_category = 'demand_offer'::public.chat_thread_category THEN 120
    WHEN p_category = 'staff_support'::public.chat_thread_category THEN 120
    WHEN p_category = 'escalation'::public.chat_thread_category THEN 60
    ELSE 240
  END;
$$;
