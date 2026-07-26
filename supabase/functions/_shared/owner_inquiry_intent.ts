/** ประเภทคำขอสอบถามเจ้าของ — ขยายได้โดยเพิ่ม type + pattern */
export type OwnerInquiryType =
  | "price_negotiation"
  | "availability"
  | "custom_terms"
  | "general";

export type OwnerInquiryIntent = {
  type: OwnerInquiryType;
  prefill: string;
};

const NEGOTIATE_KEYS = [
  "ต่อรอง", "ลดราคา", "ลดได้", "ลดเหลือ", "ต่อราคา", "ต่อค่า",
  "negotiate", "discount", "lower price",
];

const AVAILABILITY_KEYS = [
  "ห้องว่าง", "ว่างไหม", "ว่างเมื่อไหร่", "ว่างวันไหน", "พร้อมอยู่",
  "เข้าอยู่ได้", "ย้ายเข้า", "available", "move in", "vacant",
];

const CUSTOM_TERMS_KEYS = [
  "จอดรถลด", "ไม่ใช้จอด", "สัตว์พิเศษ", "เงื่อนไขพิเศษ", "ขอปรับ",
  "parking discount", "special term",
];

const READY_KEYS = [
  "ส่งเลย", "พอแล้ว", "ส่งคำถาม", "ส่งให้เจ้าของ", "ถามเจ้าของเลย",
  "ได้แล้ว", "พร้อมแล้ว", "ไม่มีแล้ว", "ส่งได้", "ส่งต่อ",
];

function matchesAny(q: string, keys: string[]): boolean {
  return keys.some((k) => q.includes(k.toLowerCase()) || q.includes(k));
}

export function isNegotiateIntent(q: string): boolean {
  if (matchesAny(q, NEGOTIATE_KEYS)) return true;
  if (!q.includes("สัญญา") && !q.includes("ระยะสัญญา")) return false;
  return q.includes("ต่อรอง") || q.includes("ลด") || q.includes("ต่อราคา") ||
    q.includes("ต่อค่า") || (q.includes("ปี") && q.includes("ได้ไหม"));
}

/** มีตัวเลขราคา/ข้อเสนอชัด — ควรส่งเจ้าของ */
export function hasSpecificNegotiateOffer(text: string): boolean {
  const q = text.trim().toLowerCase();
  if (!isNegotiateIntent(q)) return false;
  if (/\d[\d,]{3,}/.test(q)) return true;
  if (q.includes("ลดเหลือ") || q.includes("ลดให้") || q.includes("ขอลด")) {
    return true;
  }
  return false;
}

/** ลูกค้าบอกว่าพร้อมส่งคำถามให้เจ้าของแล้ว */
export function isOwnerInquiryReadyToSend(text: string): boolean {
  const q = text.trim().toLowerCase();
  if (q.length < 2) return false;
  return READY_KEYS.some((k) => q.includes(k));
}

/** รวมข้อความลูกค้าหลายรอบเป็นฉบับร่างเดียว */
export function appendOwnerInquiryDraft(draft: string, line: string): string {
  const t = line.trim();
  if (!t || isOwnerInquiryReadyToSend(t)) return draft;
  const bullet = `• ${t}`;
  if (!draft) return bullet;
  if (draft.includes(t)) return draft;
  return `${draft}\n${bullet}`;
}

/** จำแนกว่าควรเริ่มรวบรวมคำถามถามเจ้าของหรือไม่ (ไม่รวมเลขห้อง/ชั้น/ทิศ) */
export function classifyOwnerInquiryIntent(text: string): OwnerInquiryIntent | null {
  const q = text.trim().toLowerCase();
  if (q.length < 3) return null;

  if (isNegotiateIntent(q)) {
    if (hasSpecificNegotiateOffer(text)) {
      return { type: "price_negotiation", prefill: text.trim() };
    }
    return null;
  }
  if (matchesAny(q, AVAILABILITY_KEYS)) {
    return { type: "availability", prefill: text.trim() };
  }
  if (matchesAny(q, CUSTOM_TERMS_KEYS)) {
    return { type: "custom_terms", prefill: text.trim() };
  }

  return null;
}

export function inferOwnerInquiryTypeFromDraft(draft: string): OwnerInquiryType {
  return classifyOwnerInquiryIntent(draft)?.type ?? "general";
}

/** ข้อความชวนกรอกฟอร์ม — ใช้เมื่อยืนยันส่ง (โทนจาก owner_inquiry_voice) */
export function ownerInquiryOfferText(type: OwnerInquiryType): string {
  switch (type) {
    case "price_negotiation":
      return (
        "เรื่องราคาและเงื่อนไขสัญญา เจ้าของยังไม่ได้ลงรายละเอียดเพิ่มเติมไว้ในประกาศค่ะ\n\n" +
        "แอดมินช่วยส่งโปรไฟล์และคำถามไปถามเจ้าของให้ได้ — รบกวนกรอกโปรไฟล์สั้นๆ ด้านล่าง " +
        "พอได้คำตอบแล้วจะกลับมาแจ้งในแชทนี้ค่ะ"
      );
    case "availability":
      return (
        "สถานะห้องว่างมีการอัปเดตตลอดเวลาค่ะ — เจ้าของจะทราบชัดที่สุด\n\n" +
        "แอดมินช่วยสอบถามให้ได้เลย กรอกข้อมูลด้านล่างแล้วรอแจ้งกลับในแชทนี้ค่ะ"
      );
    case "custom_terms":
      return (
        "เงื่อนไขพิเศษแบบนี้ต้องให้เจ้าของพิจารณาเป็นครั้งๆ ค่ะ\n\n" +
        "กรอกรายละเอียดด้านล่าง แอดมินจะส่งให้เจ้าของและแจ้งกลับเมื่อได้คำตอบค่ะ"
      );
    default:
      return (
        "คำถามนี้ต้องให้เจ้าของยืนยันโดยตรงค่ะ\n\n" +
        "กรอกฟอร์มด้านล่าง แอดมินจะช่วยสอบถามและนำคำตอบกลับมาในแชทนี้ค่ะ"
      );
  }
}
