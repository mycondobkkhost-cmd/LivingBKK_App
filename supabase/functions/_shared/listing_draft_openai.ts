/** AI + rules — ร่างประกาศจากข้อความต้นทาง (capture / import) */

import {
  extractContacts,
  sanitizePublicText,
  stripHtmlTags,
} from "./li_parser.ts";

export type ListingAiDraftFields = {
  title: string;
  description_public: string;
  listing_type: "rent" | "sale";
  property_type: "condo" | "house" | "townhouse" | "apartment" | "other";
  price_net: number | null;
  bedrooms: number | null;
  area_sqm: number | null;
  district: string | null;
  project_name: string | null;
};

export type ListingAiDraftResult = {
  source: "openai" | "rules";
  model: string;
  confidence: number;
  flags: string[];
  fields: ListingAiDraftFields;
};

const SYSTEM = `You rewrite Thai/English property listings for RealXtate (Bangkok metro rental/sale platform).
Return ONLY valid JSON:
{
  "title": "string max 120 chars, engaging, no owner contact",
  "description_public": "string max 2000 chars, engaging Thai preferred, net price context, NO phone/Line/URL/contact",
  "listing_type": "rent|sale",
  "property_type": "condo|house|townhouse|apartment|other",
  "price_net": number or null (THB per month for rent, total for sale),
  "bedrooms": number or null,
  "area_sqm": number or null,
  "district": "string or null",
  "project_name": "string or null",
  "confidence": 0.0-1.0,
  "flags": ["string"]
}
Rules:
- NEVER include owner/agent phone, Line ID, Facebook links, or "contact me" in title/description_public.
- Do NOT invent unit numbers, floor, or building details not in source text.
- Strip marketing fluff from other platforms; write fresh copy suitable for RealXtate.
- If price unclear, set price_net null and flag "missing_price".`;

function parsePrice(text: string): number | null {
  const hay = text.replace(/,/g, "");
  const perMonth = hay.match(/([\d.]+)\s*(?:\/\s*ด\.|\/\s*เดือน|per\s*month|บาท\s*\/\s*ด)/i);
  if (perMonth) {
    const n = parseFloat(perMonth[1]);
    if (Number.isFinite(n) && n > 0) return n;
  }
  const baht = hay.match(/(?:฿|THB|บาท)\s*([\d.]+)/i) ??
    hay.match(/([\d.]+)\s*(?:บาท|฿|baht)/i);
  if (baht) {
    const n = parseFloat(baht[1]);
    if (Number.isFinite(n) && n >= 3000) return n;
  }
  const bare = hay.match(/\b([\d]{4,9})\b/);
  if (bare) {
    const n = parseFloat(bare[1]);
    if (Number.isFinite(n) && n >= 3000) return n;
  }
  return null;
}

function parseBedrooms(text: string): number | null {
  const m = text.match(/type\s*(\d+)\s*bed/i) ||
    text.match(/(\d+)\s*bedroom/i) ||
    text.match(/(\d+)\s*ห้องนอน/i);
  if (!m) return null;
  const n = parseInt(m[1], 10);
  return Number.isFinite(n) && n > 0 && n <= 20 ? n : null;
}

function parseArea(text: string): number | null {
  const m = text.match(/([\d.]+)\s*(?:ตร\.?\s*ม|ตารางเมตร|sqm|sq\.?\s*m)/i);
  if (!m) return null;
  const n = parseFloat(m[1]);
  return Number.isFinite(n) ? n : null;
}

function parseListingType(text: string): "rent" | "sale" {
  const hay = text.toLowerCase();
  if (hay.includes("ให้เช่า") || hay.includes("for rent") || hay.includes("เช่า")) {
    return "rent";
  }
  if (hay.includes("ขาย") || hay.includes("for sale")) return "sale";
  return "rent";
}

function parsePropertyType(text: string): ListingAiDraftFields["property_type"] {
  const hay = text.toLowerCase();
  if (hay.includes("townhome") || hay.includes("ทาวน์")) return "townhouse";
  if (hay.includes("house") || hay.includes("บ้าน")) return "house";
  if (hay.includes("condo") || hay.includes("คอนโด")) return "condo";
  if (hay.includes("apartment") || hay.includes("อพาร์ท")) return "apartment";
  return "condo";
}

function firstLineTitle(text: string): string {
  const line = text.split(/\n/).map((l) => l.trim()).find((l) => l.length > 8);
  return (line ?? text).slice(0, 120);
}

export function draftListingFromRules(sourceText: string): ListingAiDraftResult {
  const cleaned = stripHtmlTags(sourceText).trim();
  const flags: string[] = ["rules_fallback"];
  const price = parsePrice(cleaned);
  if (!price) flags.push("missing_price");

  const description = sanitizePublicText(cleaned).slice(0, 2000);
  const title = sanitizePublicText(firstLineTitle(cleaned)).slice(0, 120);

  return {
    source: "rules",
    model: "rules",
    confidence: 0.35,
    flags,
    fields: {
      title: title || "นำเข้าจากต้นทาง",
      description_public: description || title || cleaned.slice(0, 500),
      listing_type: parseListingType(cleaned),
      property_type: parsePropertyType(cleaned),
      price_net: price,
      bedrooms: parseBedrooms(cleaned),
      area_sqm: parseArea(cleaned),
      district: "กรุงเทพฯ",
      project_name: null,
    },
  };
}

export async function draftListingFromOpenAI(
  sourceText: string,
  context?: { platform?: string; post_url?: string | null },
): Promise<ListingAiDraftResult | null> {
  const key = Deno.env.get("OPENAI_API_KEY");
  if (!key || key.length < 10) return null;

  const model = Deno.env.get("OPENAI_MODEL") ?? "gpt-4o-mini";
  const userContent = [
    context?.platform ? `Platform: ${context.platform}` : "",
    context?.post_url ? `Source URL: ${context.post_url}` : "",
    "",
    "Source text (may contain owner contact — do NOT copy contact into output):",
    sourceText.slice(0, 12_000),
  ].filter(Boolean).join("\n");

  const res = await fetch("https://api.openai.com/v1/chat/completions", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${key}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      model,
      temperature: 0.25,
      response_format: { type: "json_object" },
      messages: [
        { role: "system", content: SYSTEM },
        { role: "user", content: userContent },
      ],
    }),
  });

  if (!res.ok) {
    console.error("listing_draft_openai", await res.text());
    return null;
  }

  const body = await res.json();
  const text = body?.choices?.[0]?.message?.content;
  if (!text || typeof text !== "string") return null;

  try {
    const p = JSON.parse(text);
    const flags = Array.isArray(p.flags)
      ? p.flags.map((f: unknown) => String(f))
      : [];
    flags.push("ai_drafted", "owner_contact_stripped");

    const title = sanitizePublicText(String(p.title ?? "")).slice(0, 120);
    const description = sanitizePublicText(String(p.description_public ?? ""))
      .slice(0, 2000);

    const contacts = extractContacts(sourceText);
    if (contacts.phones.length || contacts.lines.length) {
      flags.push("contacts_stripped");
    }

    const priceRaw = p.price_net;
    const price = typeof priceRaw === "number" && priceRaw > 0
      ? priceRaw
      : parsePrice(sourceText);

    return {
      source: "openai",
      model,
      confidence: typeof p.confidence === "number"
        ? Math.min(1, Math.max(0, p.confidence))
        : 0.7,
      flags: [...new Set(flags)],
      fields: {
        title: title || firstLineTitle(sourceText),
        description_public: description || title,
        listing_type: p.listing_type === "sale" ? "sale" : "rent",
        property_type: ["condo", "house", "townhouse", "apartment", "other"]
            .includes(p.property_type)
          ? p.property_type
          : parsePropertyType(sourceText),
        price_net: price,
        bedrooms: typeof p.bedrooms === "number" ? p.bedrooms : parseBedrooms(
          sourceText,
        ),
        area_sqm: typeof p.area_sqm === "number"
          ? p.area_sqm
          : parseArea(sourceText),
        district: typeof p.district === "string" && p.district.trim()
          ? p.district.trim()
          : "กรุงเทพฯ",
        project_name: typeof p.project_name === "string" &&
            p.project_name.trim()
          ? p.project_name.trim()
          : null,
      },
    };
  } catch {
    return null;
  }
}

export async function generateListingAiDraft(
  sourceText: string,
  context?: { platform?: string; post_url?: string | null },
): Promise<ListingAiDraftResult> {
  const ai = await draftListingFromOpenAI(sourceText, context);
  if (ai) return ai;
  return draftListingFromRules(sourceText);
}
