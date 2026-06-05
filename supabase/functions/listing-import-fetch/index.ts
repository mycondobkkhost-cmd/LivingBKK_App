import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";
import { requireAdmin } from "../_shared/admin_auth.ts";
import { corsHeaders, jsonResponse } from "../_shared/cors.ts";
import {
  fetchLiHtml,
  isLivingInsiderListingUrl,
  matchProject,
  normalizeLiUrl,
  parseLiHtml,
} from "../_shared/li_parser.ts";

const MAX_IMAGES = 12;

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
): Promise<number> {
  let uploaded = 0;
  for (let i = 0; i < Math.min(imageUrls.length, MAX_IMAGES); i++) {
    const bytes = await downloadImage(imageUrls[i]);
    if (!bytes) continue;

    const path = `${adminId}/${listingId}/li_${i}_${Date.now()}.jpeg`;
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

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const auth = await requireAdmin(req);
    if (auth instanceof Response) return auth;

    const body = await req.json();
    const importId = body.import_id as string | undefined;
    let sourceUrl = normalizeLiUrl((body.source_url as string | undefined) ?? "");

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
      sourceUrl = normalizeLiUrl(String(importRow.source_url ?? ""));
    }

    if (!sourceUrl) {
      return jsonResponse({ error: "source_url required" }, 400);
    }
    if (!isLivingInsiderListingUrl(sourceUrl)) {
      return jsonResponse({ error: "URL ต้องเป็น livinginsider.com (istockdetail/livingdetail)" }, 400);
    }

    if (!importRow) {
      const { data: dup } = await db
        .from("listing_imports")
        .select("id, status")
        .eq("source_url", sourceUrl)
        .maybeSingle();
      if (dup && dup.status !== "archived" && dup.status !== "failed") {
        return jsonResponse({
          error: "ลิงก์นี้อยู่ในคิวแล้ว",
          import_id: dup.id,
          status: dup.status,
        }, 409);
      }

      const { data: created, error: insErr } = await db
        .from("listing_imports")
        .insert({
          source_url: sourceUrl,
          source_platform: "livinginsider",
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
        .update({ status: "fetching", error_message: null })
        .eq("id", importRow.id);
    }

    const rowId = importRow.id as string;

    try {
      const html = await fetchLiHtml(sourceUrl);
      const parsed = parseLiHtml(html, sourceUrl);

      if (parsed.sourceExternalId) {
        const { data: dupLi } = await db
          .from("listing_imports")
          .select("id, status")
          .eq("source_external_id", parsed.sourceExternalId)
          .neq("id", rowId)
          .maybeSingle();
        if (dupLi && dupLi.status !== "archived" && dupLi.status !== "failed") {
          throw new Error(`LI ID ${parsed.sourceExternalId} นำเข้าแล้ว`);
        }
      }

      if (parsed.priceNet <= 0) {
        throw new Error("ไม่พบราคาในหน้า LI");
      }

      const project = await matchProject(db, parsed.projectName);

      const lat = (project?.lat as number | undefined) ?? parsed.lat ?? 13.7367;
      const lng = (project?.lng as number | undefined) ?? parsed.lng ?? 100.5608;
      const district = (project?.district as string | undefined) ??
        parsed.district ?? "กรุงเทพฯ";

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
        price_net: parsed.priceNet,
        description_public: parsed.description.slice(0, 8000),
        area_sqm: parsed.areaSqm,
        bedrooms: parsed.bedrooms,
        district,
        project_name: (project?.name_th as string | undefined) ?? parsed.projectName,
        project_id: project?.id ?? null,
        geo_zone_id: project?.geo_zone_id ?? null,
        source_platform: "livinginsider",
        source_url: sourceUrl,
        source_external_id: parsed.sourceExternalId,
        status: "draft",
        location_exact: { type: "Point", coordinates: [lng, lat] },
        location_public: { type: "Point", coordinates: [lng, lat] },
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
      );

      if (imageCount === 0) parsed.flags.push("images_upload_failed");

      const status = parsed.flags.includes("missing_price") ||
          parsed.flags.includes("missing_images")
        ? "needs_fix"
        : "draft_ready";

      const rawPayload = {
        fetched_at: new Date().toISOString(),
        li_web_id: parsed.sourceExternalId,
        contact_private: parsed.contactPrivate,
        html_bytes: html.length,
      };

      const { data: updated, error: updErr } = await db
        .from("listing_imports")
        .update({
          source_external_id: parsed.sourceExternalId,
          status,
          error_message: null,
          title_preview: parsed.title,
          project_preview: (project?.name_th as string | undefined) ??
            parsed.projectName,
          price_preview: parsed.priceNet,
          image_count: imageCount,
          listing_id: listingId,
          raw_payload: rawPayload,
          parsed: {
            ...parsed,
            contactPrivate: undefined,
            matched_project_id: project?.id ?? null,
          },
        })
        .eq("id", rowId)
        .select("*")
        .single();

      if (updErr) return jsonResponse({ error: updErr.message }, 400);

      return jsonResponse({
        import: updated,
        listing_id: listingId,
        image_count: imageCount,
        flags: parsed.flags,
      });
    } catch (e) {
      const msg = String(e);
      await db
        .from("listing_imports")
        .update({ status: "failed", error_message: msg.slice(0, 500) })
        .eq("id", rowId);
      return jsonResponse({ error: msg, import_id: rowId }, 422);
    }
  } catch (e) {
    return jsonResponse({ error: String(e) }, 500);
  }
});
