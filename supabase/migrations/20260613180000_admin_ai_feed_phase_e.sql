-- Phase E: moderation flag FK สำหรับ AI Feed

ALTER TABLE public.admin_ai_feed
  ADD COLUMN IF NOT EXISTS moderation_flag_id uuid
    REFERENCES public.moderation_flags (id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS admin_ai_feed_mod_flag_idx
  ON public.admin_ai_feed (moderation_flag_id)
  WHERE moderation_flag_id IS NOT NULL;
