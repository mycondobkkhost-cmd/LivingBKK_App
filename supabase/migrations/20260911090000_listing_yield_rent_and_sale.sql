-- Yield for investor listings: sale_installment + rent_and_sale were skipped.
-- Dual listings store rent in price_net and sale in price_sale_net — using
-- price_net as the denominator produced nonsense yields (e.g. 1000%+).

CREATE OR REPLACE FUNCTION public.sync_listing_derived_fields()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
  sale_price numeric;
BEGIN
  -- Co-agent eligibility
  IF NEW.status = 'published'
    AND NEW.co_agent_slot_status IN ('open', 'pending')
    AND (
      (NEW.listed_by_role = 'owner' AND NEW.owner_verified = true)
      OR (NEW.platform_has_owner_contact = true AND NEW.owner_co_agent_opt_in = true)
    )
  THEN
    NEW.co_agent_eligible := true;
    IF NEW.listed_by_role = 'owner' AND NEW.owner_verified THEN
      NEW.co_agent_eligibility_reason := 'owner_posted';
    ELSIF NEW.platform_has_owner_contact THEN
      NEW.co_agent_eligibility_reason := 'platform_contact';
    END IF;
  ELSE
    NEW.co_agent_eligible := false;
    IF NEW.co_agent_slot_status = 'assigned' THEN
      NEW.co_agent_eligibility_reason := NULL;
    END IF;
  END IF;

  -- Yield % for investor listings (ขาย / ขายฝาก / เช่า+ขาย)
  IF NEW.listing_type IN (
       'sale'::public.listing_type,
       'sale_installment'::public.listing_type,
       'rent_and_sale'::public.listing_type
     )
    AND NEW.monthly_rent_for_yield IS NOT NULL
    AND NEW.monthly_rent_for_yield > 0
  THEN
    sale_price := CASE
      WHEN NEW.listing_type = 'rent_and_sale'::public.listing_type
        THEN COALESCE(NEW.price_sale_net, NEW.price_net)
      ELSE NEW.price_net
    END;
    IF sale_price IS NOT NULL AND sale_price > 0 THEN
      NEW.yield_percent := round(
        ((NEW.monthly_rent_for_yield * 12) / sale_price) * 100,
        2
      );
    END IF;
  END IF;

  -- Offset public location ~300m if exact set but public missing
  IF NEW.location_exact IS NOT NULL AND NEW.location_public IS NULL THEN
    NEW.location_public := ST_Translate(
      NEW.location_exact::geometry,
      (random() - 0.5) * 0.006,
      (random() - 0.5) * 0.006
    )::geography;
  END IF;

  RETURN NEW;
END;
$$;
