import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";
import {
  thaiInboxLabel,
  thaiSlaOverdueBody,
  thaiSlaOverdueTitle,
  thaiSlaUnclaimedBody,
  thaiSlaUnclaimedTitle,
} from "../_shared/chat_notify_th.ts";
import { corsHeaders, jsonResponse } from "../_shared/cors.ts";
import { sendFcmToUser } from "../_shared/notify.ts";

type ThreadRow = {
  id: string;
  listing_code: string | null;
  category: string;
  priority: string;
  viewing_submitted: boolean;
  assigned_admin_id: string | null;
  assigned_at: string | null;
  last_message_at: string;
  sla_notified_at: string | null;
  status: string;
  admin_reply_done: boolean;
  last_message_role: string | null;
};

function slaMinutes(thread: ThreadRow): number {
  if (thread.viewing_submitted || thread.category === "viewing_request") return 30;
  if (thread.priority === "high") return 30;
  if (thread.category === "staff_support") return 120;
  if (thread.category === "escalation") return 60;
  return 240;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const cronSecret = Deno.env.get("CRON_SECRET");
    const auth = req.headers.get("Authorization") ?? "";
    if (!cronSecret || auth !== `Bearer ${cronSecret}`) {
      return jsonResponse({ error: "unauthorized" }, 401);
    }

    const db = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );

    const { data: rows, error } = await db
      .from("chat_admin_inbox")
      .select("*")
      .neq("status", "resolved");

    if (error) {
      return jsonResponse({ error: error.message }, 500);
    }

    const now = Date.now();
    const notifyCooldownMs = 30 * 60 * 1000;
    let notified = 0;

    const { data: admins } = await db
      .from("profiles")
      .select("id")
      .eq("role", "admin");

    for (const raw of rows ?? []) {
      const thread = raw as ThreadRow;

      if (thread.admin_reply_done && !thread.viewing_submitted) continue;
      if (thread.last_message_role && thread.last_message_role !== "user") {
        if (!thread.viewing_submitted || thread.admin_reply_done) continue;
      }

      const lastAt = new Date(thread.last_message_at).getTime();
      const waitMinutes = Math.floor((now - lastAt) / 60000);
      const slaLimit = slaMinutes(thread);

      if (waitMinutes < slaLimit) continue;

      const slaNotified = thread.sla_notified_at
        ? new Date(thread.sla_notified_at).getTime()
        : 0;
      if (slaNotified && now - slaNotified < notifyCooldownMs) continue;

      const listingCode = thread.listing_code ?? "";

      if (!thread.assigned_admin_id) {
        for (const admin of admins ?? []) {
          await sendFcmToUser(
            db,
            admin.id as string,
            thaiSlaUnclaimedTitle(),
            thaiSlaUnclaimedBody(listingCode, waitMinutes),
          );
        }
      } else {
        const { data: assignee } = await db
          .from("profiles")
          .select("display_name")
          .eq("id", thread.assigned_admin_id)
          .maybeSingle();

        const assigneeName = (assignee?.display_name as string) ?? "ทีมงาน";

        await sendFcmToUser(
          db,
          thread.assigned_admin_id,
          thaiSlaOverdueTitle(),
          thaiSlaOverdueBody(listingCode, waitMinutes, assigneeName),
        );

        for (const admin of admins ?? []) {
          if (admin.id === thread.assigned_admin_id) continue;
          await sendFcmToUser(
            db,
            admin.id as string,
            thaiSlaOverdueTitle(),
            thaiSlaOverdueBody(listingCode, waitMinutes, assigneeName),
          );
        }
      }

      await db
        .from("chat_threads")
        .update({ sla_notified_at: new Date().toISOString() })
        .eq("id", thread.id);

      notified++;
    }

    return jsonResponse({ ok: true, checked: rows?.length ?? 0, notified });
  } catch (e) {
    return jsonResponse({ error: String(e) }, 500);
  }
});
