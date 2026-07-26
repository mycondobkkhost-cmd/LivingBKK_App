import type {
  LocationType,
  ParsedFilters,
  SmartSearchParsedQuery,
  SoftConstraint,
} from "./smart_search_types.ts";
import { parseSearchStub } from "./search_parse_stub.ts";

const SYSTEM = `You parse Thai/English property search queries for Bangkok metro (กทม.+ปริมณฑล).
Return ONLY valid JSON matching this schema:
{
  "property_type": "condo"|"house"|"townhouse"|"apartment"|"other"|null,
  "location": { "raw_text": string, "type": "neighborhood"|"transit_station"|"project_name"|"district"|"other" }|null,
  "filters": {
    "price_min": number|null,
    "price_max": number|null,
    "bedrooms": number|null,
    "bathrooms": number|null,
    "distance_to_transit_meters": number|null,
    "listing_type": "rent"|"sale"|null,
    "pet_allowed": boolean|null,
    "co_agent_eligible": boolean|null,
    "min_yield": number|null,
    "investor_category": "bmv"|"with_tenant"|null
  },
  "soft_constraints": ["high_yield"|"below_market_value"|"with_tenant"|"near_transit"],
  "geo_zone_slugs": string[],
  "project_name": string|null
}
Rules:
- "5 ล้าน" on sale context → price_max 5000000; on rent → 50000/month if unclear assume sale when ล้าน used
- "15k" or "15000" rent → price_max 15000
- "ใกล้ BTS" → distance_to_transit_meters 1000, soft_constraints includes near_transit
- "ผลตอบแทนดี" → soft_constraints includes high_yield, min_yield 5 if not specified
- "ต่ำกว่าราคาตลาด" / BMV → soft_constraints includes below_market_value, investor_category bmv
- location.type transit_station when BTS/MRT/ARL station named; neighborhood for ทองหล่อ/สุขุมวิท; project_name for condo names`;

const VALID_LOCATION_TYPES = new Set<LocationType>([
  "neighborhood",
  "transit_station",
  "project_name",
  "district",
  "other",
]);

const VALID_SOFT: SoftConstraint[] = [
  "high_yield",
  "below_market_value",
  "with_tenant",
  "near_transit",
];

function asNumber(v: unknown): number | null {
  if (v == null) return null;
  const n = Number(v);
  return Number.isFinite(n) ? n : null;
}

function asBool(v: unknown): boolean | null {
  if (v === true || v === false) return v;
  return null;
}

function sanitizeFilters(raw: unknown): ParsedFilters {
  const f = (raw && typeof raw === "object") ? raw as Record<string, unknown> : {};
  return {
    price_min: asNumber(f.price_min),
    price_max: asNumber(f.price_max),
    bedrooms: asNumber(f.bedrooms) != null
      ? Math.floor(asNumber(f.bedrooms)!)
      : null,
    bathrooms: asNumber(f.bathrooms) != null
      ? Math.floor(asNumber(f.bathrooms)!)
      : null,
    distance_to_transit_meters: asNumber(f.distance_to_transit_meters),
    listing_type: f.listing_type === "rent" || f.listing_type === "sale"
      ? f.listing_type
      : null,
    pet_allowed: asBool(f.pet_allowed),
    co_agent_eligible: asBool(f.co_agent_eligible),
    min_yield: asNumber(f.min_yield),
    investor_category: f.investor_category === "bmv" ||
        f.investor_category === "with_tenant"
      ? f.investor_category
      : null,
  };
}

function sanitizeLocation(raw: unknown): SmartSearchParsedQuery["location"] {
  if (!raw || typeof raw !== "object") return null;
  const o = raw as Record<string, unknown>;
  const rawText = typeof o.raw_text === "string" ? o.raw_text.trim() : "";
  if (!rawText) return null;
  const type = VALID_LOCATION_TYPES.has(o.type as LocationType)
    ? o.type as LocationType
    : "other";
  return { raw_text: rawText, type };
}

function sanitizeSoft(raw: unknown): SoftConstraint[] {
  if (!Array.isArray(raw)) return [];
  return raw.filter((s): s is SoftConstraint =>
    typeof s === "string" && VALID_SOFT.includes(s as SoftConstraint)
  );
}

/** แปลง legacy stub filters → SmartSearchParsedQuery */
export function stubToSmartQuery(
  query: string,
  stubFilters: Record<string, unknown>,
): SmartSearchParsedQuery {
  const soft: SoftConstraint[] = [];
  if (stubFilters.investor_category === "bmv") {
    soft.push("below_market_value");
  }
  if (stubFilters.investor_category === "with_tenant") {
    soft.push("with_tenant");
  }
  if (stubFilters.min_yield != null) soft.push("high_yield");

  const geoSlugs = Array.isArray(stubFilters.geo_zone_slugs)
    ? stubFilters.geo_zone_slugs as string[]
    : undefined;

  let location: SmartSearchParsedQuery["location"] = null;
  if (typeof stubFilters.project_name === "string") {
    location = {
      raw_text: stubFilters.project_name,
      type: "project_name",
    };
  } else if (geoSlugs?.length) {
    location = { raw_text: geoSlugs.join(", "), type: "neighborhood" };
  }

  return {
    property_type: typeof stubFilters.property_type === "string"
      ? stubFilters.property_type as SmartSearchParsedQuery["property_type"]
      : null,
    location,
    filters: {
      price_max: asNumber(stubFilters.max_price_net),
      listing_type: stubFilters.listing_type === "rent" ||
          stubFilters.listing_type === "sale"
        ? stubFilters.listing_type
        : null,
      pet_allowed: asBool(stubFilters.pet_allowed),
      co_agent_eligible: asBool(stubFilters.co_agent_eligible),
      min_yield: asNumber(stubFilters.min_yield),
      investor_category: stubFilters.investor_category === "bmv" ||
          stubFilters.investor_category === "with_tenant"
        ? stubFilters.investor_category
        : null,
    },
    soft_constraints: soft,
    geo_zone_slugs: geoSlugs,
    project_name: typeof stubFilters.project_name === "string"
      ? stubFilters.project_name
      : null,
  };
}

export async function parseSmartSearchQuery(
  query: string,
): Promise<{ parsed: SmartSearchParsedQuery; source: "openai" | "rules" | "hybrid" }> {
  const trimmed = query.trim();
  const stub = parseSearchStub(trimmed);
  const stubParsed = stubToSmartQuery(trimmed, stub.filters);

  const aiRaw = await callOpenAIParser(trimmed);
  if (!aiRaw) {
    return { parsed: stubParsed, source: "rules" };
  }

  const merged: SmartSearchParsedQuery = {
    property_type: aiRaw.property_type ?? stubParsed.property_type,
    location: aiRaw.location ?? stubParsed.location,
    filters: {
      ...stubParsed.filters,
      ...aiRaw.filters,
      // stub ชนะเฉพาะเมื่อ AI ไม่ได้ใส่ค่า
      price_max: aiRaw.filters.price_max ?? stubParsed.filters.price_max,
      listing_type: aiRaw.filters.listing_type ?? stubParsed.filters.listing_type,
    },
    soft_constraints: [
      ...new Set([...stubParsed.soft_constraints, ...aiRaw.soft_constraints]),
    ],
    geo_zone_slugs: aiRaw.geo_zone_slugs?.length
      ? aiRaw.geo_zone_slugs
      : stubParsed.geo_zone_slugs,
    project_name: aiRaw.project_name ?? stubParsed.project_name,
  };

  const usedAi = aiRaw.location != null ||
    Object.values(aiRaw.filters).some((v) => v != null) ||
    aiRaw.soft_constraints.length > 0;

  return {
    parsed: merged,
    source: usedAi && stub.filters && Object.keys(stub.filters).length > 0
      ? "hybrid"
      : usedAi
      ? "openai"
      : "rules",
  };
}

async function callOpenAIParser(query: string): Promise<SmartSearchParsedQuery | null> {
  const key = Deno.env.get("OPENAI_API_KEY");
  if (!key || key.length < 10) return null;

  const model = Deno.env.get("OPENAI_MODEL") ?? "gpt-4o-mini";

  let res: Response;
  try {
    res = await fetch("https://api.openai.com/v1/chat/completions", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${key}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model,
        temperature: 0.05,
        response_format: { type: "json_object" },
        messages: [
          { role: "system", content: SYSTEM },
          { role: "user", content: query },
        ],
      }),
    });
  } catch (e) {
    console.error("OpenAI network error", e);
    return null;
  }

  if (!res.ok) {
    console.error("OpenAI error", await res.text());
    return null;
  }

  let body: { choices?: Array<{ message?: { content?: string } }> };
  try {
    body = await res.json();
  } catch {
    return null;
  }

  const text = body?.choices?.[0]?.message?.content;
  if (!text || typeof text !== "string") return null;

  try {
    const parsed = JSON.parse(text) as Record<string, unknown>;
    return {
      property_type: typeof parsed.property_type === "string"
        ? parsed.property_type as SmartSearchParsedQuery["property_type"]
        : null,
      location: sanitizeLocation(parsed.location),
      filters: sanitizeFilters(parsed.filters),
      soft_constraints: sanitizeSoft(parsed.soft_constraints),
      geo_zone_slugs: Array.isArray(parsed.geo_zone_slugs)
        ? parsed.geo_zone_slugs.filter((s): s is string => typeof s === "string")
        : [],
      project_name: typeof parsed.project_name === "string"
        ? parsed.project_name
        : null,
    };
  } catch (e) {
    console.error("OpenAI JSON parse failed", e, text.slice(0, 200));
    return null;
  }
}

/** สร้าง preview chips สำหรับ UI */
export function buildSearchPreview(
  parsed: SmartSearchParsedQuery,
): { label: string; value: string }[] {
  const preview: { label: string; value: string }[] = [];

  if (parsed.location?.raw_text) {
    preview.push({
      label: parsed.location.type === "transit_station" ? "รถไฟฟ้า" : "ทำเล",
      value: parsed.location.raw_text,
    });
  }
  if (parsed.property_type) {
    preview.push({ label: "ประเภท", value: parsed.property_type });
  }
  if (parsed.filters.listing_type) {
    preview.push({
      label: "ธุรกรรม",
      value: parsed.filters.listing_type === "rent" ? "เช่า" : "ขาย",
    });
  }
  if (parsed.filters.price_max != null) {
    preview.push({
      label: "งบ",
      value: `≤ ${parsed.filters.price_max.toLocaleString("th-TH")} บาท`,
    });
  }
  if (parsed.filters.bedrooms != null) {
    preview.push({
      label: "ห้องนอน",
      value: `${parsed.filters.bedrooms}+`,
    });
  }
  if (parsed.soft_constraints.includes("high_yield")) {
    preview.push({ label: "Yield", value: "ผลตอบแทนดี" });
  }
  if (parsed.soft_constraints.includes("below_market_value")) {
    preview.push({ label: "นักลงทุน", value: "BMV" });
  }
  if (parsed.filters.pet_allowed) {
    preview.push({ label: "สัตว์เลี้ยง", value: "อนุญาต" });
  }

  return preview;
}
