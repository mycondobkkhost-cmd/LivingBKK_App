import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";
import { corsHeaders, jsonResponse } from "../_shared/cors.ts";

const CAPACITIES = [
  "owner_direct_100",
  "co_agent_50_50",
  "referrer_15",
  "listing_agent",
] as const;

const TRANSACTION_TYPES = ["rent", "sale"] as const;

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
      transaction_type,
      title,
      description,
      price_net,
      price_max_net,
      transfer_terms,
      commission_scheme,
      commission_note,
      contact_name,
      contact_phone,
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

    if (transaction_type && !TRANSACTION_TYPES.includes(transaction_type)) {
      return jsonResponse({ error: "Invalid transaction_type" }, 400);
    }

    if (transaction_type === "sale" && !transfer_terms) {
      return jsonResponse({ error: "transfer_terms required for sale offers" }, 400);
    }

    const needsCommission =
      offerer_capacity === "owner_direct_100" ||
      offerer_capacity === "co_agent_50_50";
    if (needsCommission && !commission_scheme) {
      return jsonResponse({ error: "commission_scheme required" }, 400);
    }
    if (commission_scheme === "custom" && !commission_note) {
      return jsonResponse({ error: "commission_note required for custom" }, 400);
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
      .select("id, status, post_code, title")
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
        transaction_type: transaction_type ?? null,
        title,
        description,
        price_net,
        price_max_net,
        transfer_terms: transfer_terms ?? null,
        commission_scheme: commission_scheme ?? null,
        commission_note: commission_note ?? null,
        contact_name: contact_name ?? null,
        contact_phone: contact_phone ?? null,
        area_sqm,
        bedrooms,
        external_url: external_url || null,
        external_note,
      })
      .select("id, status, created_at")
      .single();

    if (insertError) {
      return jsonResponse({ error: insertError.message }, 400);
    }

    return jsonResponse({
      success: true,
      offer,
      demand_post_code: post.post_code,
      demand_post_title: post.title,
    });
  } catch (e) {
    return jsonResponse({ error: String(e) }, 500);
  }
});
