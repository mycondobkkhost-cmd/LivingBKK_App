import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";
import { feedFromOwnerAccepted } from "../_shared/admin_ai_feed.ts";
import { orchestrateAdminFeed } from "../_shared/admin_orchestrator.ts";
import { corsHeaders, jsonResponse } from "../_shared/cors.ts";
import { sendFcmToUser } from "../_shared/notify.ts";

type OwnerViewingResponse = {
  mode: "confirm_requested" | "propose_alternative";
  schedule?: string;
  proposed_date?: string;
  time_start?: string;
  time_end?: string;
  note?: string;
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

async function canActOnLead(
  db: ReturnType<typeof createClient>,
  lead: Record<string, unknown>,
  userId: string,
): Promise<boolean> {
  if (lead.assigned_to === userId) return true;
  const listingId = lead.listing_id as string | null;
  if (!listingId) return false;
  const { data: listing } = await db
    .from("listings")
    .select("owner_id, created_by_id")
    .eq("id", listingId)
    .maybeSingle();
  if (!listing) return false;
  return listing.owner_id === userId || listing.created_by_id === userId;
}

async function resolveCustomerThreadId(
  db: ReturnType<typeof createClient>,
  lead: Record<string, unknown>,
): Promise<string | null> {
  const direct = lead.thread_id as string | null;
  if (direct) return direct;

  const seekerId = lead.seeker_id as string | null;
  const listingCode = lead.listing_code as string | null;
  if (!seekerId || !listingCode) return null;

  const { data } = await db
    .from("chat_threads")
    .select("id")
    .eq("listing_code", listingCode)
    .eq("user_id", seekerId)
    .order("last_message_at", { ascending: false })
    .limit(1)
    .maybeSingle();

  const threadId = data?.id as string | undefined;
  if (threadId) {
    await db.from("leads").update({ thread_id: threadId }).eq("id", lead.id);
  }
  return threadId ?? null;
}

function requestedScheduleFromLead(lead: Record<string, unknown>): string {
  const qual = lead.qualification_json as Record<string, unknown> | null;
  const fromQual = qual?.viewing_schedule?.toString().trim();
  if (fromQual) return fromQual;
  return "ตามวันเวลาที่ลูกค้าเสนอ";
}

function formatThaiDate(isoDate: string | undefined): string {
  if (!isoDate) return "—";
  const d = new Date(`${isoDate}T12:00:00`);
  if (Number.isNaN(d.getTime())) return isoDate;
  return `${d.getDate()}/${d.getMonth() + 1}/${d.getFullYear() + 543}`;
}

function formatTimeRange(start?: string, end?: string): string {
  if (start && end) return `${start} – ${end} น.`;
  if (start) return `${start} น.`;
  return "—";
}

function scheduleSummary(
  resp: OwnerViewingResponse | undefined,
  requestedSchedule: string,
): string {
  if (!resp || resp.mode === "confirm_requested") {
    return resp?.schedule?.trim() || requestedSchedule;
  }
  const dateLine = formatThaiDate(resp.proposed_date);
  const timeLine = formatTimeRange(resp.time_start, resp.time_end);
  return `${dateLine} · ${timeLine}`;
}

function buildCustomerAiMessage(
  listingCode: string,
  resp: OwnerViewingResponse | undefined,
  requestedSchedule: string,
): string {
  const when = scheduleSummary(resp, requestedSchedule);
  const note = resp?.note?.trim();

  if (!resp || resp.mode === "confirm_requested") {
    let msg =
      `✅ ยืนยันรับนัดชมทรัพย์แล้วค่ะ\n` +
      `📅 ${when}\n`;
    if (note) msg += `📝 ${note}\n`;
    msg +=
      `\nเจ้าของทรัพย์ (${listingCode}) ยืนยันรับเคสแล้ว — ` +
      `ทีมงาน RealXtate จะติดตามและยืนยันนัดอีกครั้งก่อนวันนัดค่ะ`;
    return msg;
  }

  let msg =
    `เจ้าของทรัพย์ (${listingCode}) แจ้งว่าไม่สะดวกตามวันเวลาที่เสนอไว้\n` +
    `📅 เสนอนัดใหม่: ${when}\n`;
  if (note) msg += `📝 ${note}\n`;
  msg += `\nทีมงาน RealXtate จะประสานยืนยันกับคุณอีกครั้งเร็วๆ นี้ค่ะ`;
  return msg;
}

function buildAdminNotice(
  listingCode: string,
  resp: OwnerViewingResponse | undefined,
  requestedSchedule: string,
): string {
  const when = scheduleSummary(resp, requestedSchedule);
  const note = resp?.note?.trim();
  const modeLabel = resp?.mode === "propose_alternative"
    ? "เจ้าของรับเคส — เสนอวันเวลาใหม่"
    : "เจ้าของยืนยันรับเคสตามที่ลูกค้าขอ";

  const lines = [
    `[Owner] ${modeLabel} (${listingCode})`,
    `📅 ${when}`,
  ];
  if (note) lines.push(`📝 ${note}`);
  lines.push("", "AI แจ้งลูกค้าแล้ว — โปรดตรวจสอบและยืนยันนัดต่อ");
  return lines.join("\n");
}

async function postAcceptanceNotifications(
  db: ReturnType<typeof createClient>,
  params: {
    lead: Record<string, unknown>;
    leadId: string;
    threadId: string | null;
    listingCode: string;
    ownerViewingResponse?: OwnerViewingResponse;
  },
): Promise<void> {
  const now = new Date().toISOString();
  const requested = requestedScheduleFromLead(params.lead);
  const resp = params.ownerViewingResponse;
  const when = scheduleSummary(resp, requested);

  if (params.threadId) {
    const customerMsg = buildCustomerAiMessage(
      params.listingCode,
      resp,
      requested,
    );
    await db.from("chat_messages").insert({
      thread_id: params.threadId,
      role: "ai",
      text: customerMsg,
    });
    await db.from("chat_messages").insert({
      thread_id: params.threadId,
      role: "admin_notice",
      text: buildAdminNotice(params.listingCode, resp, requested),
      requires_admin: true,
    });
    await db.from("chat_threads").update({
      last_message_at: now,
      category: "viewing_request",
      admin_escalated: true,
      admin_reply_done: false,
    }).eq("id", params.threadId);

    const seekerId = params.lead.seeker_id as string | null;
    if (seekerId) {
      await sendFcmToUser(
        db,
        seekerId,
        "RealXtate — ยืนยันนัดชมทรัพย์",
        `${params.listingCode}: ${when}`,
        {
          type: "owner_accepted",
          thread_id: params.threadId,
          lead_id: params.leadId,
        },
      );
    }
  }

  await orchestrateAdminFeed(
    db,
    "owner-lead-action",
    feedFromOwnerAccepted({
      leadId: params.leadId,
      threadId: params.threadId,
      listingCode: params.listingCode,
      listingId: params.lead.listing_id as string | null,
      scheduleSummary: when,
      mode: resp?.mode ?? "confirm_requested",
    }),
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
    const lead_id = body.lead_id as string | undefined;
    const action = body.action as string | undefined;
    if (!lead_id || !action) {
      return jsonResponse({ error: "lead_id and action required" }, 400);
    }

    const ownerViewingResponse = body.owner_viewing_response as
      | OwnerViewingResponse
      | undefined;

    const db = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );

    const { data: lead, error: leadErr } = await db
      .from("leads")
      .select("*")
      .eq("id", lead_id)
      .single();

    if (leadErr || !lead) {
      return jsonResponse({ error: "Lead not found" }, 404);
    }

    if (!(await canActOnLead(db, lead as Record<string, unknown>, userId))) {
      return jsonResponse({ error: "Forbidden" }, 403);
    }

    const status = lead.status as string;
    const listingCode = (lead.listing_code as string) ?? "";
    const threadId = await resolveCustomerThreadId(
      db,
      lead as Record<string, unknown>,
    );

    if (action === "notify_acceptance") {
      if (status !== "accepted") {
        return jsonResponse({ error: "Lead not accepted yet" }, 409);
      }
      await postAcceptanceNotifications(db, {
        lead: lead as Record<string, unknown>,
        leadId: lead_id,
        threadId,
        listingCode,
        ownerViewingResponse,
      });
      return jsonResponse({
        success: true,
        action: "notify_acceptance",
        lead_id,
        thread_id: threadId,
      });
    }

    if (status !== "new" && status !== "routed") {
      return jsonResponse({ error: "Lead already processed" }, 409);
    }

    const now = new Date().toISOString();

    if (action === "accept") {
      const tierId = body.commission_tier_id as string | undefined;
      const notesPayload = ownerViewingResponse
        ? JSON.stringify(ownerViewingResponse)
        : null;

      const assignment = await db
        .from("lead_assignments")
        .insert({
          lead_id,
          assignee_id: userId,
          action: "accepted",
          commission_tier_id: tierId ?? null,
          contract_accepted_at: now,
          notes: notesPayload,
        })
        .select("id")
        .single();

      if (assignment.error) {
        return jsonResponse({ error: assignment.error.message }, 400);
      }

      await db.from("leads").update({
        status: "accepted",
        assigned_to: userId,
      }).eq("id", lead_id);

      if (tierId) {
        await db.from("e_contracts").insert({
          lead_assignment_id: assignment.data!.id,
          commission_tier_id: tierId,
          signer_id: userId,
          signed_at: now,
          metadata: { channel: "in_app", version: "1.0" },
        });
      }

      await postAcceptanceNotifications(db, {
        lead: lead as Record<string, unknown>,
        leadId: lead_id,
        threadId,
        listingCode,
        ownerViewingResponse,
      });

      return jsonResponse({
        success: true,
        action: "accept",
        lead_id,
        thread_id: threadId,
      });
    }

    if (action === "unavailable") {
      const unavailableUntil = body.unavailable_until as string | undefined;
      const availableAgain = body.available_again as string | undefined;
      if (!unavailableUntil) {
        return jsonResponse({ error: "unavailable_until required" }, 400);
      }

      await db.from("lead_assignments").insert({
        lead_id,
        assignee_id: userId,
        action: "declined_unavailable",
        unavailable_until: unavailableUntil,
        available_again: availableAgain ?? null,
      });

      await db.from("leads").update({ status: "declined" }).eq("id", lead_id);

      const listingId = lead.listing_id as string | null;
      if (listingId && availableAgain) {
        await db.from("listings").update({
          available_again: availableAgain,
        }).eq("id", listingId);
      }

      if (threadId) {
        await db.from("chat_messages").insert({
          thread_id: threadId,
          role: "ai",
          text:
            `ขออภัยค่ะ — เจ้าของทรัพย์ (${listingCode}) แจ้งว่าทรัพย์ไม่ว่างในช่วงนี้\n` +
            "ทีมงาน RealXtate จะช่วยหาทางเลือกอื่นให้ค่ะ",
        });
        await db.from("chat_threads").update({ last_message_at: now }).eq(
          "id",
          threadId,
        );
      }

      return jsonResponse({ success: true, action: "unavailable", lead_id });
    }

    return jsonResponse({ error: "Unknown action" }, 400);
  } catch (e) {
    return jsonResponse({ error: String(e) }, 500);
  }
});
