-- Optional: sample demand post for board testing (run manually in SQL Editor as admin user)
-- Replace CREATED_BY_UUID with your auth.users id after first signup

/*
INSERT INTO public.demand_posts (
  created_by,
  title,
  description,
  transaction_type,
  property_type,
  max_price_net,
  min_area_sqm,
  max_distance_bts_km,
  status,
  open_until
) VALUES (
  'CREATED_BY_UUID'::uuid,
  'หาคอนโดย่านทองหล่อ',
  'ห่าง BTS ไม่เกิน 1.5 กม. ขนาด 30 ตร.ม. ขึ้นไป ไม่เกิน 15,000 บาท',
  'rent',
  'condo',
  15000,
  30,
  1.5,
  'open',
  now() + interval '30 days'
);
*/
