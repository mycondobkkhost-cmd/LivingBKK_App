-- Fix production-impacting auth/listing/chat permission gaps.

-- New users must always start as seekers. Do not trust client metadata for
-- privileged roles such as admin/owner/agent during signup.
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

-- The app uses a single account with an in-app owner/agent perspective and
-- stores that intent on listings.listed_by_role, not profiles.role.
DROP POLICY IF EXISTS listings_insert ON public.listings;
CREATE POLICY listings_insert ON public.listings
  FOR INSERT TO authenticated
  WITH CHECK (
    public.is_admin()
    OR (
      created_by_id = auth.uid()
      AND owner_id = auth.uid()
      AND status IN (
        'draft'::public.listing_status,
        'pending_review'::public.listing_status
      )
    )
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

REVOKE ALL ON public.chat_admin_inbox FROM anon;
GRANT SELECT ON public.chat_admin_inbox TO authenticated;
