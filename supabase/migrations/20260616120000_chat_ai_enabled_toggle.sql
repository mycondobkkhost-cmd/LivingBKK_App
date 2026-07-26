-- Admin can pause/resume customer-facing AI per thread (independent of claim).

ALTER TABLE public.chat_threads
  ADD COLUMN IF NOT EXISTS ai_enabled boolean NOT NULL DEFAULT true;

COMMENT ON COLUMN public.chat_threads.ai_enabled IS
  'When false, customer messages are stored only — no AI auto-reply until admin re-enables.';

-- Existing claimed threads: keep AI on by default (admin toggles off manually if needed).
UPDATE public.chat_threads
SET ai_enabled = true
WHERE ai_enabled IS DISTINCT FROM true;
