-- Demand offer form fields + enum values (must commit before using new enum labels)

ALTER TYPE public.offerer_capacity ADD VALUE IF NOT EXISTS 'referrer_15';

ALTER TYPE public.chat_thread_category ADD VALUE IF NOT EXISTS 'demand_offer';

ALTER TABLE public.demand_offers
  ADD COLUMN IF NOT EXISTS transaction_type public.listing_type,
  ADD COLUMN IF NOT EXISTS price_max_net numeric(12, 2),
  ADD COLUMN IF NOT EXISTS transfer_terms text;
