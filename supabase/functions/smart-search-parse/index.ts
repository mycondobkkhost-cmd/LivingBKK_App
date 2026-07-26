import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";
import { corsHeaders, jsonResponse } from "../_shared/cors.ts";
import {
  extractListingCodeFromQuery,
  resolveListingFromQuery,
} from "../_shared/search_listing_resolve.ts";
import { parseSearchStub } from "../_shared/search_parse_stub.ts";
import {
  buildSearchPreview,
  parseSmartSearchQuery,
  stubToSmartQuery,
} from "../_shared/smart_search_parser.ts";
import {
  extractProjectName,
  resolveProjectInCatalog,
} from "../_shared/search_project_resolve.ts";
import { SmartSearchService } from "../_shared/smart_search_service.ts";
import type { SmartSearchParsedQuery } from "../_shared/smart_search_types.ts";

type LegacyFilters = Record<string, unknown>;

/** แปลง SmartSearchParsedQuery → legacy filters สำหรับ Flutter SearchFilters */
function toLegacyFilters(parsed: SmartSearchParsedQuery): LegacyFilters {
  const f = parsed.filters;
  return {
    geo_zone_slugs: parsed.geo_zone_slugs,
    listing_type: f.listing_type,
    property_type: parsed.property_type,
    max_price_net: f.price_max,
    min_price_net: f.price_min,
    bedrooms: f.bedrooms,
    pet_allowed: f.pet_allowed,
    co_agent_eligible: f.co_agent_eligible,
    investor_category: f.investor_category,
    min_yield: f.min_yield,
    project_name: parsed.project_name,
  };
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const body = await req.json();
    const query = body?.query;
    if (!query || typeof query !== "string") {
      return jsonResponse({ error: "query string required" }, 400);
    }

    // default true — เติมพิกัดอัตโนมัติเมื่อ catalog ไม่ครบ
    const enrichLocation = body?.enrich_location !== false;

    const trimmed = query.trim();
    const db = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );

    const listingResolution = await resolveListingFromQuery(db, trimmed);
    const codeHint = extractListingCodeFromQuery(trimmed);

    const { parsed: smartParsed, source } = await parseSmartSearchQuery(trimmed);
    const stub = parseSearchStub(trimmed);

    const filters: LegacyFilters = {
      ...toLegacyFilters(stubToSmartQuery(trimmed, stub.filters)),
      ...toLegacyFilters(smartParsed),
    };

    const preview = buildSearchPreview(smartParsed);
    for (const p of stub.preview) {
      if (!preview.some((x) => x.label === p.label)) preview.push(p);
    }

    if (listingResolution.status === "found") {
      preview.unshift({
        label: "รหัสทรัพย์",
        value: listingResolution.listing_code ?? codeHint ?? trimmed,
      });
    } else if (codeHint && listingResolution.status === "not_found") {
      preview.unshift({
        label: "รหัสทรัพย์",
        value: `${codeHint} (ไม่พบในระบบ)`,
      });
    }

    const projectName = extractProjectName(trimmed, filters);
    const projectResolution = await resolveProjectInCatalog(projectName);

    let location_enrichment = null;
    let location_enrichment_error: string | undefined;
    if (enrichLocation && smartParsed.location?.raw_text) {
      const service = new SmartSearchService(db);
      const enrich = await service.enrichLocation(smartParsed);
      location_enrichment = enrich.enrichment;
      location_enrichment_error = enrich.error;
      if (enrich.enrichment) {
        filters.pin_latitude = enrich.enrichment.lat;
        filters.pin_longitude = enrich.enrichment.lng;
        filters.radius_km = enrich.enrichment.radius_km;
      }
    }

    return jsonResponse({
      query: trimmed,
      filters,
      preview,
      source,
      parsed: smartParsed,
      project_resolution: projectResolution,
      listing_resolution: listingResolution,
      location_enrichment,
      location_enrichment_error,
      intent: listingResolution.status === "found"
        ? "listing_code"
        : codeHint
        ? "listing_code_not_found"
        : "filters",
    });
  } catch (e) {
    return jsonResponse({ error: String(e) }, 500);
  }
});
