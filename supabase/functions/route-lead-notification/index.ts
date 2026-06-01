import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";
import { corsHeaders, jsonResponse } from "../_shared/cors.ts";

/**
 * Triggered after new lead insert (configure Database Webhook or call from app).
 * Updates lead status to routed and stores FCM payload placeholder for future push.
 */
Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const { lead_id } = await req.json();
    if (!lead_id) {
      return jsonResponse({ error: "lead_id required" }, 400);
    }

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );

    const { data: lead, error } = await supabase
      .from("leads")
      .select("id, listing_id, listing_code, assigned_to")
      .eq("id", lead_id)
      .single();

    if (error || !lead) {
      return jsonResponse({ error: "Lead not found" }, 404);
    }

    await supabase
      .from("leads")
      .update({ status: "routed" })
      .eq("id", lead_id);

    // TODO: FCM — fetch assignee profiles.fcm_token and send push
    return jsonResponse({
      success: true,
      lead_id,
      message: "Lead routed (push notification pending FCM setup)",
    });
  } catch (e) {
    return jsonResponse({ error: String(e) }, 500);
  }
});
