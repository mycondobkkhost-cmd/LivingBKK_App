-- สิทธิ์ดูแลทรัพย์ — มอบให้เจ้าของ/โคเอ/ลูกค้า/ทีม (ไม่ใช่เจ้าของกฎหมายเสมอ)

CREATE TYPE public.property_care_role AS ENUM (
  'team_steward',
  'primary_caretaker',
  'co_agent_caretaker',
  'customer_caretaker',
  'view_only'
);

CREATE TYPE public.property_care_status AS ENUM (
  'active',
  'pending_claim',
  'revoked'
);

CREATE TABLE public.property_care_rights (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  listing_id uuid REFERENCES public.listings (id) ON DELETE CASCADE,
  inventory_id uuid REFERENCES public.property_inventory (id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES public.profiles (id) ON DELETE CASCADE,
  care_role public.property_care_role NOT NULL DEFAULT 'primary_caretaker',
  status public.property_care_status NOT NULL DEFAULT 'active',
  is_primary boolean NOT NULL DEFAULT false,
  granted_by uuid REFERENCES public.profiles (id) ON DELETE SET NULL,
  granted_at timestamptz NOT NULL DEFAULT now(),
  invite_code text,
  notes text,
  version int NOT NULL DEFAULT 1,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT property_care_rights_target_chk CHECK (
    listing_id IS NOT NULL OR inventory_id IS NOT NULL
  )
);

CREATE INDEX property_care_rights_user_idx
  ON public.property_care_rights (user_id, status);
CREATE INDEX property_care_rights_listing_idx
  ON public.property_care_rights (listing_id)
  WHERE listing_id IS NOT NULL;
CREATE INDEX property_care_rights_inventory_idx
  ON public.property_care_rights (inventory_id)
  WHERE inventory_id IS NOT NULL;

CREATE UNIQUE INDEX property_care_rights_primary_listing_uidx
  ON public.property_care_rights (listing_id)
  WHERE is_primary = true AND status = 'active' AND listing_id IS NOT NULL;

CREATE UNIQUE INDEX property_care_rights_primary_inventory_uidx
  ON public.property_care_rights (inventory_id)
  WHERE is_primary = true AND status = 'active' AND inventory_id IS NOT NULL;

CREATE TRIGGER property_care_rights_updated_at
  BEFORE UPDATE ON public.property_care_rights
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at();

CREATE TABLE public.property_care_audits (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  right_id uuid NOT NULL REFERENCES public.property_care_rights (id) ON DELETE CASCADE,
  action text NOT NULL,
  actor_id uuid REFERENCES public.profiles (id) ON DELETE SET NULL,
  payload jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.property_care_rights ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.property_care_audits ENABLE ROW LEVEL SECURITY;

CREATE POLICY property_care_rights_admin ON public.property_care_rights
  FOR ALL TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

CREATE POLICY property_care_rights_self_select ON public.property_care_rights
  FOR SELECT TO authenticated
  USING (user_id = auth.uid() AND status = 'active');

CREATE POLICY property_care_audits_admin ON public.property_care_audits
  FOR ALL TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

COMMENT ON TABLE public.property_care_rights IS
  'สิทธิ์ดูแลทรัพย์ในแอป — team_steward=ทีมดูแลแทน, primary_caretaker=ผู้ดูแลหลัก (ดู CODE-GLOSSARY-TH.md)';
