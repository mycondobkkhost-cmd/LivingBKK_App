-- LivingBKK: public-safe listing view (no unit/floor/exact location/contact)

CREATE OR REPLACE VIEW public.listings_public
WITH (security_invoker = true)
AS
SELECT
  l.id,
  l.listing_code,
  l.listing_type,
  l.status,
  l.property_type,
  l.title,
  l.description_public,
  l.price_net,
  l.co_agent_listing_type,
  l.investor_category,
  l.yield_percent,
  l.pet_allowed,
  l.smoking_allowed,
  l.furnished,
  l.bedrooms,
  l.bathrooms,
  l.area_sqm,
  l.floor_range,
  l.district,
  l.subdistrict,
  l.project_name,
  l.geo_zone_id,
  l.max_distance_bts_km,
  l.location_public,
  l.co_agent_eligible,
  l.co_agent_listing_type AS co_agent_status_display,
  l.available_from,
  l.available_again,
  l.last_bump_at,
  l.published_at,
  l.created_at,
  l.updated_at
FROM public.listings l
WHERE l.status = 'published'
  AND (l.expires_at IS NULL OR l.expires_at > now());

COMMENT ON VIEW public.listings_public IS 'Seeker-facing listing data; never exposes unit_number, exact_floor, location_exact';

-- Leads public view for assignees (censored phone)
CREATE OR REPLACE VIEW public.leads_for_assignee
WITH (security_invoker = true)
AS
SELECT
  l.id,
  l.listing_id,
  l.listing_code,
  l.seeker_nickname,
  public.censor_phone(l.seeker_phone) AS seeker_phone_censored,
  l.occupants_count,
  l.gender,
  l.occupation,
  l.workplace,
  l.move_plan,
  l.contract_duration,
  l.budget,
  l.has_car,
  l.pets,
  l.smoking,
  l.preferred_areas,
  l.qualification_json,
  l.status,
  l.assigned_to,
  l.created_at
FROM public.leads l;
