export type ChatRoomKind = "property" | "staff_support";

export type ChatLink = {
  label: string;
  kind: "listing" | "projectUnits";
  listingId: string;
  projectName?: string;
};

export type BotReply = {
  role: "ai" | "system" | "admin_notice";
  text: string;
  requires_admin?: boolean;
  links?: ChatLink[];
};

export const AI_DISCLAIMER =
  "AI เป็นตัวช่วยแนะนำโครงการและทรัพย์เบื้องต้นเท่านั้น " +
  "หากต้องการรายละเอียดที่ครบถ้วน กรุณาติดต่อเจ้าหน้าที่โดยตรง";

const SENSITIVE_KEYS = [
  "ทิศ",
  "ต่อรอง",
  "ลดราคา",
  "เจ้าของ",
  "โทร",
  "line",
  "ไลน์",
  "เลขห้อง",
  "ชั้น",
  "commission",
  "คอม",
];

export function isSensitive(text: string): boolean {
  const q = text.toLowerCase();
  return SENSITIVE_KEYS.some((k) => q.includes(k));
}

export function welcomeMessage(
  roomKind: ChatRoomKind,
  listingTitle: string,
  allowViewingRequest: boolean,
  isDiscovery = false,
): BotReply {
  if (roomKind === "staff_support") {
    return {
      role: "admin_notice",
      text:
        "สวัสดีครับ ทีม LivingBKK พร้อมช่วยเหลือ\n" +
        "พิมพ์คำถามได้เลย เราจะตอบกลับในแชทนี้โดยเร็วที่สุด",
    };
  }
  if (isDiscovery) {
    return {
      role: "ai",
      text:
        "สวัสดีครับ ผมผู้ช่วย LivingBKK\n" +
        `${AI_DISCLAIMER}\n\n` +
        "บอกทำเล · โครงการ · งบประมาณ — ผมช่วยคัดทรัพย์ในระบบให้\n" +
        "ตัวอย่าง: 「หาคอนโดเช่า ทองหล่อ งบ 18,000」\n" +
        "หรือเปิดแชทจากทรัพย์ที่สนใจเพื่อถามรายละเอียดเฉพาะห้อง",
    };
  }
  if (allowViewingRequest) {
    return {
      role: "ai",
      text:
        `สวัสดีครับ ผมผู้ช่วย LivingBKK สำหรับ ${listingTitle}\n` +
        `${AI_DISCLAIMER}\n\n` +
        "ถามรายละเอียดทรัพย์นี้ได้เลย — ถามหาทรัพย์อื่น/ทำเล/งบก็ได้ในแชทนี้\n" +
        "หากต้องการนัดดูห้อง กด「ขอนัดดูห้อง」ด้านล่างเมื่อพร้อมครับ",
    };
  }
  return {
    role: "ai",
    text:
      `สวัสดีครับ ผมผู้ช่วย LivingBKK สำหรับ ${listingTitle}\n` +
      `${AI_DISCLAIMER}\n\n` +
      "ถามเรื่องทำเล ราคา เงื่อนไข หรือให้แนะนำทรัพย์อื่นในระบบได้เลยครับ",
  };
}

export type ListingRow = {
  id: string;
  listing_code: string;
  title: string;
  project_name: string | null;
  listing_type: string;
  price_net: number;
  property_type: string;
  district: string | null;
};

function priceLabel(l: ListingRow): string {
  if (l.listing_type === "rent") {
    return `${Math.round(l.price_net / 1000)},000/เดือน`;
  }
  if (l.price_net >= 1_000_000) {
    return `${(l.price_net / 1_000_000).toFixed(1)} ล้าน`;
  }
  return `${Math.round(l.price_net)} บาท`;
}

function extractBudget(q: string): number | null {
  const m = q.match(/(\d[\d,]*)\s*(?:บาท|k|K)?/);
  if (!m) return null;
  let v = parseFloat(m[1].replace(/,/g, ""));
  if (Number.isNaN(v)) return null;
  if (/k/i.test(q) && v < 1000) v *= 1000;
  if (v < 500) v *= 1000;
  return v;
}

function textMatchesListing(q: string, l: ListingRow): boolean {
  const hay = [l.title, l.project_name, l.district, l.listing_code]
    .filter(Boolean)
    .join(" ")
    .toLowerCase();

  const zones: Record<string, string[]> = {
    "ทองหล่อ": ["thong", "thonglor", "ทองหล่อ"],
    "เอกมัย": ["ekkamai", "เอกมัย"],
    "อโศก": ["asok", "อโศก"],
    "สุขุมวิท": ["sukhumvit", "สุขุมวิท"],
    "สาทร": ["sathorn", "สาทร"],
    "สีลม": ["silom", "สีลม"],
    "พระโขนง": ["phra", "พระโขนง"],
    "อารีย์": ["ari", "อารีย์"],
    "ลาดพร้าว": ["lat", "ลาดพร้าว"],
  };

  for (const [key, aliases] of Object.entries(zones)) {
    if (q.includes(key) || aliases.some((v) => q.includes(v))) {
      if (hay.includes(key) || aliases.some((v) => hay.includes(v))) return true;
    }
  }

  if (q.includes("คอนโด") && l.property_type === "condo") return true;
  if (q.includes("บ้าน") && l.property_type !== "condo") return true;

  const tokens = q.split(/\s+/).filter((t) => t.length > 2);
  return tokens.some((t) => hay.includes(t));
}

export function aiSupportReply(text: string, listings: ListingRow[]): BotReply {
  const q = text.toLowerCase();
  const rent = !(q.includes("ซื้อ") || q.includes("sale"));
  const budget = extractBudget(q);

  let matched = listings.filter((l) => {
    if (rent && l.listing_type !== "rent") return false;
    if (!rent && l.listing_type !== "sale") return false;
    if (budget != null && l.price_net > budget * 1.15) return false;
    return textMatchesListing(q, l);
  });

  if (matched.length === 0 && budget != null) {
    matched = listings
      .filter((l) => (rent ? l.listing_type === "rent" : l.listing_type === "sale"))
      .filter((l) => l.price_net <= budget * 1.2)
      .sort((a, b) => a.price_net - b.price_net);
  }

  matched = matched.slice(0, 3);

  if (matched.length === 0) {
    return {
      role: "ai",
      text:
        "ยังไม่พบทรัพย์ที่ตรงบรีฟชัดเจนครับ " +
        "ลองระบุทำเล โครงการ หรืองบประมาณเพิ่มเติม\n" +
        "หรือกด「คุยกับเจ้าหน้าที่」เพื่อให้ทีมช่วยคัดให้",
    };
  }

  const links: ChatLink[] = matched.map((l) => ({
    label: `${l.listing_code} · ${priceLabel(l)}`,
    kind: "listing",
    listingId: l.id,
    projectName: l.project_name ?? undefined,
  }));

  const project = matched[0].project_name;
  if (project) {
    const inProject = listings.filter((l) => l.project_name === project).length;
    if (inProject > 1) {
      links.push({
        label: `ดูห้องอื่นใน ${project} (${inProject})`,
        kind: "projectUnits",
        listingId: matched[0].id,
        projectName: project,
      });
    }
  }

  const names = matched.map((l) => l.project_name ?? l.title).join(", ");
  return {
    role: "ai",
    text:
      `พบทรัพย์ที่ใกล้เคียงบรีฟของคุณ:\n${names}\n` +
      "กดลิงก์ด้านล่างเพื่อดูประกาศ หรือห้องอื่นในโครงการ",
    links,
  };
}

export function staffAckReply(): BotReply {
  return {
    role: "admin_notice",
    text: "รับข้อความแล้วครับ ทีมงานจะตอบกลับในแชทนี้โดยเร็วที่สุด",
  };
}

export function escalationReply(): BotReply {
  return {
    role: "system",
    text:
      "คำถามนี้ต้องให้เจ้าหน้าที่ตอบโดยตรง — เราแจ้งทีมแล้ว และจะติดต่อกลับในแชทนี้โดยเร็วที่สุด",
    requires_admin: true,
  };
}

/** First-pass clarify — no admin yet (lean). */
export function softClarifyReply(): BotReply {
  return {
    role: "ai",
    text:
      "ยังไม่แน่ใจคำถามครับ ลองระบุทำlez · งบ · หรือรายละเอียดที่ต้องการเพิ่ม\n" +
      "หรือพิมพ์「ขอคุยกับเจ้าหน้าที่」เมื่อต้องการให้ทีมช่วยโดยตรง",
  };
}

const STAFF_REQUEST_KEYS = [
  "ขอคุยกับเจ้าหน้าที่",
  "คุยกับเจ้าหน้าที่",
  "ติดต่อเจ้าหน้าที่",
  "ขอเจ้าหน้าที่",
  "talk to staff",
  "human agent",
];

const SMALL_TALK_KEYS = ["สวัสดี", "hello", "hi", "หวัดดี", "ขอบคุณ", "thanks"];

export function isExplicitStaffRequest(text: string): boolean {
  const q = normalize(text);
  return STAFF_REQUEST_KEYS.some((k) => q.includes(k));
}

export function isSmallTalk(text: string): boolean {
  const q = normalize(text);
  if (q.length > 40) return false;
  return SMALL_TALK_KEYS.some((k) => q.includes(k));
}

function normalize(text: string): string {
  return text.toLowerCase().trim();
}
