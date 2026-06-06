-- สถานะรอหลังบ้านตรวจก่อนเผยแพร่ (หลังผู้ใช้กดส่งประกาศ)

ALTER TYPE public.listing_status ADD VALUE IF NOT EXISTS 'pending_review';

COMMENT ON TYPE public.listing_status IS
  'draft | pending_review (submitted) | published | hidden | expired | archived';
