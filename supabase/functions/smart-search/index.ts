/**
 * POST /functions/v1/smart-search
 * Body: { "query": "หาคอนโดแถวทองหล่อ ใกล้ BTS ไม่เกิน 5 ล้าน", "limit": 50, "offset": 0 }
 *
 * Full Smart Search pipeline:
 *   OpenAI parse → Location enrichment (DB + Google) → Hybrid PostGIS query + ranking
 */
import { corsHeaders, jsonResponse } from "../_shared/cors.ts";
import { SmartSearchService } from "../_shared/smart_search_service.ts";

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return jsonResponse({ error: "POST required" }, 405);
  }

  try {
    const body = await req.json();
    const query = body?.query;
    if (!query || typeof query !== "string") {
      return jsonResponse({ error: "query string required" }, 400);
    }

    const limit = typeof body.limit === "number" ? body.limit : 50;
    const offset = typeof body.offset === "number" ? body.offset : 0;

    const service = SmartSearchService.fromEnv();
    const result = await service.search(query, { limit, offset });

    return jsonResponse(result);
  } catch (e) {
    console.error("smart-search error", e);
    return jsonResponse({ error: String(e) }, 500);
  }
});
