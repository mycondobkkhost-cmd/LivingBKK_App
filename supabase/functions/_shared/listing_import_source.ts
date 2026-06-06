/** จำแนกแหล่งลิงก์นำเข้าประกาศ (LI / Facebook / ทั่วไป) */

export type ListingImportPlatform =
  | "livinginsider"
  | "facebook"
  | "generic";

export function normalizeImportUrl(raw: string): string {
  const trimmed = raw.trim();
  if (!trimmed) return trimmed;
  try {
    const u = new URL(trimmed.startsWith("http") ? trimmed : `https://${trimmed}`);
    u.hash = "";
    return u.toString();
  } catch {
    return trimmed;
  }
}

export function detectListingImportPlatform(url: string): ListingImportPlatform {
  try {
    const u = new URL(normalizeImportUrl(url));
    const host = u.hostname.toLowerCase();
    if (host.includes("livinginsider.com")) {
      const p = u.pathname.toLowerCase();
      if (
        p.includes("istockdetail") ||
        p.includes("livingdetail") ||
        p.includes("/detail/")
      ) {
        return "livinginsider";
      }
    }
    if (
      host.includes("facebook.com") ||
      host.includes("fb.com") ||
      host === "fb.me" ||
      host.includes("fb.watch")
    ) {
      return "facebook";
    }
  } catch {
    /* fall through */
  }
  return "generic";
}

export function isLivingInsiderListingUrl(url: string): boolean {
  return detectListingImportPlatform(url) === "livinginsider";
}

export function isAllowedImportUrl(url: string): boolean {
  const normalized = normalizeImportUrl(url);
  if (!normalized) return false;
  try {
    const u = new URL(normalized);
    if (u.protocol !== "http:" && u.protocol !== "https:") return false;
    if (!u.hostname || u.hostname === "localhost") return false;
    return true;
  } catch {
    return false;
  }
}
