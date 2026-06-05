export type ChatIntentResult = {
  intent: "discovery" | "property_faq" | "sensitive" | "unknown";
  should_answer: boolean;
  needs_admin: boolean;
  reason?: string;
};

const SYSTEM = `You classify Thai/English messages in a Bangkok property rental/sale chat.
Return ONLY JSON:
{"intent":"discovery|property_faq|sensitive|unknown","should_answer":true|false,"needs_admin":true|false,"reason":"short Thai"}

Rules:
- sensitive: owner phone, negotiate price, unit number, floor, commission, contact outside platform
- discovery: find/recommend condos by area, budget, project, compare listings
- property_faq: general questions answerable without private data (pets, parking, net price policy)
- unknown: unclear; needs_admin if should not auto-answer
- should_answer=false or needs_admin=true when specific private info required`;

/** Optional LLM gate — only when rules/discovery did not match (~100 tokens). */
export async function classifyChatIntentOpenAI(
  text: string,
  hasListingContext: boolean,
): Promise<ChatIntentResult | null> {
  const key = Deno.env.get("OPENAI_API_KEY");
  if (!key || key.length < 10) return null;

  const model = Deno.env.get("OPENAI_MODEL") ?? "gpt-4o-mini";
  const user = hasListingContext
    ? `Listing context: yes\nMessage: ${text}`
    : `Listing context: no (general search)\nMessage: ${text}`;

  try {
    const res = await fetch("https://api.openai.com/v1/chat/completions", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${key}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model,
        temperature: 0,
        max_tokens: 120,
        response_format: { type: "json_object" },
        messages: [
          { role: "system", content: SYSTEM },
          { role: "user", content: user },
        ],
      }),
    });

    if (!res.ok) return null;
    const body = await res.json();
    const raw = body?.choices?.[0]?.message?.content;
    if (!raw || typeof raw !== "string") return null;

    const parsed = JSON.parse(raw);
    const intent = parsed.intent as string;
    const valid = ["discovery", "property_faq", "sensitive", "unknown"];
    if (!valid.includes(intent)) return null;

    return {
      intent: intent as ChatIntentResult["intent"],
      should_answer: parsed.should_answer === true,
      needs_admin: parsed.needs_admin === true,
      reason: typeof parsed.reason === "string" ? parsed.reason : undefined,
    };
  } catch {
    return null;
  }
}
