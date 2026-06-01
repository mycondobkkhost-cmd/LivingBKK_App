-- LivingBKK: geographic zones (Bangkok + metro)

CREATE TABLE public.geo_zones (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  slug text NOT NULL UNIQUE,
  name_th text NOT NULL,
  name_en text,
  zone_type text NOT NULL DEFAULT 'metro', -- metro, district, bts_station
  boundary geography(POLYGON, 4326),
  center geography(POINT, 4326),
  aliases text[] DEFAULT '{}',
  sort_order int NOT NULL DEFAULT 0,
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX geo_zones_boundary_idx ON public.geo_zones USING GIST (boundary);
CREATE INDEX geo_zones_center_idx ON public.geo_zones USING GIST (center);
CREATE INDEX geo_zones_aliases_idx ON public.geo_zones USING GIN (aliases);

COMMENT ON TABLE public.geo_zones IS 'Bangkok metro areas; aliases used for AI search (e.g. มศว -> asok)';
