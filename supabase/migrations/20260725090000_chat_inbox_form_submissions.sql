-- Viewing / booking form flows insert only system + admin_notice messages
-- (no role = 'user'). The inbox view required a user message, so those
-- escalations never appeared in admin pending inbox or chat-sla-cron.

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
WHERE NOT t.admin_reply_done
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
)
AND (
  EXISTS (
    SELECT 1 FROM public.chat_messages um
    WHERE um.thread_id = t.id AND um.role = 'user'
  )
  OR t.viewing_submitted
  OR t.category IN ('viewing_request', 'booking_interest')
);

GRANT SELECT ON public.chat_admin_inbox TO authenticated;
