import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";
import { corsHeaders, jsonResponse } from "../_shared/cors.ts";
import { postMakeComWebhook, sendFcmToUser } from "../_shared/notify.ts";

/**
 * Notify assignee + Make.com when an appointment is scheduled or updated.
 */
Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const body = await req.json();
    const appointment_id = body.appointment_id as string | undefined;
    if (!appointment_id) {
      return jsonResponse({ error: "appointment_id required" }, 400);
    }

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );

    const { data: appt, error } = await supabase
      .from("appointments")
      .select(
        "id, lead_id, listing_code, status, scheduled_date, time_slot, seeker_nickname, assigned_to",
      )
      .eq("id", appointment_id)
      .single();

    if (error || !appt) {
      return jsonResponse({ error: "Appointment not found" }, 404);
    }

    const listingCode = (appt.listing_code as string) ?? "";
    const date = (appt.scheduled_date as string) ?? "";
    const slot = (appt.time_slot as string) ?? "";
    const status = (appt.status as string) ?? "pending";
    const assignee = appt.assigned_to as string | null;

    await postMakeComWebhook({
      event: "appointment_scheduled",
      appointment_id,
      lead_id: appt.lead_id as string | undefined,
      listing_code: listingCode,
      status,
      scheduled_date: date,
      time_slot: slot,
      seeker_nickname: (appt.seeker_nickname as string) ?? undefined,
    });

    const fcm = await sendFcmToUser(
      supabase,
      assignee,
      "LivingBKK — นัดชม",
      "$listingCode · $date · $slot",
    );

    return jsonResponse({
      success: true,
      appointment_id,
      assigned_to: assignee,
      fcm_sent: fcm.sent,
    });
  } catch (e) {
    return jsonResponse({ error: String(e) }, 500);
  }
});
