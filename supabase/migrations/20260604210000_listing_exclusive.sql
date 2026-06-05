-- PROPPITER: ฝากทรัพย์ Exclusive (เจ้าของ) + ทรัพย์ Exclusive นายหน้า + ตั้งค่าดันฟีดอัตโนมัติ

CREATE TABLE IF NOT EXISTS public.app_platform_settings (
  id text PRIMARY KEY DEFAULT 'default',
  exclusive_rent_bump_hours int NOT NULL DEFAULT 6
    CHECK (exclusive_rent_bump_hours >= 1 AND exclusive_rent_bump_hours <= 168),
  exclusive_sale_bump_hours int NOT NULL DEFAULT 24
    CHECK (exclusive_sale_bump_hours >= 1 AND exclusive_sale_bump_hours <= 720),
  exclusive_owner_feed_boost int NOT NULL DEFAULT 45
    CHECK (exclusive_owner_feed_boost >= 0 AND exclusive_owner_feed_boost <= 200),
  exclusive_agent_feed_boost int NOT NULL DEFAULT 55
    CHECK (exclusive_agent_feed_boost >= 0 AND exclusive_agent_feed_boost <= 200),
  updated_at timestamptz NOT NULL DEFAULT now()
);

COMMENT ON TABLE public.app_platform_settings IS
  'ตั้งค่าระบบ Exclusive — ช่วงดันฟีดอัตโนมัติและคะแนนฟีด (แอดมินแก้ได้)';

INSERT INTO public.app_platform_settings (id)
VALUES ('default')
ON CONFLICT (id) DO NOTHING;

ALTER TABLE public.app_platform_settings ENABLE ROW LEVEL SECURITY;

CREATE POLICY app_platform_settings_public_read ON public.app_platform_settings
  FOR SELECT TO public
  USING (true);

CREATE POLICY app_platform_settings_admin_write ON public.app_platform_settings
  FOR ALL TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

ALTER TABLE public.listings
  ADD COLUMN IF NOT EXISTS owner_exclusive_mandate boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS owner_exclusive_contract_days int
    CHECK (owner_exclusive_contract_days IS NULL OR owner_exclusive_contract_days BETWEEN 30 AND 365),
  ADD COLUMN IF NOT EXISTS owner_exclusive_status text
    CHECK (owner_exclusive_status IS NULL OR owner_exclusive_status IN ('interested', 'contract_pending', 'active')),
  ADD COLUMN IF NOT EXISTS agent_exclusive boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS next_auto_bump_at timestamptz;

COMMENT ON COLUMN public.listings.owner_exclusive_mandate IS
  'เจ้าของสนใจฝาก Exclusive กับ PROPPITER — ห้ามฝากที่อื่นในช่วงสัญญา';
COMMENT ON COLUMN public.listings.agent_exclusive IS
  'นายหน้ามีสิทธิ์ขาย/เช่าเพียงรายเดียว (ดีลตรงกับเจ้าของ)';

CREATE INDEX IF NOT EXISTS listings_owner_exclusive_idx
  ON public.listings (owner_exclusive_mandate)
  WHERE owner_exclusive_mandate = true AND status = 'published';

CREATE INDEX IF NOT EXISTS listings_agent_exclusive_idx
  ON public.listings (agent_exclusive)
  WHERE agent_exclusive = true AND status = 'published';

-- ดันฟีดอัตโนมัติสำหรับ Exclusive ที่เผยแพร่แล้ว (เรียกจาก Cron / Edge Function รายชั่วโมง)
CREATE OR REPLACE FUNCTION public.process_exclusive_auto_bumps()
RETURNS int
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  cfg record;
  bumped int := 0;
BEGIN
  SELECT exclusive_rent_bump_hours, exclusive_sale_bump_hours
  INTO cfg
  FROM public.app_platform_settings
  WHERE id = 'default';

  IF NOT FOUND THEN
    cfg.exclusive_rent_bump_hours := 6;
    cfg.exclusive_sale_bump_hours := 24;
  END IF;

  WITH due AS (
    SELECT l.id,
      CASE
        WHEN l.listing_type IN ('sale', 'sale_installment') THEN cfg.exclusive_sale_bump_hours
        ELSE cfg.exclusive_rent_bump_hours
      END AS bump_hours
    FROM public.listings l
    WHERE l.status = 'published'
      AND l.owner_exclusive_mandate = true
      AND (l.next_auto_bump_at IS NULL OR l.next_auto_bump_at <= now())
  ),
  updated AS (
    UPDATE public.listings l
    SET
      last_bump_at = now(),
      next_auto_bump_at = now() + (d.bump_hours || ' hours')::interval,
      updated_at = now()
    FROM due d
    WHERE l.id = d.id
    RETURNING l.id
  )
  SELECT count(*)::int INTO bumped FROM updated;

  RETURN bumped;
END;
$$;

COMMENT ON FUNCTION public.process_exclusive_auto_bumps IS
  'Cron: ดันฟีดฟรีทรัพย์ฝาก Exclusive เจ้าของ — เช่าใช้ exclusive_rent_bump_hours, ขายใช้ exclusive_sale_bump_hours';

-- ตั้ง next_auto_bump เมื่ออนุมัติเผยแพร่ครั้งแรก
CREATE OR REPLACE FUNCTION public.listings_exclusive_bump_schedule()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
  rent_h int;
  sale_h int;
  bump_h int;
BEGIN
  IF NEW.status = 'published'
    AND (TG_OP = 'INSERT' OR OLD.status IS DISTINCT FROM 'published')
    AND NEW.owner_exclusive_mandate = true
    AND NEW.next_auto_bump_at IS NULL THEN
    SELECT exclusive_rent_bump_hours, exclusive_sale_bump_hours
    INTO rent_h, sale_h
    FROM public.app_platform_settings
    WHERE id = 'default';
    rent_h := COALESCE(rent_h, 6);
    sale_h := COALESCE(sale_h, 24);
    bump_h := CASE
      WHEN NEW.listing_type IN ('sale', 'sale_installment') THEN sale_h
      ELSE rent_h
    END;
    NEW.next_auto_bump_at := now() + (bump_h || ' hours')::interval;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS listings_exclusive_bump_schedule_trg ON public.listings;
CREATE TRIGGER listings_exclusive_bump_schedule_trg
  BEFORE INSERT OR UPDATE ON public.listings
  FOR EACH ROW
  EXECUTE FUNCTION public.listings_exclusive_bump_schedule();

DROP VIEW IF EXISTS public.listings_public CASCADE;

CREATE OR REPLACE VIEW public.listings_public
WITH (security_invoker = true)
AS
SELECT
  l.id,
  l.listing_code,
  l.listing_type,
  l.status,
  l.property_type,
  l.title,
  l.description_public,
  l.price_net,
  l.co_agent_listing_type,
  l.investor_category,
  l.yield_percent,
  l.pet_allowed,
  l.smoking_allowed,
  l.furnished,
  l.bedrooms,
  l.bathrooms,
  l.area_sqm,
  l.floor_range,
  l.district,
  l.subdistrict,
  COALESCE(l.project_name, pp.name_th) AS project_name,
  pp.name_en AS project_name_en,
  pp.slug AS project_slug,
  pp.bts_station AS project_bts,
  l.geo_zone_id,
  gz.slug AS geo_zone_slug,
  l.max_distance_bts_km,
  l.location_public,
  CASE WHEN l.location_public IS NOT NULL
    THEN ST_Y(l.location_public::geometry)::double precision END AS lat,
  CASE WHEN l.location_public IS NOT NULL
    THEN ST_X(l.location_public::geometry)::double precision END AS lng,
  l.co_agent_eligible,
  l.co_agent_listing_type AS co_agent_status_display,
  l.available_from,
  l.available_again,
  l.last_bump_at,
  l.published_at,
  l.created_at,
  l.updated_at,
  l.owner_exclusive_mandate,
  l.owner_exclusive_contract_days,
  l.agent_exclusive,
  inv.inventory_code,
  inv.id AS inventory_id,
  inv.member_count AS inventory_member_count,
  COALESCE(
    (
      SELECT json_agg(li.public_url ORDER BY li.sort_order)
      FROM public.listing_images li
      WHERE li.listing_id = l.id
        AND li.public_url IS NOT NULL
        AND li.moderation_status IN ('approved', 'pending')
    ),
    '[]'::json
  ) AS image_urls
FROM public.listings l
LEFT JOIN public.property_inventory inv ON inv.id = l.inventory_id
LEFT JOIN public.geo_zones gz ON gz.id = l.geo_zone_id
LEFT JOIN public.property_projects pp ON pp.id = l.project_id
WHERE l.status = 'published'
  AND (l.expires_at IS NULL OR l.expires_at > now())
  AND (
    l.inventory_id IS NULL
    OR l.id = inv.display_listing_id
  );

GRANT SELECT ON public.listings_public TO authenticated, anon;
