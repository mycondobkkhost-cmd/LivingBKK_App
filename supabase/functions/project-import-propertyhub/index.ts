import type { SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";
import { requireAdmin } from "../_shared/admin_auth.ts";
import { corsHeaders, jsonResponse } from "../_shared/cors.ts";
import { matchProject } from "../_shared/li_parser.ts";
import { createServiceClient } from "../_shared/supabase_env.ts";
import {
  discoverBangkokProjectSlugs,
  isMetroBangkokProject,
  isPropertyHubProjectUrl,
  parsePropertyHubProjectFromUrl,
  slugFromPropertyHubUrl,
} from "../_shared/propertyhub_parser.ts";

function mergeAliases(
  base: unknown,
  incoming: string[],
  extras: string[] = [],
): string[] {
  const set = new Set<string>();
  if (Array.isArray(base)) {
    for (const a of base) {
      const s = String(a).trim();
      if (s) set.add(s);
    }
  }
  for (const raw of [...incoming, ...extras]) {
    const s = (raw ?? "").trim();
    if (s) set.add(s);
  }
  return [...set].sort();
}

async function upsertProject(
  db: SupabaseClient,
  parsed: Awaited<ReturnType<typeof parsePropertyHubProjectFromUrl>>,
  userId: string,
  options?: { allowAllRegions?: boolean },
) {
  const allowAll = options?.allowAllRegions === true;
  if (
    !allowAll &&
    !isMetroBangkokProject({
      district: parsed.district,
      lat: parsed.lat,
      lng: parsed.lng,
    })
  ) {
    throw new Error("outside_metro: โครงการอยู่นอก กทม.+ปริมณฑล");
  }

  const { data: bySlug } = await db
    .from("property_projects")
    .select("id, slug, name_th, name_en, aliases")
    .eq("slug", parsed.slug)
    .maybeSingle();

  const existing = (bySlug as Record<string, unknown> | null) ??
    (await matchProject(db, parsed.nameTh)) ??
    (await matchProject(db, parsed.nameEn));

  const payload: Record<string, unknown> = {
    slug: parsed.slug,
    name_th: parsed.nameTh,
    name_en: parsed.nameEn,
    district: parsed.district,
    bts_station: parsed.btsStation,
    nearby_transit: parsed.nearbyTransit ?? [],
    property_type: parsed.propertyType,
    lat: parsed.lat,
    lng: parsed.lng,
    aliases: mergeAliases([], parsed.aliases ?? [], [parsed.slug]),
    year_built: parsed.yearBuilt,
    facilities: parsed.facilities,
    cover_image_url: parsed.coverImageUrl,
    description_th: parsed.descriptionTh,
    description_en: parsed.descriptionEn,
    source_url: parsed.sourceUrl,
    source_platform: "propertyhub",
    source_external_id: parsed.sourceExternalId,
    is_active: true,
    updated_by: userId,
  };

  if (existing?.id) {
    const keepSlug =
      (typeof existing.slug === "string" && existing.slug.trim()) ||
      parsed.slug;
    const aliasExtras: string[] = [];
    if (parsed.slug && parsed.slug !== keepSlug) {
      aliasExtras.push(parsed.slug);
    }
    payload.slug = keepSlug;
    payload.aliases = mergeAliases(
      existing.aliases,
      parsed.aliases ?? [],
      aliasExtras,
    );
    const { data, error } = await db
      .from("property_projects")
      .update(payload)
      .eq("id", existing.id)
      .select("*")
      .single();
    if (error) throw new Error(error.message);
    return { project: data, updated: true };
  }

  const { data, error } = await db
    .from("property_projects")
    .insert({ ...payload, created_by: userId })
    .select("*")
    .single();
  if (error) throw new Error(error.message);
  return { project: data, updated: false };
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const auth = await requireAdmin(req);
    if (auth instanceof Response) return auth;

    const body = await req.json();
    const mode = (body.mode as string | undefined) ?? "url";
    const db = createServiceClient();

    if (mode === "discover") {
      const slugs = await discoverBangkokProjectSlugs(
        typeof body.max_zones === "number" ? body.max_zones : undefined,
      );
      return jsonResponse({
        count: slugs.length,
        slugs,
        scope: "bangkok_metro_only",
        hint: slugs.length < 500
          ? "ใช้ scripts/discover-propertyhub-slugs.py (กทม.+ปริมณฑลเท่านั้น) แล้ว sync-propertyhub-cloud.sh"
          : undefined,
      });
    }

    if (mode === "purge_all") {
      const confirm = body.confirm === true;
      if (!confirm) {
        return jsonResponse({
          error: "confirm_required",
          hint: "ส่ง { mode: purge_all, confirm: true } — ลบโครงการทั้งหมดแล้วดึงใหม่",
        }, 400);
      }

      const { count: linkedCount, error: countErr } = await db
        .from("listings")
        .select("id", { count: "exact", head: true })
        .not("project_id", "is", null);
      if (countErr) throw new Error(countErr.message);

      const { error: unlinkErr } = await db
        .from("listings")
        .update({ project_id: null })
        .not("project_id", "is", null);
      if (unlinkErr) throw new Error(unlinkErr.message);

      const { count: projectCount, error: projCountErr } = await db
        .from("property_projects")
        .select("id", { count: "exact", head: true });
      if (projCountErr) throw new Error(projCountErr.message);

      const { error: delErr } = await db
        .from("property_projects")
        .delete()
        .neq("id", "00000000-0000-0000-0000-000000000000");
      if (delErr) throw new Error(delErr.message);

      return jsonResponse({
        purged: true,
        projects_deleted: projectCount ?? 0,
        listings_unlinked: linkedCount ?? 0,
        scope: "bangkok_metro_only",
        next: "รัน scripts/full-resync-propertyhub.sh หรือกดดึงทั้งหมดในแอป",
      });
    }

    if (mode === "deactivate_non_metro") {
      const { data: rows, error } = await db
        .from("property_projects")
        .select("id, slug, name_th, district, lat, lng, is_active")
        .eq("is_active", true);
      if (error) throw new Error(error.message);

      let deactivated = 0;
      for (const row of rows ?? []) {
        const ok = isMetroBangkokProject({
          district: row.district as string,
          lat: row.lat as number,
          lng: row.lng as number,
          address: row.name_th as string,
        });
        if (ok) continue;
        const { error: upErr } = await db
          .from("property_projects")
          .update({ is_active: false, updated_by: auth.userId })
          .eq("id", row.id);
        if (!upErr) deactivated++;
      }
      return jsonResponse({
        checked: rows?.length ?? 0,
        deactivated,
        scope: "bangkok_metro_only",
      });
    }

    if (mode === "validate_slugs") {
      const slugs = (body.slugs as string[] | undefined) ?? [];
      const limit = Math.min(typeof body.limit === "number" ? body.limit : 30, 40);
      const slice = slugs.slice(0, limit);
      const valid: string[] = [];
      const invalid: Array<{ slug: string; error: string }> = [];

      for (const slug of slice) {
        const url = `https://propertyhub.in.th/projects/${slug}`;
        try {
          const parsed = await parsePropertyHubProjectFromUrl(url);
          if (!isMetroBangkokProject({
            district: parsed.district,
            lat: parsed.lat,
            lng: parsed.lng,
          })) {
            invalid.push({ slug, error: "outside_metro" });
            continue;
          }
          valid.push(slug);
        } catch (e) {
          invalid.push({ slug, error: String(e).slice(0, 120) });
        }
        await new Promise((r) => setTimeout(r, 200));
      }

      return jsonResponse({
        checked: slice.length,
        valid,
        invalid,
        remaining: Math.max(0, slugs.length - slice.length),
        scope: "bangkok_metro_only",
      });
    }

    if (mode === "batch") {
      const slugs = (body.slugs as string[] | undefined) ?? [];
      const limit = Math.min(typeof body.limit === "number" ? body.limit : 20, 30);
      const slice = slugs.slice(0, limit);
      const allowAllRegions =
        body.allow_all_regions === true || body.import_scope === "all";
      const results: Array<Record<string, unknown>> = [];
      let ok = 0;
      let fail = 0;

      for (const slug of slice) {
        const url = `https://propertyhub.in.th/projects/${slug}`;
        try {
          const parsed = await parsePropertyHubProjectFromUrl(url);
          const { project, updated } = await upsertProject(db, parsed, auth.userId, {
            allowAllRegions: allowAllRegions,
          });
          ok++;
          results.push({ slug, ok: true, updated, id: project.id });
        } catch (e) {
          fail++;
          results.push({ slug, ok: false, error: String(e).slice(0, 200) });
        }
        await new Promise((r) => setTimeout(r, 300));
      }

      return jsonResponse({ ok, fail, remaining: Math.max(0, slugs.length - slice.length), results });
    }

    const sourceUrl = (body.source_url as string | undefined)?.trim();
    if (!sourceUrl) {
      return jsonResponse({ error: "source_url required (or mode=discover|batch)" }, 400);
    }

    if (!isPropertyHubProjectUrl(sourceUrl)) {
      return jsonResponse({
        error: "รองรับเฉพาะลิงก์ propertyhub.in.th/projects/... เท่านั้น",
      }, 400);
    }

    const normalizedUrl = sourceUrl.startsWith("http")
      ? sourceUrl
      : `https://propertyhub.in.th/projects/${slugFromPropertyHubUrl(sourceUrl) ?? body.slug}`;

    const parsed = await parsePropertyHubProjectFromUrl(normalizedUrl);

    if (body.mode === "parse" || body.parse_only === true) {
      return jsonResponse({ parsed });
    }

    const allowAllRegions =
      body.allow_all_regions === true || body.import_scope === "all";
    const { project, updated } = await upsertProject(db, parsed, auth.userId, {
      allowAllRegions: allowAllRegions,
    });

    return jsonResponse({ project, parsed, updated });
  } catch (e) {
    const msg = String(e);
    if (msg.includes("edge_config_missing")) {
      return jsonResponse({
        error: "edge_secrets_missing",
        detail: msg,
        hint: "รัน ./scripts/set-edge-secrets.sh หลังใส่ SUPABASE_SERVICE_ROLE_KEY ใน .env.local",
      }, 500);
    }
    return jsonResponse({ error: msg }, 422);
  }
});
