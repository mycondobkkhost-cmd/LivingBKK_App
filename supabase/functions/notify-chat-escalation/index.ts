import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";
import { corsHeaders, jsonResponse } from "../_shared/cors.ts";
import { postMakeComWebhook, sendFcmToUser } from "../_shared/notify.ts";
import {
  thaiEscalationBody,
  thaiEscalationTitle,
  thaiInboxLabel,
} from "../_shared/chat_notify_th.ts";

/**
 * Notify ops when a chat thread needs human attention (escalation / viewing / staff).
 */
Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const body = await req.json();
    const thread_id = body.thread_id as string | undefined;
    if (!thread_id) {
      return jsonResponse({ error: "thread_id required" }, 400);
    }

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );

    const { data: thread, error } = await supabase
      .from("chat_threads")
      .select("id, listing_code, listing_id, category, status, priority, viewing_submitted")
      .eq("id", thread_id)
      .single();

    if (error || !thread) {
      return jsonResponse({ error: "Thread not found" }, 404);
    }

    const reason = (body.reason as string) ?? "escalation";
    const listingCode = (thread.listing_code as string) ?? "";
    const preview = (body.preview as string) ?? "";
    const label = thaiInboxLabel(
      thread.category as string,
      thread.viewing_submitted as boolean,
    );

    await postMakeComWebhook({
      event: "chat_escalated",
      lead_id: thread_id,
      listing_code: listingCode,
      status: thread.status as string,
      seeker_nickname: preview.slice(0, 80) || undefined,
    });

    const { data: admins } = await supabase
      .from("profiles")
      .select("id")
      .eq("role", "admin");

    const title = thaiEscalationTitle();
    const fcmBody = thaiEscalationBody(listingCode, reason);

    let fcmSent = 0;
    for (const admin of admins ?? []) {
      const res = await sendFcmToUser(
        supabase,
        admin.id as string,
        title,
        fcmBody,
      );
      if (res.sent) fcmSent++;
    }

    return jsonResponse({
      success: true,
      thread_id,
      reason,
      category: thread.category,
      label,
      fcm_sent: fcmSent,
    });
  } catch (e) {
    return jsonResponse({ error: String(e) }, 500);
  }
});
