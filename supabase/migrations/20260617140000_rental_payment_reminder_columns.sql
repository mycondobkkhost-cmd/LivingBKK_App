-- Phase 28: reminder tracking on payment installments

ALTER TABLE public.rental_payment_installments
  ADD COLUMN IF NOT EXISTS reminders_sent_days_before int[] NOT NULL DEFAULT '{}',
  ADD COLUMN IF NOT EXISTS reminders_paused boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS slip jsonb;
