/**
 * Thai/English chat text normalization + fuzzy pattern matching for FAQ routing.
 */

/** Common Thai property-chat typos → canonical substring for matching. */
const THAI_TYPO_CANONICAL: Record<string, string> = {
  "common fee": "ค่าส่วนกลาง",
  "cam fee": "ค่าส่วนกลาง",
  "net price": "ราคา net",
  "livingbkk": "realxtate",
  "proppiter": "realxtate",
  "what is proppiter": "realxtate คือ",
  "what is realxtate": "realxtate คือ",
  "co agent": "co-agent",
  "line id": "line",
  "minimum contract": "สัญญา",
  "renew contract": "ต่อสัญญา",
  "cancel contract": "ยกเลิกสัญญา",
  "break contract": "ยกเลิกสัญญา",
  "deposit refund": "คืนเงินประกัน",
  "tenant requirements": "เงื่อนไขการเช่า",
  "documents needed": "เอกสาร",
  "privacy policy": "pdpa",
  "fully furnished": "เฟอร์นิเจอร์",
  "washing machine": "เครื่องซักผ้า",
  "smoking allowed": "สูบบุหรี่",
  "pet friendly": "สัตว์เลี้ยง",
  "foreigner rent": "ต่างชาติเช่า",
  "foreigner friendly": "ต่างชาติเช่า",
  "water electric": "ค่าน้ำค่าไฟ",
  "security camera": "cctv",
  "visitors allowed": "ผู้เยี่ยมชม",
  "visitor": "ผู้เยี่ยมชม",
  "guest parking": "ที่จอดรถ",
  "available when": "ห้องว่าง",
  "available?": "ห้องว่าง",
  "room size": "ตารางเมตร",
  "year built": "สร้างปี",
  "renovated": "รีโนเวท",
  "cooking": "ทำอาหาร",
  "internet": "อินเทอร์เน็ต",
  "wifi": "เน็ต",
  "balcony": "ระเบียง",
  "pool gym": "สระว่ายน้ำ",
  "facilities": "ส่วนกลาง",
  "cleaning service": "ทำความสะอาด",
  "city view": "วิว",
  "security": "ความปลอดภัย",
  "digital door lock": "ล็อคประตู",
  "view room": "นัดดูห้อง",
  "book viewing": "นัดดูห้อง",
  "find other zone": "หาโซน",
  "recommend project": "แนะนำคอนโด",
  "near workplace": "ใกล้ที่ทำงาน",
  "promotion": "โปรโมชั่น",
  "hot deal": "โปรโมชั่น",
  "compare": "เปรียบเทียบ",
  "shuttle bus": "รถรับส่ง",
  "find me a room": "ช่วยหาห้อง",
  "cancelled unit": "ห้องหลุดจอง",
  "เท่าไหร่": "เท่าไร",
  "เท่าไร่": "เท่าไร",
  "ทะไหร่": "เท่าไร",
  "กี่บาท": "เท่าไร",
  "price": "ราคา",
  "rent": "เช่า",
  "cam": "ค่าส่วนกลาง",
  "pet": "สัตว์เลี้ยง",
  "pets": "สัตว์เลี้ยง",
  "parking": "จอดรถ",
  "ที่จอด": "จอดรถ",
  "เน็ต": "net",
  "เนต": "เน็ต",
  "ดูห้อง": "นัดดู",
  "เข้าชม": "นัดดู",
  "bts": "bts",
  "mrt": "mrt",
  "บีทีเอส": "bts",
  "เอ็มอาที": "mrt",
  "townhouse": "ทาวน์",
  "condo": "คอนโด",
  "สัตว": "สัตว์",
  "สัต": "สัตว์",
  "แอร": "แอร์",
  "เฟอ": "เฟอร์นิเจอร์",
  "เฟอนิเจอ": "เฟอร์นิเจอร์",
  "ป่าว": "เปล่า",
  "ปะ": "ไหม",
  "มั้ย": "ไหม",
  "จิง": "จริง",
  "จิงๆ": "จริง",
  "คับ": "ครับ",
  "คัฟ": "ครับ",
  "ประมาน": "ประมาณ",
  "ส่วนกาง": "ส่วนกลาง",
  "มัดจำำ": "มัดจำ",
  "ต่อลอง": "ต่อรอง",
  "ลดน่อย": "ลดหน่อย",
  "อินเตอเนต": "อินเทอร์เน็ต",
  "ฟิตเนสส": "ฟิตเนส",
  "สระน้ำ": "สระว่ายน้ำ",
  "รปพ": "รปภ",
  "วิวว": "วิว",
  "บัดเจท": "งบประมาณ",
  "proppiter คึอ": "realxtate คือ",
  "realxtate คึอ": "realxtate คือ",
  "proppiter คือ": "realxtate คือ",
  "เลี้ยงสัตว": "สัตว์เลี้ยง",
  "สัตวเลี้ยง": "สัตว์เลี้ยง",
  "ทอสับ": "โทรศัพท์",
  "แอดมินน": "แอดมิน",
  "พนักงานน": "พนักงาน",
  "กุญแจ": "คีย์การ์ด",
  "เด่ว": "เดี๋ยว",
  "ตัง": "เงิน",
  "ก้": "ก็",
  "แมวว": "แมว",
  "พาสปอต": "พาสปอร์ต",
};

const THAI_TONE_MARKS = /[\u0E31\u0E34-\u0E3A\u0E47-\u0E4E]/g;
const EXTRA_SPACES = /\s+/g;

/** Strip combining Thai vowel/tone marks for looser matching. */
export function stripThaiTones(text: string): string {
  return text.replace(THAI_TONE_MARKS, "");
}

/** Lowercase, trim, collapse spaces, strip tones, apply typo canonicalization. */
export function normalizeChatText(text: string): string {
  let s = text.toLowerCase().trim().replace(EXTRA_SPACES, " ");
  s = stripThaiTones(s);

  const sorted = Object.keys(THAI_TYPO_CANONICAL).sort(
    (a, b) => b.length - a.length,
  );
  for (const typo of sorted) {
    const canon = THAI_TYPO_CANONICAL[typo];
    const re = new RegExp(escapeRegExp(stripThaiTones(typo.toLowerCase())), "g");
    s = s.replace(re, stripThaiTones(canon.toLowerCase()));
  }

  return s;
}

function escapeRegExp(s: string): string {
  return s.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}

/** Levenshtein edit distance (for fuzzy substring checks). */
export function levenshtein(a: string, b: string): number {
  if (a === b) return 0;
  if (a.length === 0) return b.length;
  if (b.length === 0) return a.length;

  const row = new Array<number>(b.length + 1);
  for (let j = 0; j <= b.length; j++) row[j] = j;

  for (let i = 1; i <= a.length; i++) {
    let prev = row[0];
    row[0] = i;
    for (let j = 1; j <= b.length; j++) {
      const tmp = row[j];
      const cost = a[i - 1] === b[j - 1] ? 0 : 1;
      row[j] = Math.min(row[j] + 1, row[j - 1] + 1, prev + cost);
      prev = tmp;
    }
  }
  return row[b.length];
}

/** Max allowed edit distance by pattern length. */
export function fuzzyThreshold(patternLen: number): number {
  if (patternLen <= 3) return 0;
  if (patternLen <= 5) return 1;
  if (patternLen <= 8) return 2;
  return Math.min(3, Math.floor(patternLen * 0.25));
}

/**
 * True if [pattern] appears in [text] exactly (after normalize) or via fuzzy window.
 */
export function fuzzyIncludes(text: string, pattern: string): boolean {
  const hay = normalizeChatText(text);
  const needle = normalizeChatText(pattern);
  if (!needle) return false;
  if (hay.includes(needle)) return true;

  if (needle.length < 3) return false;

  const maxDist = fuzzyThreshold(needle.length);
  if (maxDist === 0) return false;

  // Sliding window: compare substrings near pattern length
  const win = needle.length;
  for (let start = 0; start <= hay.length - Math.min(3, win); start++) {
    for (let size = Math.max(3, win - maxDist); size <= win + maxDist; size++) {
      if (start + size > hay.length) continue;
      const slice = hay.slice(start, start + size);
      if (levenshtein(slice, needle) <= maxDist) return true;
    }
  }
  return false;
}

/** Best fuzzy match score (lower = better); null if no match. */
export function fuzzyMatchScore(text: string, pattern: string): number | null {
  const hay = normalizeChatText(text);
  const needle = normalizeChatText(pattern);
  if (!needle) return null;
  if (hay.includes(needle)) return 0;

  if (needle.length < 3) return null;
  const maxDist = fuzzyThreshold(needle.length);
  if (maxDist === 0) return null;

  let best: number | null = null;
  const win = needle.length;
  for (let start = 0; start <= hay.length - Math.min(3, win); start++) {
    for (let size = Math.max(3, win - maxDist); size <= win + maxDist; size++) {
      if (start + size > hay.length) continue;
      const dist = levenshtein(hay.slice(start, start + size), needle);
      if (dist <= maxDist && (best === null || dist < best)) best = dist;
    }
  }
  return best;
}
