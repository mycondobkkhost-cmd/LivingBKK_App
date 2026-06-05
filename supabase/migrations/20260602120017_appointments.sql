-- Phase 6: admin viewing appointments + map coordinates

CREATE TYPE public.appointment_status AS ENUM (
  'pending',
  'confirmed',
  'completed',
  'cancelled'
);

CREATE TABLE public.appointments (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  lead_id uuid REFERENCES public.leads (id) ON DELETE SET NULL,
  listing_id uuid REFERENCES public.listings (id) ON DELETE SET NULL,
  listing_code text,
  seeker_nickname text NOT NULL,
  seeker_phone text,

  scheduled_date date NOT NULL,
  time_slot text NOT NULL,

  status public.appointment_status NOT NULL DEFAULT 'pending',
  location_label text,
  lat double precision,
  lng double precision,

  created_by uuid REFERENCES public.profiles (id),
  assigned_to uuid REFERENCES public.profiles (id),
  admin_notes text,

  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX appointments_date_idx ON public.appointments (scheduled_date);
CREATE INDEX appointments_status_idx ON public.appointments (status);
CREATE INDEX appointments_lead_idx ON public.appointments (lead_id);

CREATE TRIGGER appointments_updated_at
  BEFORE UPDATE ON public.appointments
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at();

ALTER TABLE public.appointments ENABLE ROW LEVEL SECURITY;

CREATE POLICY appointments_admin_all ON public.appointments
  FOR ALL TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

CREATE POLICY appointments_assignee_select ON public.appointments
  FOR SELECT TO authenticated
  USING (assigned_to = auth.uid());

CREATE POLICY appointments_assignee_update ON public.appointments
  FOR UPDATE TO authenticated
  USING (assigned_to = auth.uid())
  WITH CHECK (assigned_to = auth.uid());
