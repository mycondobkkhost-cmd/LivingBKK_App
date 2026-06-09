import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";
import { requireAdmin } from "../_shared/admin_auth.ts";
import { corsHeaders, jsonResponse } from "../_shared/cors.ts";
import { fetchPageHtml, parseGenericHtml } from "../_shared/generic_url_parser.ts";
import {
  detectListingImportPlatform,
  isAllowedImportUrl,
  normalizeImportUrl,
  type ListingImportPlatform,
} from "../_shared/listing_import_source.ts";
import {
  fetchLiHtml,
  matchProject,
  parseLiHtml,
  type LiParsedListing,
} from "../_shared/li_parser.ts";

const MAX_IMAGES = 12;
const PLACEHOLDER_PRICE = 1;

function serviceDb() {
  return createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );
}

async function downloadImage(url: string): Promise<Uint8Array | null> {
  try {
    const res = await fetch(url, {
      headers: { "User-Agent": "LivingBKK-Import/1.0" },
    });
    if (!res.ok) return null;
    const buf = new Uint8Array(await res.arrayBuffer());
    if (buf.length < 1024) return null;
    return buf;
  } catch {
    return null;
  }
}

async function uploadListingImages(
  db: ReturnType<typeof serviceDb>,
  listingId: string,
  adminId: string,
  imageUrls: string[],
  prefix: string,
): Promise<number> {
  let uploaded = 0;
  for (let i = 0; i < Math.min(imageUrls.length, MAX_IMAGES); i++) {
    const bytes = await downloadImage(imageUrls[i]);
    if (!bytes) continue;

    const path = `${adminId}/${listingId}/${prefix}_${i}_${Date.now()}.jpeg`;
    const { error: upErr } = await db.storage
      .from("listing-images")
      .upload(path, bytes, {
        contentType: "image/jpeg",
        upsert: false,
      });
    if (upErr) continue;

    const { data: pub } = db.storage.from("listing-images").getPublicUrl(path);
    const publicUrl = pub.publicUrl;

    await db.from("listing_images").insert({
      listing_id: listingId,
      storage_path: path,
      public_url: publicUrl,
      sort_order: uploaded,
      moderation_status: "approved",
    });
    uploaded++;
  }
  return uploaded;
}

async function fetchAndParse(
  sourceUrl: string,
  platform: ListingImportPlatform,
): Promise<{ html: string; parsed: LiParsedListing }> {
  if (platform === "livinginsider") {
    const html = await fetchLiHtml(sourceUrl);
    return { html, parsed: parseLiHtml(html, sourceUrl) };
  }
  const html = await fetchPageHtml(sourceUrl);
  return { html, parsed: parseGenericHtml(html, sourceUrl, platform) };
}

function resolveImportStatus(parsed: LiParsedListing, imageCount: number): string {
  if (parsed.flags.includes("facebook_login_wall")) return "needs_fix";
  if (parsed.priceNet <= 0 || parsed.flags.includes("missing_price")) {
    return "needs_fix";
  }
  if (
    imageCount === 0 ||
    parsed.flags.includes("missing_images") ||
    parsed.flags.includes("images_upload_failed") ||
    parsed.flags.includes("needs_admin_review")
  ) {
    return "needs_fix";
  }
  if (
    parsed.flags.includes("missing_project") ||
    parsed.flags.includes("missing_coords")
  ) {
    return "needs_fix";
  }
  return "draft_ready";
}

function effectivePrice(parsed: LiParsedListing): number {
  return parsed.priceNet > 0 ? parsed.priceNet : PLACEHOLDER_PRICE;
}

/** Bangkok metro bbox — reject swapped/invalid PH coords */
function resolveListingCoords(
  project: Record<string, unknown> | null,
  parsed: LiParsedListing,
): { lat: number; lng: number } {
  const fallback = { lat: 13.7367, lng: 100.5608 };
  const sources: [unknown, unknown][] = [
    [project?.lat, project?.lng],
    [parsed.lat, parsed.lng],
  ];

  for (const [rawLat, rawLng] of sources) {
    let lat = Number(rawLat);
    let lng = Number(rawLng);
    if (!Number.isFinite(lat) || !Number.isFinite(lng)) continue;
    // Common data bug: lat/lng swapped (lng stored as lat)
    if (lat > 90 && lng <= 90) {
      const tmp = lat;
      lat = lng;
      lng = tmp;
    }
    if (lat < 13.2 || lat > 14.5 || lng < 99.8 || lng > 101.2) continue;
    return { lat, lng };
  }
  return fallback;
}

function geographyPoint(lng: number, lat: number): string {
  return `SRID=4326;POINT(${lng} ${lat})`;
}

type DuplicateRef = {
  import_id: string;
  listing_id: string | null;
  listing_code: string | null;
  title_preview: string | null;
  status: string;
  source_url: string;
  source_external_id: string | null;
};

async function loadDuplicateRef(
  db: ReturnType<typeof serviceDb>,
  importId: string,
): Promise<DuplicateRef | null> {
  const { data } = await db
    .from("listing_imports")
    .select(
      "id, status, title_preview, listing_id, source_url, source_external_id, listings(listing_code)",
    )
    .eq("id", importId)
    .maybeSingle();
  if (!data) return null;
  const listing = data.listings as { listing_code?: string } | null;
  return {
    import_id: data.id as string,
    listing_id: (data.listing_id as string | null) ?? null,
    listing_code: listing?.listing_code ?? null,
    title_preview: (data.title_preview as string | null) ?? null,
    status: data.status as string,
    source_url: data.source_url as string,
    source_external_id: (data.source_external_id as string | null) ?? null,
  };
}

async function markImportFailed(
  db: ReturnType<typeof serviceDb>,
  rowId: string,
  msg: string,
  duplicateOf: DuplicateRef | null,
) {
  const parsedPatch: Record<string, unknown> = {};
  if (duplicateOf) {
    parsedPatch.duplicate_of = duplicateOf;
    parsedPatch.flags = ["duplicate_import"];
  }
  const { data: current } = await db
    .from("listing_imports")
    .select("parsed")
    .eq("id", rowId)
    .maybeSingle();
  const existingParsed = (current?.parsed as Record<string, unknown> | null) ?? {};
  const nextParsed = duplicateOf
    ? { ...existingParsed, ...parsedPatch }
    : existingParsed;

  await db
    .from("listing_imports")
    .update({
      status: "failed",
      error_message: msg.slice(0, 500),
      parsed: nextParsed,
    })
    .eq("id", rowId);
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const auth = await requireAdmin(req);
    if (auth instanceof Response) return auth;

    const body = await req.json();
    const importId = body.import_id as string | undefined;
    let sourceUrl = normalizeImportUrl((body.source_url as string | undefined) ?? "");

    const db = serviceDb();

    let importRow: Record<string, unknown> | null = null;

    if (importId) {
      const { data, error } = await db
        .from("listing_imports")
        .select("*")
        .eq("id", importId)
        .single();
      if (error || !data) {
        return jsonResponse({ error: "Import not found" }, 404);
      }
      importRow = data as Record<string, unknown>;
      sourceUrl = normalizeImportUrl(String(importRow.source_url ?? ""));
    }

    if (!sourceUrl) {
      return jsonResponse({ error: "source_url required" }, 400);
    }
    if (!isAllowedImportUrl(sourceUrl)) {
      return jsonResponse({
        error: "ลิงก์ไม่ถูกต้อง — ใช้ http(s):// ที่เข้าถึงสาธารณะได้",
      }, 400);
    }

    const platform = detectListingImportPlatform(sourceUrl);

    if (!importRow) {
      const { data: dup } = await db
        .from("listing_imports")
        .select("id, status")
        .eq("source_url", sourceUrl)
        .maybeSingle();
      if (dup && dup.status !== "archived" && dup.status !== "failed") {
        const duplicateOf = await loadDuplicateRef(db, dup.id as string);
        return jsonResponse({
          error: "ลิงก์นี้อยู่ในคิวแล้ว",
          import_id: dup.id,
          status: dup.status,
          duplicate_of: duplicateOf,
        }, 409);
      }

      const { data: created, error: insErr } = await db
        .from("listing_imports")
        .insert({
          source_url: sourceUrl,
          source_platform: platform,
          status: "fetching",
          created_by: auth.userId,
        })
        .select("*")
        .single();
      if (insErr) return jsonResponse({ error: insErr.message }, 400);
      importRow = created as Record<string, unknown>;
    } else {
      await db
        .from("listing_imports")
        .update({
          status: "fetching",
          error_message: null,
          source_platform: platform,
        })
        .eq("id", importRow.id);
    }

    const rowId = importRow.id as string;

    try {
      const { html, parsed } = await fetchAndParse(sourceUrl, platform);

      if (parsed.sourceExternalId) {
        const { data: dupExt } = await db
          .from("listing_imports")
          .select("id, status")
          .eq("source_external_id", parsed.sourceExternalId)
          .neq("id", rowId)
          .maybeSingle();
        if (dupExt && dupExt.status !== "archived" && dupExt.status !== "failed") {
          const duplicateOf = await loadDuplicateRef(db, dupExt.id as string);
          const err = new Error(
            `รายการนี้นำเข้าแล้ว (${parsed.sourceExternalId})`,
          );
          (err as Error & { duplicateOf?: DuplicateRef | null }).duplicateOf =
            duplicateOf;
          throw err;
        }
      }

      const project = await matchProject(db, parsed.projectName);

      if (!project && parsed.projectName?.trim()) {
        if (!parsed.flags.includes("project_not_in_registry")) {
          parsed.flags.push("project_not_in_registry");
        }
      }

      const { lat, lng } = resolveListingCoords(project, parsed);
      const district = (project?.district as string | undefined) ??
        parsed.district ?? "กรุงเทพฯ";
      const point = geographyPoint(lng, lat);

      const listingPayload: Record<string, unknown> = {
        owner_id: auth.userId,
        created_by_id: auth.userId,
        listed_by_role: "admin",
        platform_has_owner_contact: true,
        co_agent_eligible: true,
        co_agent_eligibility_reason: "platform_contact",
        co_agent_listing_type: "co_agent_50_50",
        owner_verified: false,
        title: parsed.title.slice(0, 200),
        listing_type: parsed.listingType,
        property_type: parsed.propertyType,
        price_net: effectivePrice(parsed),
        description_public: parsed.description.slice(0, 8000),
        area_sqm: parsed.areaSqm,
        bedrooms: parsed.bedrooms,
        district,
        project_name: (project?.name_th as string | undefined) ?? parsed.projectName,
        project_id: project?.id ?? null,
        geo_zone_id: project?.geo_zone_id ?? null,
        source_platform: platform,
        source_url: sourceUrl,
        source_external_id: parsed.sourceExternalId,
        status: "draft",
        location_exact: point,
        location_public: point,
      };

      let listingId = importRow.listing_id as string | null;

      if (listingId) {
        await db.from("listing_images").delete().eq("listing_id", listingId);
        await db.from("listings").update(listingPayload).eq("id", listingId);
      } else {
        const { data: listing, error: listErr } = await db
          .from("listings")
          .insert(listingPayload)
          .select("id, listing_code")
          .single();
        if (listErr) throw new Error(listErr.message);
        listingId = listing.id as string;
      }

      const imageCount = await uploadListingImages(
        db,
        listingId!,
        auth.userId,
        parsed.imageUrls,
        platform === "livinginsider" ? "li" : "ext",
      );

      if (imageCount === 0 && parsed.imageUrls.length > 0) {
        parsed.flags.push("images_upload_failed");
      }

      const status = resolveImportStatus(parsed, imageCount);

      const rawPayload = {
        fetched_at: new Date().toISOString(),
        source_platform: platform,
        external_id: parsed.sourceExternalId,
        contact_private: parsed.contactPrivate,
        source_meta: parsed.sourceMeta ?? null,
        html_bytes: html.length,
      };

      const { data: updated, error: updErr } = await db
        .from("listing_imports")
        .update({
          source_external_id: parsed.sourceExternalId,
          source_platform: platform,
          status,
          error_message: null,
          title_preview: parsed.title,
          project_preview: (project?.name_th as string | undefined) ??
            parsed.projectName,
          price_preview: parsed.priceNet > 0 ? parsed.priceNet : null,
          image_count: imageCount,
          listing_id: listingId,
          raw_payload: rawPayload,
          parsed: {
            ...parsed,
            contactPrivate: undefined,
            matched_project_id: project?.id ?? null,
            source_platform: platform,
            source_meta: parsed.sourceMeta ?? null,
          },
        })
        .eq("id", rowId)
        .select("*")
        .single();

      if (updErr) return jsonResponse({ error: updErr.message }, 400);

      try {
        const { syncImportToVault, syncListingToVault } = await import(
          "../_shared/vault_sync.ts"
        );
        await syncImportToVault(db, rowId);
        if (listingId) await syncListingToVault(db, listingId);
      } catch (_) {
        /* vault sync optional until migration deployed */
      }

      return jsonResponse({
        import: updated,
        listing_id: listingId,
        image_count: imageCount,
        flags: parsed.flags,
        source_platform: platform,
      });
    } catch (e) {
      const msg = String(e);
      const duplicateOf =
        (e as Error & { duplicateOf?: DuplicateRef | null }).duplicateOf ?? null;
      await markImportFailed(db, rowId, msg, duplicateOf);
      return jsonResponse({
        error: msg,
        import_id: rowId,
        duplicate_of: duplicateOf,
      }, 422);
    }
  } catch (e) {
    return jsonResponse({ error: String(e) }, 500);
  }
});
