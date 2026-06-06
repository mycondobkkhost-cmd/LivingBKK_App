import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";
import { requireAdmin } from "../_shared/admin_auth.ts";
import { corsHeaders, jsonResponse } from "../_shared/cors.ts";
import { watermarkListingImages } from "../_shared/watermark_listing_images.ts";

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const auth = await requireAdmin(req);
    if (auth instanceof Response) return auth;

    const body = await req.json();
    const importId = body.import_id as string | undefined;
    if (!importId) return jsonResponse({ error: "import_id required" }, 400);

    const db = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );

    const { data: row, error } = await db
      .from("listing_imports")
      .select("*")
      .eq("id", importId)
      .single();

    if (error || !row) return jsonResponse({ error: "Import not found" }, 404);

    const listingId = row.listing_id as string | null;
    if (!listingId) {
      return jsonResponse({ error: "ยังไม่มี draft — กดดึงข้อมูลก่อน" }, 400);
    }

    const now = new Date().toISOString();
    const expires = new Date(Date.now() + 30 * 86400000).toISOString();

    const { error: pubErr } = await db
      .from("listings")
      .update({
        status: "published",
        published_at: now,
        last_bump_at: now,
        expires_at: expires,
      })
      .eq("id", listingId);

    if (pubErr) return jsonResponse({ error: pubErr.message }, 400);

    const { data: updated, error: updErr } = await db
      .from("listing_imports")
      .update({
        status: "approved",
        reviewed_by: auth.userId,
        reviewed_at: now,
      })
      .eq("id", importId)
      .select("*")
      .single();

    if (updErr) return jsonResponse({ error: updErr.message }, 400);

    await db.from("admin_audit_log").insert({
      actor_id: auth.userId,
      action: "listing_import.approve",
      entity_type: "listing_import",
      entity_id: importId,
    }).catch(() => {});

    const watermark = await watermarkListingImages(db, listingId);

    return jsonResponse({
      import: updated,
      listing_id: listingId,
      watermark,
    });
  } catch (e) {
    return jsonResponse({ error: String(e) }, 500);
  }
});
