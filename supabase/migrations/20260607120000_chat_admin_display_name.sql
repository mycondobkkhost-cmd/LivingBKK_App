-- Admin custom label per chat thread (CRM-style rename)
ALTER TABLE public.chat_threads
  ADD COLUMN IF NOT EXISTS admin_display_name text;

COMMENT ON COLUMN public.chat_threads.admin_display_name IS
  'Optional display name set by admin for inbox / CRM';
