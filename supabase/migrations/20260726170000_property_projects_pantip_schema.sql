-- Pantip catalog import: allow projects without geocoded pins yet,
-- and expand transit_stations.aliases with Pantip-friendly labels.

ALTER TABLE public.property_projects
  ALTER COLUMN lat DROP NOT NULL,
  ALTER COLUMN lng DROP NOT NULL,
  ALTER COLUMN location DROP NOT NULL;

COMMENT ON COLUMN public.property_projects.lat IS
  'Project pin latitude. Null = catalog-only (awaiting Places/admin geocode).';
COMMENT ON COLUMN public.property_projects.lng IS
  'Project pin longitude. Null = catalog-only (awaiting Places/admin geocode).';

-- Keep location trigger null-safe (already skips when lat/lng null).
CREATE OR REPLACE FUNCTION public.sync_property_project_location()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  IF NEW.lat IS NOT NULL AND NEW.lng IS NOT NULL THEN
    NEW.location := ST_SetSRID(ST_MakePoint(NEW.lng, NEW.lat), 4326)::geography;
  ELSE
    NEW.location := NULL;
  END IF;
  RETURN NEW;
END;
$$;

-- Expand aliases for stations that already exist (do not invent new coords).
UPDATE public.transit_stations SET aliases = ARRAY[
  'BTS อโศก', 'อโศก', 'asok', 'asoke', 'bts asok'
]::text[]
WHERE slug = 'bts-asok';

UPDATE public.transit_stations SET aliases = ARRAY[
  'BTS ทองหล่อ', 'ทองหล่อ', 'thonglor', 'thong lo', 'bts ทองหล่อ'
]::text[]
WHERE slug IN ('bts-thong-lo', 'bts-thonglor');

UPDATE public.transit_stations SET aliases = ARRAY[
  'BTS เอกมัย', 'เอกมัย', 'ekkamai', 'ekamai', 'bts เอกมัย'
]::text[]
WHERE slug IN ('bts-ekkamai', 'bts-ekamai');

UPDATE public.transit_stations SET aliases = ARRAY[
  'BTS พร้อมพงษ์', 'พร้อมพงษ์', 'phrom phong', 'phromphong', 'bts พร้อมพงษ์'
]::text[]
WHERE slug IN ('bts-phrom-phong', 'bts-phromphong');

UPDATE public.transit_stations SET aliases = ARRAY[
  'BTS นานา', 'นานา', 'nana', 'bts นานา'
]::text[]
WHERE slug = 'bts-nana';

UPDATE public.transit_stations SET aliases = ARRAY[
  'BTS อารีย์', 'อารีย์', 'ari', 'bts อารีย์'
]::text[]
WHERE slug = 'bts-ari';

UPDATE public.transit_stations SET aliases = ARRAY[
  'BTS บางนา', 'บางนา', 'bangna', 'bang na', 'bts บางนา'
]::text[]
WHERE slug IN ('bts-bang-na', 'bts-bangna');

UPDATE public.transit_stations SET aliases = ARRAY[
  'BTS อ่อนนุช', 'อ่อนนุช', 'on nut', 'onnut', 'bts อ่อนนุช'
]::text[]
WHERE slug IN ('bts-on-nut', 'bts-onnut');

UPDATE public.transit_stations SET aliases = ARRAY[
  'MRT พระราม 9', 'พระราม 9', 'rama 9', 'rama9', 'mrt พระราม 9'
]::text[]
WHERE slug IN ('mrt-phra-ram-9', 'mrt-rama-9');

UPDATE public.transit_stations SET aliases = ARRAY[
  'MRT ห้วยขวาง', 'ห้วยขวาง', 'huai khwang', 'huaikhwang', 'mrt ห้วยขวาง'
]::text[]
WHERE slug IN ('mrt-huai-khwang', 'mrt-huaikhwang');

UPDATE public.transit_stations SET aliases = ARRAY[
  'MRT ลาดพร้าว', 'ลาดพร้าว', 'lat phrao', 'ladprao', 'mrt ลาดพร้าว'
]::text[]
WHERE slug IN ('mrt-lat-phrao', 'mrt-ladprao');

UPDATE public.transit_stations SET aliases = ARRAY[
  'MRT สุขุมวิท', 'mrt สุขุมวิท', 'mrt sukhumvit'
]::text[]
WHERE slug = 'mrt-sukhumvit';

UPDATE public.transit_stations SET aliases = ARRAY[
  'ARL มักกะสัน', 'มักกะสัน', 'makkasan', 'arl มักกะสัน', 'airport link มักกะสัน'
]::text[]
WHERE slug = 'arl-makkasan';
