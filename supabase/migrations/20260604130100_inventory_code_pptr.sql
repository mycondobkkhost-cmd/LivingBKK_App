-- Use app abbreviation PPTR (PROPPITER) for property inventory codes

CREATE OR REPLACE FUNCTION public.generate_inventory_code()
RETURNS text
LANGUAGE plpgsql
AS $$
DECLARE
  n bigint;
BEGIN
  SELECT nextval('public.property_inventory_seq') INTO n;
  RETURN 'PPTR-' || to_char(now(), 'YYYY') || '-' || lpad(n::text, 6, '0');
END;
$$;

UPDATE public.property_inventory
SET inventory_code = replace(inventory_code, 'PTP-', 'PPTR-')
WHERE inventory_code LIKE 'PTP-%';
