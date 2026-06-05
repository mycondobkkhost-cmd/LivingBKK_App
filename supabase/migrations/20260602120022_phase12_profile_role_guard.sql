-- Phase 12: ห้ามผู้ใช้ตั้ง role = admin เอง (ต้องตั้งผ่าน SQL / admin ที่มีอยู่)

CREATE OR REPLACE FUNCTION public.profiles_role_guard()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NEW.role = 'admin' AND (OLD.role IS NULL OR OLD.role IS DISTINCT FROM 'admin') THEN
    IF NOT public.is_admin() THEN
      RAISE EXCEPTION 'cannot_self_assign_admin'
        USING HINT = 'ติดต่อทีมงานเพื่อตั้ง role admin ใน Supabase';
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS profiles_role_guard_trigger ON public.profiles;
CREATE TRIGGER profiles_role_guard_trigger
  BEFORE UPDATE OF role ON public.profiles
  FOR EACH ROW
  EXECUTE FUNCTION public.profiles_role_guard();
