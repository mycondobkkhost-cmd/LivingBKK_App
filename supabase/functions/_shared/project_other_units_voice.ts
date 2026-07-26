/** ตอบเมื่อลูกค้าถามห้องอื่นในโครงการ แต่ในระบบมีแค่ห้องเดียว */
import type { BotReply, ListingRow } from "./chat_logic.ts";

export const PROJECT_OTHER_FORM_LABEL = "กรอกฟอร์มช่วยหาทรัพย์";

function priceLabelFull(l: ListingRow): string {
  if (l.listing_type === "rent") {
    return `${Math.round(l.price_net).toLocaleString("th-TH")} บาท/เดือน (Net)`;
  }
  if (l.price_net >= 1_000_000) {
    return `${(l.price_net / 1_000_000).toFixed(2)} ล้านบาท (Net)`;
  }
  return `${Math.round(l.price_net).toLocaleString("th-TH")} บาท (Net)`;
}

export function projectOtherUnitsSingleReply(
  listing: ListingRow,
  isCurrentThread: boolean,
): BotReply {
  const project = listing.project_name?.trim() || "โครงการนี้";
  const label = `${listing.listing_code} · ${priceLabelFull(listing)}`;
  const pointer = isCurrentThread ? " ← ห้องที่ลูกค้าเปิดแชทอยู่" : "";

  return {
    role: "ai",
    text:
      `ในโครงการ ${project} ตอนนี้เท่าที่เช็คในระบบมีห้องนี้ค่ะ:\n\n` +
      `[${label}]${pointer}\n\n` +
      "ถ้าหากลูกค้าต้องการเฉพาะห้องที่โครงการนี้เท่านั้น " +
      "สามารถกรอกฟอร์มช่วยหาทรัพย์ให้แอดมินช่วยประกาศหาได้ค่ะ " +
      "หรือถ้าดูโครงการอื่นๆ ไว้ด้วย ลองบอกรายละเอียดเพิ่มเติมเกี่ยวกับห้องที่กำลังหา " +
      "แอดมินจะดำเนินการส่งห้องในระบบที่ตรงตามเงื่อนไขมาให้ดูค่ะ",
    links: [
      {
        label,
        kind: "listing",
        listingId: listing.id,
        projectName: listing.project_name ?? undefined,
      },
      {
        label: PROJECT_OTHER_FORM_LABEL,
        kind: "requirement_form",
        listingId: "",
      },
    ],
  };
}
