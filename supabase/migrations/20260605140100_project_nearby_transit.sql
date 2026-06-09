-- สถานีรถไฟฟ้าใกล้โครงการ (หลายสถานีต่อโครงการ)

ALTER TABLE public.property_projects
  ADD COLUMN IF NOT EXISTS nearby_transit text[] NOT NULL DEFAULT '{}';

CREATE INDEX IF NOT EXISTS property_projects_nearby_transit_idx
  ON public.property_projects USING GIN (nearby_transit);

COMMENT ON COLUMN public.property_projects.nearby_transit IS
  'สถานี BTS/MRT ใกล้เคียง เช่น {BTS นานา,BTS อโศก,MRT สุขุมวิท} — ใช้ค้นหา/แท็ก';
