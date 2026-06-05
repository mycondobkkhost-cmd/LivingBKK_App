-- ชื่อและเบอร์ติดต่อในฟอร์มเสนอทรัพย์

ALTER TABLE public.demand_offers
  ADD COLUMN IF NOT EXISTS contact_name text,
  ADD COLUMN IF NOT EXISTS contact_phone text;
