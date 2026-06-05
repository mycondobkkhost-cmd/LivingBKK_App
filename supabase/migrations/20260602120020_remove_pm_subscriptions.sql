-- ยกเลิกแพ็ก PM subscription (โพสต์ฟรีทุกคน) — รายได้จาก Success Fee เท่านั้น

DROP POLICY IF EXISTS pm_select ON public.property_management_subscriptions;
DROP POLICY IF EXISTS pm_admin_write ON public.property_management_subscriptions;

DROP TABLE IF EXISTS public.property_management_subscriptions CASCADE;

DROP TYPE IF EXISTS public.pm_subscription_status;
