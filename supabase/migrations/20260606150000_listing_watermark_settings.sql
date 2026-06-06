-- ตั้งค่าลายน้ำประกาศ — แอดมินอัปโหลดจากหลังบ้าน

ALTER TABLE public.app_platform_settings
  ADD COLUMN IF NOT EXISTS listing_watermark_storage_path text,
  ADD COLUMN IF NOT EXISTS listing_watermark_public_url text,
  ADD COLUMN IF NOT EXISTS listing_watermark_opacity smallint NOT NULL DEFAULT 72,
  ADD COLUMN IF NOT EXISTS listing_watermark_size_ratio numeric(5, 4) NOT NULL DEFAULT 0.0800,
  ADD COLUMN IF NOT EXISTS listing_watermark_enabled boolean NOT NULL DEFAULT true;

COMMENT ON COLUMN public.app_platform_settings.listing_watermark_storage_path IS
  'path ใน bucket brand-assets เช่น watermark/listing-watermark.png';
COMMENT ON COLUMN public.app_platform_settings.listing_watermark_opacity IS
  'ความทึบลายน้ำ 0–255 (แนะนำ 60–90 กึ่งโปร่งแสง)';
COMMENT ON COLUMN public.app_platform_settings.listing_watermark_size_ratio IS
  'ขนาดลายน้ำเทียบความกว้างรูป เช่น 0.08 = 8%';
