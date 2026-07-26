import { SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";

export type ListingResolution = {
  status: "found" | "not_found" | "none";
  listing_id?: string;
  listing_code?: string;
  title?: string;
  project_name?: string | null;
  listing_type?: string;
  price_net?: number;
  matched_query?: string;
};

const LISTING_CODE_RE =
  /^(RENT|SALE)-[A-Z]{2}-\d{4}-\d{6}$/i;
const PIR_CODE_RE = /^PIR\d{6}-\d{4}$/i;
const INVENTORY_CODE_RE = /^(RXT|PPTR|PTP)-\d{4}-\d{6}$/i;

/** ดึงรหัสทรัพย์จากข้อความค้นหา (รองรับพิมพ์รหัสติดข้อความอื่น) */
export function extractListingCodeFromQuery(query: string): string | null {
  const q = query.trim();
  if (!q) return null;

  const upper = q.toUpperCase();
  if (LISTING_CODE_RE.test(upper) || PIR_CODE_RE.test(upper) ||
    INVENTORY_CODE_RE.test(upper)) {
    return upper;
  }

  const inline = q.match(
    /\b((?:RENT|SALE)-[A-Z]{2}-\d{4}-\d{6}|PIR\d{6}-\d{4}|(?:RXT|PPTR|PTP)-\d{4}-\d{6})\b/i,
  );
  return inline?.[1]?.toUpperCase() ?? null;
}

export function isListingCodeQuery(query: string): boolean {
  return extractListingCodeFromQuery(query) != null;
}

export async function resolveListingByCode(
  db: SupabaseClient,
  code: string,
): Promise<ListingResolution> {
  const normalized = code.trim().toUpperCase();
  if (!normalized) return { status: "none" };

  const { data: direct } = await db
    .from("listings_public")
    .select("id, listing_code, title, project_name, listing_type, price_net")
    .eq("listing_code", normalized)
    .maybeSingle();

  if (direct) {
    return {
      status: "found",
      listing_id: direct.id as string,
      listing_code: direct.listing_code as string,
      title: direct.title as string,
      project_name: direct.project_name as string | null,
      listing_type: direct.listing_type as string,
      price_net: direct.price_net as number,
      matched_query: normalized,
    };
  }

  if (INVENTORY_CODE_RE.test(normalized)) {
    const { data: inv } = await db
      .from("property_inventory")
      .select("display_listing_id, inventory_code, project_name")
      .eq("inventory_code", normalized)
      .maybeSingle();

    if (inv?.display_listing_id) {
      const { data: listing } = await db
        .from("listings_public")
        .select("id, listing_code, title, project_name, listing_type, price_net")
        .eq("id", inv.display_listing_id as string)
        .maybeSingle();

      if (listing) {
        return {
          status: "found",
          listing_id: listing.id as string,
          listing_code: listing.listing_code as string,
          title: (listing.title as string) ??
            (inv.project_name as string | undefined),
          project_name: listing.project_name as string | null,
          listing_type: listing.listing_type as string,
          price_net: listing.price_net as number,
          matched_query: normalized,
        };
      }
    }
  }

  return { status: "not_found", matched_query: normalized };
}

export async function resolveListingFromQuery(
  db: SupabaseClient | null,
  query: string,
): Promise<ListingResolution> {
  const code = extractListingCodeFromQuery(query);
  if (!code) return { status: "none" };
  if (!db) return { status: "not_found", matched_query: code };
  return await resolveListingByCode(db, code);
}
