import { corsHeaders, jsonResponse } from "../_shared/cors.ts";

const REQUIRED_FIELDS = [
  "listing_code",
  "seeker_nickname",
  "seeker_phone",
  "occupants_count",
  "gender",
  "occupation",
  "workplace",
  "move_plan",
  "contract_duration",
  "budget",
] as const;

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const { step, collected } = await req.json();
    const data = collected ?? {};
    const missing = REQUIRED_FIELDS.filter((f) => !data[f]);

    if (missing.length === 0) {
      return jsonResponse({
        complete: true,
        message: "ข้อมูลครบแล้ว พร้อมส่งคำขอ",
        next_field: null,
      });
    }

    return jsonResponse({
      complete: false,
      step: step ?? 1,
      next_field: missing[0],
      missing_count: missing.length,
      message: `กรุณากรอก: ${missing[0]}`,
    });
  } catch (e) {
    return jsonResponse({ error: String(e) }, 500);
  }
});
