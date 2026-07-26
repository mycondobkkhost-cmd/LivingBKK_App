/** Escape special chars สำหรับ PostgREST ilike patterns */
export function sanitizeIlikePattern(raw: string): string {
  return raw
    .trim()
    .replace(/\\/g, "\\\\")
    .replace(/%/g, "\\%")
    .replace(/_/g, "\\_");
}

export function ilikeContains(raw: string): string {
  return `%${sanitizeIlikePattern(raw)}%`;
}
