-- LivingBKK: demand board (blind offers)

CREATE TABLE public.demand_posts (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  post_code text NOT NULL UNIQUE,
  created_by uuid NOT NULL REFERENCES public.profiles (id),

  title text NOT NULL,
  description text,

  transaction_type public.listing_type NOT NULL,
  property_type public.property_type,

  zones jsonb DEFAULT '[]',
  max_distance_bts_km numeric(4, 2),
  min_area_sqm numeric(8, 2),
  max_price_net numeric(12, 2),
  extra_criteria jsonb DEFAULT '{}',

  status public.demand_post_status NOT NULL DEFAULT 'open',
  open_until timestamptz,

  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX demand_posts_status_idx ON public.demand_posts (status);

CREATE TRIGGER demand_posts_updated_at
  BEFORE UPDATE ON public.demand_posts
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at();

CREATE OR REPLACE FUNCTION public.generate_demand_post_code()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  IF NEW.post_code IS NULL OR NEW.post_code = '' THEN
    NEW.post_code := 'DM-' || to_char(now(), 'YYYY') || '-' ||
      lpad((floor(random() * 999999))::text, 6, '0');
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER demand_posts_generate_code
  BEFORE INSERT ON public.demand_posts
  FOR EACH ROW
  EXECUTE FUNCTION public.generate_demand_post_code();

CREATE TABLE public.demand_offers (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  demand_post_id uuid NOT NULL REFERENCES public.demand_posts (id) ON DELETE CASCADE,
  offerer_id uuid NOT NULL REFERENCES public.profiles (id),

  offerer_capacity public.offerer_capacity NOT NULL,
  offerer_app_role public.user_role NOT NULL,
  capacity_verified public.capacity_verified_status NOT NULL DEFAULT 'pending',
  capacity_verified_by uuid REFERENCES public.profiles (id),
  capacity_verified_at timestamptz,

  offer_type public.demand_offer_type NOT NULL,
  title text,
  description text,
  price_net numeric(12, 2),
  area_sqm numeric(8, 2),
  bedrooms int,
  external_url text,
  external_note text,

  unit_number text,
  exact_floor int,
  location_exact geography(POINT, 4326),

  moderation_status public.moderation_status NOT NULL DEFAULT 'pending',
  status public.demand_offer_status NOT NULL DEFAULT 'submitted',
  admin_notes text,

  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX demand_offers_post_idx ON public.demand_offers (demand_post_id);
CREATE INDEX demand_offers_offerer_idx ON public.demand_offers (offerer_id);

CREATE TRIGGER demand_offers_updated_at
  BEFORE UPDATE ON public.demand_offers
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at();

CREATE TABLE public.demand_offer_images (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  demand_offer_id uuid NOT NULL REFERENCES public.demand_offers (id) ON DELETE CASCADE,
  storage_path text NOT NULL,
  public_url text,
  sort_order int NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX demand_offer_images_offer_idx ON public.demand_offer_images (demand_offer_id);
