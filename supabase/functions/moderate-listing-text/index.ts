import { corsHeaders, jsonResponse } from "../_shared/cors.ts";

const PHONE_RE = /(0[689]\d[\s-]?\d{3}[\s-]?\d{4})|(\d{3}[-.\s]?\d{3}[-.\s]?\d{4})/;
const LINE_RE = /line\s*[@:ID]?\s*[@\w.]+/i;
const URL_RE = /https?:\/\/[^\s]+/gi;

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const { text } = await req.json();
    if (!text) {
      return jsonResponse({ error: "text required" }, 400);
    }

    const flags: { type: string; match: string }[] = [];

    const phone = text.match(PHONE_RE);
    if (phone) flags.push({ type: "phone", match: phone[0] });

    const line = text.match(LINE_RE);
    if (line) flags.push({ type: "line", match: line[0] });

    const urls = text.match(URL_RE);
    if (urls) {
      for (const u of urls) {
        flags.push({ type: "external_link", match: u });
      }
    }

    return jsonResponse({
      allowed: flags.length === 0,
      flags,
      message:
        flags.length > 0
          ? "พบข้อมูลติดต่อหรือลิงก์ภายนอก กรุณาลบก่อนเผยแพร่"
          : null,
    });
  } catch (e) {
    return jsonResponse({ error: String(e) }, 500);
  }
});
