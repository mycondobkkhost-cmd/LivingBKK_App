-- LivingBKK: official brand settings (logo, colors, typography)

CREATE TABLE IF NOT EXISTS public.app_brand_settings (
  id text PRIMARY KEY DEFAULT 'default',
  name text NOT NULL DEFAULT 'LivingBKK',
  tagline_en text NOT NULL DEFAULT 'All deals in one place · Free listing · Real-time updates',
  tagline_th text NOT NULL DEFAULT 'ครบทุกดีลอสังหาฯ · ลงประกาศฟรี · อัปเดตตลอดเวลา',
  logo_mark_url text,
  logo_horizontal_url text,
  logo_white_url text,
  favicon_url text,
  app_icon_url text,
  brand_guide_url text,
  colors jsonb NOT NULL DEFAULT '{
    "purple": "#6C5DD3",
    "purple_light": "#9B6DFF",
    "pink": "#FF5B8A",
    "navy": "#12122B",
    "off_white": "#F7F8FB"
  }'::jsonb,
  typography jsonb NOT NULL DEFAULT '{
    "font_family": "Prompt",
    "weights": ["regular", "medium", "semibold", "bold"]
  }'::jsonb,
  updated_at timestamptz NOT NULL DEFAULT now()
);

COMMENT ON TABLE public.app_brand_settings IS
  'Official LivingBKK brand identity — logo URLs, palette, typography';

INSERT INTO public.app_brand_settings (
  id, name, tagline_en, tagline_th, brand_guide_url,
  logo_mark_url, logo_horizontal_url, logo_white_url, app_icon_url, favicon_url
)
VALUES (
  'default',
  'LivingBKK',
  'All deals in one place · Free listing · Real-time updates',
  'ครบทุกดีลอสังหาฯ · ลงประกาศฟรี · อัปเดตตลอดเวลา',
  'brand/livingbkk-brand-guide.png',
  'brand/logo-mark.png',
  'brand/logo-lockup-light.png',
  'brand/logo-lockup-dark.png',
  'brand/app-icon-gradient.png',
  'brand/favicon-256.png'
)
ON CONFLICT (id) DO UPDATE SET
  tagline_en = EXCLUDED.tagline_en,
  tagline_th = EXCLUDED.tagline_th,
  brand_guide_url = EXCLUDED.brand_guide_url,
  logo_mark_url = EXCLUDED.logo_mark_url,
  logo_horizontal_url = EXCLUDED.logo_horizontal_url,
  logo_white_url = EXCLUDED.logo_white_url,
  app_icon_url = EXCLUDED.app_icon_url,
  favicon_url = EXCLUDED.favicon_url,
  updated_at = now();

ALTER TABLE public.app_brand_settings ENABLE ROW LEVEL SECURITY;

CREATE POLICY app_brand_settings_public_read ON public.app_brand_settings
  FOR SELECT TO public
  USING (true);

CREATE POLICY app_brand_settings_admin_write ON public.app_brand_settings
  FOR ALL TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- Brand asset storage (public read)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'brand-assets',
  'brand-assets',
  true,
  10485760,
  ARRAY['image/png', 'image/jpeg', 'image/webp', 'image/svg+xml']
)
ON CONFLICT (id) DO NOTHING;

CREATE POLICY brand_assets_storage_select ON storage.objects
  FOR SELECT TO public
  USING (bucket_id = 'brand-assets');

CREATE POLICY brand_assets_storage_admin_write ON storage.objects
  FOR ALL TO authenticated
  USING (bucket_id = 'brand-assets' AND public.is_admin())
  WITH CHECK (bucket_id = 'brand-assets' AND public.is_admin());
