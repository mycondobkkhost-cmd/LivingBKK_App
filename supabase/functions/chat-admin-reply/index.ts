import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";
import { requireAdmin } from "../_shared/admin_auth.ts";
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
    const text = (body.text as string | undefined)?.trim();
    const resolve = Boolean(body.resolve);
    const links = body.links as unknown[] | undefined;

    const hasLinks = Array.isArray(links) && links.length > 0;
    if (!thread_id || (!text && !hasLinks)) {
      return jsonResponse({ error: "thread_id and text or links required" }, 400);
    }

    const db = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );

    const { data: existing, error: loadError } = await db
      .from("chat_threads")
      .select("assigned_admin_id, status, user_id, listing_code, listing_title")
      .eq("id", thread_id)
      .single();

    if (loadError || !existing) {
      return jsonResponse({ error: "Thread not found" }, 404);
    }

    const assigned = existing.assigned_admin_id as string | null;
    if (assigned && assigned !== auth.userId) {
      return jsonResponse(
        { error: "มีคนรับงานแล้ว — กด「มอบหมาย」หรือให้ผู้รับตอบ", assigned_admin_id: assigned },
        409,
      );
    }

    const { data: msg, error: msgError } = await db
      .from("chat_messages")
      .insert({
        thread_id,
        role: "admin_notice",
        text: text || " ",
        links: Array.isArray(links) ? links : [],
        sender_id: auth.userId,
      })
      .select("*")
      .single();

    if (msgError) return jsonResponse({ error: msgError.message }, 400);

    const now = new Date().toISOString();
    const patch: Record<string, unknown> = {
      admin_reply_done: true,
      assigned_admin_id: auth.userId,
    };
    if (!assigned) {
      patch.assigned_at = now;
    }
    if (resolve) {
      patch.status = "resolved";
      patch.admin_escalated = false;
    }

    const { data: thread, error: threadError } = await db
      .from("chat_threads")
      .update(patch)
      .eq("id", thread_id)
      .select("*")
      .single();

    if (threadError) return jsonResponse({ error: threadError.message }, 400);

    const userId = existing.user_id as string | undefined;
    const code = (existing.listing_code as string) || "PROPPITER";
    await sendFcmToUser(
      db,
      userId,
      "PROPPITER — มีข้อความใหม่",
      `${code}: ${text.slice(0, 120)}`,
      { type: "chat_reply", thread_id },
    );

    return jsonResponse({ message: msg, thread });
  } catch (e) {
    return jsonResponse({ error: String(e) }, 500);
  }
});
