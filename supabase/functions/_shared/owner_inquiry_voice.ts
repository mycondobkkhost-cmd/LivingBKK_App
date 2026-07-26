/** โทนคุยแอดมิน — ส่งทีละฟอง ไม่รวมก้อน */
import type { ListingDetail } from "./chat_answer_openai.ts";
import type { OwnerInquiryType } from "./owner_inquiry_intent.ts";

export const VOICE = {
  formLabel: "กรอกโปรไฟล์ส่งเจ้าของ",
  formLabelReady: "กรอกโปรไฟล์ส่งเจ้าของ",
  askMoreQuestions:
    "ลูกค้ามีคำถามอื่นเพิ่มเติมด้วยไหมคะ แอดมินจะรวบรวมไปสอบถามเจ้าของให้ทีเดียวเลยค่ะ",
  profileAsk:
    "รบกวนกรอกข้อมูลลูกค้าให้แอดมินหน่อยนะคะ",
  profileFollowUp:
    "แอดมินจะดำเนินการสอบถามเจ้าของห้องให้โดยเร็วที่สุดค่ะ",
  priceNoData:
    "ในระบบข้อมูลที่ลงไว้ เป็นราคาสุทธิแล้วค่ะ",
  priceNegotiateFollow:
    "แต่ถ้าหากลูกค้าดูแล้วพร้อมจอง ทางแอดมินจะช่วยคุยกับเจ้าของให้อย่างสุดความสามารถเลยค่ะ",
  facingNoData:
    "ข้อมูลเรื่องทิศ เบื้องต้นเจ้าของห้องยังไม่ได้ลงข้อมูลไว้ค่ะ",
  floorNoData:
    "ข้อมูลเรื่องชั้น เบื้องต้นเจ้าของห้องยังไม่ได้ลงข้อมูลไว้ค่ะ",
  customTermsNoData:
    "เงื่อนไขพิเศษแบบนี้เจ้าของต้องพิจารณาเป็นครั้งๆ ค่ะ เบื้องต้นยังไม่มีรายละเอียดในระบบค่ะ",
  generalNoData:
    "คำถามนี้ต้องให้เจ้าของยืนยันโดยตรงค่ะ เบื้องต้นยังไม่มีข้อมูลในระบบค่ะ",
  unitNumberViewing:
    "เลขห้องที่แน่นอน แอดมินจะแจ้งเมื่อลูกค้านัดดูห้องจริงค่ะ — กด「ขอนัดดู」ในแชทนี้ได้เลยค่ะ",
  relayIntro: "แอดมินสอบถามเจ้าของให้แล้วนะคะ เจ้าของแจ้งมาว่า ",
  relayUncertain:
    "เจ้าของแจ้งว่าขอยังไม่ให้คำตอบในตอนนี้นะคะ เค้าแจ้งว่าอยากให้นัดดูห้องจริงก่อน " +
    "ถ้าสนใจจริงๆ ค่อยคุยเรื่องต่อรองราคาค่ะ หรือถ้าลูกค้าพร้อมจองเลย " +
    "สามารถแจ้งแอดมินได้เลยค่ะ แอดมินจะช่วยคุยให้อีกรอบค่ะ",
  relayOutro:
    "\n\nหากสนใจดำเนินการต่อ แจ้งในแชทนี้ได้เลยค่ะ หรือกด「ขอนัดดู」เพื่อนัดชมห้องจริงค่ะ",
} as const;

function formatListingNetPriceLine(listing?: ListingDetail | null): string {
  if (listing?.price_net == null || !Number.isFinite(listing.price_net)) {
    return VOICE.priceNoData;
  }
  const n = Math.round(listing.price_net);
  const suffix = listing.listing_type === "rent" ? "บาท/เดือน" : "บาท";
  return `ในระบบข้อมูลที่ลงราคา ${n.toLocaleString("th-TH")} ${suffix} เป็นราคาสุทธิแล้วค่ะ`;
}

/** ต่อรองครั้งแรก — ส่งเสริมการขาย (ไม่เปิดฟอร์มทันที) */
export function priceNegotiationSalesBurst(
  listing?: ListingDetail | null,
): string[] {
  return [formatListingNetPriceLine(listing), VOICE.priceNegotiateFollow];
}

export function daysSinceUpdate(iso: string | null | undefined): number | null {
  if (!iso) return null;
  const ms = Date.now() - new Date(iso).getTime();
  if (!Number.isFinite(ms) || ms < 0) return null;
  return Math.floor(ms / 86_400_000);
}

/** เปิดบทสนทนา — ยังไม่แนบฟอร์ม */
export function ownerInquiryOpenBurst(
  type: OwnerInquiryType,
  listing?: ListingDetail | null,
): string[] {
  if (type === "price_negotiation") {
    return [
      formatListingNetPriceLine(listing),
      `${VOICE.priceNegotiateFollow} ${VOICE.askMoreQuestions}`,
    ];
  }
  if (type === "custom_terms") {
    return [VOICE.customTermsNoData, VOICE.askMoreQuestions];
  }
  if (type === "availability") {
    const days = daysSinceUpdate(listing?.updated_at);
    const head = days != null
      ? `จากการอัปเดตข้อมูลล่าสุดจากเจ้าของ ประมาณ ${days} วันที่แล้ว ห้องยังว่างค่ะ`
      : "จากข้อมูลล่าสุดในระบบ ห้องยังว่างค่ะ";
    return [head, VOICE.askMoreQuestions];
  }
  return [VOICE.generalNoData, VOICE.askMoreQuestions];
}

/** หลังลูกค้าส่งคำถามเพิ่ม — ชวนกรอกโปรไฟล์ */
export function ownerInquiryProfileBurst(): string[] {
  return [VOICE.profileAsk, VOICE.profileFollowUp];
}

export function floorFacingBurst(listing?: ListingDetail | null): string[] {
  const floor = listing?.floor_range?.trim();
  if (floor) {
    return [
      `ห้องนี้อยู่${floor.includes("ชั้น") ? floor : `ชั้นที่ ${floor}`}ค่ะ`,
      VOICE.facingNoData,
      VOICE.askMoreQuestions,
    ];
  }
  return [VOICE.facingNoData, VOICE.askMoreQuestions];
}

export function compoundListingBurst(listing?: ListingDetail | null): string[] {
  const days = daysSinceUpdate(listing?.updated_at);
  const avail = days != null
    ? `อัปเดตล่าสุด ${days} วัน ห้องยังว่างค่ะ`
    : "จากข้อมูลล่าสุด ห้องยังว่างค่ะ";

  const contract = extractMinContractHint(listing?.description_public) ??
    "ห้องนี้สัญญาขั้นต่ำที่ 1 ปี";

  const furn = listing?.furnished === true
    ? "ส่วนเฟอร์นิเจอร์จะได้ตามรูปที่ลงเลยค่ะ"
    : listing?.furnished === false
    ? "ห้องนี้เป็นห้องเปล่าตามประกาศค่ะ"
    : "ส่วนเฟอร์นิเจอร์จะได้ตามรูปที่ลงเลยค่ะ";

  return [avail, contract, furn, VOICE.askMoreQuestions];
}

function extractMinContractHint(desc: string | null | undefined): string | null {
  if (!desc) return null;
  const d = desc.toLowerCase();
  if (d.includes("สัญญา 1 ปี") || d.includes("1 ปี")) {
    return "ห้องนี้สัญญาขั้นต่ำที่ 1 ปี";
  }
  if (d.includes("6 เดือน") || d.includes("6เดือน")) {
    return "ห้องนี้สัญญาขั้นต่ำที่ 6 เดือน";
  }
  if (d.includes("2 ปี")) return "ห้องนี้สัญญาขั้นต่ำที่ 2 ปี";
  return null;
}

export function isUnitNumberQuestion(text: string): boolean {
  const q = text.toLowerCase();
  return q.includes("เลขห้อง") || q.includes("ห้องเลข") ||
    q.includes("unit number") || q.includes("unit no");
}

export function isFloorFacingQuestion(text: string): boolean {
  const q = text.toLowerCase();
  return q.includes("ชั้น") || q.includes("ทิศ") || q.includes("หันทาง") ||
    q.includes("floor") || q.includes("facing");
}

export function isCompoundListingQuestion(text: string): boolean {
  const q = text.trim().toLowerCase();
  let n = 0;
  if (
    q.includes("ว่าง") || q.includes("เข้าอยู่") || q.includes("พร้อมอยู่") ||
    q.includes("available")
  ) n++;
  if (q.includes("สัญญา") || q.includes("ปี") || q.includes("ต่อรอง") ||
    q.includes("ลด")) n++;
  if (q.includes("เฟอร์") || q.includes("furniture")) n++;
  return n >= 2;
}

const UNCERTAIN_OWNER_KEYS = [
  "ยังไม่ยืนยัน", "ยังไม่แน่ใจ", "ต้องดูสัญญา", "ดูสัญญาก่อน",
  "นัดดูก่อน", "นัดชมก่อน", "ยังไม่ให้คำตอบ",
];

export function isOwnerUncertainReply(text: string): boolean {
  const q = text.toLowerCase();
  return UNCERTAIN_OWNER_KEYS.some((k) => q.includes(k));
}

// Legacy single-string exports (relay / tests)
export function ownerInquiryStartText(
  type: OwnerInquiryType,
  listing?: ListingDetail | null,
): string {
  return ownerInquiryOpenBurst(type, listing).join("\n");
}

export function floorFacingReplyText(listing?: ListingDetail | null): string {
  return floorFacingBurst(listing).join("\n");
}

export function compoundListingReplyText(listing?: ListingDetail | null): string {
  return compoundListingBurst(listing).join("\n");
}
