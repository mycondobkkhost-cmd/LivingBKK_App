-- เปิดคลังลับให้ demo-admin (รันบน Supabase SQL Editor ครั้งเดียว)
UPDATE public.profiles
SET admin_tier = 'ceo'
WHERE id = (
  SELECT id FROM auth.users WHERE email = 'demo-admin@livingbkk.local' LIMIT 1
);
