/** Google Places Text Search — ปักพิกัดโครงการเมื่อไม่มีในสมุดกลาง */

export type GeocodeHit = {
  lat: number;
  lng: number;
  name: string;
  formattedAddress: string;
  placeId: string | null;
  district: string | null;
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

function buildQuery(projectName: string, hintDistrict?: string | null): string {
  const name = projectName.replace(/\s+/g, " ").trim();
  const district = hintDistrict?.replace(/\s+/g, " ").trim();
  const parts = [name, "condo", district, "bangkok", "thailand"].filter(Boolean);
  return parts.join(" ");
}

export async function geocodeProjectByName(
  projectName: string,
  hintDistrict?: string | null,
): Promise<GeocodeHit | null> {
  const key = Deno.env.get("GOOGLE_MAPS_API_KEY")?.trim();
  if (!key) return null;

  const query = buildQuery(projectName, hintDistrict);
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
      name: hit.name?.trim() || projectName.trim(),
      formattedAddress: formatted,
      placeId: hit.place_id ?? null,
      district: extractDistrict(formatted),
    };
  }

  return null;
}
