import type { SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";
import { sendFcmToUser } from "./notify.ts";

function censorPhone(phone: string): string {
  const digits = phone.replace(/\D/g, "");
  if (digits.length < 6) return "***";
  return `${digits.slice(0, 2)}x-xxx-${digits.slice(-4)}`;
}

export async function resolveListingOwnerId(
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

async function ensureOwnerThread(
  db: SupabaseClient,
  params: {
    ownerUserId: string;
    listingId: string | null;
    listingCode: string;
    listingTitle?: string | null;
    projectName?: string | null;
  },
): Promise<string | null> {
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
  return threadId ?? null;
}

function buildOwnerMessage(
  listingCode: string,
  schedule: string,
  summary: Record<string, string>,
  lead?: {
    seeker_nickname?: string | null;
    seeker_phone?: string | null;
    occupation?: string | null;
  } | null,
): string {
  const nickname = lead?.seeker_nickname ??
    summary["ชื่อเล่น"] ?? summary["ชื่อ"] ?? summary["Nickname"] ?? "ลูกค้า";
  const phone = lead?.seeker_phone ?? summary["เบอร์"] ?? summary["Phone"] ?? "";
  const lines = [
    `คำขอนัดดูจากทีม RealXtate (${listingCode})`,
    `ลูกค้าขอนัด: ${schedule}`,
    "",
    `ชื่อเล่น: ${nickname}`,
    `เบอร์: ${censorPhone(phone)}`,
  ];
  if (lead?.occupation) lines.push(`อาชีพ: ${lead.occupation}`);
  if (summary["งบ"]) lines.push(`งบ: ${summary["งบ"]}`);
  if (summary["หมายเหตุ"]) lines.push(`หมายเหตุ: ${summary["หมายเหตุ"]}`);
  for (const [k, v] of Object.entries(summary)) {
    if (["ชื่อเล่น", "ชื่อ", "เบอร์", "Phone", "Nickname", "นัดดูทรัพย์", "Viewing", "งบ", "หมายเหตุ"].includes(k)) {
      continue;
    }
    if (v.trim()) lines.push(`${k}: ${v}`);
  }
  lines.push(
    "",
    "กรุณาพิจารณายืนยันรับเคสตามวันเวลาที่ลูกค้าขอ",
    "หมายเหตุ: ไม่แสดงเบอร์โทร/Line เต็ม — ติดต่อผ่านแพลตฟอร์มเท่านั้น",
  );
  return lines.join("\n");
}

export async function notifyOwnerViewingSubmitted(
  db: SupabaseClient,
  params: {
    threadId: string;
    listingId: string | null;
    listingCode: string | null;
    listingTitle?: string | null;
    projectName?: string | null;
    summary: Record<string, string>;
  },
): Promise<{ owner_notified: boolean; lead_id?: string }> {
  const listingCode = params.listingCode ?? "";
  if (!listingCode) return { owner_notified: false };

  const schedule = params.summary["นัดดูทรัพย์"] ??
    params.summary["Viewing"] ?? "-";

  const { data: leadRows } = await db
    .from("leads")
    .select("id, seeker_nickname, seeker_phone, occupation, qualification_json")
    .eq("thread_id", params.threadId)
    .order("created_at", { ascending: false })
    .limit(1);
  const lead = (leadRows ?? [])[0] as {
    id: string;
    seeker_nickname?: string | null;
    seeker_phone?: string | null;
    occupation?: string | null;
  } | undefined;

  const ownerId = await resolveListingOwnerId(
    db,
    params.listingId,
    listingCode,
  );
  if (!ownerId) return { owner_notified: false, lead_id: lead?.id };

  const ownerThreadId = await ensureOwnerThread(db, {
    ownerUserId: ownerId,
    listingId: params.listingId,
    listingCode,
    listingTitle: params.listingTitle,
    projectName: params.projectName,
  });
  if (!ownerThreadId) return { owner_notified: false, lead_id: lead?.id };

  const messageText = buildOwnerMessage(listingCode, schedule, params.summary, lead);

  await db.from("chat_messages").insert({
    thread_id: ownerThreadId,
    role: "admin_notice",
    text: messageText,
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
  }).eq("id", ownerThreadId);

  if (lead?.id) {
    await db.from("leads").update({
      status: "routed",
      assigned_to: ownerId,
    }).eq("id", lead.id);

    const base = Deno.env.get("SUPABASE_URL")!;
    const key = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    try {
      await fetch(`${base}/functions/v1/route-lead-notification`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${key}`,
        },
        body: JSON.stringify({
          lead_id: lead.id,
          channel: "owner_viewing_profile",
        }),
      });
    } catch (_) {
      // non-fatal
    }
  }

  await sendFcmToUser(
    db,
    ownerId,
    "RealXtate — คำขอนัดดูใหม่",
    `${listingCode}: มีลูกค้าส่งโปรไฟล์นัดดู — กรุณาพิจารณา`,
    { type: "viewing_request", thread_id: ownerThreadId, listing_code: listingCode },
  );

  return { owner_notified: true, lead_id: lead?.id };
}

/** แนบลิงก์ฟอร์มนัดดูเมื่อแอดมินอนุมัติร่างที่ชวนกรอกฟอร์ม */
export function shouldAttachViewingFormLink(...texts: (string | undefined)[]): boolean {
  const combined = texts.filter(Boolean).join("\n");
  return /ฟอร์ม|กรอก|นัดดู|viewing.?form|fill.?out|profile/i.test(combined) &&
    !/ส่งโปรไฟล์|ส่งคำขอนัด|ยืนยันนัดแล้ว|confirmed viewing/i.test(combined);
}
