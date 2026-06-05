/** Parse Living Insider pages into property_projects rows */

import {
  fetchLiHtml,
  isLivingInsiderListingUrl,
  normalizeLiUrl,
  parseLiHtml,
  type LiParsedListing,
} from "./li_parser.ts";

export type LiParsedProject = {
  nameTh: string;
  nameEn: string;
  district: string;
  btsStation: string | null;
  propertyType: string;
  lat: number;
  lng: number;
  aliases: string[];
  yearBuilt: number | null;
  facilities: string[];
  descriptionTh: string | null;
  coverImageUrl: string | null;
  sourceUrl: string;
  sourcePlatform: string;
  sourceExternalId: string | null;
};

export function isLivingInsiderUrl(url: string): boolean {
  try {
    const u = new URL(url);
    return u.hostname.includes("livinginsider.com");
  } catch {
    return false;
  }
}

export function isLivingInsiderProjectUrl(url: string): boolean {
  try {
    const u = new URL(url);
    return u.hostname.includes("livinginsider.com") &&
      (u.pathname.includes("living_project") ||
        u.pathname.includes("projectdetail") ||
        u.pathname.includes("/project/"));
  } catch {
    return false;
  }
}

export function slugifyProjectName(raw: string): string {
  const s = raw
    .toLowerCase()
    .trim()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/-+/g, "-")
    .replace(/^-|-$/g, "");
  return (s.length >= 2 ? s : `project-${Date.now()}`).slice(0, 80);
}

function decodeHtml(s: string): string {
  return s
    .replace(/&nbsp;/g, " ")
    .replace(/&amp;/g, "&")
    .replace(/&lt;/g, "<")
    .replace(/&gt;/g, ">")
    .replace(/\s+/g, " ")
    .trim();
}

function firstMatch(html: string, re: RegExp): string | null {
  const m = html.match(re);
  return m?.[1] ? decodeHtml(m[1]) : null;
}

function splitAliases(text: string | null): string[] {
  if (!text) return [];
  return [...new Set(
    text.split(/[,|/·]/).map((s) => s.trim()).filter((s) => s.length >= 2),
  )].slice(0, 12);
}

function parseYearBuilt(html: string): number | null {
  const m = html.match(/(?:สร้าง|complete|built)[^0-9]{0,20}(20\d{2}|19\d{2})/i) ||
    html.match(/(20\d{2}|19\d{2})\s*(?:CE|ค\.ศ|พ\.ศ)?/);
  if (!m) return null;
  let y = parseInt(m[1], 10);
  if (y > 2400) y -= 543;
  return y >= 1980 && y <= 2035 ? y : null;
}

function parseFacilities(html: string): string[] {
  const defaults = ["สระว่ายน้ำ", "ฟิตเนส", "ที่จอดรถ", "รปภ. 24 ชม."];
  const found: string[] = [];
  const hay = html.toLowerCase();
  const map: Record<string, string> = {
    pool: "สระว่ายน้ำ",
    fitness: "ฟิตเนส",
    gym: "ฟิตเนส",
    parking: "ที่จอดรถ",
    security: "รปภ. 24 ชม.",
    cowork: "Co-working",
    lounge: "Sky Lounge",
  };
  for (const [key, label] of Object.entries(map)) {
    if (hay.includes(key) || hay.includes(label)) found.push(label);
  }
  return found.length > 0 ? [...new Set(found)] : defaults;
}

function listingToProject(
  parsed: LiParsedListing,
  sourceUrl: string,
  html: string,
): LiParsedProject {
  const nameTh = parsed.projectName?.trim() ||
    parsed.zoneName?.trim() ||
    parsed.title.split(/[·|]/)[0]?.trim() ||
    "โครงการไม่ระบุชื่อ";
  const nameEn = firstMatch(html, /<meta property="og:title" content="([^"]+)"/i) ??
    nameTh;
  const district = parsed.district?.trim() || parsed.zoneName?.trim() || "กรุงเทพฯ";
  const lat = parsed.lat ?? 13.7367;
  const lng = parsed.lng ?? 100.5608;

  return {
    nameTh,
    nameEn: nameEn.slice(0, 120),
    district,
    btsStation: parsed.zoneName?.includes("BTS") ? parsed.zoneName : null,
    propertyType: parsed.propertyType,
    lat,
    lng,
    aliases: splitAliases(nameTh),
    yearBuilt: parseYearBuilt(html),
    facilities: parseFacilities(html),
    descriptionTh: parsed.description.slice(0, 4000) || null,
    coverImageUrl: parsed.imageUrls[0] ?? null,
    sourceUrl,
    sourcePlatform: "livinginsider",
    sourceExternalId: parsed.sourceExternalId,
  };
}

export function parseLiProjectPageHtml(
  html: string,
  sourceUrl: string,
): LiParsedProject {
  const nameTh = firstMatch(html, /<h1[^>]*>([^<]+)/i) ||
    firstMatch(html, /class="text_project_detail_green">\s*([^<]+)/i) ||
    firstMatch(
      html,
      /"name":\s*"([^"]+)"[^}]*"item":\s*"https:\/\/www\.livinginsider\.com\/living_project/i,
    ) ||
    "โครงการไม่ระบุชื่อ";

  const nameEn = firstMatch(html, /<meta property="og:title" content="([^"]+)"/i) ??
    nameTh;

  const district = firstMatch(html, /เขต([^<\s]+)/i) ||
    firstMatch(html, /District[^:]*:\s*([^<\n]+)/i) ||
    "กรุงเทพฯ";

  const latLng = html.match(/query=([\d.+-]+),([\d.+-]+)/);
  const lat = latLng ? parseFloat(latLng[1]) : 13.7367;
  const lng = latLng ? parseFloat(latLng[2]) : 100.5608;

  const cover = firstMatch(
    html,
    /src="(https:\/\/www\.livinginsider\.com\/upload\/[^"]+)"/i,
  );

  const externalId = firstMatch(html, /project_id:\s*'?(\d+)'?/i) ||
    firstMatch(html, /living_project\/(\d+)/i);

  return {
    nameTh: nameTh.slice(0, 120),
    nameEn: nameEn.slice(0, 120),
    district: district.slice(0, 80),
    btsStation: firstMatch(html, /BTS[^<\n]{0,40}/i),
    propertyType: html.toLowerCase().includes("town") ? "townhouse"
      : html.toLowerCase().includes("house") || html.toLowerCase().includes("บ้าน")
      ? "house"
      : "condo",
    lat: Number.isFinite(lat) ? lat : 13.7367,
    lng: Number.isFinite(lng) ? lng : 100.5608,
    aliases: splitAliases(nameTh),
    yearBuilt: parseYearBuilt(html),
    facilities: parseFacilities(html),
    descriptionTh: firstMatch(html, /class="detail-property-list-text">([^<]{20,})/i),
    coverImageUrl: cover,
    sourceUrl,
    sourcePlatform: "livinginsider",
    sourceExternalId: externalId,
  };
}

export async function parseProjectFromUrl(sourceUrl: string): Promise<LiParsedProject> {
  const url = normalizeLiUrl(sourceUrl);
  if (!isLivingInsiderUrl(url)) {
    throw new Error("URL ต้องเป็น livinginsider.com");
  }

  const html = await fetchLiHtml(url);

  if (isLivingInsiderListingUrl(url)) {
    const listing = parseLiHtml(html, url);
    if (!listing.projectName && !listing.zoneName) {
      throw new Error("ไม่พบชื่อโครงการในหน้า LI — ลองลิงก์หน้าโครงการ หรือกรอกเอง");
    }
    return listingToProject(listing, url, html);
  }

  return parseLiProjectPageHtml(html, url);
}
