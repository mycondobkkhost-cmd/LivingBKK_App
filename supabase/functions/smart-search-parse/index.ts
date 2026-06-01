import { corsHeaders, jsonResponse } from "../_shared/cors.ts";

/**
 * Parses natural-language search into structured filters.
 * Wire OpenAI/Gemini in production; stub returns demo mapping for Sukhumvit-style queries.
 */
Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const { query } = await req.json();
    if (!query || typeof query !== "string") {
      return jsonResponse({ error: "query string required" }, 400);
    }

    const q = query.toLowerCase();
    const filters: Record<string, unknown> = {};
    const preview: { label: string; value: string }[] = [];

    if (/สุขุมวิท|sukhumvit|อโศก|asok|มศว/.test(q)) {
      filters.geo_zone_slugs = ["sukhumvit", "asok"];
      preview.push({ label: "ทำเล", value: "สุขุมวิท, อโศก" });
    }
    if (/ทองหล่อ|thonglor/.test(q)) {
      filters.geo_zone_slugs = ["thonglor"];
      preview.push({ label: "ทำเล", value: "ทองหล่อ" });
    }

    const priceMatch = q.match(/(\d+)\s*k|ไม่เกิน\s*(\d+)/);
    if (priceMatch) {
      const amount = Number(priceMatch[1] || priceMatch[2]) * (q.includes("k") ? 1000 : 1);
      filters.max_price_net = amount;
      preview.push({
        label: "งบ",
        value: `≤ ${amount.toLocaleString("th-TH")} บาท/เดือน`,
      });
    }

    if (/เลี้ยงสัตว์|pet/.test(q)) {
      filters.pet_allowed = true;
      preview.push({ label: "สัตว์เลี้ยง", value: "อนุญาต" });
    }

    if (/คอนโด|condo/.test(q)) {
      filters.property_type = "condo";
    }

    return jsonResponse({ query, filters, preview });
  } catch (e) {
    return jsonResponse({ error: String(e) }, 500);
  }
});
