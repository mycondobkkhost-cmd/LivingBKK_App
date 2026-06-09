/** ฟิลด์ที่ AI อาจเติม/อัปเดต — ยกเว้นที่มนุษย์ lock แล้ว */
export const AI_MERGE_FIELDS = [
  "title",
  "description",
  "start_at",
  "end_at",
  "location_label",
  "listing_code",
  "listing_id",
  "lead_id",
  "color_hint",
  "owner_notes",
  "seeker_notes",
] as const;

export type FieldLocks = Record<string, string>;

export function isHumanLocked(
  locks: FieldLocks | null | undefined,
  field: string,
): boolean {
  return locks?.[field] === "human";
}

export function mergeAiIntoCanonical(
  canonical: Record<string, unknown>,
  aiDraft: Record<string, unknown>,
  fieldLocks: FieldLocks,
): Record<string, unknown> {
  const out = { ...canonical };
  for (const field of AI_MERGE_FIELDS) {
    if (isHumanLocked(fieldLocks, field)) continue;
    const v = aiDraft[field];
    if (v === undefined || v === null) continue;
    out[field] = v;
  }
  return out;
}

export function parseTimeSlotOnDate(
  dateIso: string,
  timeSlot: string,
): { start_at: string; end_at: string } {
  const base = dateIso.split("T")[0];
  const parts = timeSlot.replace(/–/g, "-").split("-").map((s) => s.trim());
  const startRaw = parts[0] ?? "10:00";
  const endRaw = parts[1] ?? addHour(startRaw);
  const start = normalizeTime(startRaw);
  const end = normalizeTime(endRaw);
  return {
    start_at: `${base}T${start}:00+07:00`,
    end_at: `${base}T${end}:00+07:00`,
  };
}

function normalizeTime(raw: string): string {
  const m = raw.match(/(\d{1,2})[:\.]?(\d{2})?/);
  if (!m) return "10:00";
  const h = m[1].padStart(2, "0");
  const min = (m[2] ?? "00").padStart(2, "0");
  return `${h}:${min}`;
}

function addHour(time: string): string {
  const m = time.match(/(\d{1,2})/);
  const h = m ? Math.min(23, parseInt(m[1], 10) + 1) : 11;
  return `${String(h).padStart(2, "0")}:00`;
}
