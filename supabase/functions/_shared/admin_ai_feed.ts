import { SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";

export type AdminAiFeedInput = {
  eventType: string;
  priority?: "low" | "normal" | "high" | "urgent";
  title: string;
  summary: string;
  suggestedAction?: string;
  deepLink?: string;
  threadId?: string | null;
  listingId?: string | null;
  listingCode?: string | null;
  ownerInquiryId?: string | null;
  leadId?: string | null;
  appointmentId?: string | null;
  projectRequestId?: string | null;
  moderationFlagId?: string | null;
  dedupeKey?: string | null;
  confidence?: number | null;
  metadata?: Record<string, unknown>;
};

export function adminConsoleDeepLink(
  threadId: string,
  messageId?: string,
): string {
  const base = `/admin/console?room=${encodeURIComponent(threadId)}`;
  if (messageId) {
    return `${base}&message=${encodeURIComponent(messageId)}`;
  }
  return base;
}

export function listingAdminDeepLink(listingCode: string): string {
  return `/admin?nav=inventory&code=${encodeURIComponent(listingCode)}`;
}

export function adminLeadsDeepLink(): string {
  return "/admin?nav=leads";
}

export function adminProjectsDeepLink(): string {
  return "/admin?nav=projects";
}

export function adminViewingCalendarDeepLink(): string {
  return "/admin?nav=viewingCalendar";
}

export function adminModerationDeepLink(): string {
  return "/admin?nav=moderation";
}

/** บันทึกการ์ดแจ้งแอดมิน — ใช้ service role; dedupe ตาม dedupe_key ที่ status=open */
export async function emitAdminAiFeed(
  db: SupabaseClient,
  input: AdminAiFeedInput,
): Promise<string | null> {
  const row = {
    event_type: input.eventType,
    priority: input.priority ?? "normal",
    title: input.title.slice(0, 200),
    summary: input.summary.slice(0, 2000),
    suggested_action: input.suggestedAction?.slice(0, 1000) ?? null,
    deep_link: input.deepLink ?? null,
    thread_id: input.threadId ?? null,
    listing_id: input.listingId ?? null,
    listing_code: input.listingCode ?? null,
    owner_inquiry_id: input.ownerInquiryId ?? null,
    lead_id: input.leadId ?? null,
    appointment_id: input.appointmentId ?? null,
    project_request_id: input.projectRequestId ?? null,
    moderation_flag_id: input.moderationFlagId ?? null,
    dedupe_key: input.dedupeKey ?? null,
    confidence: input.confidence ?? null,
    metadata: input.metadata ?? {},
  };

  if (input.dedupeKey) {
    const { data: existing } = await db
      .from("admin_ai_feed")
      .select("id")
      .eq("dedupe_key", input.dedupeKey)
      .eq("status", "open")
      .maybeSingle();

    if (existing?.id) {
      const { data: updated, error: updErr } = await db
        .from("admin_ai_feed")
        .update({
          summary: row.summary,
          suggested_action: row.suggested_action,
          priority: row.priority,
          metadata: row.metadata,
          updated_at: new Date().toISOString(),
        })
        .eq("id", existing.id)
        .select("id")
        .single();
      if (updErr) {
        console.error("emitAdminAiFeed dedupe update", updErr.message);
        return null;
      }
      return updated?.id as string ?? existing.id as string;
    }
  }

  const { data, error } = await db
    .from("admin_ai_feed")
    .insert(row)
    .select("id")
    .single();

  if (error) {
    console.error("emitAdminAiFeed", error.message);
    return null;
  }
  return data?.id as string ?? null;
}

export function feedFromChatRoute(params: {
  threadId: string;
  listingCode?: string | null;
  listingId?: string | null;
  source: string;
  escalate: boolean;
  escalateReason?: string;
  userText: string;
  confidence?: number;
}): AdminAiFeedInput | null {
  const { threadId, source, escalate, userText } = params;

  if (escalate) {
    const reason = params.escalateReason ?? source;
    return {
      eventType: "chat_escalation",
      priority: reason.includes("phone") || reason.includes("commission")
        ? "urgent"
        : "high",
      title: "แชทต้องการแอดมิน",
      summary: `${params.listingCode ?? "แชท"}: ${userText.slice(0, 120)}`,
      suggestedAction: "เปิดแชทและตอบลูกค้าโดยตรง",
      deepLink: adminConsoleDeepLink(threadId),
      threadId,
      listingId: params.listingId,
      listingCode: params.listingCode,
      confidence: params.confidence,
      dedupeKey: `chat_escalation:${threadId}`,
      metadata: { source, reason },
    };
  }

  if (source === "fallback_admin") {
    return {
      eventType: "chat_low_confidence",
      priority: "high",
      title: "บอทตอบไม่ได้ — ส่งแอดมินแล้ว",
      summary: `${params.listingCode ?? "แชท"}: ${userText.slice(0, 120)}`,
      suggestedAction: "ตรวจสอบแชทและช่วยตอบหากจำเป็น",
      deepLink: adminConsoleDeepLink(threadId),
      threadId,
      listingId: params.listingId,
      listingCode: params.listingCode,
      confidence: params.confidence ?? 0.2,
      dedupeKey: `chat_low_confidence:${threadId}`,
      metadata: { source },
    };
  }

  return null;
}

export function feedFromHumanOnlyThread(params: {
  threadId: string;
  listingCode?: string | null;
  listingId?: string | null;
  category: string;
  userText: string;
}): AdminAiFeedInput {
  return {
    eventType: "chat_escalation",
    priority: "high",
    title: "แชทรอทีมงาน",
    summary: `${params.listingCode ?? params.category}: ${params.userText.slice(0, 120)}`,
    suggestedAction: "เปิดแชทและตอบลูกค้า",
    deepLink: adminConsoleDeepLink(params.threadId),
    threadId: params.threadId,
    listingId: params.listingId,
    listingCode: params.listingCode,
    dedupeKey: `chat_escalation:${params.threadId}`,
    metadata: { source: "human_only_thread", category: params.category },
  };
}

export function feedFromLeadCreated(params: {
  leadId: string;
  threadId?: string | null;
  listingCode?: string | null;
  listingId?: string | null;
  seekerNickname?: string | null;
  transactionRef?: string | null;
}): AdminAiFeedInput {
  const ref = params.transactionRef ?? params.leadId.slice(0, 8);
  const name = params.seekerNickname?.trim();
  return {
    eventType: "lead_new",
    priority: "high",
    title: "Lead ใหม่",
    summary: `${params.listingCode ?? "ทรัพย์"}${name ? ` · ${name}` : ""} (${ref})`,
    suggestedAction: "ตรวจสอบ Lead และมอบหมาย / ติดต่อลูกค้า",
    deepLink: params.threadId
      ? adminConsoleDeepLink(params.threadId)
      : adminLeadsDeepLink(),
    threadId: params.threadId,
    listingId: params.listingId,
    listingCode: params.listingCode,
    leadId: params.leadId,
    dedupeKey: `lead_new:${params.leadId}`,
    metadata: { transaction_ref: params.transactionRef },
  };
}

export function feedFromViewingSubmitted(params: {
  threadId: string;
  listingCode?: string | null;
  listingId?: string | null;
  preview?: string;
  duplicatePhone?: boolean;
}): AdminAiFeedInput {
  return {
    eventType: "viewing_request",
    priority: params.duplicatePhone ? "urgent" : "high",
    title: params.duplicatePhone
      ? "คำขอนัดดู — เบอร์ซ้ำในระบบ"
      : "คำขอนัดดูทรัพย์",
    summary: `${params.listingCode ?? "ทรัพย์"}: ${(params.preview ?? "ลูกค้าส่งคำขอนัดดู").slice(0, 120)}`,
    suggestedAction: "ยืนยันนัดและประสานเจ้าของ / นำทาง",
    deepLink: adminConsoleDeepLink(params.threadId),
    threadId: params.threadId,
    listingId: params.listingId,
    listingCode: params.listingCode,
    dedupeKey: `viewing_request:${params.threadId}`,
    metadata: { duplicate_phone: params.duplicatePhone ?? false },
  };
}

export function feedFromAppointment(params: {
  appointmentId: string;
  leadId?: string | null;
  threadId?: string | null;
  listingCode?: string | null;
  scheduledDate?: string | null;
  timeSlot?: string | null;
  seekerNickname?: string | null;
  transactionRef?: string | null;
}): AdminAiFeedInput {
  const when = [params.scheduledDate, params.timeSlot].filter(Boolean).join(" · ");
  return {
    eventType: "appointment_scheduled",
    priority: "normal",
    title: "นัดชมทรัพย์",
    summary: `${params.listingCode ?? "ทรัพย์"}${when ? ` · ${when}` : ""}`,
    suggestedAction: "ตรวจสอบปฏิทินนัดดูและยืนยันกับลูกค้า",
    deepLink: params.threadId
      ? adminConsoleDeepLink(params.threadId)
      : adminViewingCalendarDeepLink(),
    threadId: params.threadId,
    listingCode: params.listingCode,
    leadId: params.leadId ?? null,
    appointmentId: params.appointmentId,
    dedupeKey: `appointment:${params.appointmentId}`,
    metadata: {
      transaction_ref: params.transactionRef,
      seeker: params.seekerNickname,
    },
  };
}

export function feedFromOwnerAccepted(params: {
  leadId: string;
  threadId?: string | null;
  listingCode?: string | null;
  listingId?: string | null;
  scheduleSummary: string;
  mode: string;
}): AdminAiFeedInput {
  const alt = params.mode === "propose_alternative";
  return {
    eventType: "owner_accepted",
    priority: "high",
    title: alt ? "เจ้าของรับเคส — เสนอเวลาใหม่" : "เจ้าของยืนยันรับเคส",
    summary: `${params.listingCode ?? "ทรัพย์"} · ${params.scheduleSummary}`,
    suggestedAction: alt
      ? "ประสานลูกค้าเรื่องเวลาใหม่และยืนยันนัด"
      : "ยืนยันนัดกับลูกค้าและมอบหมายเอเจ้นพาดู",
    deepLink: params.threadId
      ? adminConsoleDeepLink(params.threadId)
      : adminLeadsDeepLink(),
    threadId: params.threadId,
    listingId: params.listingId,
    listingCode: params.listingCode,
    leadId: params.leadId,
    dedupeKey: `owner_accepted:${params.leadId}`,
    metadata: { mode: params.mode },
  };
}

export function feedFromOwnerInquirySubmit(params: {
  inquiryId: string;
  code: string;
  threadId: string;
  listingCode: string;
  listingId?: string | null;
  question: string;
  inquiryType: string;
}): AdminAiFeedInput {
  return {
    eventType: "owner_inquiry_pending",
    priority: "normal",
    title: "ส่งคำถามให้เจ้าของแล้ว",
    summary: `${params.listingCode} (${params.code}): ${params.question.slice(0, 100)}`,
    suggestedAction: "ติดตามว่าเจ้าของตอบหรือยัง — พร้อมช่วย relay ให้ลูกค้า",
    deepLink: adminConsoleDeepLink(params.threadId),
    threadId: params.threadId,
    listingId: params.listingId,
    listingCode: params.listingCode,
    ownerInquiryId: params.inquiryId,
    dedupeKey: `owner_inquiry_pending:${params.inquiryId}`,
    metadata: { code: params.code, inquiry_type: params.inquiryType },
  };
}

export function feedFromProjectRequest(params: {
  requestId: string;
  projectName: string;
  source: string;
  sourceQuery?: string | null;
}): AdminAiFeedInput {
  return {
    eventType: "project_request_new",
    priority: "normal",
    title: "คำขอเพิ่มโครงการ",
    summary: `โครงการ: ${params.projectName}`,
    suggestedAction: "ตรวจสอบทะเบียนโครงการและเพิ่มหรือปฏิเสธคำขอ",
    deepLink: adminProjectsDeepLink(),
    projectRequestId: params.requestId,
    dedupeKey: `project_request:${params.requestId}`,
    metadata: {
      source: params.source,
      source_query: params.sourceQuery,
    },
  };
}

const MOD_FLAG_LABELS: Record<string, string> = {
  duplicate_image: "รูปซ้ำในระบบ",
  phone: "พบเบอร์โทรในข้อความ",
  line: "พบ LINE ID ในข้อความ",
  external_link: "พบลิงก์ภายนอก",
};

export function feedFromModerationFlag(params: {
  flagId: string;
  flagType: string;
  listingId?: string | null;
  listingCode?: string | null;
  rawMatch?: string | null;
}): AdminAiFeedInput {
  const label = MOD_FLAG_LABELS[params.flagType] ?? params.flagType;
  const code = params.listingCode ?? "ประกาศ";
  return {
    eventType: "moderation_flag",
    priority: params.flagType === "duplicate_image" ? "high" : "normal",
    title: `ตรวจสอบประกาศ — ${label}`,
    summary: `${code}${params.rawMatch ? `: ${params.rawMatch.slice(0, 80)}` : ""}`,
    suggestedAction: "เปิดแท็บ Moderation และอนุมัติหรือปฏิเสธ",
    deepLink: adminModerationDeepLink(),
    listingId: params.listingId,
    listingCode: params.listingCode,
    moderationFlagId: params.flagId,
    dedupeKey: `moderation_flag:${params.flagId}`,
    metadata: { flag_type: params.flagType },
  };
}

export function feedFromCoachRequest(params: {
  threadId: string;
  listingCode?: string | null;
  listingId?: string | null;
  userText: string;
  coachQuestion: string;
}): AdminAiFeedInput {
  return {
    eventType: "chat_coach_request",
    priority: "normal",
    title: "AI ขอคำแนะนำตอบลูกค้า",
    summary: `${params.listingCode ?? "แชท"}: ${params.userText.slice(0, 100)}`,
    suggestedAction: `แนะนำแนวตอบ: ${params.coachQuestion.slice(0, 200)}`,
    deepLink: adminConsoleDeepLink(params.threadId),
    threadId: params.threadId,
    listingId: params.listingId,
    listingCode: params.listingCode,
    dedupeKey: `chat_coach:${params.threadId}`,
    metadata: { coach_question: params.coachQuestion },
  };
}
export function feedFromOwnerReply(params: {
  inquiryId: string;
  threadId: string;
  listingCode?: string | null;
  seekerQuestion: string;
  ownerReplyRaw: string;
  relayText: string;
  policy: string;
}): AdminAiFeedInput {
  const needsHuman = params.policy === "needs_admin";
  return {
    eventType: needsHuman ? "owner_reply_review" : "owner_reply_relayed",
    priority: needsHuman ? "high" : "normal",
    title: needsHuman
      ? "เจ้าของตอบแล้ว — ควรให้คนตรวจก่อนส่งลูกค้า"
      : "เจ้าของตอบแล้ว — ส่งลูกค้าแล้ว",
    summary: `ถาม: ${params.seekerQuestion.slice(0, 80)} · เจ้าของ: ${params.ownerReplyRaw.slice(0, 80)}`,
    suggestedAction: needsHuman
      ? `แนะนำตอบลูกค้า: ${params.relayText.slice(0, 200)}`
      : "ตรวจสอบคำตอบที่ส่งให้ลูกค้าแล้ว",
    deepLink: adminConsoleDeepLink(params.threadId),
    threadId: params.threadId,
    listingCode: params.listingCode,
    ownerInquiryId: params.inquiryId,
    dedupeKey: `owner_reply:${params.inquiryId}`,
    metadata: { policy: params.policy, relay_preview: params.relayText.slice(0, 500) },
  };
}
