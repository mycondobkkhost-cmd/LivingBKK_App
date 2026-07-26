/**
 * SmartSearchService — ผสาน OpenAI Parser + Location Enrichment + Hybrid DB Query
 *
 * Data imputation chain (เมื่อ catalog ไม่ครบ):
 *   1. property_projects (slug/name match)
 *   2. geo_zones (neighborhood slug / center)
 *   3. transit_stations (station name)
 *   4. search_location_cache (เคย geocode แล้ว)
 *   5. Google Places API → บันทึก cache
 */

import { createClient, SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";
import { geocodeLocationByText } from "./google_places.ts";
import {
  buildSearchPreview,
  parseSmartSearchQuery,
} from "./smart_search_parser.ts";
import {
  extractListingCodeFromQuery,
  resolveListingFromQuery,
} from "./search_listing_resolve.ts";
import { namesMatch } from "./search_project_resolve.ts";
import { ilikeContains } from "./sanitize_ilike.ts";
import type {
  AutocompleteSuggestion,
  LocationEnrichment,
  SmartSearchListingHit,
  SmartSearchParsedQuery,
  SmartSearchResult,
} from "./smart_search_types.ts";

const DEFAULT_RADIUS_KM = 3.0;
const TRANSIT_DEFAULT_RADIUS_KM = 1.0;
const PROJECT_DEFAULT_RADIUS_KM = 0.8;

function normalizeCacheKey(text: string): string {
  return text.trim().toLowerCase().replace(/\s+/g, " ");
}

function defaultRadiusKm(parsed: SmartSearchParsedQuery): number {
  const meters = parsed.filters.distance_to_transit_meters;
  if (meters != null && meters > 0) return meters / 1000.0;

  const type = parsed.location?.type;
  if (type === "transit_station") return TRANSIT_DEFAULT_RADIUS_KM;
  if (type === "project_name") return PROJECT_DEFAULT_RADIUS_KM;
  if (parsed.soft_constraints.includes("near_transit")) return 1.2;
  return DEFAULT_RADIUS_KM;
}

export class SmartSearchService {
  constructor(private db: SupabaseClient) {}

  static fromEnv(): SmartSearchService {
    const db = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );
    return new SmartSearchService(db);
  }

  /** Full pipeline: parse → enrich → search */
  async search(
    query: string,
    opts: { limit?: number; offset?: number } = {},
  ): Promise<SmartSearchResult> {
    const trimmed = query.trim();
    const limit = Math.min(opts.limit ?? 50, 200);
    const offset = Math.max(opts.offset ?? 0, 0);

    // รหัสทรัพย์ — short-circuit
    const code = extractListingCodeFromQuery(trimmed);
    if (code) {
      const listingRes = await resolveListingFromQuery(this.db, trimmed);
      if (listingRes.status === "found" && listingRes.listing_id) {
        const { data: row } = await this.db
          .from("listings_public")
          .select("*")
          .eq("id", listingRes.listing_id)
          .maybeSingle();

        const hit: SmartSearchListingHit | null = row
          ? this.mapListingRow(row, 100, 0)
          : null;

        return {
          query: trimmed,
          parsed: {
            filters: {},
            soft_constraints: [],
            project_name: listingRes.project_name,
          },
          parse_source: "rules",
          location_enrichment: null,
          results: hit ? [hit] : [],
          total: hit ? 1 : 0,
          preview: [{
            label: "รหัสทรัพย์",
            value: listingRes.listing_code ?? code,
          }],
        };
      }
    }

    const { parsed, source: parseSource } = await parseSmartSearchQuery(trimmed);
    const preview = buildSearchPreview(parsed);

    let locationEnrichment: LocationEnrichment | null = null;
    let locationError: string | undefined;

    if (parsed.location?.raw_text) {
      const enrich = await this.enrichLocation(parsed);
      locationEnrichment = enrich.enrichment;
      locationError = enrich.error;
    }

    const rows = await this.executeHybridQuery(parsed, locationEnrichment, {
      limit,
      offset,
    });

    return {
      query: trimmed,
      parsed,
      parse_source: parseSource,
      location_enrichment: locationEnrichment,
      location_enrichment_error: locationError,
      results: rows,
      total: rows.length,
      preview,
    };
  }

  /**
   * Dynamic Location Enrichment — แก้ปัญหาข้อมูล catalog ไม่ครบ
   * ลำดับ: local DB → cache → Google Maps
   */
  async enrichLocation(
    parsed: SmartSearchParsedQuery,
  ): Promise<{ enrichment: LocationEnrichment | null; error?: string }> {
    const loc = parsed.location;
    if (!loc?.raw_text) {
      return { enrichment: null };
    }

    const rawText = loc.raw_text.trim();
    const radiusKm = defaultRadiusKm(parsed);

    // --- 1) property_projects ---
    if (loc.type === "project_name" || parsed.project_name) {
      const name = parsed.project_name ?? rawText;
      const { data: projects } = await this.db
        .from("property_projects")
        .select("slug, name_th, name_en, lat, lng, aliases")
        .eq("is_active", true)
        .limit(500);

      const hit = (projects ?? []).find((p) =>
        namesMatch(
          name,
          p.name_th as string,
          p.name_en as string,
          p.slug as string,
          ...((p.aliases as string[] | null) ?? []),
        )
      );
      if (hit?.lat != null && hit?.lng != null) {
        return {
          enrichment: {
            lat: hit.lat as number,
            lng: hit.lng as number,
            display_name: hit.name_th as string,
            source: "property_projects",
            radius_km: radiusKm,
            matched_slug: hit.slug as string,
          },
        };
      }
    }

    // --- 2) geo_zones (neighborhood / district) ---
    if (loc.type === "neighborhood" || loc.type === "district") {
      const slugCandidates = parsed.geo_zone_slugs ?? [];
      if (slugCandidates.length) {
        const { data: zone } = await this.db
          .from("geo_zones")
          .select("slug, name_th, center")
          .in("slug", slugCandidates)
          .not("center", "is", null)
          .limit(1)
          .maybeSingle();

        if (zone?.center) {
          const coords = await this.latLngFromGeography(zone.center);
          if (coords) {
            return {
              enrichment: {
                ...coords,
                display_name: zone.name_th as string,
                source: "geo_zones",
                radius_km: radiusKm,
                matched_slug: zone.slug as string,
              },
            };
          }
        }
      }

      const { data: zones } = await this.db
        .from("geo_zones")
        .select("slug, name_th, center")
        .or(
          `name_th.ilike.${ilikeContains(rawText)},name_en.ilike.${ilikeContains(rawText)}`,
        )
        .not("center", "is", null)
        .limit(1);

      const z = zones?.[0];
      if (z?.center) {
        const coords = await this.latLngFromGeography(z.center);
        if (coords) {
          return {
            enrichment: {
              ...coords,
              display_name: z.name_th as string,
              source: "geo_zones",
              radius_km: radiusKm,
              matched_slug: z.slug as string,
            },
          };
        }
      }
    }

    // --- 3) transit_stations ---
    if (loc.type === "transit_station") {
      const stationQuery = rawText.replace(/^(bts|mrt|arl)\s*/i, "").trim();
      const stPattern = ilikeContains(stationQuery);
      const { data: stations } = await this.db
        .from("transit_stations")
        .select("slug, name_th, system, lat, lng")
        .or(`name_th.ilike.${stPattern},name_en.ilike.${stPattern}`)
        .limit(1);

      const st = stations?.[0];
      if (st?.lat != null && st?.lng != null) {
        return {
          enrichment: {
            lat: st.lat as number,
            lng: st.lng as number,
            display_name: `${st.system} ${st.name_th}`,
            source: "transit_stations",
            radius_km: radiusKm,
            matched_slug: st.slug as string,
          },
        };
      }
    }

    // --- 4) search_location_cache ---
    const cacheKey = normalizeCacheKey(rawText);
    const { data: cached } = await this.db
      .from("search_location_cache")
      .select("*")
      .eq("query_normalized", cacheKey)
      .eq("location_type", loc.type)
      .maybeSingle();

    if (cached?.lat != null && cached?.lng != null) {
      // bump hit_count async (fire-and-forget)
      this.db
        .from("search_location_cache")
        .update({
          hit_count: (cached.hit_count as number) + 1,
          last_used_at: new Date().toISOString(),
        })
        .eq("id", cached.id as string)
        .then(() => {});

      return {
        enrichment: {
          lat: cached.lat as number,
          lng: cached.lng as number,
          display_name: (cached.display_name as string) ?? rawText,
          formatted_address: cached.formatted_address as string | null,
          place_id: cached.place_id as string | null,
          source: "search_location_cache",
          radius_km: radiusKm,
        },
      };
    }

    // --- 5) Google Places (real-time imputation) ---
    const googleHit = await geocodeLocationByText(rawText, loc.type);
    if (!googleHit) {
      return {
        enrichment: null,
        error: Deno.env.get("GOOGLE_MAPS_API_KEY")
          ? `ไม่พบพิกัดสำหรับ "${rawText}" บน Google Maps`
          : "GOOGLE_MAPS_API_KEY ไม่ได้ตั้งค่า — ใช้ได้เฉพาะ catalog ภายใน",
      };
    }

    // บันทึก cache สำหรับครั้งถัดไป
    await this.db.from("search_location_cache").upsert({
      query_normalized: cacheKey,
      location_type: loc.type,
      raw_text: rawText,
      display_name: googleHit.name,
      formatted_address: googleHit.formattedAddress,
      lat: googleHit.lat,
      lng: googleHit.lng,
      place_id: googleHit.placeId,
      source: "google_places",
      last_used_at: new Date().toISOString(),
    }, { onConflict: "query_normalized,location_type" });

    return {
      enrichment: {
        lat: googleHit.lat,
        lng: googleHit.lng,
        display_name: googleHit.name,
        formatted_address: googleHit.formattedAddress,
        place_id: googleHit.placeId,
        source: "google_places",
        radius_km: radiusKm,
      },
    };
  }

  /** Hybrid Search — RPC smart_search_listings + fallback client-side filter */
  async executeHybridQuery(
    parsed: SmartSearchParsedQuery,
    enrichment: LocationEnrichment | null,
    opts: { limit: number; offset: number },
  ): Promise<SmartSearchListingHit[]> {
    const f = parsed.filters;

    const rpcArgs: Record<string, unknown> = {
      p_property_type: parsed.property_type ?? null,
      p_listing_type: f.listing_type ?? null,
      p_price_min: f.price_min ?? null,
      p_price_max: f.price_max ?? null,
      p_bedrooms: f.bedrooms ?? null,
      p_investor_category: f.investor_category ?? null,
      p_min_yield: f.min_yield ?? null,
      p_pet_allowed: f.pet_allowed ?? null,
      p_co_agent_eligible: f.co_agent_eligible ?? null,
      p_geo_zone_slugs: parsed.geo_zone_slugs?.length
        ? parsed.geo_zone_slugs
        : null,
      p_project_slug: enrichment?.matched_slug &&
          parsed.location?.type === "project_name"
        ? enrichment.matched_slug
        : null,
      p_soft_constraints: parsed.soft_constraints.length
        ? parsed.soft_constraints
        : null,
      p_limit: opts.limit,
      p_offset: opts.offset,
    };

    if (enrichment) {
      rpcArgs.p_center_lat = enrichment.lat;
      rpcArgs.p_center_lng = enrichment.lng;
      rpcArgs.p_radius_km = enrichment.radius_km;
    }

    const { data, error } = await this.db.rpc("smart_search_listings", rpcArgs);

    if (error) {
      console.error("smart_search_listings RPC error", error);
      return await this.fallbackListingQuery(parsed, enrichment, opts);
    }

    return (data ?? []).map((row: Record<string, unknown>) =>
      this.mapListingRow(
        row,
        Number(row.rank_score ?? 0),
        row.distance_km != null ? Number(row.distance_km) : null,
      )
    );
  }

  /** Fallback เมื่อ migration ยังไม่รัน — query listings_public ตรงๆ */
  private async fallbackListingQuery(
    parsed: SmartSearchParsedQuery,
    enrichment: LocationEnrichment | null,
    opts: { limit: number; offset: number },
  ): Promise<SmartSearchListingHit[]> {
    let q = this.db.from("listings_public").select("*");

    const f = parsed.filters;
    if (parsed.property_type) {
      q = q.eq("property_type", parsed.property_type);
    }
    if (f.listing_type === "rent") {
      q = q.in("listing_type", ["rent", "rent_and_sale"]);
    } else if (f.listing_type === "sale") {
      q = q.in("listing_type", ["sale", "sale_installment", "rent_and_sale"]);
    }
    if (f.price_max != null) q = q.lte("price_net", f.price_max);
    if (f.price_min != null) q = q.gte("price_net", f.price_min);
    if (f.bedrooms != null) q = q.gte("bedrooms", f.bedrooms);

    const { data } = await q.limit(opts.limit + opts.offset);
    let rows = data ?? [];

    if (enrichment) {
      rows = rows.filter((r) => {
        const lat = r.lat as number | null;
        const lng = r.lng as number | null;
        if (lat == null || lng == null) return false;
        return haversineKm(enrichment.lat, enrichment.lng, lat, lng) <=
          enrichment.radius_km;
      });
    }

    return rows.slice(opts.offset, opts.offset + opts.limit).map((row) => {
      const lat = row.lat as number | null;
      const lng = row.lng as number | null;
      const dist = enrichment && lat != null && lng != null
        ? haversineKm(enrichment.lat, enrichment.lng, lat, lng)
        : null;
      return this.mapListingRow(row, softScore(parsed, row), dist);
    });
  }

  /** As-you-type autocomplete — local catalog + Google fallback */
  async autocomplete(
    input: string,
    limit = 10,
  ): Promise<AutocompleteSuggestion[]> {
    const q = input.trim();
    if (q.length < 1) return [];

    const out: AutocompleteSuggestion[] = [];
    const seen = new Set<string>();

    const add = (s: AutocompleteSuggestion) => {
      const key = `${s.kind}:${s.slug ?? s.place_id ?? s.title}`;
      if (seen.has(key)) return;
      seen.add(key);
      out.push(s);
    };

    // Local RPC
    const { data: local } = await this.db.rpc(
      "smart_search_autocomplete_local",
      { p_query: q, p_limit: limit },
    );

    for (const row of local ?? []) {
      add({
        kind: row.kind as AutocompleteSuggestion["kind"],
        title: row.title as string,
        subtitle: row.subtitle as string | null,
        slug: row.slug as string | null,
        lat: row.lat as number | null,
        lng: row.lng as number | null,
        source: row.source as string,
      });
    }

    // Google fallback — เฉพาะเมื่อ local น้อย
    if (out.length < limit) {
      const { placesAutocomplete } = await import("./google_places.ts");
      const google = await placesAutocomplete(q, limit - out.length);
      for (const g of google) {
        add({
          kind: "google_place",
          title: g.title,
          subtitle: g.subtitle,
          place_id: g.placeId,
          lat: g.lat ?? null,
          lng: g.lng ?? null,
          source: "google_places",
        });
      }
    }

    return out.slice(0, limit);
  }

  private mapListingRow(
    row: Record<string, unknown>,
    rankScore: number,
    distanceKm: number | null,
  ): SmartSearchListingHit {
    return {
      id: row.id as string,
      listing_code: row.listing_code as string,
      listing_type: row.listing_type as string,
      property_type: row.property_type as string,
      title: row.title as string,
      price_net: Number(row.price_net),
      price_sale_net: row.price_sale_net != null
        ? Number(row.price_sale_net)
        : null,
      bedrooms: row.bedrooms as number | null,
      yield_percent: row.yield_percent != null
        ? Number(row.yield_percent)
        : null,
      investor_category: row.investor_category as string | null,
      project_name: row.project_name as string | null,
      project_slug: row.project_slug as string | null,
      district: row.district as string | null,
      geo_zone_slug: row.geo_zone_slug as string | null,
      lat: row.lat as number | null,
      lng: row.lng as number | null,
      distance_km: distanceKm,
      rank_score: rankScore,
      semantic_score: row.semantic_score != null
        ? Number(row.semantic_score)
        : null,
    };
  }

  private async latLngFromGeography(
    geo: unknown,
  ): Promise<{ lat: number; lng: number } | null> {
    const { data, error } = await this.db.rpc("geography_to_latlng", { g: geo });
    if (error || !data) return null;
    const row = Array.isArray(data) ? data[0] : data;
    if (!row) return null;
    const lat = Number(row.lat);
    const lng = Number(row.lng);
    if (!Number.isFinite(lat) || !Number.isFinite(lng)) return null;
    return { lat, lng };
  }
}

function haversineKm(
  lat1: number,
  lng1: number,
  lat2: number,
  lng2: number,
): number {
  const r = 6371;
  const dLat = (lat2 - lat1) * Math.PI / 180;
  const dLng = (lng2 - lng1) * Math.PI / 180;
  const a = Math.sin(dLat / 2) ** 2 +
    Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) *
      Math.sin(dLng / 2) ** 2;
  return r * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

function softScore(
  parsed: SmartSearchParsedQuery,
  row: Record<string, unknown>,
): number {
  let score = 0;
  const yieldPct = Number(row.yield_percent ?? 0);
  if (parsed.soft_constraints.includes("high_yield")) {
    score += Math.min(yieldPct * 1.5, 30);
  }
  if (
    parsed.soft_constraints.includes("below_market_value") &&
    row.investor_category === "bmv"
  ) {
    score += 25;
  }
  return score;
}
