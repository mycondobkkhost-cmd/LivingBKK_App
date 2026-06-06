/** ข้อความแจ้งเตือนแชท — ภาษาไทยเข้าใจง่าย */

export function thaiInboxLabel(category: string, viewingSubmitted: boolean): string {
  if (viewingSubmitted || category === "viewing_request") return "นัดดูห้อง";
  switch (category) {
    case "staff_support":
      return "แชทเจ้าหน้าที่";
    case "escalation":
      return "ต้องเจ้าหน้าที่";
    case "discovery":
      return "ค้นหาทรัพย์";
    case "demand_offer":
      return "เสนอทรัพย์";
    case "customer_requirement":
      return "ความต้องการหาทรัพย์";
    default:
      return "แชททรัพย์";
  }
}

export function thaiNewQueueTitle(): string {
  return "แชทรอรับงาน";
}

export function thaiNewQueueBody(listingCode: string, label: string): string {
  const code = listingCode || "Support";
  return `${code} · ${label}`;
}

export function thaiClaimedTitle(): string {
  return "มีคนรับงานแล้ว";
}

export function thaiClaimedBody(
  assigneeName: string,
  listingCode: string,
): string {
  const code = listingCode || "Support";
  return `${assigneeName} รับงาน ${code} แล้ว`;
}

export function thaiAssignedTitle(): string {
  return "มอบหมายแชทให้คุณ";
}

export function thaiAssignedBody(listingCode: string, fromName: string): string {
  const code = listingCode || "Support";
  return `${code} · จาก ${fromName}`;
}

export function thaiSlaUnclaimedTitle(): string {
  return "⚠️ ยังไม่มีคนรับ";
}

export function thaiSlaUnclaimedBody(
  listingCode: string,
  waitMinutes: number,
): string {
  const code = listingCode || "Support";
  return `${code} · รอ ${waitMinutes} นาที`;
}

export function thaiSlaOverdueTitle(): string {
  return "⚠️ แชทค้าง";
}

export function thaiSlaOverdueBody(
  listingCode: string,
  waitMinutes: number,
  assigneeName: string,
): string {
  const code = listingCode || "Support";
  const who = assigneeName || "ทีมงาน";
  return `${code} · รอ ${waitMinutes} นาที · ${who}`;
}

export function thaiEscalationTitle(): string {
  return "แชทรอรับงาน";
}

export function thaiEscalationBody(
  listingCode: string,
  reason: string,
): string {
  const code = listingCode || "Support";
  const reasonTh: Record<string, string> = {
    escalation: "ต้องเจ้าหน้าที่",
    sensitive: "เรื่องละเอียดอ่อน",
    staff_request: "ขอคุยเจ้าหน้าที่",
    staff_room: "เปิดแชทเจ้าหน้าที่",
    viewing: "ส่งฟอร์มนัดดู",
    demand_offer: "เสนอทรัพย์",
    customer_requirement: "ความต้องการหาทรัพย์",
    unclear: "ถามซ้ำไม่ชัด",
  };
  const label = reasonTh[reason] ?? reason;
  return `${code} · ${label}`;
}
