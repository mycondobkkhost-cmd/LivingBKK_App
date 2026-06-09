-- Viewing staff agents (Agent One … Five) + scoped appointment access
-- enum viewing_staff เพิ่มใน 20260607165000_user_role_viewing_staff.sql

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS staff_slug text;

CREATE UNIQUE INDEX IF NOT EXISTS profiles_staff_slug_uidx
  ON public.profiles (staff_slug)
  WHERE staff_slug IS NOT NULL;

COMMENT ON COLUMN public.profiles.staff_slug IS
  'Stable slug for viewing_staff (e.g. agent-one) — used in guide_staff_id fallback';

CREATE OR REPLACE FUNCTION public.is_viewing_staff()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.profiles
    WHERE id = auth.uid()
      AND role = 'viewing_staff'::public.user_role
  );
$$;

GRANT EXECUTE ON FUNCTION public.is_viewing_staff() TO authenticated;

DROP POLICY IF EXISTS appointments_assignee_select ON public.appointments;
CREATE POLICY appointments_assignee_select ON public.appointments
  FOR SELECT TO authenticated
  USING (
    assigned_to = auth.uid()
    OR guide_staff_id = auth.uid()::text
    OR guide_staff_id = (
      SELECT staff_slug FROM public.profiles WHERE id = auth.uid()
    )
  );

DROP POLICY IF EXISTS appointments_assignee_update ON public.appointments;
CREATE POLICY appointments_assignee_update ON public.appointments
  FOR UPDATE TO authenticated
  USING (
    assigned_to = auth.uid()
    OR guide_staff_id = auth.uid()::text
    OR guide_staff_id = (
      SELECT staff_slug FROM public.profiles WHERE id = auth.uid()
    )
  )
  WITH CHECK (
    assigned_to = auth.uid()
    OR guide_staff_id = auth.uid()::text
    OR guide_staff_id = (
      SELECT staff_slug FROM public.profiles WHERE id = auth.uid()
    )
  );

ALTER TABLE public.viewing_reports ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS viewing_reports_admin ON public.viewing_reports;
CREATE POLICY viewing_reports_admin ON public.viewing_reports
  FOR ALL TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

DROP POLICY IF EXISTS viewing_reports_staff_select ON public.viewing_reports;
CREATE POLICY viewing_reports_staff_select ON public.viewing_reports
  FOR SELECT TO authenticated
  USING (
    public.is_viewing_staff()
    AND (
      guide_staff_id = auth.uid()::text
      OR guide_staff_id = (
        SELECT staff_slug FROM public.profiles WHERE id = auth.uid()
      )
    )
  );

DROP POLICY IF EXISTS viewing_reports_staff_write ON public.viewing_reports;
CREATE POLICY viewing_reports_staff_write ON public.viewing_reports
  FOR INSERT TO authenticated
  WITH CHECK (
    public.is_viewing_staff()
    AND (
      guide_staff_id = auth.uid()::text
      OR guide_staff_id = (
        SELECT staff_slug FROM public.profiles WHERE id = auth.uid()
      )
    )
  );

DROP POLICY IF EXISTS viewing_reports_staff_update ON public.viewing_reports;
CREATE POLICY viewing_reports_staff_update ON public.viewing_reports
  FOR UPDATE TO authenticated
  USING (
    public.is_viewing_staff()
    AND (
      guide_staff_id = auth.uid()::text
      OR guide_staff_id = (
        SELECT staff_slug FROM public.profiles WHERE id = auth.uid()
      )
    )
  )
  WITH CHECK (
    public.is_viewing_staff()
    AND (
      guide_staff_id = auth.uid()::text
      OR guide_staff_id = (
        SELECT staff_slug FROM public.profiles WHERE id = auth.uid()
      )
    )
  );

-- Seed Agent One … Five (password: demo12345)
CREATE EXTENSION IF NOT EXISTS pgcrypto;

DO $$
DECLARE
  agents text[][] := ARRAY[
    ARRAY['33333333-3333-3333-3333-333333330001', 'agent-one@proppiter.local', 'Agent One', 'agent-one', '081-234-5601'],
    ARRAY['33333333-3333-3333-3333-333333330002', 'agent-two@proppiter.local', 'Agent Two', 'agent-two', '081-234-5602'],
    ARRAY['33333333-3333-3333-3333-333333330003', 'agent-three@proppiter.local', 'Agent Three', 'agent-three', '081-234-5603'],
    ARRAY['33333333-3333-3333-3333-333333330004', 'agent-four@proppiter.local', 'Agent Four', 'agent-four', '081-234-5604'],
    ARRAY['33333333-3333-3333-3333-333333330005', 'agent-five@proppiter.local', 'Agent Five', 'agent-five', '081-234-5605']
  ];
  row text[];
  uid uuid;
BEGIN
  FOREACH row SLICE 1 IN ARRAY agents
  LOOP
    uid := row[1]::uuid;

    DELETE FROM auth.identities WHERE user_id = uid;
    DELETE FROM public.profiles WHERE id = uid;
    DELETE FROM auth.users WHERE id = uid;

    INSERT INTO auth.users (
      instance_id,
      id,
      aud,
      role,
      email,
      encrypted_password,
      email_confirmed_at,
      confirmation_token,
      recovery_token,
      email_change_token_new,
      email_change,
      raw_app_meta_data,
      raw_user_meta_data,
      created_at,
      updated_at
    )
    VALUES (
      '00000000-0000-0000-0000-000000000000',
      uid,
      'authenticated',
      'authenticated',
      row[2],
      crypt('demo12345', gen_salt('bf')),
      now(),
      '',
      '',
      '',
      '',
      '{"provider":"email","providers":["email"]}',
      jsonb_build_object(
        'role', 'viewing_staff',
        'display_name', row[3],
        'staff_slug', row[4]
      ),
      now(),
      now()
    );

    INSERT INTO auth.identities (
      provider_id,
      user_id,
      identity_data,
      provider,
      last_sign_in_at,
      created_at,
      updated_at
    )
    VALUES (
      uid::text,
      uid,
      jsonb_build_object(
        'sub', uid::text,
        'email', row[2],
        'email_verified', true
      ),
      'email',
      now(),
      now(),
      now()
    );

    INSERT INTO public.profiles (id, role, display_name, phone, staff_slug)
    VALUES (uid, 'viewing_staff', row[3], row[5], row[4])
    ON CONFLICT (id) DO UPDATE SET
      role = 'viewing_staff',
      display_name = EXCLUDED.display_name,
      phone = EXCLUDED.phone,
      staff_slug = EXCLUDED.staff_slug;
  END LOOP;
END $$;
