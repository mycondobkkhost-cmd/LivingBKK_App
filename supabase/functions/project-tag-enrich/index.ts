import { requireAdmin } from "../_shared/admin_auth.ts";
import { corsHeaders, jsonResponse } from "../_shared/cors.ts";
import { enrichProjectTags } from "../_shared/project_search_tag_enrich.ts";
import { createServiceClient } from "../_shared/supabase_env.ts";

/** เก็บเฉพาะ alias ชื่อโครงการ — ไม่เก็บชื่อสถานี (สถานีอยู่ที่ nearby_transit) */
function rebuildNameAliases(
  row: Record<string, unknown>,
  nearbyTransit: string[],
): string[] {
  const transitTokens = new Set<string>();
  for (const label of nearbyTransit) {
    transitTokens.add(label);
    transitTokens.add(label.replace(/^(BTS|MRT|ARL|Gold)\s+/, ""));
  }
  // common station names that must never stay in aliases unless we re-add via coords elsewhere
  const banned = [
    "อ่อนนุช", "อโศก", "อารีย์", "นานา", "สยาม", "ทองหล่อ", "เอกมัย",
    "พร้อมพงษ์", "บางจาก", "สุขุมวิท", "สีลม", "ลาดพร้าว", "ห้วยขวาง",
    "On Nut", "Asok", "Ari", "Nana", "Siam", "Thong Lo", "Ekkamai",
  ];
  for (const b of banned) transitTokens.add(b);

  const isTransit = (v: string) => {
    const t = v.trim();
    if (!t) return true;
    if (/^(BTS|MRT|ARL|Gold)\s+/i.test(t)) return true;
    if (transitTokens.has(t)) return true;
    return false;
  };

  const out: string[] = [];
  const add = (v: unknown) => {
    if (typeof v !== "string") return;
    const s = v.trim();
    if (!s || isTransit(s) || out.includes(s)) return;
    out.push(s);
  };

  add(row.name_th);
  add(row.name_en);
  if (typeof row.slug === "string") {
    add(row.slug);
    add(row.slug.replace(/-/g, " "));
  }
  for (const a of (row.aliases as string[]) ?? []) {
    add(a);
  }
  return out;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const auth = await requireAdmin(req);
    if (auth instanceof Response) return auth;

    const body = await req.json().catch(() => ({}));
    const projectId = body.project_id as string | undefined;
    const mode = (body.mode as string | undefined) ?? "bulk";
    const limit = Math.min(Number(body.limit) || 200, 500);
    const offset = Number(body.offset) || 0;

    const db = createServiceClient();

    const zoneRows = await db.from("geo_zones").select("id, slug");
    const zoneBySlug = new Map<string, string>();
    for (const z of zoneRows.data ?? []) {
      zoneBySlug.set(z.slug as string, z.id as string);
    }

    let query = db
      .from("property_projects")
      .select(
        "id, slug, name_th, name_en, district, lat, lng, bts_station, aliases, description_th, geo_zone_id",
      )
      .order("name_th");

    if (projectId) {
      query = query.eq("id", projectId);
    } else if (mode === "bulk") {
      query = query.range(offset, offset + limit - 1);
    }

    const { data: rows, error } = await query;
    if (error) return jsonResponse({ error: error.message }, 400);
    if (!rows?.length) {
      return jsonResponse({ updated: 0, results: [], done: true });
    }

    const results: Record<string, unknown>[] = [];

    for (const row of rows) {
      const enriched = enrichProjectTags({
        lat: row.lat as number,
        lng: row.lng as number,
        name_th: row.name_th as string,
        name_en: row.name_en as string,
        slug: row.slug as string,
        district: row.district as string,
        description_th: row.description_th as string | null,
        bts_station: row.bts_station as string | null,
        aliases: (row.aliases as string[]) ?? [],
      });

      const geoSlug = enriched.primary_geo_zone_slug;
      const geoZoneId = geoSlug ? zoneBySlug.get(geoSlug) ?? row.geo_zone_id : row.geo_zone_id;

      const cleanedAliases = rebuildNameAliases(row, enriched.nearby_transit);

      const { error: updErr } = await db
        .from("property_projects")
        .update({
          search_tag_slugs: enriched.search_tag_slugs,
          nearby_transit: enriched.nearby_transit,
          bts_station: enriched.bts_station,
          aliases: cleanedAliases,
          geo_zone_id: geoZoneId,
          tag_enrich_status: enriched.tag_enrich_status,
          tag_enrich_meta: enriched.tag_enrich_meta,
          updated_by: auth.userId,
        })
        .eq("id", row.id);

      results.push({
        id: row.id,
        slug: row.slug,
        status: enriched.tag_enrich_status,
        tags: enriched.search_tag_slugs,
        error: updErr?.message,
      });
    }

    const updated = results.filter((r) => !r.error).length;
    const needsReview = results.filter((r) => r.status === "needs_review").length;

    return jsonResponse({
      updated,
      needs_review: needsReview,
      results,
      next_offset: projectId ? null : offset + rows.length,
      done: projectId ? true : rows.length < limit,
    });
  } catch (e) {
    return jsonResponse({ error: String(e) }, 500);
  }
});
