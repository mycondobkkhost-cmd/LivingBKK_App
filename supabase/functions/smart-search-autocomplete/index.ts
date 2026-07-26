/**
 * POST /functions/v1/smart-search-autocomplete
 * Body: { "q": "ทอง", "limit": 10 }
 *
 * As-you-type suggestions: local catalog (projects, zones, transit) + Google Places fallback
 */
import { corsHeaders, jsonResponse } from "../_shared/cors.ts";
import { SmartSearchService } from "../_shared/smart_search_service.ts";

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST" && req.method !== "GET") {
    return jsonResponse({ error: "POST or GET required" }, 405);
  }

  try {
    let q: string | undefined;
    let limit = 10;

    if (req.method === "GET") {
      const url = new URL(req.url);
      q = url.searchParams.get("q") ?? undefined;
      limit = Number(url.searchParams.get("limit") ?? 10);
    } else {
      const body = await req.json();
      q = body?.q ?? body?.query;
      limit = typeof body?.limit === "number" ? body.limit : 10;
    }

    if (!q || typeof q !== "string") {
      return jsonResponse({ error: "q string required" }, 400);
    }

    const service = SmartSearchService.fromEnv();
    const suggestions = await service.autocomplete(q.trim(), Math.min(limit, 20));

    return jsonResponse({ q: q.trim(), suggestions });
  } catch (e) {
    console.error("smart-search-autocomplete error", e);
    return jsonResponse({ error: String(e) }, 500);
  }
});
