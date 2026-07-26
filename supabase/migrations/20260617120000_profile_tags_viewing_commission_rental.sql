-- Phase 24–27: profile_tags, viewing_requests, commission_agreements, rental_leases

-- ── profile_tags ──
CREATE TABLE IF NOT EXISTS public.profile_tags (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  code text NOT NULL UNIQUE,
  role text NOT NULL CHECK (
    role IN ('seeker_self', 'co_agent_presenter', 'client_subject')
  ),
  version int NOT NULL DEFAULT 1,
  label text NOT NULL,
  snapshot jsonb NOT NULL DEFAULT '{}'::jsonb,
  owner_user_id uuid NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  subject_display_name text,
  based_on_tag_id uuid REFERENCES public.profile_tags (id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS profile_tags_owner_idx
  ON public.profile_tags (owner_user_id, created_at DESC);

CREATE INDEX IF NOT EXISTS profile_tags_code_idx
  ON public.profile_tags (code);

-- ── viewing_requests ──
CREATE TABLE IF NOT EXISTS public.viewing_requests (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  code text NOT NULL UNIQUE,
  listing_id uuid REFERENCES public.listings (id) ON DELETE SET NULL,
  listing_code text NOT NULL,
  listing_title text NOT NULL,
  project_name text,
  scheduled_at timestamptz NOT NULL,
  client_tag_id uuid REFERENCES public.profile_tags (id) ON DELETE SET NULL,
  client_tag_code text NOT NULL,
  presenter_tag_id uuid REFERENCES public.profile_tags (id) ON DELETE SET NULL,
  presenter_tag_code text,
  source text NOT NULL DEFAULT 'customer' CHECK (
    source IN ('customer', 'co_agent', 'admin_phone')
  ),
  status text NOT NULL DEFAULT 'submitted' CHECK (
    status IN (
      'draft',
      'submitted',
      'sent_to_owner',
      'owner_confirmed',
      'owner_declined',
      'cancelled'
    )
  ),
  thread_id uuid REFERENCES public.chat_threads (id) ON DELETE SET NULL,
  appointment_id uuid REFERENCES public.appointments (id) ON DELETE SET NULL,
  created_by_user_id uuid NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS viewing_requests_thread_idx
  ON public.viewing_requests (thread_id, created_at DESC);

CREATE INDEX IF NOT EXISTS viewing_requests_listing_idx
  ON public.viewing_requests (listing_id, scheduled_at DESC);

CREATE INDEX IF NOT EXISTS viewing_requests_creator_idx
  ON public.viewing_requests (created_by_user_id, created_at DESC);

-- ── commission_agreements (popup ยอมรับค่าคอม) ──
CREATE TABLE IF NOT EXISTS public.commission_agreements (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  context text NOT NULL CHECK (
    context IN (
      'publish_listing',
      'submit_offer',
      'accept_lead',
      'confirm_viewing'
    )
  ),
  scheme_snapshot jsonb NOT NULL DEFAULT '{}'::jsonb,
  listing_id uuid REFERENCES public.listings (id) ON DELETE SET NULL,
  lead_id uuid REFERENCES public.leads (id) ON DELETE SET NULL,
  offer_id uuid REFERENCES public.demand_offers (id) ON DELETE SET NULL,
  viewing_request_id uuid REFERENCES public.viewing_requests (id) ON DELETE SET NULL,
  agreed_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS commission_agreements_user_idx
  ON public.commission_agreements (user_id, agreed_at DESC);

CREATE INDEX IF NOT EXISTS commission_agreements_context_idx
  ON public.commission_agreements (context, agreed_at DESC);

-- ── rental_leases (Phase 27) ──
CREATE TABLE IF NOT EXISTS public.rental_leases (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  listing_id uuid REFERENCES public.listings (id) ON DELETE SET NULL,
  listing_code text NOT NULL,
  title text NOT NULL,
  rent_amount int NOT NULL DEFAULT 0,
  currency text NOT NULL DEFAULT 'THB',
  payment_day_of_month int NOT NULL DEFAULT 1 CHECK (
    payment_day_of_month BETWEEN 1 AND 28
  ),
  billing_cycle text NOT NULL DEFAULT 'monthly' CHECK (
    billing_cycle IN ('monthly', 'custom')
  ),
  lease_start date NOT NULL,
  contract_signed_at timestamptz,
  lease_end date,
  status text NOT NULL DEFAULT 'active' CHECK (
    status IN ('active', 'ended', 'suspended')
  ),
  thread_id uuid REFERENCES public.chat_threads (id) ON DELETE SET NULL,
  bank_account_note text,
  project_name text,
  district text,
  payment_policy jsonb NOT NULL DEFAULT '{}'::jsonb,
  album_note jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.rental_lease_members (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  lease_id uuid NOT NULL REFERENCES public.rental_leases (id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  role text NOT NULL CHECK (role IN ('tenant', 'owner', 'agent', 'admin')),
  display_label text NOT NULL,
  profile_tag_code text,
  joined_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (lease_id, user_id)
);

CREATE TABLE IF NOT EXISTS public.rental_payment_installments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  lease_id uuid NOT NULL REFERENCES public.rental_leases (id) ON DELETE CASCADE,
  sequence int NOT NULL,
  due_date date NOT NULL,
  amount int NOT NULL DEFAULT 0,
  status text NOT NULL DEFAULT 'pending' CHECK (
    status IN ('pending', 'slip_submitted', 'paid', 'overdue', 'waived')
  ),
  paid_at timestamptz,
  slip_path text,
  note text,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (lease_id, sequence)
);

CREATE TABLE IF NOT EXISTS public.rental_group_attachments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  lease_id uuid NOT NULL REFERENCES public.rental_leases (id) ON DELETE CASCADE,
  kind text NOT NULL CHECK (kind IN ('document', 'album_photo', 'bank_note')),
  storage_path text,
  file_name text NOT NULL,
  note text,
  uploaded_by uuid REFERENCES auth.users (id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS rental_lease_members_user_idx
  ON public.rental_lease_members (user_id);

CREATE INDEX IF NOT EXISTS rental_payment_installments_lease_idx
  ON public.rental_payment_installments (lease_id, sequence);

-- ── RLS ──
ALTER TABLE public.profile_tags ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.viewing_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.commission_agreements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rental_leases ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rental_lease_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rental_payment_installments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rental_group_attachments ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS profile_tags_select ON public.profile_tags;
DROP POLICY IF EXISTS profile_tags_insert ON public.profile_tags;
DROP POLICY IF EXISTS viewing_requests_select ON public.viewing_requests;
DROP POLICY IF EXISTS viewing_requests_insert ON public.viewing_requests;
DROP POLICY IF EXISTS viewing_requests_update ON public.viewing_requests;
DROP POLICY IF EXISTS commission_agreements_select ON public.commission_agreements;
DROP POLICY IF EXISTS commission_agreements_insert ON public.commission_agreements;
DROP POLICY IF EXISTS rental_leases_select ON public.rental_leases;
DROP POLICY IF EXISTS rental_leases_admin ON public.rental_leases;
DROP POLICY IF EXISTS rental_lease_members_select ON public.rental_lease_members;
DROP POLICY IF EXISTS rental_lease_members_admin ON public.rental_lease_members;
DROP POLICY IF EXISTS rental_payment_installments_select ON public.rental_payment_installments;
DROP POLICY IF EXISTS rental_payment_installments_admin ON public.rental_payment_installments;
DROP POLICY IF EXISTS rental_group_attachments_select ON public.rental_group_attachments;
DROP POLICY IF EXISTS rental_group_attachments_insert ON public.rental_group_attachments;
DROP POLICY IF EXISTS rental_group_attachments_admin ON public.rental_group_attachments;

-- profile_tags
CREATE POLICY profile_tags_select ON public.profile_tags
  FOR SELECT TO authenticated
  USING (
    public.is_admin()
    OR owner_user_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM public.viewing_requests vr
      WHERE vr.client_tag_id = profile_tags.id
        AND (
          vr.created_by_user_id = auth.uid()
          OR EXISTS (
            SELECT 1 FROM public.listings l
            WHERE l.id = vr.listing_id
              AND (l.owner_id = auth.uid() OR l.created_by_id = auth.uid())
          )
        )
    )
    OR EXISTS (
      SELECT 1 FROM public.chat_threads ct
      JOIN public.leads ld ON ld.thread_id = ct.id
      WHERE ld.qualification_json->>'client_tag_code' = profile_tags.code
        AND (
          ct.user_id = auth.uid()
          OR EXISTS (
            SELECT 1 FROM public.listings l
            WHERE l.id = ld.listing_id AND l.owner_id = auth.uid()
          )
        )
    )
  );

CREATE POLICY profile_tags_insert ON public.profile_tags
  FOR INSERT TO authenticated
  WITH CHECK (
    public.is_admin()
    OR owner_user_id = auth.uid()
  );

-- viewing_requests
CREATE POLICY viewing_requests_select ON public.viewing_requests
  FOR SELECT TO authenticated
  USING (
    public.is_admin()
    OR created_by_user_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM public.listings l
      WHERE l.id = viewing_requests.listing_id
        AND (l.owner_id = auth.uid() OR l.created_by_id = auth.uid())
    )
    OR EXISTS (
      SELECT 1 FROM public.leads ld
      WHERE ld.thread_id = viewing_requests.thread_id
        AND ld.assigned_to = auth.uid()
    )
  );

CREATE POLICY viewing_requests_insert ON public.viewing_requests
  FOR INSERT TO authenticated
  WITH CHECK (
    public.is_admin()
    OR created_by_user_id = auth.uid()
  );

CREATE POLICY viewing_requests_update ON public.viewing_requests
  FOR UPDATE TO authenticated
  USING (
    public.is_admin()
    OR created_by_user_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM public.listings l
      WHERE l.id = viewing_requests.listing_id AND l.owner_id = auth.uid()
    )
  )
  WITH CHECK (
    public.is_admin()
    OR created_by_user_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM public.listings l
      WHERE l.id = viewing_requests.listing_id AND l.owner_id = auth.uid()
    )
  );

-- commission_agreements
CREATE POLICY commission_agreements_select ON public.commission_agreements
  FOR SELECT TO authenticated
  USING (public.is_admin() OR user_id = auth.uid());

CREATE POLICY commission_agreements_insert ON public.commission_agreements
  FOR INSERT TO authenticated
  WITH CHECK (user_id = auth.uid() OR public.is_admin());

-- rental_leases
CREATE POLICY rental_leases_select ON public.rental_leases
  FOR SELECT TO authenticated
  USING (
    public.is_admin()
    OR EXISTS (
      SELECT 1 FROM public.rental_lease_members m
      WHERE m.lease_id = rental_leases.id AND m.user_id = auth.uid()
    )
  );

CREATE POLICY rental_leases_admin ON public.rental_leases
  FOR ALL TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- rental_lease_members
CREATE POLICY rental_lease_members_select ON public.rental_lease_members
  FOR SELECT TO authenticated
  USING (
    public.is_admin()
    OR user_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM public.rental_lease_members m2
      WHERE m2.lease_id = rental_lease_members.lease_id
        AND m2.user_id = auth.uid()
    )
  );

CREATE POLICY rental_lease_members_admin ON public.rental_lease_members
  FOR ALL TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- rental_payment_installments
CREATE POLICY rental_payment_installments_select ON public.rental_payment_installments
  FOR SELECT TO authenticated
  USING (
    public.is_admin()
    OR EXISTS (
      SELECT 1 FROM public.rental_lease_members m
      WHERE m.lease_id = rental_payment_installments.lease_id
        AND m.user_id = auth.uid()
    )
  );

CREATE POLICY rental_payment_installments_admin ON public.rental_payment_installments
  FOR ALL TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- rental_group_attachments
CREATE POLICY rental_group_attachments_select ON public.rental_group_attachments
  FOR SELECT TO authenticated
  USING (
    public.is_admin()
    OR EXISTS (
      SELECT 1 FROM public.rental_lease_members m
      WHERE m.lease_id = rental_group_attachments.lease_id
        AND m.user_id = auth.uid()
    )
  );

CREATE POLICY rental_group_attachments_insert ON public.rental_group_attachments
  FOR INSERT TO authenticated
  WITH CHECK (
    public.is_admin()
    OR EXISTS (
      SELECT 1 FROM public.rental_lease_members m
      WHERE m.lease_id = rental_group_attachments.lease_id
        AND m.user_id = auth.uid()
    )
  );

CREATE POLICY rental_group_attachments_admin ON public.rental_group_attachments
  FOR ALL TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- updated_at trigger for viewing_requests
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS viewing_requests_updated_at ON public.viewing_requests;
CREATE TRIGGER viewing_requests_updated_at
  BEFORE UPDATE ON public.viewing_requests
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at();

DROP TRIGGER IF EXISTS rental_leases_updated_at ON public.rental_leases;
CREATE TRIGGER rental_leases_updated_at
  BEFORE UPDATE ON public.rental_leases
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at();
