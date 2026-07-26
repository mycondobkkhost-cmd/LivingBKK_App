import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";
import { requireAdmin } from "../_shared/admin_auth.ts";
import { corsHeaders, jsonResponse } from "../_shared/cors.ts";
import { applyAiDraftToImport } from "../_shared/listing_import_ai_draft.ts";

function serviceDb() {
  return createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );
}

function sourceTextFromImport(row: Record<string, unknown>): string | null {
  const raw = row.raw_payload as Record<string, unknown> | null;
  const capture = raw?.capture as Record<string, unknown> | null;
  const fromCapture = capture?.source_text_original as string | undefined;
  if (fromCapture?.trim()) return fromCapture.trim();

  const parsed = row.parsed as Record<string, unknown> | null;
  const fromParsed = parsed?.description as string | undefined;
  if (fromParsed?.trim()) return fromParsed.trim();

  return null;
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
    if (!importId) {
      return jsonResponse({ error: "import_id required" }, 400);
    }

    const db = serviceDb();
    const { data: row, error } = await db
      .from("listing_imports")
      .select("*")
      .eq("id", importId)
      .single();
    if (error || !row) {
      return jsonResponse({ error: "Import not found" }, 404);
    }

    const overrideText = body.source_text as string | undefined;
    const sourceText = overrideText?.trim() ||
      sourceTextFromImport(row as Record<string, unknown>);
    if (!sourceText) {
      return jsonResponse({ error: "No source text to draft from" }, 400);
    }

    const raw = row.raw_payload as Record<string, unknown> | null;
    const capture = raw?.capture as Record<string, unknown> | null;

    const { aiDraft, listingId } = await applyAiDraftToImport(
      db,
      importId,
      sourceText,
      {
        platform: row.source_platform as string,
        postUrl: (body.post_url as string | undefined) ??
          capture?.post_url as string | null ??
          row.source_url as string,
        ownerProfileUrl: (body.owner_profile_url as string | undefined) ??
          capture?.owner_profile_url as string | null,
      },
    );

    const { data: updated } = await db
      .from("listing_imports")
      .select("*")
      .eq("id", importId)
      .single();

    return jsonResponse({
      import: updated,
      listing_id: listingId,
      ai_draft: aiDraft,
    });
  } catch (e) {
    return jsonResponse({ error: String(e) }, 500);
  }
});
