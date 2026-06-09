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
    const requirementId = body.requirement_id as string | undefined;
    const summary = body.summary as Record<string, string> | undefined;
    const title = (body.title as string | undefined)?.trim();

    if (!requirementId || !summary || !title) {
      return jsonResponse(
        { error: "requirement_id, summary, and title required" },
        400,
      );
    }

    const db = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );

    const { data: reqRow, error: reqErr } = await db
      .from("customer_requirements")
      .select("id, user_id, thread_id")
      .eq("id", requirementId)
      .single();

    if (reqErr || !reqRow) {
      return jsonResponse({ error: "Requirement not found" }, 404);
    }
    if (reqRow.user_id !== userId) {
      return jsonResponse({ error: "Forbidden" }, 403);
    }

    const reqCode = `REQ-${requirementId.slice(0, 8).toUpperCase()}`;
    const listingTitle = "ความต้องการหาทรัพย์";

    let threadId = reqRow.thread_id as string | null;

    if (threadId) {
      const { data: existing } = await db
        .from("chat_threads")
        .select("*")
        .eq("id", threadId)
        .eq("user_id", userId)
        .maybeSingle();
      if (!existing) threadId = null;
    }

    if (!threadId) {
      const { data: byReq } = await db
        .from("chat_threads")
        .select("*")
        .eq("user_id", userId)
        .eq("customer_requirement_id", requirementId)
        .maybeSingle();

      if (byReq) {
        threadId = byReq.id as string;
      }
    }

    let thread: Record<string, unknown>;

    if (!threadId) {
      const { data: created, error: createError } = await db
        .from("chat_threads")
        .insert({
          user_id: userId,
          room_kind: "staff_support",
          listing_code: reqCode,
          listing_title: listingTitle,
          category: "customer_requirement",
          customer_requirement_id: requirementId,
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
      threadId = created.id as string;

      await db.from("chat_messages").insert({
        thread_id: threadId,
        role: "admin_notice",
        text:
          "แชทส่งความต้องการหาทรัพย์ — ทีม RealXtate จะช่วยหาทรัพย์ที่ตรงเงื่อนไข\n" +
          "และติดต่อกลับในแชทนี้",
      });

      await db
        .from("customer_requirements")
        .update({ thread_id: threadId, updated_at: new Date().toISOString() })
        .eq("id", requirementId);
    } else {
      const { data: loaded } = await db
        .from("chat_threads")
        .select("*")
        .eq("id", threadId)
        .single();
      thread = loaded as Record<string, unknown>;
    }

    const lines = Object.entries(summary)
      .map(([k, v]) => `• ${k}: ${v}`)
      .join("\n");

    const inserts = [
      {
        thread_id: threadId,
        role: "user",
        text: `ส่งความต้องการ: ${title}`,
        sender_id: userId,
      },
      {
        thread_id: threadId,
        role: "system",
        text: "รับความต้องการแล้ว — ทีมงานกำลังตรวจสอบ",
      },
      {
        thread_id: threadId,
        role: "system",
        text: `สรุปความต้องการ\n${lines}`,
      },
      {
        thread_id: threadId,
        role: "admin_notice",
        text: "ทีมงานจะช่วยหาทรัพย์ที่ตรงเงื่อนไขและตอบกลับในแชทนี้ครับ",
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
        listing_code: reqCode,
        listing_title: listingTitle,
        admin_escalated: true,
        admin_reply_done: false,
        category: "customer_requirement",
        status: "waiting_admin",
        last_message_at: new Date().toISOString(),
      })
      .eq("id", threadId)
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
          thread_id: threadId,
          reason: "customer_requirement",
        }),
      });
    } catch (_) {
      /* non-fatal */
    }

    return jsonResponse({ thread: updated, messages: messages ?? [] });
  } catch (e) {
    return jsonResponse({ error: String(e) }, 500);
  }
});
