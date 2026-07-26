import { requireAdmin } from "../_shared/admin_auth.ts";
import { corsHeaders, jsonResponse } from "../_shared/cors.ts";
import { geocodeProjectByName } from "../_shared/google_geocode.ts";
import {
  looksLikeMapsUrl,
  resolveAndParseCoords,
} from "../_shared/google_maps_share_url.ts";

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const auth = await requireAdmin(req);
    if (auth instanceof Response) return auth;

    const body = await req.json();
    const url = (body.url as string | undefined)?.trim() ?? "";
    const projectName = (body.project_name as string | undefined)?.trim() ?? "";
    const hintDistrict = (body.hint_district as string | undefined)?.trim() ?? null;

    const hasLink = url.length > 0 && looksLikeMapsUrl(url);
    if (!hasLink && projectName.length < 2) {
      return jsonResponse({ error: "invalid_maps_url" }, 400);
    }

    if (hasLink) {
      const hit = await resolveAndParseCoords(url);
      if (hit) {
        return jsonResponse({
          result: { ...hit, source: "maps_link" },
        });
      }
    }

    if (projectName.length >= 2) {
      const hasKey = Boolean(Deno.env.get("GOOGLE_MAPS_API_KEY")?.trim());
      if (!hasKey) {
        return jsonResponse({
          error: "google_maps_key_missing",
          google_maps_key_missing: true,
        }, 503);
      }

      const geo = await geocodeProjectByName(projectName, hintDistrict);
      if (geo) {
        return jsonResponse({
          result: {
            lat: geo.lat,
            lng: geo.lng,
            resolved_url: geo.placeId
              ? `https://www.google.com/maps/place/?q=place_id:${geo.placeId}`
              : (hasLink ? url : ""),
            place_name: geo.name.trim() || projectName,
            name_th: projectName,
            name_en: geo.name.trim() || projectName,
            district: geo.district ?? hintDistrict ?? "กรุงเทพฯ",
            source: "geocode_fallback",
          },
        });
      }

      return jsonResponse({ error: "geocode_not_found" }, 404);
    }

    if (hasLink) {
      return jsonResponse({ error: "no_coords_in_link" }, 404);
    }

    return jsonResponse({ error: "invalid_maps_url" }, 400);
  } catch (e) {
    return jsonResponse({ error: String(e) }, 500);
  }
});
