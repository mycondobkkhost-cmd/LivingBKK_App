import {
  classifyOwnerInquiryIntent,
  ownerInquiryOfferText,
  type OwnerInquiryType,
} from "./owner_inquiry_intent.ts";
import { VOICE, priceNegotiationSalesBurst } from "./owner_inquiry_voice.ts";
import { normalizeChatText } from "./chat_text_normalize.ts";
import {
  discoveryWelcomeText,
  propertyWelcomeText,
} from "./chat_ai_voice.ts";

export type ChatRoomKind = "property" | "staff_support";

export type ChatLink = {
  label: string;
  kind:
    | "listing"
    | "projectUnits"
    | "project_request"
    | "owner_inquiry_form"
    | "owner_inquiry"
    | "requirement_form"
    | "viewing_form"
    | "viewing_location";
  listingId: string;
  projectName?: string;
  refCode?: string;
};

export type BotReply = {
  role: "ai" | "system" | "admin_notice" | "admin_coach";
  text: string;
  requires_admin?: boolean;
  links?: ChatLink[];
};

export const AI_DISCLAIMER =
  "AI เป็นตัวช่วยแนะนำโครงการและทรัพย์เบื้องต้นเท่านั้น " +
  "หากต้องการรายละเอียดที่ครบถ้วน กรุณาติดต่อเจ้าหน้าที่โดยตรง";

/** ประเภทคำถามละเอียดอ่อน — แต่ละแบบมีคำตอบมาตรฐานต่างกัน */
export type SensitiveKind =
  | "contact"
  | "owner"
  | "negotiate"
  | "unit_privacy"
  | "commission";

const CONTACT_KEYS = [
  "เบอร์",
  "เบอ",
  "โทร",
  "โทรศัพท์",
  "เบอร์โทร",
  "ติดต่อเจ้าของ",
  "เบอร์เจ้าของ",
  "line",
  "ไลน์",
  "ไอดีไลน์",
  "line id",
  "whatsapp",
  "phone",
  "call",
  "เบอร์ติดต่อ",
];

const OWNER_KEYS = [
  "เจ้าของ",
  "ผู้ขาย",
  "ผู้ให้เช่า",
  "ผู้ลงประกาศ",
  "คนขาย",
  "คนเช่า",
  "owner",
  "landlord",
];

const NEGOTIATE_DIRECT_KEYS = [
  "ต่อรอง",
  "ลดราคา",
  "ลดได้",
  "ลดค่า",
  "ส่วนลด",
  "discount",
  "ขอลด",
  "ต่อราคา",
  "ต่อค่าเช่า",
  "ต่อค่า",
  "เจรจา",
];

const UNIT_PRIVACY_KEYS = [
  "เลขห้อง",
  "ห้องเลข",
  "unit",
  "ชั้น",
  "ชั้นที่",
  "floor",
  "ทิศ",
  "ทิศห้อง",
  "หันทาง",
];

function matchesAny(q: string, keys: string[]): boolean {
  return keys.some((k) => q.includes(k));
}

function isNegotiateIntent(q: string): boolean {
  if (matchesAny(q, NEGOTIATE_DIRECT_KEYS)) return true;
  if (!q.includes("สัญญา") && !q.includes("ระยะสัญญา")) return false;
  return q.includes("ต่อรอง") || q.includes("ลด") || q.includes("ต่อราคา") ||
    q.includes("ต่อค่า") || (q.includes("ปี") && q.includes("ได้ไหม"));
}

/** จำแนกคำถามละเอียดอ่อน (null = ไม่ใช่) — ลำดับสำคัญ: ต่อรอง > ติดต่อ > เจ้าของ > ห้อง/ชั้น */
export function classifySensitive(text: string): SensitiveKind | null {
  const q = text.toLowerCase().trim();

  if (isNegotiateIntent(q)) return "negotiate";

  if (matchesAny(q, CONTACT_KEYS)) return "contact";
  if (matchesAny(q, OWNER_KEYS)) return "owner";
  if (matchesAny(q, UNIT_PRIVACY_KEYS)) return "unit_privacy";

  return null;
}

export function isSensitive(text: string): boolean {
  return classifySensitive(text) != null;
}

/** ขอเบอร์เจ้าของ / ช่องทางติดต่อ — ให้ลูกค้าทิ้งเบอร์ตัวเอง */
export function contactRequestReply(): BotReply {
  return {
    role: "ai",
    text:
      "เข้าใจค่ะว่าต้องการติดต่อโดยตรง — ทางแพลตฟอร์มไม่เปิดเผยเบอร์โทร " +
      "Line หรือช่องทางส่วนตัวของเจ้าของ/ผู้ลงประกาศ เพื่อความเป็นส่วนตัวและความปลอดภัยของทุกฝ่ายค่ะ\n\n" +
      "หากสะดวก รบกวนแจ้งเบอร์ติดต่อของคุณ พร้อมคำถามหรือรายละเอียดที่อยากทราบในแชทนี้ " +
      "เจ้าหน้าที่ RealXtate จะติดต่อกลับโดยเร็วที่สุดในช่วงเวลาทำการค่ะ\n\n" +
      "หากมีคำถามอื่นที่ตอบได้จากข้อมูลประกาศ (เช่น ทำเล ราคา Net เงื่อนไขเบื้องต้น) ถามต่อได้เลยค่ะ",
  };
}

/** ถามข้อมูลเจ้าของ — PDPA */
export function ownerPdpaReply(): BotReply {
  return {
    role: "ai",
    text:
      "ขอบคุณที่สนใจทรัพย์ค่ะ\n\n" +
      "เพื่อเป็นไปตามนโยบายคุ้มครองข้อมูลส่วนบุคคล (PDPA) และความเป็นส่วนตัวของเจ้าของทรัพย์ " +
      "แพลตฟอร์มไม่สามารถเปิดเผยข้อมูลติดต่อ ชื่อ หรือข้อมูลส่วนตัวของเจ้าของ/ผู้ลงประกาศได้ค่ะ\n\n" +
      "หากมีคำถามอื่นเกี่ยวกับทรัพย์นี้ — เช่น ทำเล ราคา Net เงื่อนไขเบื้องต้น หรือการนัดดูห้อง — " +
      "แจ้งได้เลยค่ะ ยินดีช่วยตอบในสิ่งที่เปิดเผยได้ตามประกาศค่ะ",
  };
}

/** ชวนกรอกฟอร์มสอบถามเจ้าของ — ไม่ส่งแอดมินทันที */
export function ownerInquiryOfferReply(
  type: OwnerInquiryType,
  prefill?: string,
  listingId = "",
): BotReply {
  return {
    role: "ai",
    text: ownerInquiryOfferText(type),
    links: [{
      label: VOICE.formLabel,
      kind: "owner_inquiry_form",
      listingId,
      projectName: prefill?.trim() || undefined,
      refCode: type,
    }],
  };
}

/** ต่อรองราคา — ชวนกรอกฟอร์มสอบถามเจ้าของ (แทน escalate ทันที) */
export function negotiateInquiryReply(text: string, listingId = ""): BotReply {
  return ownerInquiryOfferReply("price_negotiation", text, listingId);
}

/** เลขห้อง — แจ้งเมื่อนัดดูเท่านั้น */
export function unitPrivacyReply(): BotReply {
  return {
    role: "ai",
    text: VOICE.unitNumberViewing,
  };
}

/** ค่าคอม / ส่วนแบ่ง — ส่งต่อเจ้าหน้าที่ */
export function commissionAdminReply(): BotReply {
  return {
    role: "ai",
    text:
      "เรื่องค่าคอมมิชชันและโครงสร้างส่วนแบ่งเป็นรายละเอียดที่เจ้าหน้าที่จะอธิบายให้ชัดเจนเมื่อดำเนินการต่อค่ะ — " +
      "ทีมงานได้รับแจ้งแล้ว และจะกลับมาตอบในแชทนี้โดยเร็วที่สุดค่ะ",
    requires_admin: true,
  };
}

/** ลูกค้าแจ้งเบอร์มาแล้ว — ยืนยันและส่งทีม */
export function phoneReceivedAckReply(): BotReply {
  return {
    role: "ai",
    text:
      "ขอบคุณมากค่ะ ทางเราได้รับเบอร์ติดต่อและข้อมูลของท่านเรียบร้อยแล้ว " +
      "ทีมงานจะรีบนำข้อมูลไปตรวจสอบและติดต่อกลับเพื่อให้บริการโดยเร็วที่สุดค่ะ",
    requires_admin: true,
  };
}

export function sensitiveReply(kind: SensitiveKind, text?: string): BotReply {
  switch (kind) {
    case "contact":
      if (text && containsThaiPhone(text)) return phoneReceivedAckReply();
      return contactRequestReply();
    case "owner":
      return ownerPdpaReply();
    case "negotiate":
      return {
        role: "ai",
        text: priceNegotiationSalesBurst()[0],
      };
    case "unit_privacy":
      return unitPrivacyReply();
    case "commission":
      return commissionAdminReply();
  }
}

/** ลูกค้าทิ้งเบอร์ติดต่อมาในแชท — แจ้งทีมโทรกลับ */
const TH_PHONE_PATTERN =
  /(?:^|[^\d])(0[689]\d{8}|0[2-9]\d{7,8})(?:[^\d]|$)/;

export function containsThaiPhone(text: string): boolean {
  return TH_PHONE_PATTERN.test(text.replace(/[\s\-().]/g, ""));
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
      text: discoveryWelcomeText(AI_DISCLAIMER),
    };
  }
  if (allowViewingRequest) {
    return {
      role: "ai",
      text: propertyWelcomeText(listingTitle, AI_DISCLAIMER, true),
    };
  }
  return {
    role: "ai",
    text: propertyWelcomeText(listingTitle, AI_DISCLAIMER, false),
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

const FIND_OTHER_ROOM_KEYS = [
  "หาห้องให้",
  "ช่วยหา",
  "ฝากหา",
  "หาห้อง",
  "หาคอนโดให้",
  "หาบ้านให้",
  "ช่วยสแกน",
  "ช่วยคัด",
  "find me a room",
  "help me find",
  "help find",
  "ไม่ตรงใจ",
  "ไม่ชอบ",
  "ไม่โดน",
  "ไม่ถูกใจ",
  "อยากได้อื่น",
  "อยากได้ห้องอื่น",
  "หาที่พัก",
  "หาที่อยู่",
  "หาห้องอื่น",
  "ขอห้องอื่น",
  "รีบหาที่อยู่",
  "ต้องการห้องด่วน",
];

const PROJECT_OTHER_KEYS = [
  "ห้องอื่น",
  "ตัวอื่น",
  "ในโครงการ",
  "unit อื่น",
  "ห้องอื่นอีก",
  "มีห้องอื่น",
];

const ZONE_HINTS = [
  "ทองหล่อ",
  "เอกมัย",
  "อโศก",
  "สุขุมวิท",
  "สาทร",
  "สีลม",
  "พระโขนง",
  "อารีย์",
  "ลาดพร้าว",
  "thong",
  "ekkamai",
  "asok",
  "sukhumvit",
  "sathorn",
  "silom",
  "bts",
  "mrt",
];

const GENERIC_PROJECT_HINT_REJECT = [
  "ให้ได้ไหม",
  "ได้ไหม",
  "หน่อย",
  "ช่วยหา",
  "หาห้อง",
  "หาคอนโด",
  "ไหมคะ",
  "ไหมครับ",
  "ค่ะ",
  "ครับ",
];

/** ลูกค้าขอให้ช่วยหาห้องอื่น (ไม่ใช่ห้องอื่นในโครงการเดียวกัน) */
export function wantsOtherUnitsInProject(text: string): boolean {
  const q = normalizeChatText(text);
  return PROJECT_OTHER_KEYS.some((k) => q.includes(k));
}

export function isFindOtherRoomIntent(text: string): boolean {
  const q = normalizeChatText(text);
  if (wantsOtherUnitsInProject(text)) return false;
  return FIND_OTHER_ROOM_KEYS.some((k) => q.includes(normalizeChatText(k)));
}

export function hasSearchSignals(text: string): boolean {
  const q = normalizeChatText(text);
  if (ZONE_HINTS.some((z) => q.includes(z))) return true;
  if (/\d[\d,]*\s*(?:บาท|k)/i.test(q)) return true;
  if (/\b(ideo|noble|rhythm|the\s|mobi|place)\b/i.test(q)) return true;
  return false;
}

/** ในแชททรัพย์ — ค้นหาทรัพย์อื่นเฉพาะเมื่อมีสัญญาณทำเล/งบ ไม่ใช่แค่คำว่า「หา」 */
export function isDiscoveryIntentOnProperty(text: string): boolean {
  if (isFindOtherRoomIntent(text)) return false;
  if (wantsOtherUnitsInProject(text)) return true;
  const q = normalizeChatText(text);
  const broad = [
    "หา", "แนะนำ", "ค้นห", "อยากได้", "อยากเช่า", "อยากซื้อ", "โครงการ",
    "คอนโด", "บ้าน", "เช่า", "ซื้อ", "compare", "เปรียบ",
  ];
  if (!broad.some((k) => q.includes(k)) && !/\d[\d,]*\s*(?:บาท|k)?/i.test(q)) {
    return false;
  }
  return hasSearchSignals(text);
}

/** ชื่อโครงการที่น่าจะระบุในข้อความค้นหา */
function extractProjectHint(text: string): string | null {
  if (isFindOtherRoomIntent(text)) return null;

  const t = text.trim();
  if (t.length < 4) return null;
  const condo = t.match(
    /(?:หา|ค้นหา|สนใจ|อยากได้|อยากเช่า|อยากซื้อ)?\s*(?:คอนโด|condo)?\s*([^\n,?！!]{4,60})/i,
  );
  if (condo?.[1]) {
    const name = condo[1].trim();
    if (name.length >= 4 && !/^(คอนโด|condo|บ้าน|ทาวน์)/i.test(name)) {
      const norm = normalizeChatText(name);
      if (!GENERIC_PROJECT_HINT_REJECT.some((r) => norm.includes(r))) {
        return name;
      }
    }
  }
  if (/\b(ideo|noble|rhythm|the\s|mobi|place)\b/i.test(t) && t.split(/\s+/).length >= 2) {
    return t.slice(0, 80);
  }
  return null;
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
    const projectHint = extractProjectHint(text);
    if (projectHint) {
      return {
        role: "ai",
        text:
          `ยังไม่พบโครงการ「${projectHint}」ในระบบของเราค่ะ\n` +
          "กดปุ่มด้านล่างเพื่อแจ้งให้ทีมงานเพิ่มโครงการนี้ — เราจะแจ้งเมื่อบันทึกคำขอแล้วค่ะ",
        links: [{
          label: `ขอให้ทีมเพิ่ม ${projectHint}`,
          kind: "project_request",
          listingId: "",
          projectName: projectHint,
        }],
      };
    }
    return {
      role: "ai",
      text:
        "ยังไม่พบทรัพย์ที่ตรงบรีฟชัดเจนค่ะ " +
        "ลองระบุทำเล โครงการ หรืองบประมาณเพิ่มเติม\n" +
        "หรือกด「คุยกับเจ้าหน้าที่」เพื่อให้ทีมช่วยคัดให้ค่ะ",
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
      "คำถามนี้ต้องให้เจ้าหน้าที่ตอบโดยตรงค่ะ — ทีมงานได้รับแจ้งแล้ว และจะติดต่อกลับในแชทนี้โดยเร็วที่สุดค่ะ",
    requires_admin: true,
  };
}

/** First-pass clarify — no admin yet (lean). */
export function softClarifyReply(): BotReply {
  return {
    role: "ai",
    text:
      "ยังไม่แน่ใจคำถามค่ะ ลองระบุทำเล · งบ · หรือรายละเอียดที่ต้องการเพิ่ม\n" +
      "หากต้องการให้ช่วยหาห้องอื่น พิมพ์「ช่วยหาห้อง」\n" +
      "หรือพิมพ์「ขอคุยกับเจ้าหน้าที่」เมื่อต้องการให้ทีมช่วยโดยตรงค่ะ",
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
