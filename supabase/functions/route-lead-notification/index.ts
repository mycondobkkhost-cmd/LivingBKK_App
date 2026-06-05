import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";
import { corsHeaders, jsonResponse } from "../_shared/cors.ts";
import { postMakeComWebhook, sendFcmToUser } from "../_shared/notify.ts";

/**
 * Routes a new lead to the listing owner (assignee) and notifies assignee + Make.com.
 */
Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const body = await req.json();
    const lead_id = body.lead_id as string | undefined;
    if (!lead_id) {
      return jsonResponse({ error: "lead_id required" }, 400);
    }

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );

    const { data: lead, error } = await supabase
      .from("leads")
      .select("id, listing_id, listing_code, assigned_to, status, seeker_nickname")
      .eq("id", lead_id)
      .single();

    if (error || !lead) {
      return jsonResponse({ error: "Lead not found" }, 404);
    }

    let assignee = lead.assigned_to as string | null;

    if (lead.listing_id) {
      const { data: listing } = await supabase
        .from("listings")
        .select("owner_id, created_by_id")
        .eq("id", lead.listing_id)
        .single();

      assignee = listing?.owner_id ?? listing?.created_by_id ?? assignee;
    }

    const { error: updateError } = await supabase
      .from("leads")
      .update({
        status: "routed",
        assigned_to: assignee,
      })
      .eq("id", lead_id);

    if (updateError) {
      return jsonResponse({ error: updateError.message }, 400);
    }

    const listingCode = (lead.listing_code as string) ?? "";
    const nickname = (lead.seeker_nickname as string) ?? "ลูกค้า";

    await postMakeComWebhook({
      event: "lead_routed",
      lead_id,
      listing_code: listingCode,
      status: "routed",
      seeker_nickname: nickname,
    });

    const fcm = await sendFcmToUser(
      supabase,
      assignee,
      "LivingBKK — Lead ใหม่",
      `มี Lead สำหรับ $listingCode`,
    );

    return jsonResponse({
      success: true,
      lead_id,
      assigned_to: assignee,
      channel: body.channel ?? "lead",
      fcm_sent: fcm.sent,
      message: "Lead routed to assignee",
    });
  } catch (e) {
    return jsonResponse({ error: String(e) }, 500);
  }
});
