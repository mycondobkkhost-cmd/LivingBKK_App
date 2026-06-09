-- Post-viewing reports — admin-only notes linked to appointments & leads

CREATE TABLE IF NOT EXISTS public.viewing_reports (
  id text PRIMARY KEY,
  appointment_id uuid REFERENCES public.appointments (id) ON DELETE SET NULL,
  lead_id uuid REFERENCES public.leads (id) ON DELETE SET NULL,
  listing_id uuid REFERENCES public.listings (id) ON DELETE SET NULL,
  listing_code text,
  location_label text,
  viewed_date date NOT NULL,
  time_slot text NOT NULL,
  guide_staff_id text,
  outcome text NOT NULL,
  customer_feedback text NOT NULL,
  customer_wants text NOT NULL,
  team_notes text,
  decision text NOT NULL CHECK (decision IN ('continue', 'closed')),
  intent text,
  seeker_nickname text,
  seeker_phone text,
  recorded_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS viewing_reports_lead_idx ON public.viewing_reports (lead_id);
CREATE INDEX IF NOT EXISTS viewing_reports_phone_idx ON public.viewing_reports (seeker_phone);
CREATE INDEX IF NOT EXISTS viewing_reports_appt_idx ON public.viewing_reports (appointment_id);

COMMENT ON TABLE public.viewing_reports IS
  'Admin-only post-viewing logs — outcome, feedback, wants; customer chat only on continue';
