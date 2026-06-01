import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";
import { corsHeaders, jsonResponse } from "../_shared/cors.ts";

const CAPACITIES = ["owner_direct_100", "co_agent_50_50", "listing_agent"] as const;

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return jsonResponse({ error: "Unauthorized" }, 401);
    }

    const body = await req.json();
    const {
      demand_post_id,
      offerer_capacity,
      offer_type,
      title,
      description,
      price_net,
      area_sqm,
      bedrooms,
      external_url,
      external_note,
    } = body;

    if (!demand_post_id || !offerer_capacity || !offer_type) {
      return jsonResponse(
        { error: "demand_post_id, offerer_capacity, offer_type required" },
        400,
      );
    }

    if (!CAPACITIES.includes(offerer_capacity)) {
      return jsonResponse({ error: "Invalid offerer_capacity" }, 400);
    }

    if (offer_type === "external_link" && !external_url) {
      return jsonResponse({ error: "external_url required for link offers" }, 400);
    }

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_ANON_KEY")!,
      { global: { headers: { Authorization: authHeader } } },
    );

    const { data: userData, error: userError } = await supabase.auth.getUser();
    if (userError || !userData.user) {
      return jsonResponse({ error: "Unauthorized" }, 401);
    }

    const { data: profile } = await supabase
      .from("profiles")
      .select("role")
      .eq("id", userData.user.id)
      .single();

    const { data: post } = await supabase
      .from("demand_posts")
      .select("id, status")
      .eq("id", demand_post_id)
      .single();

    if (!post || post.status !== "open") {
      return jsonResponse({ error: "Demand post not open" }, 400);
    }

    const { data: offer, error: insertError } = await supabase
      .from("demand_offers")
      .insert({
        demand_post_id,
        offerer_id: userData.user.id,
        offerer_capacity,
        offerer_app_role: profile?.role ?? "seeker",
        offer_type,
        title,
        description,
        price_net,
        area_sqm,
        bedrooms,
        external_url,
        external_note,
      })
      .select("id, status, created_at")
      .single();

    if (insertError) {
      return jsonResponse({ error: insertError.message }, 400);
    }

    return jsonResponse({ success: true, offer });
  } catch (e) {
    return jsonResponse({ error: String(e) }, 500);
  }
});
