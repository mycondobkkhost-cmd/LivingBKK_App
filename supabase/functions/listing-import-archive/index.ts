import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";
import { requireAdmin } from "../_shared/admin_auth.ts";
import { corsHeaders, jsonResponse } from "../_shared/cors.ts";

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const auth = await requireAdmin(req);
    if (auth instanceof Response) return auth;

    const body = await req.json();
    const importId = body.import_id as string | undefined;
    const purge = body.purge === true;
    if (!importId) return jsonResponse({ error: "import_id required" }, 400);

    const db = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );

    const { data: row, error } = await db
      .from("listing_imports")
      .select("id, listing_id, status")
      .eq("id", importId)
      .single();

    if (error || !row) return jsonResponse({ error: "Import not found" }, 404);

    const listingId = row.listing_id as string | null;
    if (listingId) {
      if (purge) {
        const { data: listing } = await db
          .from("listings")
          .select("status")
          .eq("id", listingId)
          .maybeSingle();
        const st = listing?.status as string | undefined;
        if (st === "draft" || st === "hidden") {
          await db.from("listings").delete().eq("id", listingId);
        } else if (st === "published") {
          await db
            .from("listings")
            .update({ status: "hidden" })
            .eq("id", listingId);
        }
      } else {
        await db
          .from("listings")
          .update({ status: "hidden" })
          .eq("id", listingId)
          .eq("status", "published");
      }
    }

    const { data: updated, error: updErr } = await db
      .from("listing_imports")
      .update({
        status: "archived",
        reviewed_by: auth.userId,
        reviewed_at: new Date().toISOString(),
      })
      .eq("id", importId)
      .select("*")
      .single();

    if (updErr) return jsonResponse({ error: updErr.message }, 400);

    return jsonResponse({ import: updated });
  } catch (e) {
    return jsonResponse({ error: String(e) }, 500);
  }
});
