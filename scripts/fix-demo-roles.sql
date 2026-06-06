-- แก้ role บัญชี demo (มี trigger ห้าม promote เป็น admin ผ่าน UPDATE)
-- รันใน Supabase Dashboard → SQL Editor

ALTER TABLE public.profiles DISABLE TRIGGER profiles_role_guard_trigger;

UPDATE public.profiles p
SET role = 'owner', display_name = 'Demo Owner'
FROM auth.users u
WHERE p.id = u.id AND u.email = 'demo-owner@livingbkk.local';

UPDATE public.profiles p
SET role = 'admin', display_name = 'Demo Admin'
FROM auth.users u
WHERE p.id = u.id AND u.email = 'demo-admin@livingbkk.local';

UPDATE public.profiles p
SET role = 'seeker', display_name = 'Demo Seeker'
FROM auth.users u
WHERE p.id = u.id AND u.email = 'demo-seeker@livingbkk.local';

ALTER TABLE public.profiles ENABLE TRIGGER profiles_role_guard_trigger;
