import { requireAdmin } from "../_shared/admin_auth.ts";
import { corsHeaders, jsonResponse } from "../_shared/cors.ts";
import { geocodeProjectByName } from "../_shared/google_geocode.ts";

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const auth = await requireAdmin(req);
    if (auth instanceof Response) return auth;

    const body = await req.json();
    const projectName = (body.project_name as string | undefined)?.trim() ?? "";
    const hintDistrict = (body.hint_district as string | undefined)?.trim() ?? null;

    if (projectName.length < 2) {
      return jsonResponse({ error: "project_name required" }, 400);
    }

    const hit = await geocodeProjectByName(projectName, hintDistrict);
    if (!hit) {
      const hasKey = Boolean(Deno.env.get("GOOGLE_MAPS_API_KEY")?.trim());
      return jsonResponse({
        error: hasKey
          ? "ไม่พบโครงการบน Google Maps — ลองชื่ออื่นหรือใส่พิกัดเอง"
          : "ยังไม่ได้ตั้ง GOOGLE_MAPS_API_KEY บน Supabase Edge",
        google_maps_key_missing: !hasKey,
      }, 404);
    }

    return jsonResponse({
      preview: {
        name_th: projectName,
        name_en: hit.name.trim() || projectName,
        formatted_address: hit.formattedAddress,
        district: hit.district ?? hintDistrict ?? "กรุงเทพฯ",
        lat: hit.lat,
        lng: hit.lng,
        place_id: hit.placeId,
        maps_url: hit.placeId
          ? `https://www.google.com/maps/place/?q=place_id:${hit.placeId}`
          : null,
      },
    });
  } catch (e) {
    return jsonResponse({ error: String(e) }, 500);
  }
});
