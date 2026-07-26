import { fuzzyIncludes, normalizeChatText } from "./chat_text_normalize.ts";

const VIEWING_KEYS = [
  "นัดดู",
  "นัดชม",
  "ขอดู",
  "ดูห้อง",
  "เข้าชม",
  "สนใจนัดดู",
  "สนใจดู",
  "อยากนัดดู",
  "อยากดู",
  "จองนัด",
  "จองนัดดู",
  "ขอชม",
  "สนใจชม",
  "นัดเข้า",
  "ขอนัด",
  "จะนัด",
  "viewing",
  "view room",
  "book viewing",
  "see the room",
];

export const TODAY_KEYS = ["วันนี้", "today", "เย็นนี้", "เช้านี้", "บ่ายนี้", "tonight"];
export const TOMORROW_KEYS = ["พรุ่งนี้", "tomorrow"];
export const WEEKEND_KEYS = ["เสาร์", "อาทิตย์", "weekend"];

/** แปลงข้อความลูกค้า (เช่น 16:00 วันนี้) เป็นป้ายกำหนดการนัดดู */
export function parseProposedViewingSchedule(text: string): string | null {
  const raw = text.toLowerCase()
    .replaceAll(/น\./g, "น")
    .replaceAll(/\s+/g, " ");

  let timePart = "";
  const clock = raw.match(/(\d{1,2})\s*[:.]\s*(\d{2})/);
  if (clock) {
    const h = clock[1].padStart(2, "0");
    timePart = `${h}:${clock[2]} น.`;
  } else {
    const hourWord = raw.match(/(\d{1,2})\s*โมง/);
    if (hourWord) {
      timePart = `${hourWord[1].padStart(2, "0")}:00 น.`;
    } else if (/(เย็น|ค่ำ|กลางคืน|evening|tonight)/.test(raw)) {
      timePart = "18:00 น.";
    }
  }
  if (!timePart) return null;

  let dayPart = "";
  if (TODAY_KEYS.some((k) => raw.includes(k))) dayPart = "วันนี้";
  else if (TOMORROW_KEYS.some((k) => raw.includes(k))) dayPart = "พรุ่งนี้";
  else if (WEEKEND_KEYS.some((k) => raw.includes(k))) dayPart = "เสาร์-อาทิตย์";
  else {
    const thaiDate = raw.match(/(\d{1,2})[/.](\d{1,2})(?:[/.](\d{2,4}))?/);
    if (thaiDate) {
      const y = thaiDate[3];
      dayPart = y
        ? `${thaiDate[1]}/${thaiDate[2]}/${y.length === 2 ? `25${y}` : y}`
        : `${thaiDate[1]}/${thaiDate[2]}`;
    }
  }

  if (dayPart) return `${dayPart} · ${timePart}`;
  return timePart;
}

export function isViewingRequestIntent(text: string): boolean {
  const q = normalizeChatText(text);
  return VIEWING_KEYS.some((k) => q.includes(normalizeChatText(k)) || fuzzyIncludes(text, k));
}

/** ลูกค้าระบุเวลานัดชัด (เช่น 18:00) — ห้าม AI ยืนยันนัดทันที */
export function hasSpecificViewingSlot(text: string): boolean {
  const raw = text.toLowerCase().replaceAll(/น\./g, "น").replaceAll(/\s+/g, " ");
  if (/\d{1,2}\s*[:.]\s*\d{2}/.test(raw)) return true;
  if (/\d{1,2}\s*โมง/.test(raw)) return true;
  if (/(^|\s)(1[89]|2[0-3])\s*(โมง|น|pm)/.test(raw)) return true;
  if (/(เย็น|ค่ำ|กลางคืน|evening|tonight)/.test(raw) &&
    (isViewingRequestIntent(text) || /นัด|ดูห้อง|viewing/.test(raw))) {
    return true;
  }
  return false;
}

export function viewingRequestBurst(text: string): string[] {
  const q = normalizeChatText(text);
  const raw = text.toLowerCase().replaceAll(/มั้ย/g, "ไหม").replaceAll(/นัดดุ/g, "นัดดู");
  const todayHit = (keys: string[]) =>
    keys.some((k) => q.includes(k) || raw.includes(k));
  if (todayHit(TODAY_KEYS)) {
    return [
      "ได้เลยค่ะ วันนี้ลูกค้าสะดวกประมาณกี่โมงคะ",
      "แอดมินจะสอบถามเจ้าของให้โดยประมาณนะคะ",
    ];
  }
  if (TOMORROW_KEYS.some((k) => q.includes(k) || raw.includes(k))) {
    return [
      "ได้เลยค่ะ พรุ่งนี้สะดวกช่วงเช้าหรือบ่ายดีคะ",
      "แอดมินจะเช็กคิวและประสานงานให้ค่ะ",
    ];
  }
  if (WEEKEND_KEYS.some((k) => q.includes(k) || raw.includes(k))) {
    return [
      "ได้เลยค่ะ เสาร์-อาทิตย์สะดวกช่วงไหนดีคะ",
      "แอดมินจะล็อกคิวและประสานงานให้ค่ะ",
    ];
  }
  return [
    "ได้เลยค่ะ สะดวกเป็นช่วงวันไหนดีคะ",
    "แอดมินจะรีบเช็กคิวและประสานงานให้ค่ะ",
  ];
}
