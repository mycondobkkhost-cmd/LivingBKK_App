-- ราคาโปรโมชั่นขาย (แยกจาก price_internal = โปรเช่า)
ALTER TABLE public.listings
  ADD COLUMN IF NOT EXISTS price_sale_promo_net numeric;

COMMENT ON COLUMN public.listings.price_sale_promo_net IS
  'ราคาขายโปรโมชั่น (ต่ำกว่า price_sale_net หรือ price_net เมื่อขายอย่างเดียว)';
