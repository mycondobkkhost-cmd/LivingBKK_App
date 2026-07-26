-- inventory_members — เชื่อม listing กับ property_inventory (ใช้ใน listings_public view)
-- คืนตารางที่หายจาก migration บน cloud ที่ถูก revert

CREATE TABLE IF NOT EXISTS public.inventory_members (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  inventory_id uuid NOT NULL REFERENCES public.property_inventory (id) ON DELETE CASCADE,
  listing_id uuid NOT NULL REFERENCES public.listings (id) ON DELETE CASCADE,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (listing_id)
);

CREATE INDEX IF NOT EXISTS inventory_members_inventory_idx
  ON public.inventory_members (inventory_id);

-- backfill จาก listings.inventory_id ที่มีอยู่แล้ว
INSERT INTO public.inventory_members (inventory_id, listing_id)
SELECT l.inventory_id, l.id
FROM public.listings l
WHERE l.inventory_id IS NOT NULL
ON CONFLICT (listing_id) DO NOTHING;

ALTER TABLE public.inventory_members ENABLE ROW LEVEL SECURITY;

CREATE POLICY inventory_members_admin ON public.inventory_members
  FOR ALL TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());
