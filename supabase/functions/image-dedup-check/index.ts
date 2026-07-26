import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";
import { corsHeaders, jsonResponse } from "../_shared/cors.ts";
import { feedFromModerationFlag } from "../_shared/admin_ai_feed.ts";
import { orchestrateAdminFeed } from "../_shared/admin_orchestrator.ts";

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const { listing_id, perceptual_hash } = await req.json();
    if (!listing_id || !perceptual_hash) {
      return jsonResponse({ error: "listing_id and perceptual_hash required" }, 400);
    }

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );

    const { data: dupes } = await supabase
      .from("listing_images")
      .select("id, listing_id")
      .eq("perceptual_hash", perceptual_hash)
      .neq("listing_id", listing_id)
      .limit(3);

    const duplicate = (dupes?.length ?? 0) > 0;
    let flagId: string | null = null;

    if (duplicate) {
      const { data: flag } = await supabase
        .from("moderation_flags")
        .insert({
          listing_id,
          flag_type: "duplicate_image",
          raw_match: perceptual_hash,
        })
        .select("id")
        .single();
      flagId = flag?.id as string ?? null;

      await supabase
        .from("listing_images")
        .update({ moderation_status: "pending" })
        .eq("listing_id", listing_id);

      if (flagId) {
        const { data: listing } = await supabase
          .from("listings")
          .select("listing_code")
          .eq("id", listing_id)
          .maybeSingle();

        await orchestrateAdminFeed(
          supabase,
          "image-dedup-check",
          feedFromModerationFlag({
            flagId,
            flagType: "duplicate_image",
            listingId: listing_id,
            listingCode: listing?.listing_code as string | null,
            rawMatch: perceptual_hash,
          }),
        );
      }
    }

    return jsonResponse({ duplicate, matches: dupes?.length ?? 0, flag_id: flagId });
  } catch (e) {
    return jsonResponse({ error: String(e) }, 500);
  }
});
