import { corsHeaders, jsonResponse } from "../_shared/cors.ts";
import { serviceDb } from "../_shared/supabase_env.ts";
import { requireVaultTier } from "../_shared/vault_auth.ts";
import {
  syncAllImportsToVault,
  syncImportToVault,
  syncListingToVault,
  syncProfileToVault,
} from "../_shared/vault_sync.ts";

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const auth = await requireVaultTier(req);
    if (auth instanceof Response) return auth;

    const body = await req.json().catch(() => ({}));
    const action = (body.action as string | undefined) ?? "list";
    const db = serviceDb();

    if (action === "sync") {
      const imports = await syncAllImportsToVault(db);

      const { data: listings } = await db
        .from("listings")
        .select("id")
        .not("source_url", "is", null)
        .limit(200);
      for (const l of listings ?? []) {
        await syncListingToVault(db, l.id as string);
      }

      const { count } = await db
        .from("vault_assets")
        .select("id", { count: "exact", head: true });
      return jsonResponse({
        synced_imports: imports,
        total_assets: count ?? 0,
      });
    }

    if (action === "detail") {
      const entityType = body.entity_type as string | undefined;
      const entityId = body.entity_id as string | undefined;
      if (!entityType || !entityId) {
        return jsonResponse({ error: "entity_type and entity_id required" }, 400);
      }

      let { data, error } = await db
        .from("vault_assets")
        .select("*")
        .eq("entity_type", entityType)
        .eq("entity_id", entityId)
        .maybeSingle();

      if (!data) {
        if (entityType === "listing_import") {
          await syncImportToVault(db, entityId);
        } else if (entityType === "listing") {
          await syncListingToVault(db, entityId);
        } else if (entityType === "profile") {
          await syncProfileToVault(db, entityId);
        }
        const refetch = await db
          .from("vault_assets")
          .select("*")
          .eq("entity_type", entityType)
          .eq("entity_id", entityId)
          .maybeSingle();
        data = refetch.data;
        error = refetch.error;
      }

      if (error) return jsonResponse({ error: error.message }, 400);
      if (!data) return jsonResponse({ error: "Not found" }, 404);

      await db.from("admin_audit_log").insert({
        actor_id: auth.userId,
        action: "vault.view",
        entity_type: entityType,
        entity_id: entityId,
        payload: { tier: auth.tier },
      });

      return jsonResponse({ asset: data });
    }

    // list
    const entityType = body.entity_type as string | undefined;
    const limit = Math.min(Number(body.limit) || 50, 100);
    const offset = Number(body.offset) || 0;

    let q = db
      .from("vault_assets")
      .select(
        "id, entity_type, entity_id, source_platform, title_preview, "
        + "listing_id, listing_code, profile_id, import_id, captured_at, updated_at, "
        + "payload",
        { count: "exact" },
      )
      .order("updated_at", { ascending: false })
      .range(offset, offset + limit - 1);

    if (entityType) q = q.eq("entity_type", entityType);

    const { data, error, count } = await q;
    if (error) return jsonResponse({ error: error.message }, 400);

    const items = (data ?? []).map((row) => {
      const p = (row.payload as Record<string, unknown>) ?? {};
      return {
        id: row.id,
        entity_type: row.entity_type,
        entity_id: row.entity_id,
        source_platform: row.source_platform,
        title_preview: row.title_preview,
        listing_id: row.listing_id,
        listing_code: row.listing_code,
        profile_id: row.profile_id,
        import_id: row.import_id,
        captured_at: row.captured_at,
        updated_at: row.updated_at,
        has_phones: Array.isArray(p.phones) && (p.phones as unknown[]).length > 0 ||
          !!p.owner_phone,
        has_lines: Array.isArray(p.lines) && (p.lines as unknown[]).length > 0 ||
          !!p.owner_line,
        source_url: p.source_url ?? p.post_url ?? null,
      };
    });

    return jsonResponse({
      items,
      total: count ?? items.length,
      offset,
      limit,
    });
  } catch (e) {
    return jsonResponse({ error: String(e) }, 500);
  }
});
