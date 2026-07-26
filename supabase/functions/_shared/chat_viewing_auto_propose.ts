import type { SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";
import { feedFromViewingSubmitted } from "./admin_ai_feed.ts";
import { orchestrateAdminFeed } from "./admin_orchestrator.ts";
import { ensureFemaleAiTone } from "./chat_ai_voice.ts";
import type { ChatTurnMessage } from "./chat_conversational_openai.ts";
import type { BotReply } from "./chat_logic.ts";
import type { RouteResult } from "./chat_route_shared.ts";
import {
  isViewingRequestIntent,
  parseProposedViewingSchedule,
} from "./viewing_request_voice.ts";

type LeadRow = {
  id: string;
  seeker_nickname: string;
  seeker_phone: string;
  occupation?: string | null;
  move_plan?: string | null;
  contract_duration?: string | null;
  budget?: number | null;
  qualification_json?: Record<string, unknown> | null;
  listing_id?: string | null;
  listing_code?: string | null;
};

function aiBurst(texts: string[]): BotReply[] {
  return texts.map((t) => ({ role: "ai" as const, text: ensureFemaleAiTone(t) }));
}

function coachResult(params: {
  userBursts: string[];
  coachQuestion: string;
  topicKey?: string;
  category: string;
  analysisNote?: string;
  links?: BotReply["links"];
}): RouteResult {
  const userReplies = aiBurst(params.userBursts);
  const analysisLine = params.analysisNote
    ? `\n\n📊 วิเคราะห์: ${params.analysisNote}`
    : "";
  const coachText =
    `🤖 ขอคำแนะนำค่ะ — ลูกค้าถามว่า:\n「${params.coachQuestion}」${analysisLine}\n\n` +
    `พิมพ์แนวทางตอบ + กลยุทธ์ (นัดดู / ปิดการขาย / กรอกฟอร์ม) จะส่งให้ลูกค้าในแชทให้ค่ะ`;
  const last = userReplies.length - 1;
  if (params.links?.length && last >= 0) {
    userReplies[last] = { ...userReplies[last], links: params.links };
  }
  return {
    reply: userReplies[last],
    replies: userReplies,
    category: params.category,
    status: "waiting_admin",
    priority: "high",
    escalate: false,
    notifyAdmin: true,
    source: "viewing_auto_propose",
    unclearStreak: 0,
    coachPending: true,
    coachQuestion: params.coachQuestion,
    coachReplies: [{ role: "admin_coach", text: coachText }],
    coachTopicKey: params.topicKey,
  };
}

function isViewingFollowUp(params: {
  threadCategory?: string;
  viewingSubmitted?: boolean;
  recentMessages?: ChatTurnMessage[];
}): boolean {
  if (params.threadCategory === "viewing_request") return true;
  if (params.viewingSubmitted) return true;
  const recent = params.recentMessages ?? [];
  return recent.some((m) => {
    if (m.role === "user" && isViewingRequestIntent(m.text)) return true;
    if (m.role === "ai" && /นัดดู|สะดวก.*โมง|เช็กคิว|กรอกฟอร์มนัดดู/.test(m.text)) {
      return true;
    }
    return false;
  });
}

function censorPhone(phone: string): string {
  const digits = phone.replace(/\D/g, "");
  if (digits.length < 6) return "***";
  return `${digits.slice(0, 2)}x-xxx-${digits.slice(-4)}`;
}

function parseProfileFromSystemText(text: string): Record<string, string> {
  const out: Record<string, string> = {};
  if (!text.includes("สรุปโปรไฟล์")) return out;
  for (const line of text.split("\n")) {
    const m = line.match(/^[•\-]\s*([^:]+):\s*(.+)$/);
    if (m) out[m[1].trim()] = m[2].trim();
  }
  return out;
}

async function loadParsedProfileFromThread(
  db: SupabaseClient,
  threadId: string,
): Promise<Record<string, string>> {
  const { data } = await db
    .from("chat_messages")
    .select("text")
    .eq("thread_id", threadId)
    .eq("role", "system")
    .ilike("text", "%สรุปโปรไฟล์%")
    .order("created_at", { ascending: false })
    .limit(1);
  const row = (data ?? [])[0] as { text?: string } | undefined;
  return row?.text ? parseProfileFromSystemText(row.text) : {};
}

async function loadLeadForThread(
  db: SupabaseClient,
  params: {
    threadId: string;
    userId: string;
    listingId: string | null;
    listingCode: string | null;
  },
): Promise<LeadRow | null> {
  const { data: byThread } = await db
    .from("leads")
    .select(
      "id, seeker_nickname, seeker_phone, occupation, move_plan, contract_duration, budget, qualification_json, listing_id, listing_code",
    )
    .eq("thread_id", params.threadId)
    .order("created_at", { ascending: false })
    .limit(1);
  if ((byThread ?? []).length > 0) return byThread![0] as LeadRow;

  if (params.listingId) {
    const { data: byListing } = await db
      .from("leads")
      .select(
        "id, seeker_nickname, seeker_phone, occupation, move_plan, contract_duration, budget, qualification_json, listing_id, listing_code",
      )
      .eq("seeker_id", params.userId)
      .eq("listing_id", params.listingId)
      .order("created_at", { ascending: false })
      .limit(1);
    if ((byListing ?? []).length > 0) return byListing![0] as LeadRow;
  }

  if (params.listingCode) {
    const { data: byCode } = await db
      .from("leads")
      .select(
        "id, seeker_nickname, seeker_phone, occupation, move_plan, contract_duration, budget, qualification_json, listing_id, listing_code",
      )
      .eq("seeker_id", params.userId)
      .eq("listing_code", params.listingCode)
      .order("created_at", { ascending: false })
      .limit(1);
    if ((byCode ?? []).length > 0) return byCode![0] as LeadRow;
  }

  return null;
}

function buildSummaryFromLead(
  lead: LeadRow,
  schedule: string,
  listingCode: string | null,
  listingTitle?: string | null,
): Record<string, string> {
  const qual = (lead.qualification_json ?? {}) as Record<string, unknown>;
  const budgetMin = qual.budget_min;
  const budgetMax = qual.budget_max;
  let budgetLine = "";
  if (budgetMin != null && budgetMax != null) {
    budgetLine = `${budgetMin} – ${budgetMax} บาท/เดือน`;
  } else if (lead.budget != null) {
    budgetLine = `${lead.budget} บาท/เดือน`;
  }

  const summary: Record<string, string> = {
    "ชื่อเล่น": lead.seeker_nickname,
    "ชื่อ": lead.seeker_nickname,
    "เบอร์": lead.seeker_phone,
    "นัดดูทรัพย์": schedule,
  };
  if (listingCode) {
    summary["ทรัพย์"] = listingTitle
      ? `${listingCode} · ${listingTitle}`
      : listingCode;
  }
  if (lead.occupation) summary["อาชีพ"] = lead.occupation;
  if (lead.move_plan) summary["แผนย้ายเข้า"] = lead.move_plan;
  if (lead.contract_duration) summary["สัญญา"] = lead.contract_duration;
  if (budgetLine) summary["งบ"] = budgetLine;
  return summary;
}

function buildSummaryFromParsedProfile(
  parsed: Record<string, string>,
  schedule: string,
  listingCode: string | null,
  listingTitle?: string | null,
): Record<string, string> {
  const nickname = parsed["ชื่อเล่น"] ?? parsed["ชื่อ"] ?? parsed["Nickname"] ?? "";
  const phone = parsed["เบอร์"] ?? parsed["Phone"] ?? "";
  const summary: Record<string, string> = { ...parsed };
  if (nickname) {
    summary["ชื่อเล่น"] = nickname;
    summary["ชื่อ"] = nickname;
  }
  if (phone) summary["เบอร์"] = phone;
  summary["นัดดูทรัพย์"] = schedule;
  if (listingCode && !summary["ทรัพย์"]) {
    summary["ทรัพย์"] = listingTitle
      ? `${listingCode} · ${listingTitle}`
      : listingCode;
  }
  return summary;
}

function ownerSafeSummary(
  lead: LeadRow | null,
  parsed: Record<string, string>,
  schedule: string,
): string {
  const nickname = lead?.seeker_nickname ??
    parsed["ชื่อเล่น"] ?? parsed["ชื่อ"] ?? "ลูกค้า";
  const phone = lead?.seeker_phone ?? parsed["เบอร์"] ?? "";
  const lines = [
    `ชื่อเล่น: ${nickname}`,
    `เบอร์: ${censorPhone(phone)}`,
    ...(lead?.occupation ? [`อาชีพ: ${lead.occupation}`] : []),
    ...(parsed["งบ"] ? [`งบ: ${parsed["งบ"]}`] : []),
    `ลูกค้าขอนัด: ${schedule}`,
  ];
  return lines.join("\n");
}

async function resolveOwnerId(
  db: SupabaseClient,
  listingId: string | null,
  listingCode: string | null,
): Promise<string | null> {
  if (listingId) {
    const { data } = await db
      .from("listings")
      .select("owner_id, created_by_id")
      .eq("id", listingId)
      .maybeSingle();
    if (data) {
      return (data.owner_id ?? data.created_by_id) as string | null;
    }
  }
  if (listingCode) {
    const { data } = await db
      .from("listings")
      .select("owner_id, created_by_id")
      .eq("listing_code", listingCode)
      .maybeSingle();
    if (data) {
      return (data.owner_id ?? data.created_by_id) as string | null;
    }
  }
  return null;
}

async function recordViewingOnThread(
  db: SupabaseClient,
  params: {
    threadId: string;
    summary: Record<string, string>;
    transactionRef?: string | null;
    duplicate?: boolean;
  },
): Promise<void> {
  const viewing = params.summary["นัดดูทรัพย์"] ?? "-";
  const lines = Object.entries(params.summary)
    .map(([k, v]) => `• ${k}: ${v}`)
    .join("\n");

  const inserts: Array<Record<string, unknown>> = [
    {
      thread_id: params.threadId,
      role: "system",
      text:
        "ระบบได้รับคำขอของคุณแล้ว\n" +
        "ทีมงานจะติดต่อกลับหาคุณโดยเร็วที่สุด บางกรณีอาจเป็นการโทรติดต่อกลับ" +
        (params.transactionRef
          ? `\nเลขอ้างอิง: ${params.transactionRef}`
          : ""),
    },
  ];
  if (params.duplicate) {
    inserts.push({
      thread_id: params.threadId,
      role: "admin_notice",
      text: "⚠️ แจ้งทีมงาน: พบ 4 ตัวท้ายเบอร์ลูกค้าซ้ำในระบบ — รอตรวจสอบ",
    });
  }
  inserts.push(
    {
      thread_id: params.threadId,
      role: "system",
      text: `สรุปโปรไฟล์ลูกค้า\n${lines}`,
    },
    {
      thread_id: params.threadId,
      role: "admin_notice",
      text:
        `รายละเอียดนัดดู: ${viewing}\n` +
        "เจ้าหน้าที่จะยืนยันนัดและประสานงานให้ครับ",
    },
  );

  await db.from("chat_messages").insert(inserts);
  await db.from("chat_threads").update({
    viewing_submitted: true,
    admin_escalated: true,
    admin_reply_done: false,
    category: "viewing_request",
    status: "waiting_admin",
    priority: "high",
  }).eq("id", params.threadId);
}

async function notifyOwnerViewingRequest(
  db: SupabaseClient,
  params: {
    ownerUserId: string;
    listingId: string | null;
    listingCode: string;
    listingTitle?: string | null;
    projectName?: string | null;
    messageText: string;
    leadId: string;
  },
): Promise<void> {
  let threadRow: Record<string, unknown> | null = null;
  if (params.listingId) {
    const { data } = await db
      .from("chat_threads")
      .select("*")
      .eq("user_id", params.ownerUserId)
      .eq("listing_id", params.listingId)
      .maybeSingle();
    threadRow = data;
  }
  if (!threadRow) {
    const { data } = await db
      .from("chat_threads")
      .select("*")
      .eq("user_id", params.ownerUserId)
      .eq("listing_code", params.listingCode)
      .order("last_message_at", { ascending: false })
      .limit(1)
      .maybeSingle();
    threadRow = data;
  }

  let threadId = threadRow?.id as string | undefined;
  if (!threadId) {
    const { data: created } = await db
      .from("chat_threads")
      .insert({
        user_id: params.ownerUserId,
        room_kind: "property",
        listing_id: params.listingId,
        listing_code: params.listingCode,
        listing_title: params.listingTitle ?? params.listingCode,
        project_name: params.projectName,
        category: "viewing_request",
        status: "waiting_admin",
        priority: "high",
        admin_escalated: true,
        admin_reply_done: false,
        viewing_submitted: true,
      })
      .select("*")
      .single();
    threadId = created?.id as string | undefined;
  }
  if (!threadId) return;

  await db.from("chat_messages").insert({
    thread_id: threadId,
    role: "admin_notice",
    text: params.messageText,
    requires_admin: false,
  });
  await db.from("chat_threads").update({
    category: "viewing_request",
    status: "waiting_admin",
    priority: "high",
    admin_escalated: true,
    admin_reply_done: false,
    viewing_submitted: true,
    last_message_at: new Date().toISOString(),
  }).eq("id", threadId);
}

async function notifyEscalation(
  threadId: string,
  listingCode: string | null,
  listingId: string | null,
  preview: string,
): Promise<void> {
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
        listing_code: listingCode,
        listing_id: listingId,
        reason: "viewing_request",
        preview,
      }),
    });
  } catch (_) {
    // non-fatal
  }
}

async function routeLeadToOwner(leadId: string): Promise<void> {
  const base = Deno.env.get("SUPABASE_URL")!;
  const key = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
  try {
    await fetch(`${base}/functions/v1/route-lead-notification`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${key}`,
      },
      body: JSON.stringify({ lead_id: leadId, channel: "owner_viewing_profile" }),
    });
  } catch (_) {
    // non-fatal
  }
}

export function shouldAutoProposeViewing(params: {
  text: string;
  hasListing: boolean;
  threadCategory?: string;
  viewingSubmitted?: boolean;
  recentMessages?: ChatTurnMessage[];
}): boolean {
  if (!params.hasListing) return false;
  if (!parseProposedViewingSchedule(params.text)) return false;
  return isViewingRequestIntent(params.text) ||
    isViewingFollowUp({
      threadCategory: params.threadCategory,
      viewingSubmitted: params.viewingSubmitted,
      recentMessages: params.recentMessages,
    });
}

/** กรอกฟอร์มนัดดูอัตโนมัติ + ส่งโปรไฟล์หาเจ้าของเมื่อมีข้อมูลลูกค้า */
export async function autoProposeViewingFromSlot(
  db: SupabaseClient,
  params: {
    threadId: string;
    userId: string;
    text: string;
    listingId: string | null;
    listingCode: string | null;
    listingTitle?: string | null;
    projectName?: string | null;
    transactionRef?: string | null;
    threadCategory?: string;
    viewingSubmitted?: boolean;
    recentMessages?: ChatTurnMessage[];
  },
): Promise<RouteResult> {
  const schedule = parseProposedViewingSchedule(params.text);
  if (!schedule) {
    return coachResult({
      userBursts: [
        "ขอบคุณที่สนใจนัดดูนะคะ แอดมินจะเช็กคิวกับเจ้าของและเวลาทำการนิติให้ก่อนค่ะ",
      ],
      coachQuestion: params.text,
      topicKey: "viewing_time_proposed",
      category: "viewing_request",
    });
  }

  const lead = await loadLeadForThread(db, {
    threadId: params.threadId,
    userId: params.userId,
    listingId: params.listingId,
    listingCode: params.listingCode,
  });
  const parsedProfile = await loadParsedProfileFromThread(db, params.threadId);
  const hasProfile = lead != null ||
    Boolean(parsedProfile["ชื่อเล่น"] ?? parsedProfile["ชื่อ"]);

  if (!hasProfile) {
    return coachResult({
      userBursts: [
        `รับทราบเวลา ${schedule} ค่ะ แอดมินจะเช็กคิวกับเจ้าของและนิติให้ก่อนยืนยันนะคะ`,
        "รบกวนกรอกฟอร์มนัดดูในแชทนี้ เพื่อให้ทีมส่งโปรไฟล์และคำขอนัดไปหาเจ้าของได้เลยค่ะ",
      ],
      coachQuestion: params.text,
      topicKey: "viewing_time_need_profile",
      category: "viewing_request",
      analysisNote: `ลูกค้าระบุเวลา ${schedule} แต่ยังไม่มีโปรไฟล์ — ต้องกรอกฟอร์มก่อนส่งเจ้าของ`,
      links: [{
        label: "กรอกฟอร์มนัดดู",
        kind: "viewing_form",
        listingId: params.listingId ?? "",
      }],
    });
  }

  const summary = lead
    ? buildSummaryFromLead(
      lead,
      schedule,
      params.listingCode,
      params.listingTitle,
    )
    : buildSummaryFromParsedProfile(
      parsedProfile,
      schedule,
      params.listingCode,
      params.listingTitle,
    );

  const duplicate = Boolean(
    (lead?.qualification_json as Record<string, unknown> | undefined)
      ?.duplicate_phone_suffix,
  );

  await recordViewingOnThread(db, {
    threadId: params.threadId,
    summary,
    transactionRef: params.transactionRef,
    duplicate,
  });

  if (lead) {
    const qual = { ...(lead.qualification_json ?? {}) } as Record<string, unknown>;
    qual.viewing_schedule = schedule;
    await db.from("leads").update({
      qualification_json: qual,
      updated_at: new Date().toISOString(),
    }).eq("id", lead.id);
  }

  const listingCode = params.listingCode ?? lead?.listing_code ?? "ทรัพย์";
  const ownerId = await resolveOwnerId(db, params.listingId, listingCode);
  const ownerSummary = ownerSafeSummary(lead, parsedProfile, schedule);

  if (ownerId && lead?.id) {
    const messageText =
      `คำขอนัดดูจากทีม RealXtate (${listingCode})\n` +
      `ลูกค้าขอนัด: ${schedule}\n` +
      `กรุณาพิจารณายืนยันรับเคสตามวันเวลาที่ลูกค้าขอ\n\n` +
      `${ownerSummary}\n\n` +
      "หมายเหตุ: ไม่แสดงเบอร์โทร/Line เต็ม — ติดต่อผ่านแพลตฟอร์มเท่านั้น";

    await notifyOwnerViewingRequest(db, {
      ownerUserId: ownerId,
      listingId: params.listingId,
      listingCode,
      listingTitle: params.listingTitle,
      projectName: params.projectName,
      messageText,
      leadId: lead.id,
    });
    await routeLeadToOwner(lead.id);
  } else if (ownerId) {
    const messageText =
      `คำขอนัดดูจากทีม RealXtate (${listingCode})\n` +
      `ลูกค้าขอนัด: ${schedule}\n\n` +
      `${ownerSummary}\n\n` +
      "หมายเหตุ: ไม่แสดงเบอร์โทร/Line เต็ม — ติดต่อผ่านแพลตฟอร์มเท่านั้น";
    await notifyOwnerViewingRequest(db, {
      ownerUserId: ownerId,
      listingId: params.listingId,
      listingCode,
      listingTitle: params.listingTitle,
      projectName: params.projectName,
      messageText,
      leadId: "pending",
    });
  }

  await notifyEscalation(
    params.threadId,
    params.listingCode,
    params.listingId,
    summary["ชื่อเล่น"] ?? summary["ชื่อ"] ?? schedule,
  );

  await orchestrateAdminFeed(
    db,
    "chat-viewing-auto-propose",
    feedFromViewingSubmitted({
      threadId: params.threadId,
      listingCode: params.listingCode,
      listingId: params.listingId,
      preview: summary["ชื่อเล่น"] ?? summary["ชื่อ"] ?? schedule,
      duplicatePhone: duplicate,
    }),
  );

  const profileNote = ownerSummary.replaceAll("\n", " · ");
  return coachResult({
    userBursts: [
      `รับทราบค่ะ ลูกค้าสะดวก ${schedule} — แอดมินส่งโปรไฟล์และคำขอนัดให้เจ้าของตรวจสอบแล้วนะคะ`,
      "ทีมจะยืนยันนัดอีกครั้งหลังเช็กคิวเจ้าของและนิติ ถ้ามีการเปลี่ยนเวลาจะแจ้งในแชทนี้ค่ะ",
    ],
    coachQuestion: params.text,
    topicKey: "viewing_time_auto_sent",
    category: "viewing_request",
    analysisNote:
      `ส่งคำขอนัดอัตโนมัติแล้ว (${schedule}) · ${profileNote}`,
  });
}
