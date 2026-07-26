import { createClient, SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";
import { corsHeaders, jsonResponse } from "../_shared/cors.ts";
import { ensureChatThread } from "../_shared/chat_db.ts";
import type { ListingDetail } from "../_shared/chat_answer_openai.ts";
import { ensureFemaleAiTone } from "../_shared/chat_ai_voice.ts";
import {
  feedFromChatRoute,
  feedFromCoachRequest,
  feedFromHumanOnlyThread,
} from "../_shared/admin_ai_feed.ts";
import { loadChatBotTrainingSettings } from "../_shared/chat_bot_training_settings.ts";
import { loadLearnedAnswers, bumpLearnedAnswerUse } from "../_shared/chat_learned_memory.ts";
import type { ChatTurnMessage } from "../_shared/chat_conversational_openai.ts";
import { orchestrateAdminFeed } from "../_shared/admin_orchestrator.ts";
import type { FaqRule } from "../_shared/chat_route_shared.ts";
import {
  getLatestUserMessageId,
  loadTrailingUserBurstText,
  waitForUserBurstStable,
} from "../_shared/chat_user_burst.ts";

type ThreadRow = {
  id: string;
  user_id: string;
  room_kind: string;
  listing_id: string | null;
  listing_code: string | null;
  listing_title: string;
  project_name: string | null;
  category: string;
  status: string;
  priority: string;
  viewing_submitted: boolean;
  allow_viewing_request: boolean;
  admin_escalated: boolean;
  admin_reply_done: boolean;
  unclear_streak?: number;
  owner_inquiry_collecting?: boolean;
  owner_inquiry_draft?: string;
  coach_pending?: boolean;
  coach_question?: string | null;
  ai_enabled?: boolean;
  transaction_ref?: string | null;
};

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

function serviceClient(): SupabaseClient {
  return createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );
}

async function ensureThread(
  db: SupabaseClient,
  userId: string,
  body: Record<string, unknown>,
): Promise<ThreadRow> {
  return (await ensureChatThread(db, userId, body)) as ThreadRow;
}

async function insertMessage(
  db: SupabaseClient,
  threadId: string,
  role: string,
  text: string,
  opts: { requires_admin?: boolean; links?: unknown[]; sender_id?: string } = {},
) {
  const { data, error } = await db
    .from("chat_messages")
    .insert({
      thread_id: threadId,
      role,
      text,
      links: opts.links ?? [],
      requires_admin: opts.requires_admin ?? false,
      sender_id: opts.sender_id ?? null,
    })
    .select("*")
    .single();
  if (error) throw new Error(error.message);
  return data;
}

async function loadRecentMessages(
  db: SupabaseClient,
  threadId: string,
): Promise<ChatTurnMessage[]> {
  const { data } = await db
    .from("chat_messages")
    .select("role, text")
    .eq("thread_id", threadId)
    .in("role", ["user", "ai", "admin_notice"])
    .order("created_at", { ascending: false })
    .limit(12);
  const rows = (data ?? []) as { role: string; text: string }[];
  return rows.reverse().map((r) => ({
    role: r.role as ChatTurnMessage["role"],
    text: r.text,
  }));
}

async function loadFaqRules(db: SupabaseClient): Promise<FaqRule[]> {
  const { data } = await db
    .from("chat_faq_rules")
    .select("scope, patterns, reply_text, priority, escalate")
    .eq("is_active", true)
    .order("priority", { ascending: true });
  return (data ?? []) as FaqRule[];
}

async function loadCurrentListing(
  db: SupabaseClient,
  listingId: string | null,
): Promise<ListingDetail | null> {
  if (!listingId) return null;
  const { data } = await db
    .from("listings_public")
    .select(
      "id, listing_code, title, project_name, project_bts, listing_type, price_net, property_type, district, subdistrict, description_public, pet_allowed, furnished, bedrooms, bathrooms, area_sqm, floor_range, max_distance_bts_km, lat, lng, updated_at",
    )
    .eq("id", listingId)
    .maybeSingle();
  if (!data) return null;

  const base = data as ListingDetail & { lat?: number | null; lng?: number | null };
  let mapLat = base.lat ?? null;
  let mapLng = base.lng ?? null;
  let projectBts = base.project_bts ?? null;

  const { data: listingRow } = await db
    .from("listings")
    .select("project_id")
    .eq("id", listingId)
    .maybeSingle();

  const projectId = listingRow?.project_id as string | null | undefined;
  if (projectId) {
    const { data: project } = await db
      .from("property_projects")
      .select("lat, lng, bts_station, name_th")
      .eq("id", projectId)
      .maybeSingle();
    if (project?.lat != null && project?.lng != null) {
      mapLat = Number(project.lat);
      mapLng = Number(project.lng);
      if (project.bts_station) projectBts = String(project.bts_station);
    }
  }

  return {
    ...base,
    map_lat: mapLat,
    map_lng: mapLng,
    project_bts: projectBts,
  };
}

async function notifyEscalation(thread: ThreadRow, reason: string, preview?: string) {
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
        thread_id: thread.id,
        listing_code: thread.listing_code,
        listing_id: thread.listing_id,
        category: thread.category,
        reason,
        preview,
      }),
    });
  } catch (_) {
    // non-fatal
  }
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const userId = await authUserId(req);
    if (!userId) return jsonResponse({ error: "Unauthorized" }, 401);

    const body = await req.json();
    const text = (body.text as string | undefined)?.trim();
    if (!text) return jsonResponse({ error: "text required" }, 400);

    const db = serviceClient();
    const thread = await ensureThread(db, userId, body);

    const { count: priorUserMessages } = await db
      .from("chat_messages")
      .select("id", { count: "exact", head: true })
      .eq("thread_id", thread.id)
      .eq("role", "user");

    const userMsg = await insertMessage(db, thread.id, "user", text, {
      sender_id: userId,
    });

    if (thread.ai_enabled === false) {
      const { data: updated, error: updateError } = await db
        .from("chat_threads")
        .update({
          last_message_at: new Date().toISOString(),
        })
        .eq("id", thread.id)
        .select("*")
        .single();

      if (updateError) {
        return jsonResponse({ error: updateError.message }, 400);
      }

      return jsonResponse({
        thread: updated,
        user_message: userMsg,
        replies: [],
        route_source: "ai_paused",
      });
    }

    const humanOnlyCategories = new Set([
      "customer_requirement",
      "demand_offer",
    ]);
    if (humanOnlyCategories.has(thread.category)) {
      const ackText =
        "ได้รับข้อความแล้วครับ ทีมงานจะตอบกลับในแชทนี้";
      const reply = await insertMessage(db, thread.id, "admin_notice", ackText);

      const { data: updated, error: updateError } = await db
        .from("chat_threads")
        .update({
          admin_reply_done: false,
          admin_escalated: true,
          status: "waiting_admin",
          unclear_streak: 0,
          last_message_at: new Date().toISOString(),
        })
        .eq("id", thread.id)
        .select("*")
        .single();

      if (updateError) {
        return jsonResponse({ error: updateError.message }, 400);
      }

      await notifyEscalation(
        { ...thread, ...updated } as ThreadRow,
        thread.category,
        text,
      );

      await orchestrateAdminFeed(
        db,
        "chat-turn-human-only",
        feedFromHumanOnlyThread({
          threadId: thread.id,
          listingCode: thread.listing_code,
          listingId: thread.listing_id,
          category: thread.category,
          userText: text,
        }),
      );

      return jsonResponse({
        thread: updated,
        user_message: userMsg,
        replies: [reply],
        route_source: "human_only_thread",
      });
    }

    const latestAfterBurst = await waitForUserBurstStable(db, thread.id);
    if (latestAfterBurst && latestAfterBurst !== userMsg.id) {
      const { data: touch } = await db
        .from("chat_threads")
        .update({ last_message_at: new Date().toISOString() })
        .eq("id", thread.id)
        .select("*")
        .single();
      return jsonResponse({
        thread: touch ?? thread,
        user_message: userMsg,
        replies: [],
        route_source: "burst_coalesce",
      });
    }

    const routeText = (await loadTrailingUserBurstText(db, thread.id)).trim() ||
      text;

    const [faqRules, listingsResult, currentListing, recentMessages, learnedAnswers, botTraining] =
      await Promise.all([
      loadFaqRules(db),
      db
        .from("listings_public")
        .select(
          "id, listing_code, title, project_name, listing_type, price_net, property_type, district",
        )
        .limit(200),
      loadCurrentListing(db, thread.listing_id),
      loadRecentMessages(db, thread.id),
      loadLearnedAnswers(db, {
        listingId: thread.listing_id,
        propertyType: null,
        userText: routeText,
      }),
      loadChatBotTrainingSettings(db),
    ]);

    const { routeChatMessage } = await import("../_shared/chat_router.ts");

    const routed = await routeChatMessage({
      text: routeText,
      isStaffRoom: thread.room_kind === "staff_support",
      listingId: thread.listing_id,
      listingCode: thread.listing_code,
      projectName: thread.project_name,
      listings: (listingsResult.data ?? []) as never[],
      faqRules,
      priorUserMessages: priorUserMessages ?? 0,
      unclearStreak: (thread.unclear_streak as number) ?? 0,
      currentListing,
      ownerInquiryCollecting: thread.owner_inquiry_collecting === true,
      ownerInquiryDraft: (thread.owner_inquiry_draft as string) ?? "",
      recentMessages,
      learnedAnswers,
      botTraining,
      db,
      threadId: thread.id,
      userId,
      threadCategory: thread.category,
      viewingSubmitted: thread.viewing_submitted === true,
      listingTitle: thread.listing_title,
      transactionRef: thread.transaction_ref,
    });

    const stillLatest = await getLatestUserMessageId(db, thread.id);
    if (stillLatest && stillLatest !== userMsg.id) {
      return jsonResponse({
        thread,
        user_message: userMsg,
        replies: [],
        route_source: "burst_coalesce_late",
      });
    }

    const replyList = [
      ...(routed.replies ?? [routed.reply]),
      ...(routed.coachReplies ?? []),
    ];
    const insertedReplies = [];
    for (const r of replyList) {
      const botText = r.role === "admin_notice" || r.role === "admin_coach"
        ? r.text
        : ensureFemaleAiTone(r.text);
      insertedReplies.push(
        await insertMessage(db, thread.id, r.role, botText, {
          requires_admin: r.requires_admin,
          links: r.links ?? [],
        }),
      );
    }
    // ลูกค้าได้แค่ข้อความที่ควรเห็น — admin_coach อยู่ใน DB ให้แอดมิน/console เท่านั้น
    const customerReplies = insertedReplies.filter(
      (m) => (m as { role?: string }).role !== "admin_coach",
    );

    const patch: Record<string, unknown> = {
      admin_reply_done: false,
      category: routed.category,
      status: routed.status,
      priority: routed.priority,
      admin_escalated: routed.escalate,
      unclear_streak: routed.unclearStreak,
      coach_pending: routed.coachPending ?? false,
      coach_question: routed.coachQuestion ?? null,
    };

    if (routed.ownerInquiryCollecting !== undefined) {
      patch.owner_inquiry_collecting = routed.ownerInquiryCollecting;
      patch.owner_inquiry_draft = routed.ownerInquiryDraft ?? "";
    }

    if (routed.viewingSubmitted) {
      patch.viewing_submitted = true;
    }

    if (routed.learnedAnswerId) {
      await bumpLearnedAnswerUse(db, routed.learnedAnswerId);
    }

    if (routed.notifyAdmin) {
      await notifyEscalation(
        { ...thread, ...patch } as ThreadRow,
        routed.escalateReason ?? "escalation",
        routeText,
      );
    }

    const feedInput = routed.coachPending && routed.coachQuestion
      ? feedFromCoachRequest({
        threadId: thread.id,
        listingCode: thread.listing_code,
        listingId: thread.listing_id,
        userText: routeText,
        coachQuestion: routed.coachQuestion,
      })
      : feedFromChatRoute({
        threadId: thread.id,
        listingCode: thread.listing_code,
        listingId: thread.listing_id,
        source: routed.source,
        escalate: routed.escalate,
        escalateReason: routed.escalateReason,
        userText: routeText,
      });
    if (feedInput) {
      await orchestrateAdminFeed(db, "chat-turn", feedInput);
    }

    const { data: updated, error: updateError } = await db
      .from("chat_threads")
      .update(patch)
      .eq("id", thread.id)
      .select("*")
      .single();

    if (updateError) {
      return jsonResponse({ error: updateError.message }, 400);
    }

    return jsonResponse({
      thread: updated,
      user_message: userMsg,
      replies: customerReplies,
      route_source: routed.source,
    });
  } catch (e) {
    return jsonResponse({ error: String(e) }, 500);
  }
});
