/**
 * โทน AI แชท RealXtate — แอดมิน/ทีมงาน (ค่ะ/คะ) · ห้าม ดิฉัน/ผม/ครับ
 * 「ครับ」สงวนให้ทีมแอดมินมนุษย์ (role admin_notice หลังรับงานจริง)
 */
export const GREETING_REPLY_TEXT =
  "สวัสดีค่ะ แอดมิน RealXtate ยินดีให้บริการค่ะ สอบถามรายละเอียดทรัพย์หรือทำเลที่สนใจได้เลยนะคะ";

/**
 * สต็อกจากแพทเทิร์นแชท LINE OA จริง (pantip-property-automation)
 * ปรับชื่อแบรนด์เป็น RealXtate — ใช้เป็นแนวทาง ห้ามบังคับ copy เป๊ะทุกครั้ง
 * ดู docs/CHAT-LINE-OA-PLAYBOOK-FROM-PANTIP.md
 */
export const LINE_OA_STOCK = {
  checkStatus:
    "แอดมินขออนุญาตตรวจสอบสถานะห้องให้ก่อนนะคะ เดี๋ยวอัปเดตให้ค่ะ",
  askTenantProfile:
    "เบื้องต้นรบกวนขอข้อมูลผู้เช่าสั้นๆ ไว้ประสานงานกับเจ้าของด้วยนะคะ " +
    "(ชื่อเล่น / สัญชาติ / เบอร์โทร / จำนวนผู้เข้าพัก / วันที่ย้ายเข้าโดยประมาณ)",
  negotiateAskOwner:
    "แอดมินขอลองสอบถามทางเจ้าของให้ก่อนนะคะ พองบที่สะดวกประมาณเท่าไรคะ จะได้ประสานให้ตรงขึ้นค่ะ",
  notVacantAskBrief:
    "ขอโทษด้วยนะคะ ห้องนี้ไม่ว่างแล้วค่ะ ถ้าสะดวกบอกงบ / โซน / จำนวนห้องนอนมาได้เลยค่ะ แอดมินช่วยดูห้องใกล้เคียงให้ได้ค่ะ",
  discoveryAskBrief:
    "รบกวนบอกสั้นๆ ได้ไหมคะ เช่าหรือซื้อ / งบ / โซนหรือใกล้ BTS-MRT / ห้องนอน เดี๋ยวแอดมินจัดตัวเลือกใกล้เคียงให้ค่ะ",
  depositDefaultHint:
    "โดยทั่วไปแรกเข้ามักชำระค่าเช่าล่วงหน้า 1 เดือน + ประกัน 2 เดือน (รวม ~3 เดือน) ค่ะ — ยืนยันตามประกาศ/เจ้าของอีกครั้งนะคะ",
  contractDefaultHint:
    "โดยทั่วไปรับสัญญา 1 ปีขึ้นไปค่ะ ถ้าระยะสั้น แอดมินขอสอบถามเจ้าของเป็นเคสๆ นะคะ",
} as const;

/** FAQ แอร์ / เครื่องใช้ไฟฟ้า / ทีวี — ชวนถามเพิ่มแล้วส่งเจ้าของ */
export const APPLIANCES_FAQ_REPLY =
  "เบื้องต้นที่มีข้อมูล จะมีเครื่องใช้ไฟฟ้าพื้นฐานตามรูปในประกาศเลยค่ะ\n\n" +
  "ถ้าอยากทราบว่ามีทีวีหรือไม่ กี่นิ้ว หรือยี่ห้ออะไร หรือหากมีคำถามอื่น ๆ เพิ่มเติม " +
  "สามารถพิมพ์สอบถามได้เลยนะคะ แอดมินจะรวบรวมไปสอบถามเจ้าของให้ทีเดียวเลยค่ะ";

const APPLIANCE_KEYS = [
  "ทีวี",
  "tv",
  "แอร์",
  "ตู้เย็น",
  "ไมโครเวฟ",
  "เครื่องใช้ไฟฟ้า",
  "appliance",
];

export function isAppliancesQuestion(text: string): boolean {
  const q = text.toLowerCase();
  return APPLIANCE_KEYS.some((k) => q.includes(k));
}

const GREETING_KEYS = ["สวัสดี", "hello", "hi", "หวัดดี", "hey"];

/** ทักทายล้วนๆ — ไม่ใช่「สวัสดีค่ะ ราคาเท่าไร」 */
export function isGreetingOnly(text: string): boolean {
  const raw = text.trim();
  if (raw.length > 40) return false;

  const q = raw.toLowerCase();
  if (!GREETING_KEYS.some((k) => q.includes(k))) return false;

  let rest = q
    .replace(/[!?.,…]/g, " ")
    .replace(/\s+/g, " ")
    .trim();

  for (const strip of [
    "สวัสดี",
    "hello",
    "hi",
    "หวัดดี",
    "hey",
    "ค่ะ",
    "คะ",
    "ครับ",
    "คับ",
    "จ้า",
    "น้า",
    "นะ",
    "ค้า",
  ]) {
    rest = rest.split(strip).join(" ").replace(/\s+/g, " ").trim();
  }

  return rest.length === 0;
}

export const AI_VOICE_RULE = `
VOICE (mandatory for all AI replies):
- You represent RealXtate customer chat — never ดิฉัน, never ผม
- Thai polite particles: ค่ะ, คะ, นะคะ, ไหมคะ only
- NEVER use ครับ, นะครับ, ไหมครับ, ครับผม, ดิฉัน
- First person: use "แอดมิน" or "ทีมงาน" by context (pick what sounds natural):
  · แอดมิน — direct help, answer, schedule viewing, follow up one-on-one
  · ทีมงาน — coordinating, handoff, escalation, checking with owner/internal
- You may omit subject when the sentence flows without it
- Warm, professional — like a real Thai property LINE OA admin (short, clear, ค่ะ)
- Prefer 1–3 short bubbles; one job per bubble (greet → check → result)
- Light emoji only if it helps; never spam
- End with one short clarifying question when info is incomplete (งบ / โซน / เช่า-ซื้อ / ห้องนอน)
`.trim();

/** บล็อกแนวทางจากประวัติ LINE OA — ใส่ใน system prompt */
export function lineOaPlaybookBlock(): string {
  const s = LINE_OA_STOCK;
  return `
LINE-OA PLAYBOOK (lessons from real Thai property OA — NOT copy Pantip names/ครับ):

CORE (what to learn):
- Do NOT answer recklessly when unsure — no inventing vacancy, price cuts, deposit, contract, phones
- When LISTING DATA / owner case is already confirmed (fresh owner confirmation, clear status in context) → you MAY confirm to the customer confidently
- When status is missing, stale, or ambiguous → hold first (e.g. "${s.checkStatus}"), set cta=owner_inquiry and/or needs_coach — do NOT guess

VACANCY / "ว่างไหม":
- Confirmed vacant in data → say vacant + soft invite viewing
- Confirmed not vacant → "${s.notVacantAskBrief}"
- Uncertain → check-status holding only — never invent

VIEWING INTEREST:
- Soft invite + ask time preference, then "${s.askTenantProfile}" / cta=viewing
- Still NEVER confirm a specific slot as booked (see VIEWING rules) until ops confirms

NEGOTIATE / budget too low:
- Uncertain discount → "${s.negotiateAskOwner}" — never invent a number
- If owner already confirmed a figure in context → you may relay that figure only

DEPOSIT / CONTRACT:
- Prefer LISTING DATA; soft default hint only if matching product policy and labeled as typical
- If unsure → needs_coach=true — do not invent months

DISCOVERY (no listing yet):
- "${s.discoveryAskBrief}"

CO-AGENT:
- Welcome collaboration; check status when needed — don't invent rights

HANDOFF (คุยคน / คุยแอดมิน / ขอแอดมิน / human):
- needs_coach=true; customer holding: ทีมงานจะติดต่อกลับโดยเร็ว — ask งบ/ทำเล while waiting

VOICE: RealXtate female admin only (ค่ะ/คะ) — never ครับ, never copy personal admin names from other brands
`.trim();
}

/** ปรับข้อความบอทอัตโนมัติ (FAQ เก่า / GPT) ให้เป็นโทนแอดมิน */
export function ensureFemaleAiTone(text: string): string {
  let s = text.trim();
  if (!s) return s;

  if (s.includes("ยินดีที่สนใจห้องนี้นะคะ")) {
    s = GREETING_REPLY_TEXT;
  }

  s = s
    .replace(/ไหมครับ/g, "ไหมคะ")
    .replace(/นะครับ/g, "นะคะ")
    .replace(/ครับผม/g, "ค่ะ")
    .replace(/ผมผู้ช่วย/g, "แอดมิน RealXtate")
    .replace(/ผมช่วย/g, "แอดมินช่วย")
    .replace(/ผมจะ/g, "แอดมินจะ")
    .replace(/ผมได้/g, "แอดมินได้")
    .replace(/ผม/g, "แอดมิน")
    .replace(/ดิฉันช่วย/g, "แอดมินช่วย")
    .replace(/ดิฉันจะ/g, "แอดมินจะ")
    .replace(/ดิฉันได้/g, "แอดมินได้")
    .replace(/ดิฉัน/g, "แอดมิน")
    .replace(/ครับ/g, "ค่ะ");

  return s;
}

/** Co-Agent — AI-first อธิบายเงื่อนไขก่อน ไม่ escalate ทันที */
export const CO_AGENT_REPLY =
  "RealXtate รองรับการทำงานร่วมกับ Co-Agent สำหรับทรัพย์ที่เจ้าของโพสต์เอง " +
  "หรือเจ้าของ opt-in รับ co-agent แล้วค่ะ\n\n" +
  "ถ้าสนใจร่วมงาน กรุณาส่งรหัสทรัพย์ (LB-…) หรือรายละเอียดทรัพย์ในแชทนี้ได้เลยค่ะ " +
  "แอดมินจะตรวจสอบสิทธิ์และติดต่อกลับค่ะ";

/** อินเทอร์เน็ต — บริการช่างเน็ตทั้งสองค่าย (มีจริงในแอป) */
export const INTERNET_FAQ_REPLY_BURST = [
  "ตามรายละเอียดค่าเช่าจะไม่ได้รวมอินเทอร์เน็ตค่ะ ทางเรามีบริการช่างอินเทอร์เน็ตให้นะคะ ทั้งสองค่าย",
  "ลูกค้าแค่ทำการเลือกแพ็กเกจ ไม่ต้องลำบากติดต่อพนักงานเองเลยค่ะ",
] as const;

const INTERNET_KEYS = [
  "อินเทอร์เน็ต",
  "เน็ต",
  "wifi",
  "wi-fi",
  "internet",
  "ติดเน็ต",
  "ติดตั้งเน็ต",
];

export function isInternetQuestion(text: string): boolean {
  const q = text.toLowerCase();
  return INTERNET_KEYS.some((k) => q.includes(k));
}

export const FIND_OTHER_ACK =
  "เข้าใจค่ะ ห้องนี้อาจยังไม่ตรงใจ — RealXtate ช่วยหาห้องที่ตรงบรีฟได้ค่ะ";

export const FIND_OTHER_FORK =
  "กรอกบรีฟในแชทแยก (ทีมคัดส่งให้) — แชทนี้ยังถามเรื่องทรัพย์นี้ต่อได้เลยค่ะ " +
  "หลังส่งฟอร์มแล้ว ทีมจะแจ้งแอดมินเมื่อพร้อมคัดห้องให้จริงๆ ค่ะ";

export function propertyWelcomeText(
  listingTitle: string,
  disclaimer: string,
  allowViewing: boolean,
): string {
  const head = `สวัสดีค่ะ แอดมินช่วยดูแลเรื่อง ${listingTitle} ให้นะคะ`;
  if (allowViewing) {
    return (
      `${head}\n\n` +
      "ถามรายละเอียดได้เลยค่ะ — ทำเล ราคา เงื่อนไข หรืออยากนัดดูก็บอกได้เลย\n" +
      "ถ้าห้องนี้ยังไม่ตรงใจ พิมพ์「ช่วยหาห้อง」ได้ค่ะ"
    );
  }
  return (
    `${head}\n\n` +
    "ถามเรื่องทำเล ราคา เงื่อนไข หรือให้แนะนำทรัพย์อื่นในระบบได้เลยค่ะ"
  );
}

export function discoveryWelcomeText(disclaimer: string): string {
  return (
    "สวัสดีค่ะ แอดมิน RealXtate ดูแลให้นะคะ\n" +
    `${disclaimer}\n\n` +
    "บอกทำเล · โครงการ · งบประมาณ — แอดมินช่วยคัดทรัพย์ในระบบให้ค่ะ\n" +
    "ตัวอย่าง: 「หาคอนโดเช่า ทองหล่อ งบ 18,000」\n" +
    "หรือเปิดแชทจากทรัพย์ที่สนใจเพื่อถามรายละเอียดเฉพาะห้อง"
  );
}
