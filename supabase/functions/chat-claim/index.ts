import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";
import { requireAdmin } from "../_shared/admin_auth.ts";
import {
  thaiClaimedBody,
  thaiClaimedTitle,
  thaiInboxLabel,
} from "../_shared/chat_notify_th.ts";
import { corsHeaders, jsonResponse } from "../_shared/cors.ts";
import { sendFcmToUser } from "../_shared/notify.ts";

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const auth = await requireAdmin(req);
    if (auth instanceof Response) return auth;

    const body = await req.json();
    const thread_id = body.thread_id as string | undefined;
    if (!thread_id) {
      return jsonResponse({ error: "thread_id required" }, 400);
    }

    const db = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );

    const { data: thread, error: fetchError } = await db
      .from("chat_threads")
      .select("*")
      .eq("id", thread_id)
      .single();

    if (fetchError || !thread) {
      return jsonResponse({ error: "Thread not found" }, 404);
    }

    if (thread.status === "resolved") {
      return jsonResponse({ error: "เคสปิดแล้ว" }, 409);
    }

    const existing = thread.assigned_admin_id as string | null;
    if (existing && existing !== auth.userId) {
      return jsonResponse({ error: "มีคนรับงานแล้ว", assigned_admin_id: existing }, 409);
    }

    if (existing === auth.userId) {
      return jsonResponse({ thread, already_claimed: true });
    }

    const { data: updated, error: updateError } = await db
      .from("chat_threads")
      .update({
        assigned_admin_id: auth.userId,
        assigned_at: new Date().toISOString(),
        sla_notified_at: null,
      })
      .eq("id", thread_id)
      .select("*")
      .single();

    if (updateError) {
      return jsonResponse({ error: updateError.message }, 400);
    }

    const { data: claimer } = await db
      .from("profiles")
      .select("display_name")
      .eq("id", auth.userId)
      .maybeSingle();

    const claimerName = (claimer?.display_name as string) ?? "ทีมงาน";
    const listingCode = (thread.listing_code as string) ?? "";

    const { data: admins } = await db
      .from("profiles")
      .select("id")
      .eq("role", "admin")
      .neq("id", auth.userId);

    for (const admin of admins ?? []) {
      await sendFcmToUser(
        db,
        admin.id as string,
        thaiClaimedTitle(),
        thaiClaimedBody(claimerName, listingCode),
      );
    }

    return jsonResponse({
      thread: updated,
      label: thaiInboxLabel(
        thread.category as string,
        thread.viewing_submitted as boolean,
      ),
    });
  } catch (e) {
    return jsonResponse({ error: String(e) }, 500);
  }
});
