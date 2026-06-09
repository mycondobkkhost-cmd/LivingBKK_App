import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";
import { corsHeaders, jsonResponse } from "../_shared/cors.ts";
import { postMakeComWebhook, sendFcmToUsers } from "../_shared/notify.ts";

type RentalPaymentEvent = "reminder" | "admin_confirmed" | "slip_submitted";

/**
 * Push ชำระค่าเช่า — แจ้งเตือนก่อนครบ · ยืนยันรับเงิน · ส่งสลิป
 * Body: event, lease_id, listing_code, recipient_user_ids[], installment_*
 */
Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const body = await req.json();
    const event = body.event as RentalPaymentEvent | undefined;
    const lease_id = body.lease_id as string | undefined;
    const listing_code = (body.listing_code as string) ?? "";
    const recipient_user_ids = (body.recipient_user_ids as string[] | undefined) ??
      [];

    if (!event || !lease_id) {
      return jsonResponse({ error: "event and lease_id required" }, 400);
    }

    const sequence = body.installment_sequence as number | undefined;
    const due_date = body.due_date as string | undefined;
    const days_before = body.days_before as number | undefined;
    const note = body.note as string | undefined;

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );

    let title = "RealXtate — ค่าเช่า";
    let pushBody = listing_code;
    let fcmType = "rental_payment_reminder";

    switch (event) {
      case "reminder":
        title = "RealXtate — ใกล้ครบชำระค่าเช่า";
        pushBody = [
          listing_code,
          sequence != null ? `รอบที่ ${sequence}` : null,
          days_before != null ? `อีก ${days_before} วัน` : null,
          due_date ?? null,
        ].filter(Boolean).join(" · ");
        fcmType = "rental_payment_reminder";
        break;
      case "admin_confirmed":
        title = "RealXtate — ยืนยันรับเงินแล้ว";
        pushBody = [
          listing_code,
          sequence != null ? `รอบที่ ${sequence}` : null,
          "แอดมินยืนยันรับเงินแล้ว",
          due_date ?? null,
        ].filter(Boolean).join(" · ");
        fcmType = "rental_payment_confirmed";
        break;
      case "slip_submitted":
        title = "RealXtate — ส่งสลิปค่าเช่าแล้ว";
        pushBody = [
          listing_code,
          sequence != null ? `รอบที่ ${sequence}` : null,
        ].filter(Boolean).join(" · ");
        fcmType = "rental_payment_slip";
        break;
    }

    await postMakeComWebhook({
      event: `rental_payment_${event}`,
      listing_code,
      status: event,
    });

    const fcm = await sendFcmToUsers(
      supabase,
      recipient_user_ids,
      title,
      pushBody,
      {
        type: fcmType,
        lease_id,
        channel: "livingbkk",
        ...(sequence != null ? { installment_sequence: String(sequence) } : {}),
        ...(note ? { note } : {}),
      },
    );

    return jsonResponse({
      success: true,
      event,
      lease_id,
      fcm_sent: fcm.sent,
      recipients: recipient_user_ids.length,
    });
  } catch (e) {
    return jsonResponse({ error: String(e) }, 500);
  }
});
