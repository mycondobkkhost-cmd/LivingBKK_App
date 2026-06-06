import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";
import { requireAdmin } from "../_shared/admin_auth.ts";
import { corsHeaders, jsonResponse } from "../_shared/cors.ts";

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const auth = await requireAdmin(req);
    if (auth instanceof Response) return auth;

    const body = await req.json();
    const offerId = body.offer_id as string | undefined;

    if (!offerId) {
      return jsonResponse({ error: "offer_id required" }, 400);
    }

    const db = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );

    const { data: offer, error: offerErr } = await db
      .from("demand_offers")
      .select(
        "*, demand_posts(id, post_code, transaction_type, property_type, zones)",
      )
      .eq("id", offerId)
      .single();

    if (offerErr || !offer) {
      return jsonResponse({ error: "Offer not found" }, 404);
    }

    if (offer.listing_id) {
      const { data: listing } = await db
        .from("listings")
        .select("id, listing_code, status, title")
        .eq("id", offer.listing_id)
        .single();
      return jsonResponse({
        already_promoted: true,
        listing,
        offer_code: offer.offer_code,
      });
    }

    const post = offer.demand_posts as Record<string, unknown> | null;
    const txn = (offer.transaction_type ?? post?.transaction_type ?? "rent") as string;
    const propType = (post?.property_type ?? "condo") as string;
    const zones = post?.zones;
    const district = Array.isArray(zones) && zones.length > 0
      ? String(zones[0])
      : "กรุงเทพฯ";

    const { data: listing, error: insErr } = await db
      .from("listings")
      .insert({
        owner_id: offer.offerer_id,
        created_by_id: auth.userId,
        listing_type: txn,
        property_type: propType,
        title: offer.title ?? `ข้อเสนอ ${offer.offer_code ?? offerId.slice(0, 8)}`,
        description_public: offer.description ?? "",
        price_net: Math.max(Number(offer.price_net ?? 0), 1),
        area_sqm: offer.area_sqm,
        bedrooms: offer.bedrooms,
        district,
        unit_number: offer.unit_number,
        exact_floor: offer.exact_floor,
        location_exact: offer.location_exact,
        status: "pending_review",
        source_demand_offer_id: offerId,
      })
      .select("id, listing_code, status, title")
      .single();

    if (insErr || !listing) {
      return jsonResponse({ error: insErr?.message ?? "Create listing failed" }, 400);
    }

    await db
      .from("demand_offers")
      .update({
        listing_id: listing.id,
        promoted_at: new Date().toISOString(),
        status: "accepted",
        capacity_verified: "verified",
        capacity_verified_by: auth.userId,
        capacity_verified_at: new Date().toISOString(),
      })
      .eq("id", offerId);

    return jsonResponse({
      listing,
      offer_code: offer.offer_code,
    });
  } catch (e) {
    return jsonResponse({ error: String(e) }, 500);
  }
});
