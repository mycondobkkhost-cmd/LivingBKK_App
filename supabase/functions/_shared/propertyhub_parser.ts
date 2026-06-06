/** PropertyHub.in.th — แหล่งข้อมูลโครงการเดียว (Path A) */

import {
  formatBtsField,
  mergeNearbyTransitLabels,
  transitAliases,
} from "./transit_proximity.ts";

export type PropertyHubParsedProject = {
  slug: string;
  nameTh: string;
  nameEn: string;
  district: string;
  btsStation: string | null;
  nearbyTransit: string[];
  propertyType: string;
  lat: number;
  lng: number;
  yearBuilt: number | null;
  facilities: string[];
  coverImageUrl: string | null;
  descriptionTh: string | null;
  descriptionEn: string | null;
  developerName: string | null;
  aliases: string[];
  sourceUrl: string;
  sourceExternalId: string;
};

const UA =
  "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15";

/** กทม.+ปริมณฑล — path บน Property Hub */
export const METRO_PROVINCE_SLUGS = [
  "bangkok",
  "nonthaburi",
  "pathum-thani",
  "samut-prakan",
  "samut-sakhon",
  "nakhon-pathom",
] as const;

const EXCLUDED_REGION_KEYWORDS = [
  "chiang mai", "เชียงใหม่", "phuket", "ภูเก็ต", "pattaya", "พัทยา",
  "chonburi", "ชลบุรี", "rayong", "ระยอง", "khon kaen", "ขอนแก่น",
  "hat yai", "หาดใหญ่", "songkhla", "สงขลา", "udon", "อุดร",
  "nakhon ratchasima", "โคราช",
];

const METRO_DISTRICT_HINTS = [
  "กรุงเทพ", "bangkok", "นนทบุรี", "nonthaburi", "ปทุมธานี", "pathum",
  "สมุทรปราการ", "samut prakan", "samut sakhon", "นครปฐม", "nakhon pathom",
  "บางใหญ่", "บางบัวทอง", "บางกรวย", "เมืองนนทบุรี", "เมืองปทุมธานี",
  "คลองหลวง", "รังสิต", "บางพลี", "พระประแดง",
];

const BKK_DISTRICTS = [
  "พระนคร", "ดุสิต", "หนองจอก", "บางรัก", "บางเขน", "บางกะปิ", "ปทุมวัน", "ป้อมปราบ",
  "พระโขนง", "มีนบุรี", "ลาดกระบัง", "ยานนาวา", "สัมพันธวงศ์", "พญาไท", "ธนบุรี",
  "คลองสาน", "ตลิ่งชัน", "บางกอกใหญ่", "ห้วยขวาง", "คลองเตย", "ตลิ่งชัน", "บางกอกน้อย",
  "บางขุนเทียน", "ภาษีเจริญ", "หนองแขม", "ราษฎร์บูรณะ", "บางพลัด", "ดินแดง",
  "บึงกุ่ม", "สาทร", "บางซื่อ", "จตุจักร", "บางคอแหลม", "ประเวศ", "คลองเตย",
  "สวนหลวง", "จอมทอง", "ดอนเมือง", "ราชเทวี", "ลาดพร้าว", "วัฒนา", "บางแค",
  "หลักสี่", "สายไหม", "คันนายาว", "สะพานสูง", "วังทองหลาง", "คลองสามวา",
  "บางนา", "ทวีวัฒนา", "ทุ่งครุ", "บางบอน", "บางใหญ่", "บางบัวทอง", "บางกรวย",
  "เมืองนนทบุรี", "เมืองปทุมธานี",
];

const FACILITY_LABELS: Record<string, string> = {
  pool: "สระว่ายน้ำ",
  fitness: "ฟิตเนส",
  park: "สวนสาธารณะ",
  parking: "ที่จอดรถ",
  cctv: "กล้องวงจรปิด",
  security: "รปภ.",
  lift: "ลิฟต์",
  keycard: "คีย์การ์ด",
  steam: "ห้องอบไอน้ำ",
  sauna: "ซาวน่า",
  jacuzzi: "จากุซซี่",
  evCharger: "ที่ชาร์จ EV",
  shuttle: "รถรับส่ง",
  playground: "สนามเด็กเล่น",
  restaurant: "ร้านอาหาร",
  laundry: "ซักรีด",
  library: "ห้องสมุด",
  wifi: "Wi‑Fi",
  allowPet: "เลี้ยงสัตว์ได้",
  bicycleParking: "ที่จอดจักรยาน",
  motorcycleParking: "ที่จอดมอเตอร์ไซค์",
};

export function isPropertyHubProjectUrl(url: string): boolean {
  try {
    const u = new URL(url.startsWith("http") ? url : `https://${url}`);
    return u.hostname.includes("propertyhub.in.th") &&
      /\/projects\/[a-z0-9-]+/.test(u.pathname);
  } catch {
    return false;
  }
}

export function slugFromPropertyHubUrl(url: string): string | null {
  try {
    const u = new URL(url.startsWith("http") ? url : `https://${url}`);
    const m = u.pathname.match(/\/projects\/([a-z0-9-]+)/);
    return m?.[1] ?? null;
  } catch {
    return null;
  }
}

export async function fetchPropertyHubHtml(url: string): Promise<string> {
  let lastErr: Error | null = null;
  for (let attempt = 0; attempt < 2; attempt++) {
    try {
      const res = await fetch(url, {
        headers: {
          "User-Agent": UA,
          Accept: "text/html,application/xhtml+xml",
          "Accept-Language": "th-TH,th;q=0.9,en;q=0.8",
        },
        redirect: "follow",
      });
      if (!res.ok) throw new Error(`PropertyHub HTTP ${res.status}`);
      return await res.text();
    } catch (e) {
      lastErr = e instanceof Error ? e : new Error(String(e));
      await new Promise((r) => setTimeout(r, 400 * (attempt + 1)));
    }
  }
  throw lastErr ?? new Error("PropertyHub fetch failed");
}

function mapProjectType(raw: string | null): string {
  const t = (raw ?? "CONDO").toUpperCase();
  if (t.includes("TOWN")) return "townhouse";
  if (t.includes("HOUSE") || t.includes("HOME")) return "house";
  if (t.includes("APART")) return "apartment";
  if (t === "CONDO") return "condo";
  return "other";
}

/** อยู่ในกรอบ กทม.+ปริมณฑล หรือไม่ */
export function isMetroBangkokProject(input: {
  district?: string | null;
  lat?: number | null;
  lng?: number | null;
  address?: string | null;
}): boolean {
  const text = `${input.address ?? ""} ${input.district ?? ""}`.toLowerCase();
  for (const bad of EXCLUDED_REGION_KEYWORDS) {
    if (text.includes(bad)) return false;
  }
  const lat = input.lat;
  const lng = input.lng;
  if (typeof lat === "number" && typeof lng === "number" && !Number.isNaN(lat) && !Number.isNaN(lng)) {
    if (lat < 13.42 || lat > 14.28 || lng < 100.12 || lng > 100.98) return false;
    return true;
  }
  if (METRO_DISTRICT_HINTS.some((h) => text.includes(h))) return true;
  return BKK_DISTRICTS.some((d) => text.includes(d) || d.includes(text.trim()));
}

/** เขตจาก address เช่น "ห้วยขวาง กรุงเทพมหานคร" */
export function parseDistrictFromAddress(address: string | null): string {
  if (!address?.trim()) return "กรุงเทพฯ";
  const parts = address.trim().split(/\s+/);
  for (const p of parts) {
    if (BKK_DISTRICTS.some((d) => p.includes(d) || d.includes(p))) return p;
  }
  return parts[0] || "กรุงเทพฯ";
}

function facilitiesFromObject(json: string | null): string[] {
  if (!json) return defaultFacilities();
  try {
    const raw = JSON.parse(json.replace(/\\"/g, '"'));
    if (typeof raw !== "object" || raw === null) return defaultFacilities();
    const out: string[] = [];
    for (const [key, on] of Object.entries(raw)) {
      if (on === true && FACILITY_LABELS[key]) out.push(FACILITY_LABELS[key]);
    }
    return out.length > 0 ? out : defaultFacilities();
  } catch {
    return defaultFacilities();
  }
}

function defaultFacilities(): string[] {
  return ["สระว่ายน้ำ", "ฟิตเนส", "ที่จอดรถ", "รปภ."];
}

function normalizeCoverUrl(path: string | null): string | null {
  if (!path?.trim()) return null;
  const p = path.trim();
  if (p.startsWith("http")) return p;
  const rel = p.startsWith("/") ? p.slice(1) : p;
  return `https://bcdn.propertyhub.in.th/${rel}`;
}

function parseMetaDescription(html: string): string | null {
  const m = html.match(/<meta\s+name="description"\s+content="([^"]+)"/i);
  return m?.[1]?.replace(/&quot;/g, '"') ?? null;
}

function parseNearestTransit(html: string): string | null {
  const m = html.match(
    /((?:BTS|MRT|ARL|Airport Rail Link)[^<\n"\\]{2,40}?\d+\s*(?:m|เมตร))/i,
  );
  if (!m) return null;
  return m[1]
    .replace(/\\"/g, "")
    .replace(/\)\s*/, " ")
    .replace(/\s+/g, " ")
    .trim()
    .slice(0, 80);
}

function buildAliases(
  nameTh: string,
  nameEn: string,
  slug: string,
  extra: string[],
): string[] {
  const set = new Set<string>();
  const add = (s: string | null | undefined) => {
    const t = s?.trim();
    if (t && t.length >= 2) set.add(t);
  };
  add(nameTh);
  add(nameEn);
  add(slug.replace(/-/g, " "));
  for (const w of nameTh.split(/\s+/)) {
    if (w.length >= 2) add(w);
  }
  for (const w of nameEn.split(/\s+/)) {
    if (w.length >= 2) add(w);
  }
  for (const a of extra) add(a);
  return [...set].slice(0, 24);
}

type CoreFields = {
  nameTh: string;
  nameEn: string;
  address: string;
  lat: number;
  lng: number;
  projectType: string;
  facilitiesJson: string | null;
  yearBuilt: number | null;
  coverRel: string | null;
  descriptionRaw: string | null;
  developerName: string | null;
  aliasExtras: string[];
};

function parseCoreFields(html: string): CoreFields | null {
  // description อาจมี \u003c หรือ HTML — ห้ามใช้ [^\\]* เพราะจะ match ไม่ติด
  const escaped =
    /\\"name\\":\\"([^\\]+)\\",\\"nameEnglish\\":\\"([^\\]+)\\",\\"description\\":\\"((?:[^"\\]|\\.)*?)\\",\\"address\\":\\"([^\\]*)\\",\\"location\\":\{\\"lat\\":([0-9.+-]+),\\"lng\\":([0-9.+-]+)\},\\"projectType\\":\\"([^\\]+)\\",\\"facilities\\":(\{[^}]+\})/;
  let m = html.match(escaped);
  if (m) {
    const yearM = html.match(/completedYear\\":\\"(\d{4})\\"/);
    const coverM = html.match(/coverPicture\\":\\"([^\\]+)\\"/);
    const devM = html.match(/\\"developer\\":\{[^}]*\\"name\\":\\"([^\\]*)\\"/);
    const namesM = html.match(/possibleProjectNames\\":\[([^\]]+)\]/);
    const extras: string[] = [];
    if (namesM) {
      const inner = namesM[1].replace(/\\"/g, '"');
      for (const nm of inner.matchAll(/"([^"]+)"/g)) extras.push(nm[1]);
    }
    const y = yearM ? parseInt(yearM[1], 10) : null;
    return {
      nameTh: m[1],
      nameEn: m[2],
      address: m[4],
      lat: parseFloat(m[5]),
      lng: parseFloat(m[6]),
      projectType: m[7],
      facilitiesJson: m[8],
      yearBuilt: y && y >= 1980 && y <= 2035 ? y : null,
      coverRel: coverM?.[1] ?? null,
      descriptionRaw: m[3] && !m[3].startsWith("$") ? m[3] : null,
      developerName: devM?.[1]?.trim() || null,
      aliasExtras: extras,
    };
  }

  const plain =
    /"name":"([^"]+)","nameEnglish":"([^"]+)","description":"((?:[^"\\]|\\.)*?)","address":"([^"]*)","location":\{"lat":([0-9.+-]+),"lng":([0-9.+-]+)\},"projectType":"([^"]*)"(?:,"facilities":(\[[^\]]*\]|\{[^}]+\}))?/;
  m = html.match(plain);
  if (!m) return null;

  const yearMatch = html.match(/ปีที่สร้างเสร็จ[^0-9]{0,20}(20\d{2}|19\d{2})/) ??
    html.match(/completedYear\\":\\"(\d{4})\\"/);
  let yearBuilt: number | null = null;
  if (yearMatch) {
    const y = parseInt(yearMatch[1], 10);
    yearBuilt = y >= 1980 && y <= 2035 ? y : null;
  }

  const coverMatch = html.match(
    /https:\/\/bcdn\.propertyhub\.in\.th\/pictures\/[^"\\]+\.(?:jpg|jpeg|png)/,
  ) ?? html.match(/coverPicture\\":\\"([^\\]+)\\"/);

  return {
    nameTh: m[1],
    nameEn: m[2],
    address: m[4],
    lat: parseFloat(m[5]),
    lng: parseFloat(m[6]),
    projectType: m[7],
    facilitiesJson: m[8] ?? null,
    yearBuilt,
    coverRel: coverMatch?.[0]?.startsWith("http") ? coverMatch[0] : coverMatch?.[1] ?? null,
    descriptionRaw: m[3] || null,
    developerName: null,
    aliasExtras: [],
  };
}

/** Parse embedded JSON from Next.js RSC payload on /projects/{slug} pages */
export function parsePropertyHubProjectHtml(
  html: string,
  slug: string,
  sourceUrl: string,
): PropertyHubParsedProject {
  const core = parseCoreFields(html);
  if (!core) {
    throw new Error(`ไม่พบข้อมูลโครงการจาก PropertyHub (${slug})`);
  }

  const metaDesc = parseMetaDescription(html);
  const district = parseDistrictFromAddress(core.address);
  const btsStation = parseNearestTransit(html);
  const facilities = core.facilitiesJson?.startsWith("[")
    ? (() => {
      try {
        const arr = JSON.parse(core.facilitiesJson!.replace(/\\"/g, '"'));
        return Array.isArray(arr) && arr.length > 0
          ? arr.map((x) => String(x))
          : defaultFacilities();
      } catch {
        return defaultFacilities();
      }
    })()
    : facilitiesFromObject(core.facilitiesJson);

  let descriptionTh = core.descriptionRaw || metaDesc;
  if (!descriptionTh || descriptionTh.length < 12) {
    const bits = [
      core.nameTh,
      core.nameEn !== core.nameTh ? core.nameEn : null,
      district,
      core.developerName ? `โดย ${core.developerName}` : null,
      btsStation,
    ].filter(Boolean);
    descriptionTh = bits.join(" · ");
  }

  const coverImageUrl = normalizeCoverUrl(core.coverRel) ??
    html.match(
      /https:\/\/bcdn\.propertyhub\.in\.th\/pictures\/[^"\\]+\.(?:jpg|jpeg|png)/,
    )?.[0] ??
    null;

  const nearbyTransit = mergeNearbyTransitLabels({
    lat: core.lat,
    lng: core.lng,
    descriptionTh,
    html,
    existing: btsStation,
    maxKm: 1.0,
    limit: 5,
  });
  const btsResolved = formatBtsField(nearbyTransit) ?? btsStation;

  const aliases = buildAliases(
    core.nameTh,
    core.nameEn,
    slug,
    [...core.aliasExtras, ...transitAliases(nearbyTransit)],
  );

  return {
    slug,
    nameTh: core.nameTh,
    nameEn: core.nameEn,
    district,
    btsStation: btsResolved,
    nearbyTransit,
    propertyType: mapProjectType(core.projectType),
    lat: core.lat,
    lng: core.lng,
    yearBuilt: core.yearBuilt,
    facilities,
    coverImageUrl,
    descriptionTh,
    descriptionEn: core.nameEn,
    developerName: core.developerName,
    aliases,
    sourceUrl,
    sourceExternalId: slug,
  };
}

export async function parsePropertyHubProjectFromUrl(
  url: string,
): Promise<PropertyHubParsedProject> {
  const slug = slugFromPropertyHubUrl(url);
  if (!slug) throw new Error("URL ต้องเป็น propertyhub.in.th/projects/...");
  const normalized = url.startsWith("http") ? url : `https://${url}`;
  const html = await fetchPropertyHubHtml(normalized);
  return parsePropertyHubProjectHtml(html, slug, normalized);
}

/** Bangkok metro BTS/MRT zone slugs for discovery crawl */
export const BANGKOK_ZONE_SLUGS = [
  "asok", "phrom-phong", "thonglor", "ekkamai", "on-nut", "bang-chak", "bearing",
  "udom-suk", "bang-na", "samrong", "ari", "sanam-pao", "phaya-thai",
  "victory-monument", "siam", "chit-lom", "ploenchit", "nana", "rama-9",
  "huai-khwang", "sutthisan", "lat-phrao", "phra-khanong", "q-suek",
  "wutthakat", "talat-phlu", "bang-wa", "phra-chan", "saphan-taksin",
  "surasak", "saphan-khwai", "mo-chit", "chatuchak-park", "lat-krabang",
  "makkasan", "phetchaburi", "sukhumvit", "silom", "lumphini", "sam-yan",
  "hualamphong", "wat-mangkon", "sam-yot", "sanam-chai", "itsaraphap",
  "ratchathewi", "national-stadium", "ratchadamri", "khlong-toei", "queen-sirikit",
  "si-lom", "saladaeng", "chong-nonsi", "surasak", "saphan-taksin",
  "krung-thon-buri", "wongwian-yai", "pho-nang", "talad-plu", "bang-wa",
  "phra-khanong", "eakamai", "bang-chak", "punnawithi", "udom-suk",
];

/** slug ที่ไม่ใช่หน้าโครงการ (เช่น id ประกาศ --6016885) */
export function isValidPropertyHubProjectSlug(slug: string): boolean {
  if (slug.length < 3 || slug.length > 72) return false;
  if (slug.startsWith("-") || slug.endsWith("-")) return false;
  if (slug.includes("---") || slug.includes("for-sale") || slug.includes("for-rent")) {
    return false;
  }
  if (!/^[a-z0-9][a-z0-9-]*[a-z0-9]$/.test(slug)) return false;
  if (/^--?\d{5,}/.test(slug)) return false;
  return true;
}

export function discoverProjectSlugsFromHtml(html: string): string[] {
  const fromProjects = [...html.matchAll(/\/projects\/([a-z0-9-]+)/g)].map((m) => m[1]);
  const fromListing = [...html.matchAll(/project-([a-z0-9-]+)/g)].map((m) => m[1]);
  const bad = new Set(["undefined", "new", "edit", "search"]);
  return [...new Set([...fromProjects, ...fromListing])].filter(
    (s) => !bad.has(s) && isValidPropertyHubProjectSlug(s),
  );
}

export async function discoverBangkokProjectSlugs(
  maxZones?: number,
): Promise<string[]> {
  const slugs = new Set<string>();
  const zoneCount = maxZones == null || maxZones <= 0
    ? BANGKOK_ZONE_SLUGS.length
    : Math.min(maxZones, BANGKOK_ZONE_SLUGS.length);
  const zones = BANGKOK_ZONE_SLUGS.slice(0, zoneCount);

  const zonePaths = (zone: string) => [
    `https://propertyhub.in.th/en/condo-for-rent/bts-${zone}`,
    `https://propertyhub.in.th/en/condo-for-sale/bts-${zone}`,
  ];

  for (const zone of zones) {
    for (const url of zonePaths(zone)) {
      try {
        const html = await fetchPropertyHubHtml(url);
        for (const s of discoverProjectSlugsFromHtml(html)) slugs.add(s);
      } catch {
        /* skip */
      }
      await new Promise((r) => setTimeout(r, 200));
    }
  }

  const metroListingPaths = [
    "condo-for-rent", "condo-for-sale",
    "house-for-rent", "house-for-sale",
    "townhouse-for-rent", "townhouse-for-sale",
  ];
  for (const province of METRO_PROVINCE_SLUGS) {
    for (const kind of metroListingPaths) {
      const url = `https://propertyhub.in.th/en/${kind}/${province}`;
      try {
        const html = await fetchPropertyHubHtml(url);
        for (const s of discoverProjectSlugsFromHtml(html)) slugs.add(s);
      } catch {
        /* skip */
      }
      await new Promise((r) => setTimeout(r, 200));
    }
  }

  for (const url of [
    "https://propertyhub.in.th/en/new-projects",
    "https://propertyhub.in.th/en/condo-for-rent/bangkok",
    "https://propertyhub.in.th/en/condo-for-sale/bangkok",
    "https://propertyhub.in.th/",
  ]) {
    try {
      const html = await fetchPropertyHubHtml(url);
      for (const s of discoverProjectSlugsFromHtml(html)) slugs.add(s);
    } catch {
      /* skip */
    }
    await new Promise((r) => setTimeout(r, 200));
  }

  return [...slugs].sort();
}
