-- Fix listing contact storage + booking-interest chat inbox.

ALTER TABLE public.listings
  ADD COLUMN IF NOT EXISTS owner_contact_name text,
  ADD COLUMN IF NOT EXISTS owner_contact_phone text,
  ADD COLUMN IF NOT EXISTS owner_line_id text;

COMMENT ON COLUMN public.listings.owner_contact_name IS
  'Private poster contact name for admin operations; never selected in listings_public.';
COMMENT ON COLUMN public.listings.owner_contact_phone IS
  'Private poster contact phone for admin operations; never selected in listings_public.';
COMMENT ON COLUMN public.listings.owner_line_id IS
  'Private poster LINE ID for admin operations; never selected in listings_public.';

ALTER TYPE public.chat_thread_category ADD VALUE IF NOT EXISTS 'booking_interest';

DROP VIEW IF EXISTS public.chat_admin_inbox CASCADE;

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
  OR t.category::text IN (
    'escalation',
    'viewing_request',
    'demand_offer',
    'customer_requirement',
    'discovery',
    'booking_interest'
  )
  OR (t.category::text = 'staff_support' AND t.status = 'waiting_admin')
  OR (t.status = 'waiting_admin')
  OR t.admin_escalated
);

GRANT SELECT ON public.chat_admin_inbox TO authenticated;
