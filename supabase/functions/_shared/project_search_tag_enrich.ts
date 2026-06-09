/** แท็กมาตรฐานโครงการ ระดับ A/B — mirror mobile/lib/utils/project_search_tag_enrich.dart */

import {
  labelsFromText,
  nearbyStationsFromCoords,
  transitLabelsFromCoords,
  transitSlug,
} from "./transit_proximity.ts";

type Poi = {
  id: string;
  lat: number;
  lng: number;
  matchRadiusKm: number;
  confidence: string;
};

const GEO_ZONES = [
  { slug: "thonglor", centerLat: 13.722, centerLng: 100.582, maxKm: 1.2 },
  { slug: "sukhumvit-mid", centerLat: 13.728, centerLng: 100.576, maxKm: 1.2 },
  { slug: "asok", centerLat: 13.738, centerLng: 100.561, maxKm: 1.2 },
  { slug: "sukhumvit-early", centerLat: 13.742, centerLng: 100.552, maxKm: 1.2 },
  { slug: "bangna", centerLat: 13.668, centerLng: 100.602, maxKm: 1.5 },
  { slug: "ari", centerLat: 13.78, centerLng: 100.545, maxKm: 1.2 },
  { slug: "silom", centerLat: 13.726, centerLng: 100.532, maxKm: 1.2 },
  { slug: "rama-9", centerLat: 13.76, centerLng: 100.568, maxKm: 1.2 },
  { slug: "ladprao", centerLat: 13.8, centerLng: 100.573, maxKm: 1.2 },
  { slug: "onnut", centerLat: 13.7, centerLng: 100.603, maxKm: 1.2 },
  { slug: "huai-khwang", centerLat: 13.7785, centerLng: 100.5736, maxKm: 1.2 },
];

const STATION_ZONE: Record<string, string[]> = {
  "Thong Lo": ["thonglor"],
  "Ekkamai": ["thonglor"],
  "Phrom Phong": ["sukhumvit-mid"],
  "Asok": ["asok"],
  "Nana": ["asok", "sukhumvit-early"],
  "Bearing": ["bangna"],
  "Samrong": ["bangna"],
  "Bang Chak": ["onnut"],
  "On Nut": ["onnut"],
  "Phra Ram 9": ["rama-9"],
  "Huai Khwang": ["huai-khwang"],
  "Makkasan": ["asok"],
  "Sukhumvit": ["asok"],
  "Ari": ["ari"],
  "Mo Chit": ["ari"],
};

const POIS: Poi[] = [
  { id: "edu-srinakharinwirot", lat: 13.7455, lng: 100.5652, matchRadiusKm: 2.0, confidence: "coords" },
  { id: "edu-chula", lat: 13.7367, lng: 100.5331, matchRadiusKm: 2.5, confidence: "coords" },
  { id: "landmark-bangkok-hospital", lat: 13.753, lng: 100.577, matchRadiusKm: 2.0, confidence: "coords" },
  { id: "landmark-rca", lat: 13.7475, lng: 100.5795, matchRadiusKm: 1.5, confidence: "coords" },
  { id: "landmark-sukhumvit-55", lat: 13.724, lng: 100.5785, matchRadiusKm: 0.9, confidence: "coords" },
];

function haversineKm(lat1: number, lng1: number, lat2: number, lng2: number): number {
  const r = 6371;
  const dLat = (lat2 - lat1) * Math.PI / 180;
  const dLng = (lng2 - lng1) * Math.PI / 180;
  const a = Math.sin(dLat / 2) ** 2 +
    Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) *
      Math.sin(dLng / 2) ** 2;
  return r * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

export type EnrichResult = {
  search_tag_slugs: string[];
  nearby_transit: string[];
  bts_station: string | null;
  aliases_extra: string[];
  primary_geo_zone_slug: string | null;
  tag_enrich_status: string;
  tag_enrich_meta: Record<string, unknown>;
};

export function enrichProjectTags(input: {
  lat: number;
  lng: number;
  name_th?: string | null;
  name_en?: string | null;
  slug?: string | null;
  district?: string | null;
  description_th?: string | null;
  bts_station?: string | null;
  aliases?: string[];
}): EnrichResult {
  const { lat, lng } = input;
  if (lat < 5 || lat > 21 || lng < 97 || lng > 106) {
    return {
      search_tag_slugs: [],
      nearby_transit: [],
      bts_station: null,
      aliases_extra: [],
      primary_geo_zone_slug: null,
      tag_enrich_status: "missing_coords",
      tag_enrich_meta: { reason: "invalid_coords" },
    };
  }

  const slugSet = new Set<string>();
  const sources: Record<string, unknown>[] = [];
  const textWarnings: string[] = [];
  const reviewReasons: string[] = [];
  let transitHitCount = 0;

  const addSlug = (id: string, source: string, distanceM?: number) => {
    if (!id || slugSet.has(id)) return;
    slugSet.add(id);
    sources.push({ id, source, ...(distanceM != null ? { distance_m: distanceM } : {}) });
  };

  let primaryZone: string | null = null;
  let bestZoneKm = Infinity;

  for (const { station, km } of nearbyStationsFromCoords(lat, lng)) {
    transitHitCount++;
    addSlug(transitSlug(station.system, station.nameEn), "A_transit", Math.round(km * 1350));
    for (const z of STATION_ZONE[station.nameEn] ?? []) {
      addSlug(z, "A_transit_zone", Math.round(km * 1350));
    }
  }

  for (const z of GEO_ZONES) {
    const km = haversineKm(lat, lng, z.centerLat, z.centerLng);
    if (km <= z.maxKm) {
      addSlug(z.slug, "A_zone", Math.round(km * 1000));
      if (km < bestZoneKm) {
        bestZoneKm = km;
        primaryZone = z.slug;
      }
    }
  }

  for (const poi of POIS) {
    if (poi.confidence !== "coords") continue;
    const km = haversineKm(lat, lng, poi.lat, poi.lng);
    if (km <= poi.matchRadiusKm) {
      addSlug(poi.id, "A_poi", Math.round(km * 1000));
    }
  }

  const nameHay = [
    input.name_th,
    input.name_en,
    input.slug?.replace(/-/g, " "),
    ...(input.aliases ?? []),
  ].filter(Boolean).join(" ").toLowerCase();

  if (nameHay.includes("ทรู") || nameHay.includes("true")) {
    const nearThonglor = haversineKm(lat, lng, 13.7242, 100.5784) <= 1.5;
    if (primaryZone === "thonglor" || nearThonglor) {
      addSlug("thonglor", "B_name");
      if (input.slug) addSlug(input.slug, "B_project");
    } else {
      reviewReasons.push("name_true_but_far_from_thonglor");
    }
  }

  for (const label of labelsFromText(input.description_th)) {
    const namePart = label.replace(/^(BTS|MRT|ARL|Gold)\s+/, "");
    const stations = nearbyStationsFromCoords(lat, lng, 50, 50);
    const hit = stations.find((h) => h.station.nameTh === namePart || `${h.station.system} ${h.station.nameTh}` === label);
    if (!hit) continue;
    const km = haversineKm(lat, lng, hit.station.lat, hit.station.lng);
    if (km > 1.5) textWarnings.push(`marketing_${label}_${Math.round(km * 1000)}m`);
  }

  const nearbyTransit = transitLabelsFromCoords(lat, lng);

  if (input.slug) slugSet.add(input.slug);

  const hasAB = transitHitCount > 0 || primaryZone != null || slugSet.size > 1;
  const status = reviewReasons.length > 0 ? "needs_review" : !hasAB ? "needs_review" : "auto_ok";

  return {
    search_tag_slugs: [...slugSet],
    nearby_transit: nearbyTransit,
    bts_station: nearbyTransit.length > 0 ? nearbyTransit.join(" · ") : null,
    aliases_extra: nearbyTransit.map((l) => l.replace(/^(BTS|MRT|ARL|Gold)\s+/, "")),
    primary_geo_zone_slug: primaryZone,
    tag_enrich_status: status,
    tag_enrich_meta: {
      tier: "AB_only",
      sources,
      ...(textWarnings.length ? { text_warnings: textWarnings } : {}),
      ...(reviewReasons.length ? { review_reasons: reviewReasons } : {}),
      enriched_at: new Date().toISOString(),
    },
  };
}

// re-export for callers
export { transitSlug } from "./transit_proximity.ts";
