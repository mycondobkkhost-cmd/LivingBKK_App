-- ป้าย HOT บนการ์ดประกาศ — แอดมินตั้งเกณฑ์วิว/ชม. หรือปิดได้

ALTER TABLE public.app_platform_settings
  ADD COLUMN IF NOT EXISTS hot_badge_enabled boolean NOT NULL DEFAULT true,
  ADD COLUMN IF NOT EXISTS hot_views_per_hour_threshold int NOT NULL DEFAULT 100
    CHECK (hot_views_per_hour_threshold >= 1 AND hot_views_per_hour_threshold <= 100000);

COMMENT ON COLUMN public.app_platform_settings.hot_badge_enabled IS
  'เปิด/ปิดป้าย HOT บนการ์ดประกาศแนะนำ';
COMMENT ON COLUMN public.app_platform_settings.hot_views_per_hour_threshold IS
  'เกณฑ์ป้าย HOT — จำนวนวิวขั้นต่ำใน 1 ชั่วโมง';
