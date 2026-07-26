import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";
import { requireAdmin } from "../_shared/admin_auth.ts";
import { corsHeaders, jsonResponse } from "../_shared/cors.ts";
import { ensureFemaleAiTone } from "../_shared/chat_ai_voice.ts";
import { shouldAttachViewingFormLink } from "../_shared/chat_owner_viewing_notify.ts";
import {
  phraseCoachGuidanceForUser,
  type ChatTurnMessage,
} from "../_shared/chat_conversational_openai.ts";
import {
  saveLearnedAnswer,
} from "../_shared/chat_learned_memory.ts";
import { sendFcmToUser } from "../_shared/notify.ts";

type CoachMode = "draft" | "confirm";

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const auth = await requireAdmin(req);
    if (auth instanceof Response) return auth;

    const body = await req.json();
    const thread_id = body.thread_id as string | undefined;
    const guidance = (body.guidance as string | undefined)?.trim();
    const mode = ((body.mode as string | undefined) ?? "draft") as CoachMode;
    const confirmed_text = (body.confirmed_text as string | undefined)?.trim();
    const save_scope = (body.save_scope as string | undefined) ?? "global";
    const topic_key = (body.topic_key as string | undefined)?.trim();

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

    if (mode === "confirm") {
      if (!confirmed_text) {
        return jsonResponse({ error: "confirmed_text required" }, 400);
      }

      const { data: lastCoach } = await db
        .from("chat_messages")
        .select("text")
        .eq("thread_id", thread_id)
        .eq("role", "admin_coach")
        .order("created_at", { ascending: false })
        .limit(1)
        .maybeSingle();

      const guidanceForMemory = (lastCoach?.text as string | undefined)?.trim() ||
        confirmed_text;

      const attachForm = shouldAttachViewingFormLink(
        confirmed_text,
        guidanceForMemory,
        thread.coach_question as string | undefined,
      );

      const links = attachForm
        ? [{
          label: "กรอกฟอร์มนัดดู",
          kind: "viewing_form",
          listing_id: (thread.listing_id as string | null) ?? "",
        }]
        : [];

      const { data: aiMsg, error: msgErr } = await db
        .from("chat_messages")
        .insert({
          thread_id,
          role: "ai",
          text: ensureFemaleAiTone(confirmed_text),
          ...(links.length ? { links } : {}),
        })
        .select("*")
        .single();

      if (msgErr) return jsonResponse({ error: msgErr.message }, 400);

      const topicKey = topic_key ||
        `coach_${Date.now().toString(36)}`;

      const { data: lastUser } = await db
        .from("chat_messages")
        .select("text")
        .eq("thread_id", thread_id)
        .eq("role", "user")
        .order("created_at", { ascending: false })
        .limit(1)
        .maybeSingle();

      await saveLearnedAnswer(db, {
        topicKey,
        questionExample: ((lastUser?.text as string) ?? "").slice(0, 500),
        answerGuidance: guidanceForMemory.slice(0, 4000),
        scope: save_scope === "listing" ? "listing" : "global",
        listingId: save_scope === "listing" ? thread.listing_id as string : null,
        propertyType: null,
        sourceThreadId: thread_id,
        createdBy: auth.userId,
      });

      const { data: updated, error: updErr } = await db
        .from("chat_threads")
        .update({
          coach_pending: false,
          coach_question: null,
          status: "open",
          admin_escalated: false,
          assigned_admin_id: auth.userId,
          last_message_at: new Date().toISOString(),
        })
        .eq("id", thread_id)
        .select("*")
        .single();

      if (updErr) return jsonResponse({ error: updErr.message }, 400);

      const userId = thread.user_id as string | undefined;
      const code = (thread.listing_code as string) || "RealXtate";
      await sendFcmToUser(
        db,
        userId,
        "RealXtate — มีข้อความใหม่",
        `${code}: ${confirmed_text.slice(0, 120)}`,
        { type: "chat_reply", thread_id },
      );

      return jsonResponse({
        thread: updated,
        ai_messages: [aiMsg],
        learned_topic: topicKey,
        mode: "confirm",
      });
    }

    if (!guidance) {
      return jsonResponse({ error: "guidance required for draft" }, 400);
    }

    const coachQuestion = (thread.coach_question as string | null) ??
      "คำถามลูกค้า";

    const { data: recentRows } = await db
      .from("chat_messages")
      .select("role, text")
      .eq("thread_id", thread_id)
      .in("role", ["user", "ai", "admin_notice"])
      .order("created_at", { ascending: false })
      .limit(12);

    const recentMessages = ((recentRows ?? []) as { role: string; text: string }[])
      .reverse()
      .map((r) => ({
        role: r.role as ChatTurnMessage["role"],
        text: r.text,
      }));

    const latestUser = [...recentMessages]
      .reverse()
      .find((m) => m.role === "user");
    const userQuestion = latestUser?.text?.trim() || coachQuestion;

    await db.from("chat_messages").insert({
      thread_id,
      role: "admin_coach",
      text: guidance,
      sender_id: auth.userId,
    });

    const bursts = await phraseCoachGuidanceForUser({
      userQuestion,
      coachQuestion,
      adminGuidance: guidance,
      listingCode: thread.listing_code as string | null,
      recentMessages,
    }) ?? [guidance];

    const insertedDrafts = [];
    for (const b of bursts) {
      const { data: msg, error: draftErr } = await db
        .from("chat_messages")
        .insert({
          thread_id,
          role: "ai_draft",
          text: ensureFemaleAiTone(b),
        })
        .select("*")
        .single();
      if (draftErr) return jsonResponse({ error: draftErr.message }, 400);
      insertedDrafts.push(msg);
    }

    const draftText = bursts.join("\n\n");

    const { data: updated, error: updErr } = await db
      .from("chat_threads")
      .update({
        coach_pending: false,
        coach_question: null,
        status: "open",
        assigned_admin_id: auth.userId,
        last_message_at: new Date().toISOString(),
      })
      .eq("id", thread_id)
      .select("*")
      .single();

    if (updErr) return jsonResponse({ error: updErr.message }, 400);

    return jsonResponse({
      thread: updated,
      draft_messages: insertedDrafts,
      draft_text: draftText,
      mode: "draft",
    });
  } catch (e) {
    return jsonResponse({ error: String(e) }, 500);
  }
});
