-- โครงสร้างค่าคอมที่ผู้เสนอระบุ (ไม่ผูกกับ % ใน dropdown บทบาท)

ALTER TABLE public.demand_offers
  ADD COLUMN IF NOT EXISTS commission_scheme text,
  ADD COLUMN IF NOT EXISTS commission_note text;
