-- LivingBKK: commission tiers, e-contracts, property management

CREATE TABLE public.commission_tiers (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  name text NOT NULL,
  min_months int NOT NULL,
  max_months int,
  platform_percent numeric(5, 2) NOT NULL,
  agent_percent numeric(5, 2) NOT NULL,
  owner_percent numeric(5, 2) NOT NULL,
  is_active boolean NOT NULL DEFAULT true,
  sort_order int NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE public.e_contracts (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  lead_assignment_id uuid REFERENCES public.lead_assignments (id),
  co_agent_request_id uuid REFERENCES public.co_agent_requests (id),
  commission_tier_id uuid REFERENCES public.commission_tiers (id),
  signer_id uuid NOT NULL REFERENCES public.profiles (id),
  template_version text NOT NULL DEFAULT '1.0',
  signed_at timestamptz,
  ip_address inet,
  metadata jsonb DEFAULT '{}',
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT e_contracts_reference_check CHECK (
    lead_assignment_id IS NOT NULL OR co_agent_request_id IS NOT NULL
  )
);

CREATE TABLE public.property_management_subscriptions (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  owner_id uuid NOT NULL REFERENCES public.profiles (id),
  listing_id uuid REFERENCES public.listings (id),
  annual_fee numeric(12, 2) NOT NULL DEFAULT 20000,
  starts_at date NOT NULL,
  ends_at date NOT NULL,
  status public.pm_subscription_status NOT NULL DEFAULT 'active',
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX pm_subscriptions_owner_idx ON public.property_management_subscriptions (owner_id);
