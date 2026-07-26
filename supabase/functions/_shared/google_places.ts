/**
 * Google Maps Places — Text Search, Autocomplete, Geocoding
 * ใช้เติมพิกัดเมื่อ catalog ภายใน (geo_zones, property_projects, transit_stations) ไม่ครบ
 */

import type { LocationType } from "./smart_search_types.ts";

export type GeocodeHit = {
  lat: number;
  lng: number;
  name: string;
  formattedAddress: string;
  placeId: string | null;
  district: string | null;
};

export type AutocompleteHit = {
  placeId: string;
  title: string;
  subtitle: string;
  lat?: number;
  lng?: number;
};

const METRO_BBOX = {
  latMin: 13.2,
  latMax: 14.5,
  lngMin: 99.8,
  lngMax: 101.2,
};

function inMetro(lat: number, lng: number): boolean {
  return lat >= METRO_BBOX.latMin && lat <= METRO_BBOX.latMax &&
    lng >= METRO_BBOX.lngMin && lng <= METRO_BBOX.lngMax;
}

function normalizePlaceId(raw: string | undefined | null): string | null {
  if (!raw) return null;
  const id = raw.trim();
  if (!id) return null;
  return id.startsWith("places/") ? id.slice("places/".length) : id;
}

function extractDistrict(formattedAddress: string): string | null {
  const parts = formattedAddress.split(",").map((p) => p.trim());
  for (const p of parts) {
    if (/กรุงเทพ|bangkok/i.test(p)) continue;
    if (/^\d{5}$/.test(p)) continue;
    if (/thailand/i.test(p)) continue;
    if (p.length >= 2 && p.length <= 40) return p;
  }
  return null;
}

/** สร้าง query ให้ Google เข้าใจบริบทกทม. */
export function buildPlacesQuery(rawText: string, locationType: LocationType): string {
  const name = rawText.replace(/\s+/g, " ").trim();
  const suffix = locationType === "transit_station"
    ? "BTS MRT station Bangkok Thailand"
    : locationType === "project_name"
    ? "condo Bangkok Thailand"
    : "Bangkok Thailand";
  return `${name} ${suffix}`.trim();
}

function getMapsKey(): string | null {
  const key = Deno.env.get("GOOGLE_MAPS_API_KEY")?.trim();
  return key && key.length > 5 ? key : null;
}

async function geocodeViaPlacesNew(
  key: string,
  query: string,
  fallbackName: string,
): Promise<GeocodeHit | null> {
  const res = await fetch("https://places.googleapis.com/v1/places:searchText", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "X-Goog-Api-Key": key,
      "X-Goog-FieldMask":
        "places.displayName,places.formattedAddress,places.location,places.id",
    },
    body: JSON.stringify({
      textQuery: query,
      languageCode: "th",
      regionCode: "TH",
    }),
  });

  if (!res.ok) return null;

  const body = await res.json() as {
    places?: Array<{
      id?: string;
      displayName?: { text?: string };
      formattedAddress?: string;
      location?: { latitude?: number; longitude?: number };
    }>;
  };

  if (!body.places?.length) return null;

  for (const hit of body.places.slice(0, 5)) {
    const lat = Number(hit.location?.latitude);
    const lng = Number(hit.location?.longitude);
    if (!Number.isFinite(lat) || !Number.isFinite(lng)) continue;
    if (!inMetro(lat, lng)) continue;

    const formatted = hit.formattedAddress ?? "";
    return {
      lat,
      lng,
      name: hit.displayName?.text?.trim() || fallbackName,
      formattedAddress: formatted,
      placeId: normalizePlaceId(hit.id),
      district: extractDistrict(formatted),
    };
  }

  return null;
}

async function geocodeViaLegacyPlaces(
  key: string,
  query: string,
  fallbackName: string,
): Promise<GeocodeHit | null> {
  const url = new URL("https://maps.googleapis.com/maps/api/place/textsearch/json");
  url.searchParams.set("query", query);
  url.searchParams.set("key", key);
  url.searchParams.set("language", "th");
  url.searchParams.set("region", "th");

  const res = await fetch(url.toString());
  if (!res.ok) return null;

  const body = await res.json() as {
    status?: string;
    results?: Array<{
      name?: string;
      formatted_address?: string;
      place_id?: string;
      geometry?: { location?: { lat?: number; lng?: number } };
    }>;
  };

  if (body.status !== "OK" || !body.results?.length) return null;

  for (const hit of body.results.slice(0, 5)) {
    const lat = Number(hit.geometry?.location?.lat);
    const lng = Number(hit.geometry?.location?.lng);
    if (!Number.isFinite(lat) || !Number.isFinite(lng)) continue;
    if (!inMetro(lat, lng)) continue;

    const formatted = hit.formatted_address ?? "";
    return {
      lat,
      lng,
      name: hit.name?.trim() || fallbackName,
      formattedAddress: formatted,
      placeId: hit.place_id ?? null,
      district: extractDistrict(formatted),
    };
  }

  return null;
}

/** Text Search — รองรับ neighborhood / transit / project */
export async function geocodeLocationByText(
  rawText: string,
  locationType: LocationType = "other",
): Promise<GeocodeHit | null> {
  const key = getMapsKey();
  if (!key) return null;

  const query = buildPlacesQuery(rawText, locationType);

  const fromNew = await geocodeViaPlacesNew(key, query, rawText);
  if (fromNew) return fromNew;

  return await geocodeViaLegacyPlaces(key, query, rawText);
}

/** Backward compat — ใช้โดย project-geocode-preview */
export async function geocodeProjectByName(
  projectName: string,
  hintDistrict?: string | null,
): Promise<GeocodeHit | null> {
  const district = hintDistrict?.replace(/\s+/g, " ").trim();
  const parts = [projectName.replace(/\s+/g, " ").trim(), "condo", district, "bangkok", "thailand"]
    .filter(Boolean);
  const key = getMapsKey();
  if (!key) return null;

  const query = parts.join(" ");
  const fromNew = await geocodeViaPlacesNew(key, query, projectName);
  if (fromNew) return fromNew;
  return await geocodeViaLegacyPlaces(key, query, projectName);
}

/** Places Autocomplete (New API) — fallback เมื่อ local catalog ไม่พอ */
export async function placesAutocomplete(
  input: string,
  limit = 5,
): Promise<AutocompleteHit[]> {
  const key = getMapsKey();
  const q = input.trim();
  if (!key || q.length < 2) return [];

  try {
    const res = await fetch("https://places.googleapis.com/v1/places:autocomplete", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-Goog-Api-Key": key,
      },
      body: JSON.stringify({
        input: q,
        languageCode: "th",
        regionCode: "TH",
        includedRegionCodes: ["TH"],
        locationBias: {
          circle: {
            center: { latitude: 13.7563, longitude: 100.5018 },
            radius: 50000.0,
          },
        },
      }),
    });

    if (!res.ok) {
      return await legacyAutocomplete(key, q, limit);
    }

    const body = await res.json() as {
      suggestions?: Array<{
        placePrediction?: {
          placeId?: string;
          text?: { text?: string };
          structuredFormat?: {
            mainText?: { text?: string };
            secondaryText?: { text?: string };
          };
        };
      }>;
    };

    const out: AutocompleteHit[] = [];
    for (const s of body.suggestions ?? []) {
      const p = s.placePrediction;
      if (!p?.placeId) continue;
      const main = p.structuredFormat?.mainText?.text ?? p.text?.text ?? "";
      const sub = p.structuredFormat?.secondaryText?.text ?? "";
      out.push({
        placeId: normalizePlaceId(p.placeId) ?? p.placeId,
        title: main,
        subtitle: sub,
      });
      if (out.length >= limit) break;
    }
    return out;
  } catch (e) {
    console.error("Places autocomplete error", e);
    return legacyAutocomplete(key, q, limit);
  }
}

async function legacyAutocomplete(
  key: string,
  input: string,
  limit: number,
): Promise<AutocompleteHit[]> {
  const url = new URL(
    "https://maps.googleapis.com/maps/api/place/autocomplete/json",
  );
  url.searchParams.set("input", input);
  url.searchParams.set("key", key);
  url.searchParams.set("language", "th");
  url.searchParams.set("components", "country:th");
  url.searchParams.set("location", "13.7563,100.5018");
  url.searchParams.set("radius", "50000");

  const res = await fetch(url.toString());
  if (!res.ok) return [];

  const body = await res.json() as {
    status?: string;
    predictions?: Array<{
      place_id?: string;
      description?: string;
      structured_formatting?: {
        main_text?: string;
        secondary_text?: string;
      };
    }>;
  };

  if (body.status !== "OK" || !body.predictions?.length) return [];

  return body.predictions.slice(0, limit).map((p) => ({
    placeId: p.place_id ?? "",
    title: p.structured_formatting?.main_text ?? p.description ?? "",
    subtitle: p.structured_formatting?.secondary_text ?? "",
  })).filter((h) => h.placeId);
}
