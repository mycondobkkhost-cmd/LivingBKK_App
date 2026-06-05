import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";
import { corsHeaders, jsonResponse } from "../_shared/cors.ts";

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

    if (duplicate) {
      await supabase.from("moderation_flags").insert({
        listing_id,
        flag_type: "duplicate_image",
        raw_match: perceptual_hash,
      });
      await supabase
        .from("listing_images")
        .update({ moderation_status: "pending" })
        .eq("listing_id", listing_id);
    }

    return jsonResponse({ duplicate, matches: dupes?.length ?? 0 });
  } catch (e) {
    return jsonResponse({ error: String(e) }, 500);
  }
});
