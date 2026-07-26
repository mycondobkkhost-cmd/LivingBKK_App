-- คำขอสอบถามเจ้าของ (ต่อรองราคา / ห้องว่าง / รายละเอียดลึก) — ตัวกลาง AI แปลและส่งกลับลูกค้า
DO $$ BEGIN
  ALTER TYPE public.chat_thread_category ADD VALUE IF NOT EXISTS 'owner_inquiry';
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

CREATE TABLE IF NOT EXISTS public.owner_inquiries (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  code text NOT NULL UNIQUE,
  thread_id uuid NOT NULL REFERENCES public.chat_threads (id) ON DELETE CASCADE,
  listing_id uuid REFERENCES public.listings (id) ON DELETE SET NULL,
  listing_code text NOT NULL,
  seeker_id uuid NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  owner_id uuid REFERENCES auth.users (id) ON DELETE SET NULL,
  inquiry_type text NOT NULL DEFAULT 'general'
    CHECK (inquiry_type IN (
      'price_negotiation', 'availability', 'unit_detail',
      'custom_terms', 'general'
    )),
  seeker_question text NOT NULL,
  seeker_context jsonb NOT NULL DEFAULT '{}'::jsonb,
  status text NOT NULL DEFAULT 'pending_owner'
    CHECK (status IN (
      'pending_owner', 'owner_replied', 'relayed',
      'needs_admin', 'expired', 'cancelled'
    )),
  owner_reply_raw text,
  owner_reply_relay text,
  relay_policy text CHECK (relay_policy IN ('auto_ok', 'blocked_pii', 'needs_admin')),
  owner_thread_id uuid REFERENCES public.chat_threads (id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  owner_notified_at timestamptz,
  owner_replied_at timestamptz,
  relayed_at timestamptz
);

CREATE INDEX IF NOT EXISTS owner_inquiries_owner_status_idx
  ON public.owner_inquiries (owner_id, status, created_at DESC);

CREATE INDEX IF NOT EXISTS owner_inquiries_seeker_idx
  ON public.owner_inquiries (seeker_id, created_at DESC);

CREATE INDEX IF NOT EXISTS owner_inquiries_thread_idx
  ON public.owner_inquiries (thread_id);

CREATE TRIGGER owner_inquiries_updated_at
  BEFORE UPDATE ON public.owner_inquiries
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

ALTER TABLE public.owner_inquiries ENABLE ROW LEVEL SECURITY;

CREATE POLICY owner_inquiries_insert_seeker ON public.owner_inquiries
  FOR INSERT TO authenticated
  WITH CHECK (seeker_id = auth.uid());

CREATE POLICY owner_inquiries_select_parties ON public.owner_inquiries
  FOR SELECT TO authenticated
  USING (
    seeker_id = auth.uid()
    OR owner_id = auth.uid()
    OR public.is_admin()
  );

CREATE POLICY owner_inquiries_update_owner ON public.owner_inquiries
  FOR UPDATE TO authenticated
  USING (owner_id = auth.uid() OR public.is_admin())
  WITH CHECK (owner_id = auth.uid() OR public.is_admin());
