-- Post-viewing follow-up outcome on appointments

ALTER TABLE public.appointments
  ADD COLUMN IF NOT EXISTS follow_up jsonb;

COMMENT ON COLUMN public.appointments.follow_up IS
  'Post-viewing: decision continue|closed, intent consider|find_more|both, reason, recorded_at';
