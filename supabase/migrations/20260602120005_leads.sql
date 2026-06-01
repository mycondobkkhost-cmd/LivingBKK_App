-- LivingBKK: leads and assignments

CREATE TABLE public.leads (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  listing_id uuid REFERENCES public.listings (id),
  listing_code text,
  seeker_id uuid REFERENCES public.profiles (id),

  seeker_nickname text NOT NULL,
  seeker_phone text NOT NULL,

  occupants_count int,
  gender text,
  occupation text,
  workplace text,
  move_plan text,
  contract_duration text,
  budget numeric(12, 2),
  has_car boolean,
  pets text,
  smoking text,
  preferred_areas text[],

  qualification_json jsonb DEFAULT '{}',
  status public.lead_status NOT NULL DEFAULT 'new',
  assigned_to uuid REFERENCES public.profiles (id),

  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX leads_listing_idx ON public.leads (listing_id);
CREATE INDEX leads_status_idx ON public.leads (status);
CREATE INDEX leads_assigned_idx ON public.leads (assigned_to);

CREATE TRIGGER leads_updated_at
  BEFORE UPDATE ON public.leads
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at();

CREATE TABLE public.lead_assignments (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  lead_id uuid NOT NULL REFERENCES public.leads (id) ON DELETE CASCADE,
  assignee_id uuid NOT NULL REFERENCES public.profiles (id),
  action public.lead_assignment_action NOT NULL,
  unavailable_until date,
  available_again date,
  contract_accepted_at timestamptz,
  commission_tier_id uuid,
  notes text,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX lead_assignments_lead_idx ON public.lead_assignments (lead_id);

-- Censor phone for display (e.g. 0812345678 -> 08x-xxx-5678)
CREATE OR REPLACE FUNCTION public.censor_phone(phone text)
RETURNS text
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT CASE
    WHEN phone IS NULL OR length(phone) < 6 THEN '***'
    ELSE left(phone, 2) || 'x-xxx-' || right(regexp_replace(phone, '\D', '', 'g'), 4)
  END;
$$;
