import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";
import { corsHeaders, jsonResponse } from "../_shared/cors.ts";

const ADMIN_INTERNAL_PREFIX = "🔒[โน้ตแอดมิน] ";

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

type OfferDetails = {
  listing_id?: string;
  listing_code?: string;
  listing_title?: string;
  listing_price?: number;
  external_note?: string;
  tags?: string[];
  offerer_capacity?: string;
  transaction_type?: string;
  demand_post_id?: string;
  from_stock_pick?: boolean;
  cover_url?: string;
  contact_name?: string;
  contact_phone?: string;
};

function capacityLabel(cap?: string): string {
  switch (cap) {
    case "owner_direct_100":
      return "เจ้าของทรัพย์";
    case "co_agent_50_50":
      return "โคเอเจนท์";
    case "referrer_15":
      return "ผู้แนะนำ";
    case "listing_agent":
      return "เอเจนท์ฝั่งประกาศ";
    default:
      return cap ?? "—";
  }
}

function txnLabel(tx?: string): string {
  return tx === "sale" ? "ขาย" : "เช่า";
}

function formatPriceTHB(value?: number): string {
  if (value == null || value <= 0) return "—";
  return `${Math.round(value).toLocaleString("th-TH")} บาท`;
}

function listingLink(details: OfferDetails) {
  if (!details.listing_id) return null;
  const code = details.listing_code ?? "";
  const title = details.listing_title ?? "";
  const label = code && title ? `${code} · ${title}` : (code || title || "ดูประกาศ");
  return {
    label,
    kind: "listing",
    listingId: details.listing_id,
    projectName: title || null,
  };
}

function buildShortSummary(details: OfferDetails, demandPostCode: string): string {
  const tags = (details.tags ?? []).join(" ");
  const lines = [
    tags,
    `• ประกาศหาทรัพย์: ${demandPostCode}`,
    details.listing_code ? `• ทรัพย์ที่เสนอ: ${details.listing_code}` : null,
    details.listing_title ? `• ชื่อทรัพย์: ${details.listing_title}` : null,
    `• ประเภท: ${txnLabel(details.transaction_type)}`,
    `• เสนอในฐานะ: ${capacityLabel(details.offerer_capacity)}`,
    details.listing_price ? `• ราคา: ${formatPriceTHB(details.listing_price)}` : null,
    details.external_note ? `• หมายเหตุ: ${details.external_note}` : null,
  ].filter(Boolean);
  return `สรุปข้อเสนอ\n${lines.join("\n")}`;
}

function buildListingCardText(details: OfferDetails): string {
  const parts = ["ทรัพย์ที่เสนอ"];
  if (details.external_note?.trim()) {
    parts.push(`\nหมายเหตุ: ${details.external_note.trim()}`);
  }
  if (details.listing_code) {
    parts.push(`\nประกาศนี้เสนอโดย ${details.listing_code}`);
  }
  return parts.join("");
}

function buildAdminInternalSummary(
  summary: Record<string, string>,
  details: OfferDetails,
): string {
  const lines = Object.entries(summary).map(([k, v]) => `• ${k}: ${v}`);
  if (details.contact_name || details.contact_phone) {
    lines.push("— ติดต่อผู้เสนอ (แอดมินเท่านั้น) —");
    if (details.contact_name) lines.push(`• ชื่อ: ${details.contact_name}`);
    if (details.contact_phone) lines.push(`• เบอร์: ${details.contact_phone}`);
  }
  return `${ADMIN_INTERNAL_PREFIX}สรุปภายในแอดมิน\n${lines.join("\n")}`;
}

async function forwardToSeeker(
  db: ReturnType<typeof createClient>,
  details: OfferDetails,
  demandPostCode: string,
): Promise<void> {
  if (!details.demand_post_id || !details.listing_id) return;

  let seekerUserId: string | null = null;
  let seekerThreadId: string | null = null;

  const { data: reqRow } = await db
    .from("customer_requirements")
    .select("id, user_id, thread_id")
    .eq("demand_post_id", details.demand_post_id)
    .order("created_at", { ascending: false })
    .limit(1)
    .maybeSingle();

  if (reqRow) {
    seekerUserId = reqRow.user_id as string;
    seekerThreadId = reqRow.thread_id as string | null;
  }

  if (!seekerUserId) {
    const { data: post } = await db
      .from("demand_posts")
      .select("seeker_user_id")
      .eq("id", details.demand_post_id)
      .maybeSingle();
    seekerUserId = post?.seeker_user_id as string | null;
  }

  if (!seekerUserId) return;

  if (!seekerThreadId) {
    const { data: threadByUser } = await db
      .from("chat_threads")
      .select("id")
      .eq("user_id", seekerUserId)
      .eq("category", "customer_requirement")
      .order("last_message_at", { ascending: false })
      .limit(1)
      .maybeSingle();
    seekerThreadId = threadByUser?.id as string | null;
  }

  if (!seekerThreadId && reqRow?.id) {
    const { data: threadByReq } = await db
      .from("chat_threads")
      .select("id")
      .eq("user_id", seekerUserId)
      .eq("customer_requirement_id", reqRow.id)
      .maybeSingle();
    seekerThreadId = threadByReq?.id as string | null;
  }

  if (!seekerThreadId) return;

  const tags = (details.tags ?? []).join(" ");
  const link = listingLink(details);
  const seekerText = [
    "มีทรัพย์เสนอตรงความต้องการของคุณ",
    tags,
    details.external_note?.trim() ? `หมายเหตุ: ${details.external_note.trim()}` : null,
    details.listing_code ? `ประกาศนี้เสนอโดย ${details.listing_code}` : null,
  ].filter(Boolean).join("\n");

  const inserts = [
    {
      thread_id: seekerThreadId,
      role: "system",
      text: seekerText,
      links: link ? [link] : [],
    },
  ];

  await db.from("chat_messages").insert(inserts);
  await db
    .from("chat_threads")
    .update({ last_message_at: new Date().toISOString() })
    .eq("id", seekerThreadId);
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
    const details = (body.details ?? {}) as OfferDetails;

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
          "ทีม RealXtate จะตรวจสอบและติดต่อกลับในแชทนี้",
      });
    }

    const hasListing = Boolean(details.listing_id);
    const link = hasListing ? listingLink(details) : null;

    const inserts: Record<string, unknown>[] = [
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
    ];

    if (hasListing) {
      inserts.push({
        thread_id: thread.id,
        role: "system",
        text: buildShortSummary(details, demandPostCode),
      });
      inserts.push({
        thread_id: thread.id,
        role: "system",
        text: buildListingCardText(details),
        links: link ? [link] : [],
      });
      inserts.push({
        thread_id: thread.id,
        role: "admin_notice",
        text: buildAdminInternalSummary(summary, details),
      });
    } else {
      const lines = Object.entries(summary)
        .map(([k, v]) => `• ${k}: ${v}`)
        .join("\n");
      inserts.push({
        thread_id: thread.id,
        role: "system",
        text: `สรุปข้อเสนอ\n${lines}`,
      });
      inserts.push({
        thread_id: thread.id,
        role: "admin_notice",
        text: "เจ้าหน้าที่จะตรวจสอบข้อเสนอและแจ้งผลในแชทนี้ครับ",
      });
    }

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

    if (hasListing) {
      try {
        await forwardToSeeker(db, details, demandPostCode);
      } catch (_) {
        /* non-fatal */
      }
    }

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
