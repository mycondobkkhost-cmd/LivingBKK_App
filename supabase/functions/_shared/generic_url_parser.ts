/**
 * Generic / Facebook / Open Graph parser — ดึงหัวข้อ คำอธิบาย รูปจาก HTML สาธารณะ
 * ราคา/ตร.ม. อาจไม่ครบ → แอดมินแก้ในฟอร์มตรวจสอบ
 */

import type { ListingImportPlatform } from "./listing_import_source.ts";
import { detectListingImportPlatform } from "./listing_import_source.ts";
import type { LiParsedListing } from "./li_parser.ts";
import {
  extractContacts,
  sanitizePublicText,
  UA,
} from "./li_parser.ts";

const FB_MOBILE_UA =
  "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1";

function decodeHtml(s: string): string {
  return s
    .replace(/&nbsp;/g, " ")
    .replace(/&amp;/g, "&")
    .replace(/&lt;/g, "<")
    .replace(/&gt;/g, ">")
    .replace(/&quot;/g, '"')
    .replace(/&#x([0-9a-f]+);/gi, (_, hex) =>
      String.fromCodePoint(parseInt(hex, 16)))
    .replace(/&#(\d+);/g, (_, n) => String.fromCodePoint(Number(n)))
    .replace(/\s+/g, " ")
    .trim();
}

function firstMatch(html: string, re: RegExp): string | null {
  const m = html.match(re);
  return m?.[1] ? decodeHtml(m[1]) : null;
}

/** Facebook www มักคืน Redirecting… — ใช้ m.facebook.com + mobile UA */
function normalizeFacebookFetchUrl(url: string): string {
  try {
    const u = new URL(url);
    const host = u.hostname.toLowerCase();
    if (
      host === "facebook.com" ||
      host === "www.facebook.com" ||
      (host.endsWith(".facebook.com") && !host.startsWith("m."))
    ) {
      u.hostname = "m.facebook.com";
    }
    return u.toString();
  } catch {
    return url;
  }
}

function isJunkFetchTitle(title: string): boolean {
  const t = title.trim().toLowerCase();
  return (
    t === "redirecting..." ||
    t === "redirecting" ||
    t === "error" ||
    t.startsWith("sorry, something went wrong")
  );
}

function parseFacebookOembedTitle(html: string): string | null {
  const m =
    html.match(
      /<link[^>]+rel=["']alternate["'][^>]+title=["']([^"']+)["']/i,
    ) ??
      html.match(
        /<link[^>]+title=["']([^"']+)["'][^>]+rel=["']alternate["']/i,
      );
  if (!m?.[1]) return null;
  return decodeHtml(m[1]).replace(/\s*\|\s*Facebook.*$/i, "").trim() || null;
}

function parseFacebookCanonicalPostUrl(html: string): string | null {
  const m =
    html.match(
      /<link[^>]+rel=["']alternate["'][^>]+href=["']([^"']+)["']/i,
    ) ??
      html.match(
        /<link[^>]+href=["']([^"']+)["'][^>]+rel=["']alternate["']/i,
      );
  const href = m?.[1];
  if (!href) return null;
  try {
    const u = new URL(href);
    const postUrl = u.searchParams.get("url");
    return postUrl ? decodeURIComponent(postUrl) : null;
  } catch {
    return null;
  }
}

export async function fetchPageHtml(
  url: string,
  platform?: ListingImportPlatform,
): Promise<string> {
  const resolvedPlatform = platform ?? detectListingImportPlatform(url);
  let fetchUrl = url;
  let userAgent = UA;
  if (resolvedPlatform === "facebook") {
    fetchUrl = normalizeFacebookFetchUrl(url);
    userAgent = FB_MOBILE_UA;
  }

  const res = await fetch(fetchUrl, {
    headers: {
      "User-Agent": userAgent,
      Accept: "text/html,application/xhtml+xml",
      "Accept-Language": "th-TH,th;q=0.9,en;q=0.8",
    },
    redirect: "follow",
  });
  if (!res.ok) {
    throw new Error(`ดึงหน้าเว็บไม่ได้ HTTP ${res.status}`);
  }
  return await res.text();
}

function metaContent(html: string, keys: string[]): string | null {
  for (const key of keys) {
    const v =
      firstMatch(
        html,
        new RegExp(
          `<meta[^>]+(?:property|name)=["']${key}["'][^>]+content=["']([^"']*)["']`,
          "i",
        ),
      ) ??
        firstMatch(
          html,
          new RegExp(
            `<meta[^>]+content=["']([^"']*)["'][^>]+(?:property|name)=["']${key}["']`,
            "i",
          ),
        );
    if (v && v.trim()) return v.trim();
  }
  return null;
}

function parseOgImages(html: string): string[] {
  const urls = new Set<string>();
  const patterns = [
    /property=["']og:image(?::url)?["'][^>]+content=["']([^"']+)["']/gi,
    /content=["']([^"']+)["'][^>]+property=["']og:image(?::url)?["']/gi,
    /name=["']twitter:image["'][^>]+content=["']([^"']+)["']/gi,
    /content=["']([^"']+)["'][^>]+name=["']twitter:image["']/gi,
    /<link[^>]+rel=["']image_src["'][^>]+href=["']([^"']+)["']/gi,
  ];
  for (const re of patterns) {
    for (const m of html.matchAll(re)) {
      const u = m[1]?.trim();
      if (u && u.startsWith("http")) urls.add(u);
    }
  }
  return [...urls];
}

function parsePriceFromText(text: string): number | null {
  const hay = text.replace(/,/g, "");
  const million = hay.match(/([\d.]+)\s*(?:ล้าน|ล\.|million|M\b)/i);
  if (million) {
    const n = parseFloat(million[1]);
    if (Number.isFinite(n) && n > 0) return Math.round(n * 1_000_000);
  }
  const perMonth = hay.match(/([\d.]+)\s*(?:\/\s*ด\.|\/\s*เดือน|per\s*month)/i);
  if (perMonth) {
    const n = parseFloat(perMonth[1]);
    if (Number.isFinite(n) && n > 0) return n;
  }
  const baht = hay.match(/(?:฿|THB|บาท)\s*([\d.]+)/i) ??
    hay.match(/([\d.]+)\s*(?:บาท|฿|baht)/i);
  if (baht) {
    const n = parseFloat(baht[1]);
    if (Number.isFinite(n) && n > 0) return n;
  }
  const bare = hay.match(/\b([\d]{4,9})\b/);
  if (bare) {
    const n = parseFloat(bare[1]);
    if (Number.isFinite(n) && n >= 3000) return n;
  }
  return null;
}

function parseListingType(text: string): "rent" | "sale" {
  const hay = text.toLowerCase();
  if (
    hay.includes("ให้เช่า") ||
    hay.includes("for rent") ||
    hay.includes("เช่า") ||
    hay.includes("/ด.") ||
    hay.includes("per month")
  ) {
    return "rent";
  }
  if (
    hay.includes("ขาย") ||
    hay.includes("for sale") ||
    hay.includes("ซื้อ")
  ) {
    return "sale";
  }
  return "rent";
}

function parsePropertyType(text: string): LiParsedListing["propertyType"] {
  const hay = text.toLowerCase();
  if (hay.includes("townhome") || hay.includes("ทาวน์")) return "townhouse";
  if (hay.includes("house") || hay.includes("บ้านเดี่ยว") || hay.includes("บ้าน")) {
    return "house";
  }
  if (hay.includes("condo") || hay.includes("คอนโด")) return "condo";
  if (hay.includes("apartment") || hay.includes("อพาร์ท")) return "apartment";
  return "condo";
}

function parseAreaSqm(text: string): number | null {
  const m = text.match(/([\d.]+)\s*(?:ตร\.?\s*ม|ตารางเมตร|sqm|sq\.?\s*m)/i);
  if (!m) return null;
  const n = parseFloat(m[1]);
  return Number.isFinite(n) ? n : null;
}

function parseBedrooms(text: string): number | null {
  const m = text.match(/(\d+)\s*(?:ห้องนอน|bed)/i);
  if (!m) return null;
  const n = parseInt(m[1], 10);
  return Number.isFinite(n) ? n : null;
}

function externalIdFromUrl(sourceUrl: string, platform: ListingImportPlatform): string | null {
  try {
    const u = new URL(sourceUrl);
    if (platform === "facebook") {
      const story = u.searchParams.get("story_fbid") ??
        u.pathname.match(/\/posts\/(\d+)/)?.[1] ??
        u.pathname.match(/(\d{8,})/)?.[1];
      if (story) return `fb-${story}`;
    }
    const tail = u.pathname.split("/").filter(Boolean).pop();
    if (tail && tail.length >= 4 && tail.length <= 80) return tail.slice(0, 80);
    return null;
  } catch {
    return null;
  }
}

function extractUrlsFromText(text: string): string[] {
  const urls = new Set<string>();
  for (const m of text.matchAll(/https?:\/\/[^\s<>"')\]]+/gi)) {
    const u = m[0]?.replace(/[.,;:!?)]+$/, "").trim();
    if (u && u.length > 12) urls.add(u);
  }
  return [...urls].slice(0, 30);
}

function parseFacebookPoster(html: string): { name: string | null; url: string | null } {
  const author = metaContent(html, [
    "article:author",
    "og:article:author",
    "author",
    "twitter:creator",
  ]);
  if (author?.startsWith("http")) {
    return { name: null, url: author };
  }
  if (author && author.trim()) {
    return { name: author.trim(), url: null };
  }
  const ldAuthor = firstMatch(
    html,
    /"author"\s*:\s*\{[^}]*"name"\s*:\s*"([^"]+)"/i,
  );
  const ldUrl = firstMatch(
    html,
    /"author"\s*:\s*\{[^}]*"url"\s*:\s*"([^"]+)"/i,
  );
  return {
    name: ldAuthor,
    url: ldUrl,
  };
}

function isFacebookLoginWall(html: string): boolean {
  const hay = html.slice(0, 120_000).toLowerCase();
  return (
    hay.includes('id="loginform"') ||
    hay.includes("login_form") ||
    hay.includes("you must log in") ||
    hay.includes("เข้าสู่ระบบ facebook")
  );
}

export function parseGenericHtml(
  html: string,
  sourceUrl: string,
  platform: ListingImportPlatform,
): LiParsedListing {
  const flags: string[] = ["generic_og_parse"];

  if (platform === "facebook") {
    flags.push("facebook_source");
    if (isFacebookLoginWall(html)) {
      flags.push("facebook_login_wall");
    }
  }

  const ogTitle = metaContent(html, ["og:title", "twitter:title"]);
  const titleTag = firstMatch(html, /<title[^>]*>([^<]+)<\/title>/i);
  const oembedTitle = platform === "facebook" ? parseFacebookOembedTitle(html) : null;
  let title = ogTitle ?? oembedTitle ?? titleTag ?? "นำเข้าจากลิงก์ภายนอก";
  title = decodeHtml(title)
    .replace(/\s*[-|·]\s*Facebook.*$/i, "")
    .replace(/\s*[-|·]\s*Meta.*$/i, "")
    .trim();

  if (platform === "facebook" && isJunkFetchTitle(title)) {
    flags.push("facebook_fetch_blocked");
    const fallback = oembedTitle && !isJunkFetchTitle(oembedTitle)
      ? oembedTitle
      : "นำเข้าจาก Facebook (ดึงข้อมูลไม่ครบ — กรอกมือ)";
    title = fallback;
  }

  const ogDesc = metaContent(html, ["og:description", "description", "twitter:description"]) ?? "";
  const bodySnippet = firstMatch(html, /<body[^>]*>([\s\S]{0, 8000})/i) ?? "";
  const rawDescription = decodeHtml(`${ogDesc}`.trim() || bodySnippet.slice(0, 2000));
  const contactPrivate = extractContacts(rawDescription + " " + html.slice(0, 30_000));
  const description = sanitizePublicText(rawDescription);

  if (!ogTitle && !titleTag) flags.push("missing_title");
  if (!description || description.length < 8) flags.push("missing_description");

  const priceNet = parsePriceFromText(`${title} ${rawDescription}`);
  if (!priceNet) flags.push("missing_price");

  const imageUrls = parseOgImages(html);
  if (imageUrls.length === 0) flags.push("missing_images");

  const listingType = parseListingType(`${title} ${rawDescription}`);
  const propertyType = parsePropertyType(`${title} ${rawDescription}`);
  const areaSqm = parseAreaSqm(`${title} ${rawDescription}`);
  const bedrooms = parseBedrooms(`${title} ${rawDescription}`);

  if (contactPrivate.phones.length || contactPrivate.lines.length) {
    flags.push("contacts_stripped");
  }

  flags.push("needs_admin_review");

  const fbCanonical = platform === "facebook"
    ? parseFacebookCanonicalPostUrl(html)
    : null;
  const canonicalUrl = fbCanonical ??
    metaContent(html, ["og:url", "twitter:url"]) ??
    sourceUrl;
  const postText = rawDescription || description || title;
  const poster = platform === "facebook" ? parseFacebookPoster(html) : { name: null, url: null };
  const postLinks = platform === "facebook"
    ? extractUrlsFromText(`${postText} ${ogDesc}`)
    : extractUrlsFromText(postText);

  const sourceMeta = platform === "facebook"
    ? {
      postUrl: canonicalUrl,
      postText: postText.slice(0, 12_000),
      posterName: poster.name,
      posterUrl: poster.url,
      postLinks,
    }
    : platform === "generic"
    ? {
      postUrl: canonicalUrl,
      postText: postText.slice(0, 12_000),
      postLinks: extractUrlsFromText(postText),
    }
    : undefined;

  return {
    sourceExternalId: externalIdFromUrl(sourceUrl, platform),
    title,
    description: description || title,
    listingType,
    propertyType,
    priceNet: priceNet ?? 0,
    areaSqm,
    bedrooms,
    lat: null,
    lng: null,
    district: "กรุงเทพฯ",
    projectName: null,
    zoneName: null,
    imageUrls,
    flags,
    contactPrivate,
    sourceMeta,
    sourceTextOriginal: rawDescription,
  };
}
