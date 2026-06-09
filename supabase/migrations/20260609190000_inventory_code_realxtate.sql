-- RealXtate rebrand: property inventory codes PPTR/PTP → RXT

CREATE OR REPLACE FUNCTION public.generate_inventory_code()
RETURNS text
LANGUAGE plpgsql
AS $$
DECLARE
  n bigint;
BEGIN
  SELECT nextval('public.property_inventory_seq') INTO n;
  RETURN 'RXT-' || to_char(now(), 'YYYY') || '-' || lpad(n::text, 6, '0');
END;
$$;

COMMENT ON FUNCTION public.generate_inventory_code() IS
  'รหัสทะเบียนทรัพย์กลาง RealXtate — RXT-YYYY-######';

UPDATE public.property_inventory
SET inventory_code = replace(inventory_code, 'PPTR-', 'RXT-')
WHERE inventory_code LIKE 'PPTR-%';

UPDATE public.property_inventory
SET inventory_code = replace(inventory_code, 'PTP-', 'RXT-')
WHERE inventory_code LIKE 'PTP-%';
