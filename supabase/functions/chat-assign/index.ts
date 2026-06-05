import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";
import { requireAdmin } from "../_shared/admin_auth.ts";
import { thaiAssignedBody, thaiAssignedTitle } from "../_shared/chat_notify_th.ts";
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
    const assignee_id = body.assignee_id as string | undefined;

    if (!thread_id || !assignee_id) {
      return jsonResponse({ error: "thread_id and assignee_id required" }, 400);
    }

    const db = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );

    const { data: assignee } = await db
      .from("profiles")
      .select("id, role, display_name")
      .eq("id", assignee_id)
      .maybeSingle();

    if (!assignee || assignee.role !== "admin") {
      return jsonResponse({ error: "ผู้รับต้องเป็นแอดมิน" }, 400);
    }

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

    const { data: fromProfile } = await db
      .from("profiles")
      .select("display_name")
      .eq("id", auth.userId)
      .maybeSingle();

    const fromName = (fromProfile?.display_name as string) ?? "ทีมงาน";
    const listingCode = (thread.listing_code as string) ?? "";

    const { data: updated, error: updateError } = await db
      .from("chat_threads")
      .update({
        assigned_admin_id: assignee_id,
        assigned_at: new Date().toISOString(),
        sla_notified_at: null,
      })
      .eq("id", thread_id)
      .select("*")
      .single();

    if (updateError) {
      return jsonResponse({ error: updateError.message }, 400);
    }

    if (assignee_id !== auth.userId) {
      await sendFcmToUser(
        db,
        assignee_id,
        thaiAssignedTitle(),
        thaiAssignedBody(listingCode, fromName),
      );
    }

    return jsonResponse({ thread: updated });
  } catch (e) {
    return jsonResponse({ error: String(e) }, 500);
  }
});
