-- Security hardening for production auth and admin-only views.

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
    COALESCE(NULLIF(NEW.raw_user_meta_data ->> 'display_name', ''), NEW.email),
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
  IF NEW.role IS DISTINCT FROM OLD.role AND NOT public.is_admin() THEN
    RAISE EXCEPTION 'cannot_self_assign_role'
      USING HINT = 'ติดต่อทีมงานเพื่อเปลี่ยนสิทธิ์บัญชี';
  END IF;
  RETURN NEW;
END;
$$;

ALTER VIEW public.chat_admin_inbox SET (security_invoker = true);
ALTER VIEW public.analytics_platform_stats SET (security_invoker = true);
ALTER VIEW public.client_error_summary SET (security_invoker = true);
