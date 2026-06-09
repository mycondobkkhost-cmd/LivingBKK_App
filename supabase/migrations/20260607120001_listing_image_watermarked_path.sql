-- แยกไฟล์ต้นฉบับ (storage_path) กับรูปมีลายน้ำสำหรับหน้าบ้าน (public_url)

ALTER TABLE public.listing_images
  ADD COLUMN IF NOT EXISTS watermarked_storage_path text;

COMMENT ON COLUMN public.listing_images.storage_path IS
  'ไฟล์ต้นฉบับใน Storage — แอดมินดาวน์โหลดจาก path นี้';
COMMENT ON COLUMN public.listing_images.watermarked_storage_path IS
  'ไฟล์มีลายน้ำ PROPPITER — public_url ชี้มาที่นี่หลังเผยแพร่';
COMMENT ON COLUMN public.listing_images.public_url IS
  'URL สำหรับหน้าบ้าน/ดาวน์โหลดยูส — รูปมีลายน้ำหลัง publish';
