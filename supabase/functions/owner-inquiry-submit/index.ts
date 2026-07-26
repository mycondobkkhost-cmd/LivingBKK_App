import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";
import { corsHeaders, jsonResponse } from "../_shared/cors.ts";
import { sendFcmToUser } from "../_shared/notify.ts";
import {
  feedFromOwnerInquirySubmit,
} from "../_shared/admin_ai_feed.ts";
import { orchestrateAdminFeed } from "../_shared/admin_orchestrator.ts";

const INQUIRY_TYPES = [
  "price_negotiation",
  "availability",
  "unit_detail",
  "custom_terms",
  "general",
] as const;

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

function nextCode(): string {
  const y = new Date().getFullYear();
  const n = Math.floor(Math.random() * 900000) + 100000;
  return `OIQ-${y}-${n}`;
}

function ownerNotifyText(
  code: string,
  listingCode: string,
  question: string,
  context: Record<string, unknown>,
): string {
  const profile = Object.entries(context)
    .filter(([, v]) => v != null && String(v).trim() !== "")
    .map(([k, v]) => `${k}: ${v}`)
    .join("\n");

  return (
    `📩 มีลูกค้าส่งโปรไฟล์สอบถามเกี่ยวกับ ${listingCode}\n` +
    `เลขอ้างอิง: ${code}\n\n` +
    (profile ? `โปรไฟล์ผู้สนใจ:\n${profile}\n\n` : "") +
    `สิ่งที่สอบถาม/เงื่อนไข:\n${question}\n\n` +
    `กรุณาตอบในแอป → งานของฉัน → คำถามจากลูกค้า`
  );
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
    const listing_code = String(body.listing_code ?? "").trim();
    const listing_id = body.listing_id as string | undefined;
    const inquiry_type = String(body.inquiry_type ?? "general");
    const seeker_question = String(body.seeker_question ?? "").trim();
    const seeker_context = (body.seeker_context ?? {}) as Record<string, unknown>;

    if (!thread_id || !listing_code || seeker_question.length < 2) {
      return jsonResponse({ error: "thread_id, listing_code, seeker_question required" }, 400);
    }
    if (!INQUIRY_TYPES.includes(inquiry_type as typeof INQUIRY_TYPES[number])) {
      return jsonResponse({ error: "Invalid inquiry_type" }, 400);
    }

    const db = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );

    const { data: thread, error: threadErr } = await db
      .from("chat_threads")
      .select("*")
      .eq("id", thread_id)
      .eq("user_id", userId)
      .single();

    if (threadErr || !thread) {
      return jsonResponse({ error: "Thread not found" }, 404);
    }

    let ownerId: string | null = null;
    const lid = listing_id ?? thread.listing_id;
    if (lid) {
      const { data: listing } = await db
        .from("listings")
        .select("owner_id, created_by_id")
        .eq("id", lid)
        .maybeSingle();
      ownerId = (listing?.owner_id ?? listing?.created_by_id) as string | null;
    }

    const code = nextCode();
    const contextLines = Object.entries(seeker_context)
      .filter(([, v]) => v != null && String(v).trim() !== "")
      .map(([k, v]) => `• ${k}: ${v}`)
      .join("\n");

    const fullQuestion = contextLines
      ? `${seeker_question}\n${contextLines}`
      : seeker_question;

    const { data: inquiry, error: insErr } = await db
      .from("owner_inquiries")
      .insert({
        code,
        thread_id,
        listing_id: lid,
        listing_code,
        seeker_id: userId,
        owner_id: ownerId,
        inquiry_type,
        seeker_question,
        seeker_context,
        status: "pending_owner",
      })
      .select("*")
      .single();

    if (insErr || !inquiry) {
      return jsonResponse({ error: insErr?.message ?? "Insert failed" }, 400);
    }

    await orchestrateAdminFeed(
      db,
      "owner-inquiry-submit",
      feedFromOwnerInquirySubmit({
        inquiryId: inquiry.id as string,
        code,
        threadId: thread_id,
        listingCode: listing_code,
        listingId: lid as string | undefined,
        question: seeker_question,
        inquiryType: inquiry_type,
      }),
    );

    const seekerAck =
      `✅ ส่งคำถามให้เจ้าของแล้วครับ (เลขอ้างอิง ${code})\n` +
      "พอได้คำตอบแล้วจะแจ้งกลับในแชทนี้โดยเร็วที่สุดครับ";

    const { data: seekerMsgs, error: msgErr } = await db
      .from("chat_messages")
      .insert([
        { thread_id, role: "system", text: seekerAck },
        {
          thread_id,
          role: "system",
          text: `สรุปคำถามที่ส่งให้เจ้าของ\n${fullQuestion}`,
        },
      ])
      .select("*");

    if (msgErr) return jsonResponse({ error: msgErr.message }, 400);

    await db
      .from("chat_threads")
      .update({
        category: "owner_inquiry",
        status: "open",
        admin_escalated: false,
        admin_reply_done: true,
        priority: "normal",
        last_message_at: new Date().toISOString(),
      })
      .eq("id", thread_id);

    let ownerThreadId: string | null = null;
    if (ownerId) {
      let ownerThread: Record<string, unknown> | null = null;
      if (lid) {
        const { data } = await db
          .from("chat_threads")
          .select("*")
          .eq("user_id", ownerId)
          .eq("listing_id", lid)
          .maybeSingle();
        ownerThread = data;
      }
      if (!ownerThread) {
        const { data: created } = await db
          .from("chat_threads")
          .insert({
            user_id: ownerId,
            room_kind: "property",
            listing_id: lid,
            listing_code,
            listing_title: thread.listing_title ?? listing_code,
            project_name: thread.project_name,
            category: "owner_inquiry",
            status: "open",
            priority: "high",
          })
          .select("*")
          .single();
        ownerThread = created;
      }
      ownerThreadId = ownerThread?.id as string | null;

      if (ownerThreadId) {
        const ownerText = ownerNotifyText(
          code,
          listing_code,
          fullQuestion,
          seeker_context,
        );
        await db.from("chat_messages").insert({
          thread_id: ownerThreadId,
          role: "admin_notice",
          text: ownerText,
          links: [{
            label: `ตอบคำถาม ${code}`,
            kind: "owner_inquiry",
            refCode: inquiry.id,
          }],
        });

        await db
          .from("owner_inquiries")
          .update({
            owner_thread_id: ownerThreadId,
            owner_notified_at: new Date().toISOString(),
          })
          .eq("id", inquiry.id);

        try {
          await sendFcmToUser(
            db,
            ownerId,
            "มีลูกค้าสอบถามเกี่ยวกับทรัพย์",
            `${listing_code}: ${seeker_question.slice(0, 80)}`,
            {
              channel: "owner_inquiry",
              inquiry_id: inquiry.id,
              listing_code,
            },
          );
        } catch (_) {}
      }
    }

    return jsonResponse({
      inquiry,
      messages: seekerMsgs,
      owner_thread_id: ownerThreadId,
    });
  } catch (e) {
    return jsonResponse({ error: String(e) }, 500);
  }
});
