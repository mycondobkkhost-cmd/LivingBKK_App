-- ลายน้ำ PROPPITER ฝังในไฟล์รูปหลังเผยแพร่

ALTER TABLE public.listing_images
  ADD COLUMN IF NOT EXISTS watermark_applied_at timestamptz;

COMMENT ON COLUMN public.listing_images.watermark_applied_at IS
  'เมื่อใส่ลายน้ำ PROPPITER ฝังในไฟล์แล้ว (หลัง publish)';
