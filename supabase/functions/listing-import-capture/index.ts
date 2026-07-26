import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";
import { requireAdmin } from "../_shared/admin_auth.ts";
import { corsHeaders, jsonResponse } from "../_shared/cors.ts";
import {
  applyAiDraftToImport,
  CaptureImportDuplicateError,
  createCaptureImportRow,
} from "../_shared/listing_import_ai_draft.ts";

function serviceDb() {
  return createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const auth = await requireAdmin(req);
    if (auth instanceof Response) return auth;

    const body = await req.json();
    const sourceText = String(body.source_text ?? "").trim();
    if (sourceText.length < 8) {
      return jsonResponse({ error: "source_text required (min 8 chars)" }, 400);
    }

    const postUrl = body.post_url as string | undefined;
    const ownerProfileUrl = body.owner_profile_url as string | undefined;

    const db = serviceDb();
    const { importId, listingId } = await createCaptureImportRow(db, auth.userId, {
      sourceText,
      postUrl,
      ownerProfileUrl,
    });

    await applyAiDraftToImport(db, importId, sourceText, {
      platform: "manual_capture",
      postUrl: postUrl?.trim() || null,
      ownerProfileUrl: ownerProfileUrl?.trim() || null,
    });

    const { data: updated } = await db
      .from("listing_imports")
      .select("*")
      .eq("id", importId)
      .single();

    try {
      const { syncImportToVault, syncListingToVault } = await import(
        "../_shared/vault_sync.ts"
      );
      await syncImportToVault(db, importId);
      await syncListingToVault(db, listingId);
    } catch (_) {
      /* optional */
    }

    return jsonResponse({
      import: updated,
      listing_id: listingId,
      import_id: importId,
    });
  } catch (e) {
    if (e instanceof CaptureImportDuplicateError) {
      return jsonResponse({
        error: e.message,
        import_id: e.importId,
        duplicate_of: e.duplicateOf,
      }, 409);
    }
    return jsonResponse({ error: String(e) }, 500);
  }
});
