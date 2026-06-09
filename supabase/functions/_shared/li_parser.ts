/** Living Insider HTML parser — istockdetail / livingdetail */

export type ImportSourceMeta = {
  postUrl?: string | null;
  postText?: string | null;
  posterName?: string | null;
  posterUrl?: string | null;
  postLinks?: string[];
};

export type LiParsedListing = {
  sourceExternalId: string | null;
  title: string;
  description: string;
  listingType: "rent" | "sale";
  propertyType: "condo" | "house" | "townhouse" | "apartment" | "other";
  priceNet: number;
  areaSqm: number | null;
  bedrooms: number | null;
  lat: number | null;
  lng: number | null;
  district: string | null;
  projectName: string | null;
  zoneName: string | null;
  imageUrls: string[];
  flags: string[];
  contactPrivate: { phones: string[]; lines: string[]; urls: string[] };
  sourceMeta?: ImportSourceMeta;
};

const UA =
  "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15";

const PHONE_RE =
  /(0[689]\d[\s-]?\d{3}[\s-]?\d{4})|(\d{3}[-.\s]?\d{3}[-.\s]?\d{4})/g;
const LINE_RE = /line\s*[@:ID]?\s*[@\w.]+/gi;
const URL_RE = /https?:\/\/[^\s<>"']+/gi;

const BUILDING_TYPE_MAP: Record<string, LiParsedListing["propertyType"]> = {
  "1": "condo",
  "2": "house",
  "3": "townhouse",
  "4": "apartment",
  "8": "other",
  "9": "other",
};

export function normalizeLiUrl(raw: string): string {
  const trimmed = raw.trim();
  if (!trimmed) return trimmed;
  try {
    const u = new URL(trimmed.startsWith("http") ? trimmed : `https://${trimmed}`);
    u.hash = "";
    return u.toString();
  } catch {
    return trimmed;
  }
}

export function isLivingInsiderListingUrl(url: string): boolean {
  try {
    const u = new URL(url);
    return u.hostname.includes("livinginsider.com") &&
      (u.pathname.includes("istockdetail") ||
        u.pathname.includes("livingdetail") ||
        u.pathname.includes("/detail/"));
  } catch {
    return false;
  }
}

export async function fetchLiHtml(url: string): Promise<string> {
  const res = await fetch(url, {
    headers: {
      "User-Agent": UA,
      Accept: "text/html,application/xhtml+xml",
      "Accept-Language": "th-TH,th;q=0.9,en;q=0.8",
    },
    redirect: "follow",
  });
  if (!res.ok) {
    throw new Error(`LI fetch HTTP ${res.status}`);
  }
  return await res.text();
}

function decodeHtml(s: string): string {
  return s
    .replace(/&nbsp;/g, " ")
    .replace(/&amp;/g, "&")
    .replace(/&lt;/g, "<")
    .replace(/&gt;/g, ">")
    .replace(/&#(\d+);/g, (_, n) => String.fromCharCode(Number(n)))
    .replace(/\s+/g, " ")
    .trim();
}

function firstMatch(html: string, re: RegExp): string | null {
  const m = html.match(re);
  return m?.[1] ? decodeHtml(m[1]) : null;
}

export function extractContacts(text: string): LiParsedListing["contactPrivate"] {
  const phones = [...text.matchAll(PHONE_RE)].map((m) => m[0]);
  const lines = [...text.matchAll(LINE_RE)].map((m) => m[0]);
  const urls = [...text.matchAll(URL_RE)].map((m) => m[0]);
  return {
    phones: [...new Set(phones)],
    lines: [...new Set(lines)],
    urls: [...new Set(urls)],
  };
}

export function sanitizePublicText(text: string): string {
  let out = text;
  out = out.replace(PHONE_RE, "[ติดต่อผ่าน LivingBKK]");
  out = out.replace(LINE_RE, "[Line ถูกซ่อน]");
  out = out.replace(URL_RE, "");
  return out.replace(/\s{2,}/g, " ").trim();
}

function parsePrice(html: string): number | null {
  const block = firstMatch(html, /<span class="text_b">([^<]+)<\/span>/i);
  if (!block) return null;
  const digits = block.replace(/[^\d.]/g, "");
  const n = parseFloat(digits);
  return Number.isFinite(n) && n > 0 ? n : null;
}

function parseArea(html: string): number | null {
  const m = html.match(
    /class="detail-property-list-text">\s*([\d.]+)\s*ตร\.ม/i,
  );
  if (!m) return null;
  const n = parseFloat(m[1]);
  return Number.isFinite(n) ? n : null;
}

function parseLatLng(html: string): { lat: number | null; lng: number | null } {
  const m = html.match(/query=([\d.+-]+),([\d.+-]+)/);
  if (!m) return { lat: null, lng: null };
  const lat = parseFloat(m[1]);
  const lng = parseFloat(m[2]);
  return {
    lat: Number.isFinite(lat) ? lat : null,
    lng: Number.isFinite(lng) ? lng : null,
  };
}

function parseImages(html: string): string[] {
  const urls = new Set<string>();
  const patterns = [
    /class="gallery-item"[^>]*\n\s*href="(https:\/\/www\.livinginsider\.com\/upload\/topic[^"]+)"/gi,
    /data-src="(https:\/\/www\.livinginsider\.com\/upload\/topic[^"]+)"/gi,
    /src='(https:\/\/www\.livinginsider\.com\/upload\/topic[^']+)'/gi,
    /src="(https:\/\/www\.livinginsider\.com\/upload\/topic[^"]+)"/gi,
  ];
  for (const re of patterns) {
    for (const m of html.matchAll(re)) {
      const u = m[1];
      if (u && !u.includes("photo-contact")) urls.add(u);
    }
  }
  return [...urls];
}

function parseListingType(html: string, title: string): "rent" | "sale" {
  const postType = firstMatch(html, /web_post_type:\s*'(\d+)'/i);
  if (postType === "4" || postType === "2") return "rent";
  if (postType === "1" || postType === "3") return "sale";
  const hay = `${title} ${html.slice(0, 8000)}`.toLowerCase();
  if (hay.includes("ให้เช่า") || hay.includes("for rent") || hay.includes("/ด.")) {
    return "rent";
  }
  return "sale";
}

function parsePropertyType(html: string): LiParsedListing["propertyType"] {
  const bt = firstMatch(html, /web_building_type:\s*'(\d+)'/i);
  if (bt && BUILDING_TYPE_MAP[bt]) return BUILDING_TYPE_MAP[bt];
  const hay = html.toLowerCase();
  if (hay.includes("townhome") || hay.includes("ทาวน์")) return "townhouse";
  if (hay.includes("house") || hay.includes("บ้าน")) return "house";
  if (hay.includes("condo") || hay.includes("คอนโด")) return "condo";
  return "other";
}

function parseBedrooms(html: string, title: string): number | null {
  const m = title.match(/(\d+)\s*bed/i) ||
    html.match(/ห้องนอน[^0-9]*(\d+)/i) ||
    html.match(/(\d+)\s*ห้องนอน/i);
  if (!m) return null;
  const n = parseInt(m[1], 10);
  return Number.isFinite(n) ? n : null;
}

function parseProjectName(html: string, description: string): string | null {
  const breadcrumb = firstMatch(
    html,
    /"name":\s*"([^"]+)"[^}]*"item":\s*"https:\/\/www\.livinginsider\.com\/living_project/i,
  );
  if (breadcrumb && !breadcrumb.includes("ไม่ระบุ")) return breadcrumb;

  const green = firstMatch(html, /class="text_project_detail_green">\s*([^<]+)/i);
  if (green && !green.includes("ไม่ระบุ")) return green;

  const origin = description.match(
    /(?:at|@|โครงการ|project)\s+([A-Za-z0-9\u0E00-\u0E7F\s\-']{3,40})/i,
  );
  if (origin) return origin[1].trim();

  return null;
}

function parseZone(html: string): string | null {
  return firstMatch(
    html,
    /class="text_project_detail_green">\s*([^<]+)/i,
  );
}

export function parseLiHtml(html: string, sourceUrl: string): LiParsedListing {
  const flags: string[] = [];

  const webId = firstMatch(html, /id='data_web_id'[^>]*value="(\d+)"/i) ||
    firstMatch(html, /topic_id:\s*"(\d+)"/i);

  let title = firstMatch(html, /<title>([^<|]+)/i) ?? "Imported listing";
  title = title.replace(/\s*\|\s*Livinginsider.*$/i, "").trim();

  const ogDesc = firstMatch(html, /property="og:description"\s+content="([^"]*)"/i) ??
    "";
  const bodyDesc = firstMatch(html, /<p class="wordwrap">([\s\S]*?)<\/p>/i) ?? "";
  const rawDescription = decodeHtml(`${ogDesc} ${bodyDesc}`.trim());

  const contactPrivate = extractContacts(rawDescription + " " + html.slice(0, 50000));
  const description = sanitizePublicText(rawDescription);

  const priceNet = parsePrice(html);
  if (!priceNet) flags.push("missing_price");

  const areaSqm = parseArea(html);
  const { lat, lng } = parseLatLng(html);
  if (lat == null || lng == null) flags.push("missing_coords");

  const imageUrls = parseImages(html);
  if (imageUrls.length === 0) flags.push("missing_images");

  const listingType = parseListingType(html, title);
  const propertyType = parsePropertyType(html);
  const bedrooms = parseBedrooms(html, title);
  const projectName = parseProjectName(html, rawDescription);
  if (!projectName) flags.push("missing_project");

  const zoneName = parseZone(html);
  const district = zoneName?.split(/\s+/)[0] ?? "กรุงเทพฯ";

  if (contactPrivate.phones.length || contactPrivate.lines.length) {
    flags.push("contacts_stripped");
  }

  return {
    sourceExternalId: webId,
    title,
    description,
    listingType,
    propertyType,
    priceNet: priceNet ?? 0,
    areaSqm,
    bedrooms,
    lat,
    lng,
    district,
    projectName,
    zoneName,
    imageUrls,
    flags,
    contactPrivate,
  };
}

export async function matchProject(
  db: { from: (t: string) => unknown },
  projectName: string | null,
): Promise<Record<string, unknown> | null> {
  if (!projectName) return null;
  const name = projectName.trim();
  if (name.length < 2) return null;

  // deno-lint-ignore no-explicit-any
  const client = db as any;
  const safe = name.replace(/[%_,.()]/g, " ").trim();
  const { data } = await client
    .from("property_projects")
    .select("id, slug, name_th, name_en, district, lat, lng, geo_zone_id, bts_station")
    .eq("is_active", true)
    .or(`name_th.ilike.%${safe}%,name_en.ilike.%${safe}%`)
    .limit(1)
    .maybeSingle();

  if (data) return data as Record<string, unknown>;

  const short = name.split(/\s+/).slice(0, 2).join(" ");
  if (short.length >= 3 && short !== name) {
    const { data: data2 } = await client
      .from("property_projects")
      .select("id, slug, name_th, name_en, district, lat, lng, geo_zone_id, bts_station")
      .eq("is_active", true)
      .or(`name_th.ilike.%${short}%,name_en.ilike.%${short}%`)
      .limit(1)
      .maybeSingle();
    if (data2) return data2 as Record<string, unknown>;
  }

  return null;
}

export { UA };
