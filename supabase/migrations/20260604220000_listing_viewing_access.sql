-- การเปิดห้องนัดดู (เก็บตอนลงประกาศ — สอบถามเพิ่มเมื่อมีลูกค้าสนใจ)

ALTER TABLE public.listings
  ADD COLUMN IF NOT EXISTS viewing_access jsonb NOT NULL DEFAULT '{"follow_up_later": true}'::jsonb;

COMMENT ON COLUMN public.listings.viewing_access IS
  'วิธีเปิดห้องนัดดู: modes owner_open|juristic_key|mailbox_key, owner_notice_days, note, follow_up_later';
