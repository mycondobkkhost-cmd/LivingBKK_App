-- PROPPITER: home promo carousel banners (max 10 active)

CREATE TABLE IF NOT EXISTS public.home_promo_banners (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  slug text NOT NULL UNIQUE,
  sort_order int NOT NULL CHECK (sort_order >= 1 AND sort_order <= 10),
  is_active boolean NOT NULL DEFAULT true,
  title_th text NOT NULL,
  title_en text NOT NULL,
  subtitle_th text NOT NULL DEFAULT '',
  subtitle_en text NOT NULL DEFAULT '',
  detail_th text NOT NULL DEFAULT '',
  detail_en text NOT NULL DEFAULT '',
  bullet_th jsonb NOT NULL DEFAULT '[]'::jsonb,
  bullet_en jsonb NOT NULL DEFAULT '[]'::jsonb,
  badge_th text,
  badge_en text,
  image_url text,
  image_storage_path text,
  gradient_start text NOT NULL DEFAULT '#12122B',
  gradient_end text NOT NULL DEFAULT '#FF5B8A',
  accent_color text NOT NULL DEFAULT '#FFD54F',
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

COMMENT ON TABLE public.home_promo_banners IS
  'Home carousel promo banners — up to 10 active, managed from admin';

CREATE UNIQUE INDEX IF NOT EXISTS home_promo_banners_active_sort_idx
  ON public.home_promo_banners (sort_order)
  WHERE is_active = true;

CREATE OR REPLACE FUNCTION public.home_promo_banners_active_limit()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
  active_count int;
BEGIN
  IF NEW.is_active THEN
    SELECT count(*)::int INTO active_count
    FROM public.home_promo_banners
    WHERE is_active = true
      AND id IS DISTINCT FROM NEW.id;
    IF active_count >= 10 THEN
      RAISE EXCEPTION 'home_promo_max_active'
        USING HINT = 'Maximum 10 active promo banners';
    END IF;
  END IF;
  NEW.updated_at := now();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS home_promo_banners_active_limit_trg ON public.home_promo_banners;
CREATE TRIGGER home_promo_banners_active_limit_trg
  BEFORE INSERT OR UPDATE ON public.home_promo_banners
  FOR EACH ROW
  EXECUTE FUNCTION public.home_promo_banners_active_limit();

ALTER TABLE public.home_promo_banners ENABLE ROW LEVEL SECURITY;

CREATE POLICY home_promo_banners_public_read ON public.home_promo_banners
  FOR SELECT TO public
  USING (is_active = true);

CREATE POLICY home_promo_banners_admin_all ON public.home_promo_banners
  FOR ALL TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- Public read bucket for promo images (21:9 ultra-wide)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'home-promo',
  'home-promo',
  true,
  524288,
  ARRAY['image/jpeg', 'image/png', 'image/webp']
)
ON CONFLICT (id) DO NOTHING;

CREATE POLICY home_promo_storage_select ON storage.objects
  FOR SELECT TO public
  USING (bucket_id = 'home-promo');

CREATE POLICY home_promo_storage_admin_write ON storage.objects
  FOR ALL TO authenticated
  USING (bucket_id = 'home-promo' AND public.is_admin())
  WITH CHECK (bucket_id = 'home-promo' AND public.is_admin());

-- Seed defaults (images uploaded later via admin; app falls back to bundled assets by slug)
INSERT INTO public.home_promo_banners (
  slug, sort_order, title_th, title_en, subtitle_th, subtitle_en,
  detail_th, detail_en, bullet_th, bullet_en, gradient_start, gradient_end, accent_color
) VALUES
(
  'exclusive_rent', 1,
  'ฝากปล่อยเช่า Exclusive', 'Exclusive rental management',
  'ขั้นต่ำ 60 วัน · ล้างแอร์ฟรี 1 ครั้ง', 'Min. 60 days · Free AC cleaning once',
  'ฝากปล่อยเช่ากับ PROPPITER แบบ Exclusive — ทีมงานดูแลครบตั้งแต่หาผู้เช่าจนถึงส่งมอบห้อง',
  'List your rental exclusively with PROPPITER — full-service from tenant matching to handover.',
  '["สัญญาขั้นต่ำเพียง 60 วัน","รับโปรโมชั่นล้างแอร์ฟรี 1 ครั้ง ระหว่างที่มีผู้เช่า","ไม่จำกัดจำนวนเครื่องแอร์","ทีมงานช่วยโปรโมตและคัดกรองผู้เช่าให้"]'::jsonb,
  '["Minimum contract just 60 days","Free AC cleaning once while tenanted","Unlimited AC units included","Our team promotes and screens tenants for you"]'::jsonb,
  '#12122B', '#FF5B8A', '#FFD54F'
),
(
  'agent_partner', 2,
  'รับสมัครพาร์ทเนอร์นายหน้า', 'Agent partner program',
  'ทั้งขายและเช่า · มีงานรองรับตลอด', 'Sales & rent · Steady deal flow',
  'เข้าร่วมเครือข่ายนายหน้า PROPPITER — รับงานขายและเช่าจากแพลตฟอร์ม พร้อมทีมแอดมินช่วยประสาน',
  'Join PROPPITER agent partners — sales and rental leads from the platform with admin support.',
  '["รับงานทั้งขายและเช่าในพื้นที่ กทม.และปริมณฑล","มีลีดและนัดชมจากระบบแมตช์","Blind intermediation ตามกฎแพลตฟอร์ม","รายได้จาก Success Fee เมื่อปิดดีล"]'::jsonb,
  '["Sales and rental deals in Bangkok metro","Leads and viewings from our matching engine","Blind intermediation per platform rules","Success Fee on closed deals"]'::jsonb,
  '#12122B', '#7C3AED', '#FF8A65'
),
(
  'room_service', 3,
  'บริการตรวจรับห้องคืน', 'Move-out room services',
  'เริ่มต้นที่ 1,500 บาท · แม่บ้าน · ซ่อม · รีโนเวท', 'From ฿1,500 · cleaning · repairs · renovation',
  'บริการตรวจรับห้องคืน เริ่มต้นที่ 1,500 บาท — จ้างแม่บ้าน ซ่อมแซมและรีโนเวทในราคาพิเศษเมื่อจองผ่านทีมงาน PROPPITER',
  'Move-out room inspection from ฿1,500 — housekeeping, repairs and renovation at special rates via our team.',
  '["ตรวจรับห้องคืน เริ่มต้นที่ 1,500 บาท","รายงานภาพประกอบหลังตรวจรับ","จ้างแม่บ้านทำความสะอาดลึก","ซ่อมแซมและรีโนเวทก่อนปล่อยเช่าใหม่"]'::jsonb,
  '["Move-out inspection from ฿1,500","Photo report included","Deep cleaning by vetted housekeeping","Repairs and renovation before re-listing"]'::jsonb,
  '#12122B', '#FF5B8A', '#4DD0E1'
)
ON CONFLICT (slug) DO NOTHING;
