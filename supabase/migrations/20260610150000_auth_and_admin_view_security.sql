-- Hardening: users must not self-assign elevated roles; admin views must honor RLS.

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.profiles (id, display_name, role)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data ->> 'display_name', NEW.email),
    'seeker'::public.user_role
  );
  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.profiles_role_guard()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    IF NEW.role IS DISTINCT FROM 'seeker'::public.user_role
      AND current_setting('role', true) IS DISTINCT FROM 'service_role'
      AND NOT public.is_admin()
    THEN
      RAISE EXCEPTION 'cannot_self_assign_role'
        USING HINT = 'ติดต่อทีมงานเพื่อตั้ง role ใน Supabase';
    END IF;
    RETURN NEW;
  END IF;

  IF NEW.role IS DISTINCT FROM OLD.role
    AND current_setting('role', true) IS DISTINCT FROM 'service_role'
    AND NOT public.is_admin()
  THEN
    RAISE EXCEPTION 'cannot_self_assign_role'
      USING HINT = 'ติดต่อทีมงานเพื่อตั้ง role ใน Supabase';
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS profiles_role_guard_trigger ON public.profiles;
CREATE TRIGGER profiles_role_guard_trigger
  BEFORE INSERT OR UPDATE OF role ON public.profiles
  FOR EACH ROW
  EXECUTE FUNCTION public.profiles_role_guard();

ALTER VIEW IF EXISTS public.chat_admin_inbox SET (security_invoker = true);
ALTER VIEW IF EXISTS public.lead_stats_daily SET (security_invoker = true);
ALTER VIEW IF EXISTS public.appointment_stats_daily SET (security_invoker = true);
ALTER VIEW IF EXISTS public.platform_stats_daily SET (security_invoker = true);
ALTER VIEW IF EXISTS public.analytics_platform_stats SET (security_invoker = true);
ALTER VIEW IF EXISTS public.client_error_summary SET (security_invoker = true);
