import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";
import { corsHeaders, jsonResponse } from "../_shared/cors.ts";
import { feedFromModerationFlag } from "../_shared/admin_ai_feed.ts";
import { orchestrateAdminFeed } from "../_shared/admin_orchestrator.ts";

const PHONE_RE = /(0[689]\d[\s-]?\d{3}[\s-]?\d{4})|(\d{3}[-.\s]?\d{3}[-.\s]?\d{4})/;
const LINE_RE = /line\s*[@:ID]?\s*[@\w.]+/i;
const URL_RE = /https?:\/\/[^\s]+/gi;

const VALID_FLAG_TYPES = new Set([
  "phone",
  "line",
  "external_link",
  "duplicate_image",
]);

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const body = await req.json();
    const text = body.text as string | undefined;
    const listing_id = body.listing_id as string | undefined;
    const listing_code = body.listing_code as string | undefined;

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

    let persistedFlagId: string | null = null;

    if (flags.length > 0 && listing_id) {
      const db = createClient(
        Deno.env.get("SUPABASE_URL")!,
        Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
      );

      const primary = flags[0];
      const flagType = VALID_FLAG_TYPES.has(primary.type)
        ? primary.type
        : "external_link";

      const { data: flag } = await db
        .from("moderation_flags")
        .insert({
          listing_id,
          flag_type: flagType,
          raw_match: primary.match,
        })
        .select("id")
        .single();

      persistedFlagId = flag?.id as string ?? null;

      if (persistedFlagId) {
        let code = listing_code ?? null;
        if (!code) {
          const { data: listing } = await db
            .from("listings")
            .select("listing_code")
            .eq("id", listing_id)
            .maybeSingle();
          code = listing?.listing_code as string | null;
        }

        await orchestrateAdminFeed(
          db,
          "moderate-listing-text",
          feedFromModerationFlag({
            flagId: persistedFlagId,
            flagType,
            listingId: listing_id,
            listingCode: code,
            rawMatch: primary.match,
          }),
        );
      }
    }

    return jsonResponse({
      allowed: flags.length === 0,
      flags,
      flag_id: persistedFlagId,
      message:
        flags.length > 0
          ? "พบข้อมูลติดต่อหรือลิงก์ภายนอก กรุณาลบก่อนเผยแพร่"
          : null,
    });
  } catch (e) {
    return jsonResponse({ error: String(e) }, 500);
  }
});
