import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";
import { requireAdmin } from "../_shared/admin_auth.ts";
import { corsHeaders, jsonResponse } from "../_shared/cors.ts";
import { matchProject } from "../_shared/li_parser.ts";
import {
  discoverBangkokProjectSlugs,
  isMetroBangkokProject,
  isPropertyHubProjectUrl,
  parsePropertyHubProjectFromUrl,
  slugFromPropertyHubUrl,
} from "../_shared/propertyhub_parser.ts";

function serviceDb() {
  return createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );
}

async function upsertProject(
  db: ReturnType<typeof serviceDb>,
  parsed: Awaited<ReturnType<typeof parsePropertyHubProjectFromUrl>>,
  userId: string,
) {
  if (!isMetroBangkokProject({
    district: parsed.district,
    lat: parsed.lat,
    lng: parsed.lng,
  })) {
    throw new Error("outside_metro: โครงการอยู่นอก กทม.+ปริมณฑล");
  }

  const existing = await matchProject(db, parsed.nameTh) ??
    await matchProject(db, parsed.nameEn);

  const payload: Record<string, unknown> = {
    slug: parsed.slug,
    name_th: parsed.nameTh,
    name_en: parsed.nameEn,
    district: parsed.district,
    bts_station: parsed.btsStation,
    property_type: parsed.propertyType,
    lat: parsed.lat,
    lng: parsed.lng,
    aliases: parsed.aliases,
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
    const db = serviceDb();

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
      const results: Array<Record<string, unknown>> = [];
      let ok = 0;
      let fail = 0;

      for (const slug of slice) {
        const url = `https://propertyhub.in.th/projects/${slug}`;
        try {
          const parsed = await parsePropertyHubProjectFromUrl(url);
          const { project, updated } = await upsertProject(db, parsed, auth.userId);
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

    const parsed = await parsePropertyHubProjectFromUrl(
      sourceUrl.startsWith("http")
        ? sourceUrl
        : `https://propertyhub.in.th/projects/${slugFromPropertyHubUrl(sourceUrl) ?? body.slug}`,
    );
    const { project, updated } = await upsertProject(db, parsed, auth.userId);

    return jsonResponse({ project, parsed, updated });
  } catch (e) {
    return jsonResponse({ error: String(e) }, 422);
  }
});
