import { createClient, SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";
import { corsHeaders, jsonResponse } from "../_shared/cors.ts";
import { ensureChatThread } from "../_shared/chat_db.ts";
import type { ListingDetail } from "../_shared/chat_answer_openai.ts";
import { FaqRule, routeChatMessage } from "../_shared/chat_router.ts";

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
      "id, listing_code, title, project_name, listing_type, price_net, property_type, district, subdistrict, description_public, pet_allowed, furnished, bedrooms, bathrooms, area_sqm, floor_range, max_distance_bts_km",
    )
    .eq("id", listingId)
    .maybeSingle();
  return (data as ListingDetail | null) ?? null;
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

    if (Boolean(body.force_admin_handoff)) {
      const reply = await insertMessage(
        db,
        thread.id,
        "system",
        "คำถามนี้ต้องให้เจ้าหน้าที่ตอบโดยตรง — เราแจ้งทีมแล้ว และจะติดต่อกลับในแชทนี้โดยเร็วที่สุด",
        { requires_admin: true },
      );

      const { data: updated, error: updateError } = await db
        .from("chat_threads")
        .update({
          admin_reply_done: false,
          admin_escalated: true,
          status: "waiting_admin",
          category: "escalation",
          priority: "high",
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
        "property_handoff",
        text,
      );

      return jsonResponse({
        thread: updated,
        user_message: userMsg,
        replies: [reply],
        route_source: "forced_admin_handoff",
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

      return jsonResponse({
        thread: updated,
        user_message: userMsg,
        replies: [reply],
        route_source: "human_only_thread",
      });
    }

    const [faqRules, listingsResult, currentListing] = await Promise.all([
      loadFaqRules(db),
      db
        .from("listings_public")
        .select(
          "id, listing_code, title, project_name, listing_type, price_net, property_type, district",
        )
        .limit(200),
      loadCurrentListing(db, thread.listing_id),
    ]);

    const routed = await routeChatMessage({
      text,
      isStaffRoom: thread.room_kind === "staff_support",
      listingId: thread.listing_id,
      listingCode: thread.listing_code,
      projectName: thread.project_name,
      listings: (listingsResult.data ?? []) as never[],
      faqRules,
      priorUserMessages: priorUserMessages ?? 0,
      unclearStreak: (thread.unclear_streak as number) ?? 0,
      currentListing,
    });

    const reply = await insertMessage(db, thread.id, routed.reply.role, routed.reply.text, {
      requires_admin: routed.reply.requires_admin,
      links: routed.reply.links ?? [],
    });

    const patch: Record<string, unknown> = {
      admin_reply_done: false,
      category: routed.category,
      status: routed.status,
      priority: routed.priority,
      admin_escalated: routed.escalate,
      unclear_streak: routed.unclearStreak,
    };

    if (routed.notifyAdmin) {
      await notifyEscalation(
        { ...thread, ...patch } as ThreadRow,
        routed.escalateReason ?? "escalation",
        text,
      );
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
      replies: [reply],
      route_source: routed.source,
    });
  } catch (e) {
    return jsonResponse({ error: String(e) }, 500);
  }
});
