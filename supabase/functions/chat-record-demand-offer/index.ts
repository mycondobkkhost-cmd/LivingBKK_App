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
    const summary = body.summary as Record<string, string> | undefined;
    const demandPostCode = body.demand_post_code as string | undefined;
    const demandPostTitle = body.demand_post_title as string | undefined;

    if (!summary || !demandPostCode) {
      return jsonResponse({ error: "summary and demand_post_code required" }, 400);
    }

    const db = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );

    const listingCode = demandPostCode;
    const listingTitle = demandPostTitle
      ? `เสนอทรัพย์ · ${demandPostTitle}`
      : "เสนอทรัพย์";

    let { data: thread } = await db
      .from("chat_threads")
      .select("*")
      .eq("user_id", userId)
      .eq("category", "demand_offer")
      .maybeSingle();

    if (!thread) {
      const { data: created, error: createError } = await db
        .from("chat_threads")
        .insert({
          user_id: userId,
          room_kind: "staff_support",
          listing_code: listingCode,
          listing_title: listingTitle,
          category: "demand_offer",
          admin_escalated: true,
          status: "waiting_admin",
          priority: "normal",
        })
        .select("*")
        .single();

      if (createError || !created) {
        return jsonResponse({ error: createError?.message ?? "Create thread failed" }, 400);
      }
      thread = created;

      await db.from("chat_messages").insert({
        thread_id: thread.id,
        role: "admin_notice",
        text:
          "แชทหมวด「เสนอทรัพย์」 — ส่งข้อเสนอตรงความต้องการบนบอร์ดได้ที่นี่\n" +
          "ทีม PROPPITER จะตรวจสอบและติดต่อกลับในแชทนี้",
      });
    }

    const lines = Object.entries(summary)
      .map(([k, v]) => `• ${k}: ${v}`)
      .join("\n");

    const inserts = [
      {
        thread_id: thread.id,
        role: "user",
        text: `ส่งข้อเสนอทรัพย์ (${demandPostCode})`,
      },
      {
        thread_id: thread.id,
        role: "system",
        text:
          "ระบบบันทึกข้อเสนอของคุณแล้ว\n" +
          "ทีมงานจะตรวจสอบและติดต่อกลับในแชทนี้",
      },
      {
        thread_id: thread.id,
        role: "system",
        text: `สรุปข้อเสนอ\n${lines}`,
      },
      {
        thread_id: thread.id,
        role: "admin_notice",
        text: "เจ้าหน้าที่จะตรวจสอบข้อเสนอและแจ้งผลในแชทนี้ครับ",
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
        listing_code: listingCode,
        listing_title: listingTitle,
        admin_escalated: true,
        admin_reply_done: false,
        category: "demand_offer",
        status: "waiting_admin",
        last_message_at: new Date().toISOString(),
      })
      .eq("id", thread.id)
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
        body: JSON.stringify({ thread_id: thread.id, reason: "demand_offer" }),
      });
    } catch (_) {
      /* non-fatal */
    }

    return jsonResponse({ thread: updated, messages: messages ?? [] });
  } catch (e) {
    return jsonResponse({ error: String(e) }, 500);
  }
});
