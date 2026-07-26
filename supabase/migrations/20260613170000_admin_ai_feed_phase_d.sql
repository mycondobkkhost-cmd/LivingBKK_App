-- Phase D: Admin AI Feed — FK ขยาย, dedupe, realtime

ALTER TABLE public.admin_ai_feed
  ADD COLUMN IF NOT EXISTS lead_id uuid REFERENCES public.leads (id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS appointment_id uuid REFERENCES public.appointments (id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS project_request_id uuid REFERENCES public.project_requests (id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS dedupe_key text;

CREATE INDEX IF NOT EXISTS admin_ai_feed_lead_idx
  ON public.admin_ai_feed (lead_id)
  WHERE lead_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS admin_ai_feed_appt_idx
  ON public.admin_ai_feed (appointment_id)
  WHERE appointment_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS admin_ai_feed_project_req_idx
  ON public.admin_ai_feed (project_request_id)
  WHERE project_request_id IS NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS admin_ai_feed_dedupe_open_uidx
  ON public.admin_ai_feed (dedupe_key)
  WHERE dedupe_key IS NOT NULL AND status = 'open';

ALTER PUBLICATION supabase_realtime ADD TABLE public.admin_ai_feed;
