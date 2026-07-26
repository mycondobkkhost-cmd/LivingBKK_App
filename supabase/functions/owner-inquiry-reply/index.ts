import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";
import { corsHeaders, jsonResponse } from "../_shared/cors.ts";
import { relayOwnerReplyWithAI } from "../_shared/owner_inquiry_relay.ts";
import { sendFcmToUser } from "../_shared/notify.ts";
import {
  feedFromOwnerReply,
} from "../_shared/admin_ai_feed.ts";
import { orchestrateAdminFeed } from "../_shared/admin_orchestrator.ts";

async function authUserId(req: Request): Promise<string | null> {
  const authHeader = req.headers.get("Authorization");
  if (!authHeader) return null;
  const client = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_ANON_KEY")!,
    { global: { headers: { Authorization: authHeader } } },
  );
  const { data, error } = await client.auth.getUser();
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
    const inquiry_id = body.inquiry_id as string | undefined;
    const reply_text = String(body.reply_text ?? "").trim();

    if (!inquiry_id || reply_text.length < 1) {
      return jsonResponse({ error: "inquiry_id and reply_text required" }, 400);
    }

    const db = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );

    const { data: inquiry, error: fetchErr } = await db
      .from("owner_inquiries")
      .select("*")
      .eq("id", inquiry_id)
      .single();

    if (fetchErr || !inquiry) {
      return jsonResponse({ error: "Inquiry not found" }, 404);
    }

    const isOwner = inquiry.owner_id === userId;
    const { data: profile } = await db
      .from("profiles")
      .select("role")
      .eq("id", userId)
      .maybeSingle();
    const isAdmin = profile?.role === "admin";

    if (!isOwner && !isAdmin) {
      return jsonResponse({ error: "Forbidden" }, 403);
    }

    if (inquiry.status !== "pending_owner") {
      return jsonResponse({ error: "Inquiry already answered" }, 400);
    }

    const relay = await relayOwnerReplyWithAI(
      reply_text,
      inquiry.inquiry_type as string,
      inquiry.seeker_question as string,
    );

    const now = new Date().toISOString();
    const patch: Record<string, unknown> = {
      owner_reply_raw: reply_text,
      owner_replied_at: now,
      relay_policy: relay.policy,
    };

    if (relay.policy === "auto_ok" || relay.policy === "blocked_pii") {
      patch.status = "relayed";
      patch.owner_reply_relay = relay.relayText;
      patch.relayed_at = now;
    } else {
      patch.status = "needs_admin";
      patch.owner_reply_relay = relay.relayText || null;
    }

    const { data: updated, error: updErr } = await db
      .from("owner_inquiries")
      .update(patch)
      .eq("id", inquiry_id)
      .select("*")
      .single();

    if (updErr || !updated) {
      return jsonResponse({ error: updErr?.message ?? "Update failed" }, 400);
    }

    await orchestrateAdminFeed(db, "owner-inquiry-reply", feedFromOwnerReply({
      inquiryId: inquiry_id,
      threadId: inquiry.thread_id as string,
      listingCode: inquiry.listing_code as string | null,
      seekerQuestion: inquiry.seeker_question as string,
      ownerReplyRaw: reply_text,
      relayText: relay.relayText,
      policy: relay.policy,
    }));

    const seekerThreadId = inquiry.thread_id as string;
    const inserts: Array<Record<string, unknown>> = [];

    if (relay.policy === "auto_ok" || relay.policy === "blocked_pii") {
      inserts.push({
        thread_id: seekerThreadId,
        role: "admin_notice",
        text:
          `📬 คำตอบจากเจ้าของ (${inquiry.code})\n\n${relay.relayText}`,
      });
    } else {
      inserts.push({
        thread_id: seekerThreadId,
        role: "system",
        text:
          "ได้รับคำตอบจากเจ้าของแล้ว — ทีมงานกำลังตรวจสอบก่อนแจ้งกลับให้คุณครับ",
      });
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
            thread_id: seekerThreadId,
            listing_code: inquiry.listing_code,
            listing_id: inquiry.listing_id,
            reason: "owner_inquiry_relay",
            preview: reply_text.slice(0, 120),
          }),
        });
      } catch (_) {}
    }

    if (inquiry.owner_thread_id) {
      inserts.push({
        thread_id: inquiry.owner_thread_id,
        role: "system",
        text: `✅ บันทึกคำตอบของคุณแล้ว (${inquiry.code})`,
        sender_id: userId,
      });
    }

    const { data: messages } = await db
      .from("chat_messages")
      .insert(inserts)
      .select("*");

    await db
      .from("chat_threads")
      .update({ last_message_at: now })
      .eq("id", seekerThreadId);

    try {
      await sendFcmToUser(
        db,
        inquiry.seeker_id as string,
        "มีคำตอบจากเจ้าของแล้ว",
        `ทรัพย์ ${inquiry.listing_code} — เปิดแชทเพื่อดูรายละเอียด`,
        {
          channel: "owner_inquiry_relay",
          inquiry_id,
          thread_id: seekerThreadId,
        },
      );
    } catch (_) {}

    return jsonResponse({ inquiry: updated, messages, relay });
  } catch (e) {
    return jsonResponse({ error: String(e) }, 500);
  }
});
