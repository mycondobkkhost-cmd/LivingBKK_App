import type { SearchParseResult } from "./search_parse_stub.ts";

const SYSTEM = `You parse Thai/English property search queries for Bangkok metro rentals/sales.
Return ONLY valid JSON: {"filters":{...},"preview":[{"label":"...","value":"..."}]}
filters keys (optional): geo_zone_slugs (array of: sukhumvit, asok, thonglor, bangna),
listing_type (rent|sale), property_type (condo|house|townhome),
max_price_net (number THB/month), min_yield (number), pet_allowed (boolean),
co_agent_eligible (boolean), investor_category (with_tenant|bmv), project_name (string).
preview: Thai labels ทำเล, งบ, สัตว์เลี้ยง, ธุรกรรม, Co-Agent, นักลงทุน, Yield, โครงการ.`;

export async function parseSearchOpenAI(query: string): Promise<SearchParseResult | null> {
  const key = Deno.env.get("OPENAI_API_KEY");
  if (!key || key.length < 10) return null;

  const model = Deno.env.get("OPENAI_MODEL") ?? "gpt-4o-mini";

  const res = await fetch("https://api.openai.com/v1/chat/completions", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${key}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      model,
      temperature: 0.1,
      response_format: { type: "json_object" },
      messages: [
        { role: "system", content: SYSTEM },
        { role: "user", content: query },
      ],
    }),
  });

  if (!res.ok) {
    console.error("OpenAI error", await res.text());
    return null;
  }

  const body = await res.json();
  const text = body?.choices?.[0]?.message?.content;
  if (!text || typeof text !== "string") return null;

  try {
    const parsed = JSON.parse(text);
    return {
      filters: (parsed.filters as Record<string, unknown>) ?? {},
      preview: Array.isArray(parsed.preview) ? parsed.preview : [],
    };
  } catch {
    return null;
  }
}
