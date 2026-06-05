-- แก้บัญชี demo-admin ที่ล็อกอินแล้ว error 500
-- รันใน Supabase → SQL Editor → Run
--
-- หลังรันเสร็จ ล็อกอิน:
--   อีเมล: demo-admin@livingbkk.local
--   รหัส: demo12345

CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ลบบัญชีเดิมที่ insert ไม่ครบ (ทำให้ Auth error 500)
DELETE FROM auth.identities WHERE user_id = '22222222-2222-2222-2222-222222222222';
DELETE FROM public.profiles WHERE id = '22222222-2222-2222-2222-222222222222';
DELETE FROM auth.users WHERE id = '22222222-2222-2222-2222-222222222222';

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
  '22222222-2222-2222-2222-222222222222',
  'authenticated',
  'authenticated',
  'demo-admin@livingbkk.local',
  crypt('demo12345', gen_salt('bf')),
  now(),
  '',
  '',
  '',
  '',
  '{"provider":"email","providers":["email"]}',
  '{"role":"admin","display_name":"LivingBKK Demo Admin"}',
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
  '22222222-2222-2222-2222-222222222222',
  '22222222-2222-2222-2222-222222222222',
  jsonb_build_object(
    'sub', '22222222-2222-2222-2222-222222222222',
    'email', 'demo-admin@livingbkk.local',
    'email_verified', true
  ),
  'email',
  now(),
  now(),
  now()
);

INSERT INTO public.profiles (id, role, display_name)
VALUES (
  '22222222-2222-2222-2222-222222222222',
  'admin',
  'LivingBKK Demo Admin'
)
ON CONFLICT (id) DO UPDATE SET
  role = 'admin',
  display_name = EXCLUDED.display_name;
