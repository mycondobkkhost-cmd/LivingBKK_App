/** Structured output จาก AI Query Parser — สัญญา JSON กับ OpenAI */

export type LocationType =
  | "neighborhood"
  | "transit_station"
  | "project_name"
  | "district"
  | "other";

export type ParsedLocation = {
  raw_text: string;
  type: LocationType;
};

export type ParsedFilters = {
  price_min?: number | null;
  price_max?: number | null;
  bedrooms?: number | null;
  bathrooms?: number | null;
  distance_to_transit_meters?: number | null;
  listing_type?: "rent" | "sale" | null;
  pet_allowed?: boolean | null;
  co_agent_eligible?: boolean | null;
  min_yield?: number | null;
  investor_category?: "bmv" | "with_tenant" | null;
};

export type SoftConstraint =
  | "high_yield"
  | "below_market_value"
  | "with_tenant"
  | "near_transit";

export type SmartSearchParsedQuery = {
  property_type?: "condo" | "house" | "townhouse" | "apartment" | "other" | null;
  location?: ParsedLocation | null;
  filters: ParsedFilters;
  soft_constraints: SoftConstraint[];
  /** legacy keys สำหรับ backward compat กับ Flutter SearchFilters */
  geo_zone_slugs?: string[];
  project_name?: string | null;
};

export type LocationEnrichment = {
  lat: number;
  lng: number;
  display_name: string;
  formatted_address?: string | null;
  place_id?: string | null;
  /** แหล่งที่มาของพิกัด — ใช้ debug / UI badge */
  source:
    | "property_projects"
    | "geo_zones"
    | "transit_stations"
    | "search_location_cache"
    | "google_places"
    | "none";
  radius_km: number;
  matched_slug?: string | null;
};

export type SmartSearchListingHit = {
  id: string;
  listing_code: string;
  listing_type: string;
  property_type: string;
  title: string;
  price_net: number;
  price_sale_net?: number | null;
  bedrooms?: number | null;
  yield_percent?: number | null;
  investor_category?: string | null;
  project_name?: string | null;
  project_slug?: string | null;
  district?: string | null;
  geo_zone_slug?: string | null;
  lat?: number | null;
  lng?: number | null;
  distance_km?: number | null;
  rank_score: number;
  semantic_score?: number | null;
};

export type SmartSearchResult = {
  query: string;
  parsed: SmartSearchParsedQuery;
  parse_source: "openai" | "rules" | "hybrid";
  location_enrichment: LocationEnrichment | null;
  location_enrichment_error?: string | null;
  results: SmartSearchListingHit[];
  total: number;
  preview: { label: string; value: string }[];
};

export type AutocompleteSuggestion = {
  kind: "project" | "neighborhood" | "transit_station" | "listing" | "google_place";
  title: string;
  subtitle?: string | null;
  slug?: string | null;
  lat?: number | null;
  lng?: number | null;
  place_id?: string | null;
  source: string;
};
