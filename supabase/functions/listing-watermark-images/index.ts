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

    const body = await req.json() as { listing_id?: string };
    const listingId = body.listing_id;
    if (!listingId) {
      return jsonResponse({ error: "listing_id required" }, 400);
    }

    const db = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );

    const { data: listing } = await db
      .from("listings")
      .select("id, status")
      .eq("id", listingId)
      .maybeSingle();

    if (!listing) {
      return jsonResponse({ error: "listing not found" }, 404);
    }

    if (listing.status !== "published") {
      return jsonResponse({ error: "listing must be published" }, 400);
    }

    const result = await watermarkListingImages(db, listingId);

    await db.from("admin_audit_log").insert({
      actor_id: auth.userId,
      action: "listing.watermark_images",
      entity_type: "listing",
      entity_id: listingId,
      metadata: result,
    }).catch(() => {});

    return jsonResponse({ ok: true, listing_id: listingId, ...result });
  } catch (e) {
    console.error(e);
    return jsonResponse({ error: String(e) }, 500);
  }
});
