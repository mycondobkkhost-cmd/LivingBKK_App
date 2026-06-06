-- Phase gap closure: PIR listing codes, requirement chat, offer codes, admin inbox

-- ── PIR listing codes (DDMMYY + daily seq, Asia/Bangkok midnight reset) ──

CREATE TABLE IF NOT EXISTS public.listing_code_daily_seq (
  stat_date date PRIMARY KEY,
  n int NOT NULL DEFAULT 0
);

CREATE OR REPLACE FUNCTION public.bangkok_today()
RETURNS date
LANGUAGE sql
STABLE
AS $$
  SELECT (now() AT TIME ZONE 'Asia/Bangkok')::date;
$$;

CREATE OR REPLACE FUNCTION public.next_pir_listing_code()
RETURNS text
LANGUAGE plpgsql
AS $$
DECLARE
  d date := public.bangkok_today();
  seq int;
  dd text;
BEGIN
  INSERT INTO public.listing_code_daily_seq (stat_date, n)
  VALUES (d, 1)
  ON CONFLICT (stat_date) DO UPDATE
    SET n = public.listing_code_daily_seq.n + 1
  RETURNING n INTO seq;

  IF seq > 9999 THEN
    RAISE EXCEPTION 'Daily PIR listing code limit (9999) exceeded for %', d;
  END IF;

  dd := to_char(d, 'DDMMYY');
  RETURN 'PIR' || dd || '-' || lpad(seq::text, 4, '0');
END;
$$;

CREATE OR REPLACE FUNCTION public.generate_listing_code()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  IF NEW.listing_code IS NULL OR NEW.listing_code = '' THEN
    NEW.listing_code := public.next_pir_listing_code();
  END IF;
  RETURN NEW;
END;
$$;

-- ── Offer codes (OFR + DDMMYY + daily seq) ──

CREATE TABLE IF NOT EXISTS public.offer_code_daily_seq (
  stat_date date PRIMARY KEY,
  n int NOT NULL DEFAULT 0
);

CREATE OR REPLACE FUNCTION public.next_offer_code()
RETURNS text
LANGUAGE plpgsql
AS $$
DECLARE
  d date := public.bangkok_today();
  seq int;
  dd text;
BEGIN
  INSERT INTO public.offer_code_daily_seq (stat_date, n)
  VALUES (d, 1)
  ON CONFLICT (stat_date) DO UPDATE
    SET n = public.offer_code_daily_seq.n + 1
  RETURNING n INTO seq;

  IF seq > 9999 THEN
    RAISE EXCEPTION 'Daily offer code limit (9999) exceeded for %', d;
  END IF;

  dd := to_char(d, 'DDMMYY');
  RETURN 'OFR' || dd || '-' || lpad(seq::text, 4, '0');
END;
$$;

ALTER TABLE public.demand_offers
  ADD COLUMN IF NOT EXISTS offer_code text,
  ADD COLUMN IF NOT EXISTS listing_id uuid REFERENCES public.listings (id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS promoted_at timestamptz;

CREATE UNIQUE INDEX IF NOT EXISTS demand_offers_offer_code_uidx
  ON public.demand_offers (offer_code)
  WHERE offer_code IS NOT NULL;

CREATE OR REPLACE FUNCTION public.generate_demand_offer_code()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  IF NEW.offer_code IS NULL OR NEW.offer_code = '' THEN
    NEW.offer_code := public.next_offer_code();
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS demand_offers_generate_code ON public.demand_offers;
CREATE TRIGGER demand_offers_generate_code
  BEFORE INSERT ON public.demand_offers
  FOR EACH ROW
  EXECUTE FUNCTION public.generate_demand_offer_code();

-- ── Demand board seeker link ──

ALTER TABLE public.demand_posts
  ADD COLUMN IF NOT EXISTS seeker_user_id uuid REFERENCES public.profiles (id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS demand_posts_seeker_idx
  ON public.demand_posts (seeker_user_id)
  WHERE seeker_user_id IS NOT NULL;

-- ── Customer requirement ↔ chat thread ──

DO $$ BEGIN
  ALTER TYPE public.chat_thread_category ADD VALUE IF NOT EXISTS 'customer_requirement';
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

ALTER TABLE public.customer_requirements
  ADD COLUMN IF NOT EXISTS thread_id uuid REFERENCES public.chat_threads (id) ON DELETE SET NULL;

ALTER TABLE public.chat_threads
  ADD COLUMN IF NOT EXISTS customer_requirement_id uuid
    REFERENCES public.customer_requirements (id) ON DELETE SET NULL;

CREATE UNIQUE INDEX IF NOT EXISTS chat_threads_user_requirement_uidx
  ON public.chat_threads (user_id, customer_requirement_id)
  WHERE customer_requirement_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS customer_requirements_thread_idx
  ON public.customer_requirements (thread_id)
  WHERE thread_id IS NOT NULL;

-- ── Owner contact vault (admin tier) ──

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS admin_tier text NOT NULL DEFAULT 'standard'
    CHECK (admin_tier IN ('standard', 'lead', 'super'));

CREATE TABLE IF NOT EXISTS public.owner_contact_requests (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  listing_id uuid NOT NULL REFERENCES public.listings (id) ON DELETE CASCADE,
  thread_id uuid REFERENCES public.chat_threads (id) ON DELETE SET NULL,
  requested_by uuid NOT NULL REFERENCES public.profiles (id),
  approved_by uuid REFERENCES public.profiles (id),
  reason text NOT NULL DEFAULT '',
  status text NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending', 'approved', 'denied', 'expired')),
  admin_note text,
  revealed_phone text,
  expires_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS owner_contact_requests_listing_idx
  ON public.owner_contact_requests (listing_id, status);

ALTER TABLE public.owner_contact_requests ENABLE ROW LEVEL SECURITY;

CREATE POLICY owner_contact_requests_admin ON public.owner_contact_requests
  FOR ALL TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

CREATE POLICY owner_contact_requests_requester_select ON public.owner_contact_requests
  FOR SELECT TO authenticated
  USING (requested_by = auth.uid());

-- ── Admin inbox: include customer_requirement threads ──

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
AND (
  (t.viewing_submitted AND NOT t.admin_reply_done)
  OR t.category IN (
    'escalation',
    'viewing_request',
    'demand_offer',
    'customer_requirement'
  )
  OR (t.category = 'staff_support' AND t.status = 'waiting_admin')
  OR (t.status = 'waiting_admin' AND t.priority = 'high')
  OR (t.status = 'waiting_admin' AND t.unclear_streak >= 2)
);

GRANT SELECT ON public.chat_admin_inbox TO authenticated;

ALTER TABLE public.listings
  ADD COLUMN IF NOT EXISTS source_demand_offer_id uuid
    REFERENCES public.demand_offers (id) ON DELETE SET NULL;

-- ── FAQ priority fixes (POV D2/D4) ──

UPDATE public.chat_faq_rules
SET priority = 15
WHERE is_active = true
  AND scope = 'property'::public.chat_faq_scope
  AND topic_th = 'สัญญา(ทั่วไป)';

UPDATE public.chat_faq_rules
SET priority = 25
WHERE is_active = true
  AND scope = 'property'::public.chat_faq_scope
  AND topic_th = 'ยกเลิกสัญญา';

UPDATE public.chat_faq_rules
SET priority = 5
WHERE is_active = true
  AND scope = 'property'::public.chat_faq_scope
  AND topic_th = 'ค่าส่วนกลาง';

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
    WHEN p_category = 'customer_requirement'::public.chat_thread_category THEN 120
    WHEN p_category = 'staff_support'::public.chat_thread_category THEN 120
    WHEN p_category = 'escalation'::public.chat_thread_category THEN 60
    ELSE 240
  END;
$$;
