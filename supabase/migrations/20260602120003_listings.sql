-- LivingBKK: listings

CREATE TABLE public.listings (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  listing_code text NOT NULL UNIQUE,
  owner_id uuid NOT NULL REFERENCES public.profiles (id),
  created_by_id uuid NOT NULL REFERENCES public.profiles (id),

  listing_type public.listing_type NOT NULL,
  status public.listing_status NOT NULL DEFAULT 'draft',
  property_type public.property_type NOT NULL DEFAULT 'condo',

  title text NOT NULL,
  description_public text,

  -- Public pricing (commission-inclusive; only net shown to seekers)
  price_net numeric(12, 2) NOT NULL,
  price_internal numeric(12, 2),

  -- Killer filters
  co_agent_listing_type public.co_agent_listing_type,
  investor_category public.investor_category NOT NULL DEFAULT 'none',
  yield_percent numeric(5, 2),
  monthly_rent_for_yield numeric(12, 2),

  pet_allowed boolean DEFAULT false,
  smoking_allowed boolean DEFAULT false,
  furnished boolean,
  bedrooms int,
  bathrooms int,
  area_sqm numeric(8, 2),
  floor_range text,

  district text,
  subdistrict text,
  project_name text,
  geo_zone_id uuid REFERENCES public.geo_zones (id),
  max_distance_bts_km numeric(4, 2),

  -- Private (never in listings_public view)
  unit_number text,
  exact_floor int,
  location_exact geography(POINT, 4326),
  location_public geography(POINT, 4326),

  -- Listing origin & co-agent eligibility
  listed_by_role public.listed_by_role NOT NULL DEFAULT 'owner',
  owner_verified boolean NOT NULL DEFAULT false,
  platform_has_owner_contact boolean NOT NULL DEFAULT false,
  owner_co_agent_opt_in boolean NOT NULL DEFAULT true,
  co_agent_eligible boolean NOT NULL DEFAULT false,
  co_agent_eligibility_reason public.co_agent_eligibility_reason,
  co_agent_slot_status public.co_agent_slot_status NOT NULL DEFAULT 'open',
  assigned_co_agent_id uuid REFERENCES public.profiles (id),

  available_from date,
  contract_occupied_until date,
  available_again date,

  last_bump_at timestamptz,
  expires_at timestamptz,
  published_at timestamptz,

  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),

  CONSTRAINT listings_price_net_positive CHECK (price_net > 0)
);

CREATE INDEX listings_status_idx ON public.listings (status);
CREATE INDEX listings_owner_idx ON public.listings (owner_id);
CREATE INDEX listings_type_price_idx ON public.listings (listing_type, price_net);
CREATE INDEX listings_co_agent_eligible_idx ON public.listings (co_agent_eligible)
  WHERE co_agent_eligible = true AND status = 'published';
CREATE INDEX listings_location_public_idx ON public.listings USING GIST (location_public);
CREATE INDEX listings_geo_zone_idx ON public.listings (geo_zone_id);

CREATE TRIGGER listings_updated_at
  BEFORE UPDATE ON public.listings
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at();

-- Generate listing code
CREATE OR REPLACE FUNCTION public.generate_listing_code()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  IF NEW.listing_code IS NULL OR NEW.listing_code = '' THEN
    NEW.listing_code := 'LB-' || to_char(now(), 'YYYY') || '-' ||
      lpad((floor(random() * 999999))::text, 6, '0');
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER listings_generate_code
  BEFORE INSERT ON public.listings
  FOR EACH ROW
  EXECUTE FUNCTION public.generate_listing_code();

-- Compute co_agent_eligible + yield
CREATE OR REPLACE FUNCTION public.sync_listing_derived_fields()
RETURNS trigger
LANGUAGE plpgsql
AS $$
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

  -- Yield % for investor listings
  IF NEW.listing_type = 'sale'
    AND NEW.monthly_rent_for_yield IS NOT NULL
    AND NEW.price_net > 0
  THEN
    NEW.yield_percent := round(
      ((NEW.monthly_rent_for_yield * 12) / NEW.price_net) * 100,
      2
    );
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

CREATE TRIGGER listings_sync_derived
  BEFORE INSERT OR UPDATE ON public.listings
  FOR EACH ROW
  EXECUTE FUNCTION public.sync_listing_derived_fields();
