-- LivingBKK: category listing codes + transaction reference numbers

CREATE SEQUENCE IF NOT EXISTS public.ref_listing_seq START 1;
CREATE SEQUENCE IF NOT EXISTS public.ref_chat_seq START 1;
CREATE SEQUENCE IF NOT EXISTS public.ref_lead_seq START 1;
CREATE SEQUENCE IF NOT EXISTS public.ref_appt_seq START 1;

CREATE OR REPLACE FUNCTION public.property_type_prefix(pt public.property_type)
RETURNS text
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT CASE pt
    WHEN 'condo' THEN 'CD'
    WHEN 'house' THEN 'HS'
    WHEN 'townhouse' THEN 'TH'
    WHEN 'apartment' THEN 'AP'
    ELSE 'OT'
  END;
$$;

CREATE OR REPLACE FUNCTION public.next_transaction_ref(prefix text, seq regclass)
RETURNS text
LANGUAGE plpgsql
AS $$
DECLARE
  n bigint;
BEGIN
  EXECUTE format('SELECT nextval(%L)', seq::text) INTO n;
  RETURN prefix || '-' || to_char(now(), 'YYYY') || '-' || lpad(n::text, 6, '0');
END;
$$;

-- RENT-CD-2026-000042 / SALE-HS-2026-000001
CREATE OR REPLACE FUNCTION public.generate_listing_code()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  IF NEW.listing_code IS NULL OR NEW.listing_code = '' THEN
    NEW.listing_code :=
      upper(NEW.listing_type::text) || '-' ||
      public.property_type_prefix(NEW.property_type) || '-' ||
      to_char(now(), 'YYYY') || '-' ||
      lpad(nextval('public.ref_listing_seq')::text, 6, '0');
  END IF;
  RETURN NEW;
END;
$$;

ALTER TABLE public.chat_threads
  ADD COLUMN IF NOT EXISTS transaction_ref text;

ALTER TABLE public.leads
  ADD COLUMN IF NOT EXISTS transaction_ref text;

ALTER TABLE public.appointments
  ADD COLUMN IF NOT EXISTS transaction_ref text;

CREATE UNIQUE INDEX IF NOT EXISTS chat_threads_transaction_ref_uidx
  ON public.chat_threads (transaction_ref)
  WHERE transaction_ref IS NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS leads_transaction_ref_uidx
  ON public.leads (transaction_ref)
  WHERE transaction_ref IS NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS appointments_transaction_ref_uidx
  ON public.appointments (transaction_ref)
  WHERE transaction_ref IS NOT NULL;

CREATE OR REPLACE FUNCTION public.generate_chat_transaction_ref()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  IF NEW.transaction_ref IS NULL OR NEW.transaction_ref = '' THEN
    NEW.transaction_ref := public.next_transaction_ref('CHAT', 'public.ref_chat_seq');
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS chat_threads_generate_ref ON public.chat_threads;
CREATE TRIGGER chat_threads_generate_ref
  BEFORE INSERT ON public.chat_threads
  FOR EACH ROW
  EXECUTE FUNCTION public.generate_chat_transaction_ref();

CREATE OR REPLACE FUNCTION public.generate_lead_transaction_ref()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  IF NEW.transaction_ref IS NULL OR NEW.transaction_ref = '' THEN
    NEW.transaction_ref := public.next_transaction_ref('LEAD', 'public.ref_lead_seq');
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS leads_generate_ref ON public.leads;
CREATE TRIGGER leads_generate_ref
  BEFORE INSERT ON public.leads
  FOR EACH ROW
  EXECUTE FUNCTION public.generate_lead_transaction_ref();

CREATE OR REPLACE FUNCTION public.generate_appt_transaction_ref()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  IF NEW.transaction_ref IS NULL OR NEW.transaction_ref = '' THEN
    NEW.transaction_ref := public.next_transaction_ref('APPT', 'public.ref_appt_seq');
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS appointments_generate_ref ON public.appointments;
CREATE TRIGGER appointments_generate_ref
  BEFORE INSERT ON public.appointments
  FOR EACH ROW
  EXECUTE FUNCTION public.generate_appt_transaction_ref();

-- Admin inbox includes transaction ref for tagging
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
  t.viewing_submitted,
  t.admin_escalated,
  t.admin_reply_done,
  t.transaction_ref,
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
