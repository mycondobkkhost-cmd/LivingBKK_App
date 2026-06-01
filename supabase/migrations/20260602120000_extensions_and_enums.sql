-- LivingBKK: extensions and enums

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS postgis;

-- Roles
CREATE TYPE public.user_role AS ENUM ('seeker', 'owner', 'agent', 'admin');

-- Listings
CREATE TYPE public.listing_type AS ENUM ('rent', 'sale');
CREATE TYPE public.listing_status AS ENUM ('draft', 'published', 'hidden', 'expired');
CREATE TYPE public.property_type AS ENUM ('condo', 'house', 'townhouse', 'apartment', 'other');
CREATE TYPE public.listed_by_role AS ENUM ('owner', 'agent', 'admin');
CREATE TYPE public.co_agent_listing_type AS ENUM ('owner_direct', 'co_agent_50_50');
CREATE TYPE public.co_agent_eligibility_reason AS ENUM ('owner_posted', 'platform_contact');
CREATE TYPE public.co_agent_slot_status AS ENUM ('open', 'pending', 'assigned');
CREATE TYPE public.investor_category AS ENUM ('none', 'with_tenant', 'bmv');

-- Leads
CREATE TYPE public.lead_status AS ENUM ('new', 'routed', 'accepted', 'declined', 'closed');
CREATE TYPE public.lead_assignment_action AS ENUM ('accepted', 'declined_unavailable');

-- Co-agent requests
CREATE TYPE public.co_agent_request_status AS ENUM ('pending', 'approved', 'rejected', 'withdrawn');

-- Demand board
CREATE TYPE public.demand_post_status AS ENUM ('open', 'closed', 'fulfilled');
CREATE TYPE public.demand_offer_type AS ENUM ('in_app', 'external_link');
CREATE TYPE public.offerer_capacity AS ENUM (
  'owner_direct_100',
  'co_agent_50_50',
  'listing_agent'
);
CREATE TYPE public.capacity_verified_status AS ENUM ('pending', 'verified', 'rejected');
CREATE TYPE public.demand_offer_status AS ENUM (
  'submitted',
  'under_review',
  'shortlisted',
  'accepted',
  'rejected'
);

-- Moderation
CREATE TYPE public.moderation_status AS ENUM ('pending', 'approved', 'rejected');
CREATE TYPE public.moderation_flag_type AS ENUM (
  'phone',
  'line',
  'external_link',
  'duplicate_image'
);

-- PM
CREATE TYPE public.pm_subscription_status AS ENUM ('active', 'cancelled', 'expired');
