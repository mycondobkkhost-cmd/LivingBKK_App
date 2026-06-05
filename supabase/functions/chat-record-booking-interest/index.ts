import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";
import { corsHeaders, jsonResponse } from "../_shared/cors.ts";

async function authUserId(req: Request): Promise<string | null> {
  const authHeader = req.headers.get("Authorization");
  if (!authHeader) return null;

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_ANON_KEY")!,
    { global: { headers: { Authorization: authHeader } } },
  );

  const { data, error } = await supabase.auth.getUser();
  if (error || !data.user) return null;
  return data.user.id;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const userId = await authUserId(req);
    if (!userId) return jsonResponse({ error: "Unauthorized" }, 401);

    const body = await req.json();
    const thread_id = body.thread_id as string | undefined;
    const summary = body.summary as Record<string, string> | undefined;

    if (!thread_id || !summary) {
      return jsonResponse({ error: "thread_id and summary required" }, 400);
    }

    const lines = Object.entries(summary)
      .map(([k, v]) => `• ${k}: ${v}`)
      .join("\n");

    const db = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );

    const { data: thread, error: threadError } = await db
      .from("chat_threads")
      .select("*")
      .eq("id", thread_id)
      .eq("user_id", userId)
      .single();

    if (threadError || !thread) {
      return jsonResponse({ error: "Thread not found" }, 404);
    }

    const inserts: Array<Record<string, unknown>> = [
      {
        thread_id,
        role: "system",
        text:
          "ระบบได้รับความสนใจจองของคุณแล้ว\n" +
          "ทีมงานจะติดต่อกลับโดยเร็วที่สุด — กรุณารอแอดมินตอบในแชทนี้" +
          (thread.transaction_ref
            ? `\nเลขอ้างอิง: ${thread.transaction_ref}`
            : ""),
      },
      {
        thread_id,
        role: "system",
        text: `รายละเอียด\n${lines}`,
      },
      {
        thread_id,
        role: "admin_notice",
        text: "🔥 ลูกค้าสนใจจอง — ตอบทันที (ความสำคัญสูงสุด)",
      },
    ];

    const { data: messages, error: msgError } = await db
      .from("chat_messages")
      .insert(inserts)
      .select("*");

    if (msgError) return jsonResponse({ error: msgError.message }, 400);

    const { data: updated, error: updateError } = await db
      .from("chat_threads")
      .update({
        admin_escalated: true,
        admin_reply_done: false,
        category: "booking_interest",
        status: "waiting_admin",
        priority: "high",
      })
      .eq("id", thread_id)
      .select("*")
      .single();

    if (updateError) return jsonResponse({ error: updateError.message }, 400);

    const base = Deno.env.get("SUPABASE_URL")!;
    const key = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    try {
      await fetch(`${base}/functions/v1/notify-chat-escalation`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${key}`,
        },
        body: JSON.stringify({
          thread_id,
          listing_code: thread.listing_code,
          listing_id: thread.listing_id,
          reason: "booking_interest",
          preview: summary["ทรัพย์"] ?? "",
        }),
      });
    } catch (_) {}

    return jsonResponse({ thread: updated, messages });
  } catch (e) {
    return jsonResponse({ error: String(e) }, 500);
  }
});
