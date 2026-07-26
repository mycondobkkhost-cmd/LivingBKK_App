-- ทรัพย์ที่ไม่มี listing_id ใน DB แต่มี listing_code ต้องแยก thread ได้หลายห้อง
-- เดิม: user ละ 1 ห้องเมื่อ listing_id IS NULL → เปิดแชททรัพย์ที่ 2 ล้มเหลวเงียบๆ

DROP INDEX IF EXISTS public.chat_threads_user_discovery_uidx;

CREATE UNIQUE INDEX IF NOT EXISTS chat_threads_user_discovery_uidx
  ON public.chat_threads (user_id)
  WHERE room_kind = 'property'
    AND listing_id IS NULL
    AND (listing_code IS NULL OR btrim(listing_code) = '');

CREATE UNIQUE INDEX IF NOT EXISTS chat_threads_user_property_code_uidx
  ON public.chat_threads (user_id, listing_code)
  WHERE room_kind = 'property'
    AND listing_code IS NOT NULL
    AND btrim(listing_code) <> '';
