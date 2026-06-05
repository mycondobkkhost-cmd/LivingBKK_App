import { corsHeaders, jsonResponse } from "../_shared/cors.ts";
import { parseSearchOpenAI } from "../_shared/search_parse_openai.ts";
import { parseSearchStub } from "../_shared/search_parse_stub.ts";

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const { query } = await req.json();
    if (!query || typeof query !== "string") {
      return jsonResponse({ error: "query string required" }, 400);
    }

    const ai = await parseSearchOpenAI(query.trim());
    const stub = parseSearchStub(query);
    const source = ai && Object.keys(ai.filters).length > 0 ? "openai" : "rules";

    const filters = { ...stub.filters, ...(ai?.filters ?? {}) };
    const preview = [
      ...stub.preview,
      ...(ai?.preview ?? []).filter(
        (p) => !stub.preview.some((s) => s.label === p.label && s.value === p.value),
      ),
    ];

    return jsonResponse({
      query,
      filters,
      preview,
      source,
    });
  } catch (e) {
    return jsonResponse({ error: String(e) }, 500);
  }
});
