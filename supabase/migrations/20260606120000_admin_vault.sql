-- Phase 23: คลังข้อมูลลับ (vault_assets) + admin_tier ใหม่

-- 1) admin_tier: standard → admin, เพิ่ม ceo
ALTER TABLE public.profiles DROP CONSTRAINT IF EXISTS profiles_admin_tier_check;
UPDATE public.profiles SET admin_tier = 'admin' WHERE admin_tier = 'standard';
ALTER TABLE public.profiles
  ALTER COLUMN admin_tier SET DEFAULT 'admin';
ALTER TABLE public.profiles
  ADD CONSTRAINT profiles_admin_tier_check
  CHECK (admin_tier IN ('admin', 'lead', 'super', 'ceo'));

COMMENT ON COLUMN public.profiles.admin_tier IS
  'CEO/SUPER = คลังลับ · LEAD/ADMIN = ปฏิบัติการเซ็นเซอร์';

-- 2) ตารางกลางเก็บข้อมูลลับ
CREATE TABLE IF NOT EXISTS public.vault_assets (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  entity_type text NOT NULL
    CHECK (entity_type IN ('listing_import', 'listing', 'profile', 'chat_thread')),
  entity_id uuid NOT NULL,
  source_platform text,
  title_preview text,
  listing_id uuid REFERENCES public.listings (id) ON DELETE SET NULL,
  listing_code text,
  profile_id uuid REFERENCES public.profiles (id) ON DELETE SET NULL,
  import_id uuid REFERENCES public.listing_imports (id) ON DELETE SET NULL,
  payload jsonb NOT NULL DEFAULT '{}'::jsonb,
  captured_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (entity_type, entity_id)
);

CREATE INDEX IF NOT EXISTS vault_assets_type_updated_idx
  ON public.vault_assets (entity_type, updated_at DESC);
CREATE INDEX IF NOT EXISTS vault_assets_listing_idx
  ON public.vault_assets (listing_id) WHERE listing_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS vault_assets_profile_idx
  ON public.vault_assets (profile_id) WHERE profile_id IS NOT NULL;

CREATE TRIGGER vault_assets_updated_at
  BEFORE UPDATE ON public.vault_assets
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at();

COMMENT ON TABLE public.vault_assets IS
  'ข้อมูลลับ (PII, ลิงก์ต้นทาง, ข้อความโพสต์เต็ม) — อ่านผ่าน vault-browse เท่านั้น';

-- 3) คำขอ / มอบสิทธิ์ (โครง Phase 23 — UI ต่อยอด)
CREATE TABLE IF NOT EXISTS public.admin_access_requests (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  entity_type text NOT NULL,
  entity_id uuid NOT NULL,
  requested_by uuid NOT NULL REFERENCES public.profiles (id),
  reason text NOT NULL CHECK (length(trim(reason)) >= 8),
  scopes_requested text[] NOT NULL DEFAULT '{}',
  scopes_approved text[],
  grant_hours int,
  status text NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending', 'approved', 'denied', 'expired', 'revoked')),
  reviewed_by uuid REFERENCES public.profiles (id),
  admin_note text,
  reviewed_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.admin_access_grants (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  request_id uuid REFERENCES public.admin_access_requests (id) ON DELETE SET NULL,
  entity_type text NOT NULL,
  entity_id uuid NOT NULL,
  grantee_id uuid NOT NULL REFERENCES public.profiles (id),
  scope text NOT NULL,
  granted_by uuid NOT NULL REFERENCES public.profiles (id),
  expires_at timestamptz,
  revoked_at timestamptz,
  revoked_by uuid REFERENCES public.profiles (id),
  created_at timestamptz NOT NULL DEFAULT now()
);

-- 4) helpers
CREATE OR REPLACE FUNCTION public.is_vault_tier()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid()
      AND role = 'admin'
      AND admin_tier IN ('super', 'ceo')
  );
$$;

GRANT EXECUTE ON FUNCTION public.is_vault_tier() TO authenticated;

-- 5) RLS — vault ไม่เปิด SELECT ตรงจาก client (อ่านผ่าน Edge + service role)
ALTER TABLE public.vault_assets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.admin_access_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.admin_access_grants ENABLE ROW LEVEL SECURITY;

-- demo admin = CEO (seed id)
UPDATE public.profiles
SET admin_tier = 'ceo'
WHERE id = '22222222-2222-2222-2222-222222222222';
