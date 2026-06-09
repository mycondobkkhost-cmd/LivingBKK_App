import { requireAdmin } from "../_shared/admin_auth.ts";
import { corsHeaders, jsonResponse } from "../_shared/cors.ts";
import { matchProject } from "../_shared/li_parser.ts";
import {
  parseProjectFromUrl,
  slugifyProjectName,
} from "../_shared/project_parser.ts";
import { createServiceClient } from "../_shared/supabase_env.ts";
import { enrichProjectTags } from "../_shared/project_search_tag_enrich.ts";
import { transitAliases } from "../_shared/transit_proximity.ts";

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const auth = await requireAdmin(req);
    if (auth instanceof Response) return auth;

    const body = await req.json();
    const sourceUrl = (body.source_url as string | undefined)?.trim();
    const upsert = body.upsert !== false;

    if (!sourceUrl) {
      return jsonResponse({ error: "source_url required" }, 400);
    }

    const parsed = await parseProjectFromUrl(sourceUrl);
    const enriched = enrichProjectTags({
      lat: parsed.lat,
      lng: parsed.lng,
      name_th: parsed.nameTh,
      name_en: parsed.nameEn,
      description_th: parsed.descriptionTh,
      bts_station: parsed.btsStation,
      aliases: parsed.aliases,
    });
    const aliases = [
      ...new Set([...parsed.aliases, ...transitAliases(enriched.nearby_transit), ...enriched.aliases_extra]),
    ];
    const db = createServiceClient();

    if (!upsert) {
      return jsonResponse({ parsed, matched: null });
    }

    const existing = await matchProject(db, parsed.nameTh);
    const slug = existing?.slug as string | undefined ??
      slugifyProjectName(parsed.nameEn || parsed.nameTh);

    let geoZoneId: string | null = (existing?.geo_zone_id as string | null) ?? null;
    if (enriched.primary_geo_zone_slug) {
      const { data: gz } = await db
        .from("geo_zones")
        .select("id")
        .eq("slug", enriched.primary_geo_zone_slug)
        .maybeSingle();
      if (gz?.id) geoZoneId = gz.id as string;
    }

    const payload: Record<string, unknown> = {
      slug,
      name_th: parsed.nameTh,
      name_en: parsed.nameEn,
      district: parsed.district,
      bts_station: enriched.bts_station,
      nearby_transit: enriched.nearby_transit,
      search_tag_slugs: [...new Set([slug, ...enriched.search_tag_slugs])],
      tag_enrich_status: enriched.tag_enrich_status,
      tag_enrich_meta: enriched.tag_enrich_meta,
      geo_zone_id: geoZoneId,
      property_type: parsed.propertyType,
      lat: parsed.lat,
      lng: parsed.lng,
      aliases: aliases,
      year_built: parsed.yearBuilt,
      facilities: parsed.facilities,
      description_th: parsed.descriptionTh,
      cover_image_url: parsed.coverImageUrl,
      source_url: parsed.sourceUrl,
      source_platform: parsed.sourcePlatform,
      source_external_id: parsed.sourceExternalId,
      is_active: true,
      updated_by: auth.userId,
    };

    let project;
    if (existing?.id) {
      const { data, error } = await db
        .from("property_projects")
        .update(payload)
        .eq("id", existing.id)
        .select("*")
        .single();
      if (error) return jsonResponse({ error: error.message }, 400);
      project = data;
    } else {
      const { data, error } = await db
        .from("property_projects")
        .insert({ ...payload, created_by: auth.userId })
        .select("*")
        .single();
      if (error) return jsonResponse({ error: error.message }, 400);
      project = data;
    }

    await db.from("admin_audit_log").insert({
      actor_id: auth.userId,
      action: existing?.id ? "project.import_update" : "project.import_create",
      entity_type: "property_project",
      entity_id: project.id,
    }).catch(() => {});

    return jsonResponse({
      project,
      parsed,
      updated: Boolean(existing?.id),
    });
  } catch (e) {
    const msg = String(e);
    if (msg.includes("edge_config_missing")) {
      return jsonResponse({
        error: "edge_secrets_missing",
        detail: msg,
        hint: "รัน ./scripts/set-edge-secrets.sh",
      }, 500);
    }
    return jsonResponse({ error: msg }, 422);
  }
});
