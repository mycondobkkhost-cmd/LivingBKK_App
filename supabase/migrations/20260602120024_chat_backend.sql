-- LivingBKK Phase 14: Chat backend (persisted threads + messages)

CREATE TYPE public.chat_room_kind AS ENUM ('property', 'ai_support', 'staff_support');

CREATE TYPE public.chat_thread_category AS ENUM (
  'property_faq',
  'ai_support',
  'staff_support',
  'escalation',
  'viewing_request'
);

CREATE TYPE public.chat_thread_status AS ENUM (
  'open',
  'waiting_admin',
  'resolved',
  'auto_closed'
);

CREATE TYPE public.chat_thread_priority AS ENUM ('normal', 'high');

CREATE TYPE public.chat_message_role AS ENUM ('user', 'ai', 'system', 'admin_notice');

CREATE TABLE public.chat_threads (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id uuid NOT NULL REFERENCES public.profiles (id) ON DELETE CASCADE,
  room_kind public.chat_room_kind NOT NULL DEFAULT 'property',
  listing_id uuid REFERENCES public.listings (id) ON DELETE SET NULL,
  listing_code text,
  listing_title text NOT NULL DEFAULT '',
  project_name text,
  category public.chat_thread_category NOT NULL DEFAULT 'property_faq',
  status public.chat_thread_status NOT NULL DEFAULT 'open',
  priority public.chat_thread_priority NOT NULL DEFAULT 'normal',
  assigned_admin_id uuid REFERENCES public.profiles (id),
  viewing_submitted boolean NOT NULL DEFAULT false,
  allow_viewing_request boolean NOT NULL DEFAULT false,
  admin_escalated boolean NOT NULL DEFAULT false,
  admin_reply_done boolean NOT NULL DEFAULT false,
  last_message_at timestamptz NOT NULL DEFAULT now(),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX chat_threads_user_property_uidx
  ON public.chat_threads (user_id, listing_id)
  WHERE room_kind = 'property' AND listing_id IS NOT NULL;

CREATE UNIQUE INDEX chat_threads_user_ai_support_uidx
  ON public.chat_threads (user_id)
  WHERE room_kind = 'ai_support';

CREATE UNIQUE INDEX chat_threads_user_staff_support_uidx
  ON public.chat_threads (user_id)
  WHERE room_kind = 'staff_support';

CREATE INDEX chat_threads_user_idx ON public.chat_threads (user_id, last_message_at DESC);
CREATE INDEX chat_threads_admin_inbox_idx
  ON public.chat_threads (status, priority, last_message_at DESC)
  WHERE status = 'waiting_admin';

CREATE TABLE public.chat_messages (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  thread_id uuid NOT NULL REFERENCES public.chat_threads (id) ON DELETE CASCADE,
  role public.chat_message_role NOT NULL,
  text text NOT NULL,
  links jsonb NOT NULL DEFAULT '[]'::jsonb,
  requires_admin boolean NOT NULL DEFAULT false,
  sender_id uuid REFERENCES public.profiles (id),
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX chat_messages_thread_idx
  ON public.chat_messages (thread_id, created_at ASC);

CREATE TRIGGER chat_threads_updated_at
  BEFORE UPDATE ON public.chat_threads
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at();

CREATE OR REPLACE FUNCTION public.chat_thread_touch_last_message()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  UPDATE public.chat_threads
  SET last_message_at = NEW.created_at,
      updated_at = now()
  WHERE id = NEW.thread_id;
  RETURN NEW;
END;
$$;

CREATE TRIGGER chat_messages_touch_thread
  AFTER INSERT ON public.chat_messages
  FOR EACH ROW
  EXECUTE FUNCTION public.chat_thread_touch_last_message();

-- Admin inbox view (no PII beyond nickname in messages)
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
  t.viewing_submitted,
  t.admin_escalated,
  t.admin_reply_done,
  t.last_message_at,
  t.created_at,
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
WHERE t.status = 'waiting_admin'
   OR (t.viewing_submitted AND NOT t.admin_reply_done)
   OR t.admin_escalated
   OR t.category IN ('staff_support', 'escalation', 'viewing_request');

GRANT SELECT ON public.chat_admin_inbox TO authenticated;

ALTER TABLE public.chat_threads ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chat_messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY chat_threads_select ON public.chat_threads
  FOR SELECT TO authenticated
  USING (user_id = auth.uid() OR public.is_admin());

CREATE POLICY chat_threads_insert ON public.chat_threads
  FOR INSERT TO authenticated
  WITH CHECK (user_id = auth.uid());

CREATE POLICY chat_threads_update ON public.chat_threads
  FOR UPDATE TO authenticated
  USING (user_id = auth.uid() OR public.is_admin())
  WITH CHECK (user_id = auth.uid() OR public.is_admin());

CREATE POLICY chat_messages_select ON public.chat_messages
  FOR SELECT TO authenticated
  USING (
    public.is_admin()
    OR EXISTS (
      SELECT 1 FROM public.chat_threads t
      WHERE t.id = thread_id AND t.user_id = auth.uid()
    )
  );

CREATE POLICY chat_messages_insert ON public.chat_messages
  FOR INSERT TO authenticated
  WITH CHECK (
    public.is_admin()
    OR EXISTS (
      SELECT 1 FROM public.chat_threads t
      WHERE t.id = thread_id AND t.user_id = auth.uid()
    )
  );

ALTER PUBLICATION supabase_realtime ADD TABLE public.chat_messages;
ALTER PUBLICATION supabase_realtime ADD TABLE public.chat_threads;
