-- AI feed สำหรับแอดมิน — การ์ดแจ้งเตือนพร้อมลิงก์ลึก
CREATE TABLE IF NOT EXISTS public.admin_ai_feed (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  event_type text NOT NULL,
  priority text NOT NULL DEFAULT 'normal'
    CHECK (priority IN ('low', 'normal', 'high', 'urgent')),
  status text NOT NULL DEFAULT 'open'
    CHECK (status IN ('open', 'read', 'acted', 'dismissed')),
  title text NOT NULL,
  summary text NOT NULL,
  suggested_action text,
  deep_link text,
  thread_id uuid REFERENCES public.chat_threads(id) ON DELETE SET NULL,
  listing_id uuid,
  listing_code text,
  owner_inquiry_id uuid REFERENCES public.owner_inquiries(id) ON DELETE SET NULL,
  confidence numeric,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb
);

CREATE INDEX IF NOT EXISTS admin_ai_feed_status_created_idx
  ON public.admin_ai_feed (status, created_at DESC);

CREATE INDEX IF NOT EXISTS admin_ai_feed_thread_idx
  ON public.admin_ai_feed (thread_id)
  WHERE thread_id IS NOT NULL;

ALTER TABLE public.admin_ai_feed ENABLE ROW LEVEL SECURITY;

CREATE POLICY admin_ai_feed_admin_select ON public.admin_ai_feed
  FOR SELECT TO authenticated
  USING (public.is_admin());

CREATE POLICY admin_ai_feed_admin_update ON public.admin_ai_feed
  FOR UPDATE TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

CREATE TRIGGER admin_ai_feed_updated_at
  BEFORE UPDATE ON public.admin_ai_feed
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
