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
      await db
        .from("listings")
        .update({ status: "hidden" })
        .eq("id", listingId)
        .eq("status", "published");
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
