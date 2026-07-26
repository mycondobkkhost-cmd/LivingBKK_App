import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";
import { requireAdmin } from "../_shared/admin_auth.ts";
import { ensureFemaleAiTone } from "../_shared/chat_ai_voice.ts";
import { corsHeaders, jsonResponse } from "../_shared/cors.ts";
import { saveLearnedAnswer } from "../_shared/chat_learned_memory.ts";

type MsgRow = { role: string; text: string; created_at: string };

function extractQaPairs(messages: MsgRow[]): { q: string; a: string }[] {
  const pairs: { q: string; a: string }[] = [];
  let lastUser: string | null = null;
  for (const m of messages) {
    const role = m.role;
    const text = (m.text ?? "").trim();
    if (!text) continue;
    if (role === "user") {
      lastUser = text;
      continue;
    }
    if (role === "admin_notice" && lastUser) {
      pairs.push({ q: lastUser, a: text });
      lastUser = null;
    }
  }
  return pairs.slice(-6);
}

function transcriptBlock(messages: MsgRow[], max = 18): string {
  const roleLabel = (r: string) => {
    if (r === "user") return "ลูกค้า";
    if (r === "admin_notice") return "ทีม";
    if (r === "ai") return "AI";
    if (r === "system") return "ระบบ";
    return r;
  };
  return messages
    .slice(-max)
    .filter((m) => m.text?.trim())
    .map((m) => `${roleLabel(m.role)}: ${m.text.trim()}`)
    .join("\n");
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const auth = await requireAdmin(req);
    if (auth instanceof Response) return auth;

    const body = await req.json();
    const thread_id = body.thread_id as string | undefined;
    const notify_customer = body.notify_customer !== false;

    if (!thread_id) {
      return jsonResponse({ error: "thread_id required" }, 400);
    }

    const db = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );

    const { data: thread, error: threadErr } = await db
      .from("chat_threads")
      .select("*")
      .eq("id", thread_id)
      .single();

    if (threadErr || !thread) {
      return jsonResponse({ error: "Thread not found" }, 404);
    }

    const assigned = thread.assigned_admin_id as string | null;
    if (assigned && assigned !== auth.userId) {
      return jsonResponse(
        { error: "มีคนรับงานแล้ว — ให้ผู้รับงานคืนให้ AI" },
        409,
      );
    }

    const { data: msgRows } = await db
      .from("chat_messages")
      .select("role, text, created_at")
      .eq("thread_id", thread_id)
      .in("role", ["user", "ai", "admin_notice", "system", "admin_coach"])
      .order("created_at", { ascending: true });

    const messages = (msgRows ?? []) as MsgRow[];
    const listingId = thread.listing_id as string | null;
    const listingCode = (thread.listing_code as string | null) ?? "";
    const scope = listingId ? "listing" : "global";
    const learnedIds: string[] = [];

    const pairs = extractQaPairs(messages);
    for (let i = 0; i < pairs.length; i++) {
      const { q, a } = pairs[i];
      const id = await saveLearnedAnswer(db, {
        topicKey: `handoff_${listingCode || thread_id}_${i}`,
        questionExample: q.slice(0, 500),
        answerGuidance:
          `ทีมตอบลูกค้าแบบนี้: 「${a}」\n` +
          `เมื่อลูกค้าถามเรื่องใกล้เคียง ให้ AI สานต่อแนวทางทีม (ปรับถ้อยคำเป็นธรรมชาติ อย่า copy เป๊ะ)`,
        scope: scope as "global" | "listing",
        listingId,
        sourceThreadId: thread_id,
        createdBy: auth.userId,
      });
      if (id) learnedIds.push(id);
    }

    const transcript = transcriptBlock(messages);
    if (transcript.length > 20) {
      const ctxId = await saveLearnedAnswer(db, {
        topicKey: `handoff_ctx_${listingCode || thread_id}`,
        questionExample:
          `บทสนทนาล่าสุด${listingCode ? ` · ${listingCode}` : ""}`,
        answerGuidance:
          `CONTINUITY — อ่านประวัติแชทนี้แล้วคุยต่อจากทีม:\n${transcript}\n\n` +
          `ให้ AI สานต่อแนวทางทีม ไม่เริ่มต้นใหม่ทั้งหมด`,
        scope: scope as "global" | "listing",
        listingId,
        sourceThreadId: thread_id,
        createdBy: auth.userId,
      });
      if (ctxId) learnedIds.push(ctxId);
    }

    let handoffAi: Record<string, unknown> | null = null;
    if (notify_customer) {
      const handoffText = ensureFemaleAiTone(
        listingCode
          ? `ทีมงานรับช่วยคุยต่อแล้วนะคะ (${listingCode}) — ถามต่อเรื่องทรัพย์นี้ได้เลยค่ะ`
          : "ทีมงานรับช่วยคุยต่อแล้วนะคะ — ถามต่อได้เลยค่ะ",
      );
      const { data: aiRow, error: aiErr } = await db
        .from("chat_messages")
        .insert({
          thread_id,
          role: "ai",
          text: handoffText,
        })
        .select("*")
        .single();
      if (aiErr) return jsonResponse({ error: aiErr.message }, 400);
      handoffAi = aiRow;
    }

    const { data: updated, error: updErr } = await db
      .from("chat_threads")
      .update({
        status: "open",
        admin_escalated: false,
        admin_reply_done: true,
        coach_pending: false,
        coach_question: null,
        unclear_streak: 0,
        ai_enabled: true,
        category: listingId || listingCode
          ? "property_faq"
          : (thread.category as string) ?? "discovery",
        priority: "normal",
        assigned_admin_id: auth.userId,
        last_message_at: new Date().toISOString(),
      })
      .eq("id", thread_id)
      .select("*")
      .single();

    if (updErr) return jsonResponse({ error: updErr.message }, 400);

    return jsonResponse({
      thread: updated,
      learned_count: learnedIds.length,
      learned_ids: learnedIds,
      handoff_message: handoffAi,
    });
  } catch (e) {
    return jsonResponse({ error: String(e) }, 500);
  }
});
