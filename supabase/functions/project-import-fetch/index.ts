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

function mergeStringLists(...lists: unknown[]): string[] {
  const set = new Set<string>();
  for (const list of lists) {
    if (!Array.isArray(list)) continue;
    for (const raw of list) {
      const s = String(raw ?? "").trim();
      if (s) set.add(s);
    }
  }
  return [...set];
}

function isPropertyHubMaster(row: Record<string, unknown> | null | undefined): boolean {
  return String(row?.source_platform ?? "") === "propertyhub";
}

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
    const db = createServiceClient();

    if (!upsert) {
      return jsonResponse({ parsed, matched: null });
    }

    const existing = await matchProject(db, parsed.nameTh) as
      | Record<string, unknown>
      | null;
    // When enriching a PH master, load full row for merge-safe fields
    let existingFull: Record<string, unknown> | null = existing;
    if (existing?.id) {
      const { data } = await db
        .from("property_projects")
        .select(
          "id, slug, name_th, name_en, district, lat, lng, geo_zone_id, bts_station, nearby_transit, aliases, source_platform, source_url, source_external_id, property_type, year_built, facilities, description_th, cover_image_url, search_tag_slugs",
        )
        .eq("id", existing.id)
        .maybeSingle();
      if (data) existingFull = data as Record<string, unknown>;
    }

    const phMaster = isPropertyHubMaster(existingFull);
    const slug = (existingFull?.slug as string | undefined)?.trim() ||
      slugifyProjectName(parsed.nameEn || parsed.nameTh);

    let geoZoneId: string | null =
      (existingFull?.geo_zone_id as string | null) ?? null;
    if (enriched.primary_geo_zone_slug) {
      const { data: gz } = await db
        .from("geo_zones")
        .select("id")
        .eq("slug", enriched.primary_geo_zone_slug)
        .maybeSingle();
      if (gz?.id) geoZoneId = gz.id as string;
    }

    const incomingAliases = mergeStringLists(
      parsed.aliases,
      transitAliases(enriched.nearby_transit),
      enriched.aliases_extra,
      // Keep LI spelling as searchable alias — never as master name when PH exists
      phMaster ? [parsed.nameTh, parsed.nameEn] : [],
    );

    const existingLat = existingFull?.lat as number | null | undefined;
    const existingLng = existingFull?.lng as number | null | undefined;
    const useIncomingCoords =
      parsed.lat != null &&
      parsed.lng != null &&
      (existingLat == null || existingLng == null || !phMaster);

    const payload: Record<string, unknown> = {
      slug,
      // Property Hub keeps canonical names; LI may only add aliases
      name_th: phMaster
        ? existingFull!.name_th
        : (existingFull?.name_th ?? parsed.nameTh),
      name_en: phMaster
        ? existingFull!.name_en
        : (existingFull?.name_en ?? parsed.nameEn),
      district: (existingFull?.district as string | undefined)?.trim()
        ? existingFull!.district
        : parsed.district,
      bts_station: existingFull?.bts_station || enriched.bts_station,
      nearby_transit: mergeStringLists(
        existingFull?.nearby_transit,
        enriched.nearby_transit,
      ),
      search_tag_slugs: mergeStringLists(
        existingFull?.search_tag_slugs,
        [slug],
        enriched.search_tag_slugs,
      ),
      tag_enrich_status: enriched.tag_enrich_status,
      tag_enrich_meta: enriched.tag_enrich_meta,
      geo_zone_id: geoZoneId,
      property_type: existingFull?.property_type ?? parsed.propertyType,
      lat: useIncomingCoords ? parsed.lat : (existingLat ?? parsed.lat),
      lng: useIncomingCoords ? parsed.lng : (existingLng ?? parsed.lng),
      aliases: mergeStringLists(existingFull?.aliases, incomingAliases),
      year_built: existingFull?.year_built ?? parsed.yearBuilt,
      facilities: mergeStringLists(existingFull?.facilities, parsed.facilities),
      description_th: existingFull?.description_th ?? parsed.descriptionTh,
      cover_image_url: existingFull?.cover_image_url ?? parsed.coverImageUrl,
      source_url: phMaster
        ? (existingFull?.source_url ?? parsed.sourceUrl)
        : parsed.sourceUrl,
      source_platform: phMaster
        ? "propertyhub"
        : (existingFull?.source_platform ?? parsed.sourcePlatform),
      source_external_id: phMaster
        ? (existingFull?.source_external_id ?? parsed.sourceExternalId)
        : parsed.sourceExternalId,
      is_active: true,
      updated_by: auth.userId,
    };

    let project;
    if (existingFull?.id) {
      const { data, error } = await db
        .from("property_projects")
        .update(payload)
        .eq("id", existingFull.id)
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
      action: existingFull?.id
        ? (phMaster ? "project.li_enrich_ph_master" : "project.import_update")
        : "project.import_create",
      entity_type: "property_project",
      entity_id: project.id,
    }).catch(() => {});

    return jsonResponse({
      project,
      parsed,
      updated: Boolean(existingFull?.id),
      ph_name_preserved: phMaster,
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
