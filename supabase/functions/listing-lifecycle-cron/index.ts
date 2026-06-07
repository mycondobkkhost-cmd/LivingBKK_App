import {
  createClient,
  type SupabaseClient,
} from "https://esm.sh/@supabase/supabase-js@2.49.1";
import { corsHeaders, jsonResponse } from "../_shared/cors.ts";
import { sendFcmToUser } from "../_shared/notify.ts";

type ListingRow = {
  id: string;
  owner_id: string;
  listing_code: string;
  title: string;
  listing_type: string;
  last_bump_at: string | null;
  published_at: string | null;
  last_reminder_at: string | null;
};

type ArchivedRow = {
  id: string;
  owner_id: string;
  listing_code: string;
  title: string;
};

function daysBetween(from: Date, to: Date): number {
  return Math.floor((to.getTime() - from.getTime()) / 86400000);
}

function activityAnchor(row: ListingRow): Date {
  if (row.last_bump_at) return new Date(row.last_bump_at);
  if (row.published_at) return new Date(row.published_at);
  return new Date();
}

/** แจ้งเตือนทุก 7 วัน (FCM) จนกว่าจะ bump หรือครบ 30 วัน */
async function sendBumpReminders(
  supabase: SupabaseClient<any, any, any>,
): Promise<{ checked: number; sent: number }> {
  const { data, error } = await supabase
    .from("listings")
    .select(
      "id, owner_id, listing_code, title, listing_type, last_bump_at, published_at, last_reminder_at",
    )
    .eq("status", "published")
    .is("owner_deleted_at", null);

  if (error || !data) {
    return { checked: 0, sent: 0 };
  }

  const now = new Date();
  let sent = 0;

  for (const row of data as ListingRow[]) {
    const anchor = activityAnchor(row);
    const daysSinceBump = daysBetween(anchor, now);
    if (daysSinceBump < 7 || daysSinceBump >= 30) continue;

    const lastRem = row.last_reminder_at
      ? new Date(row.last_reminder_at)
      : null;
    const daysSinceRem = lastRem ? daysBetween(lastRem, now) : 999;
    if (daysSinceRem < 7) continue;

    const daysLeft = 30 - daysSinceBump;
    const title = "LivingBKK — ยืนยันว่าง";
    const body = `${row.listing_code} · ${row.title}\n` +
      `กดอัปเดตว่าทรัพย์ยังว่าง — เหลือ ${daysLeft} วันก่อนเก็บประกาศอัตโนมัติ`;

    const fcm = await sendFcmToUser(supabase, row.owner_id, title, body, {
      type: "listing_bump",
      listing_id: row.id,
    });

    if (fcm.sent) {
      sent++;
      await supabase
        .from("listings")
        .update({ last_reminder_at: now.toISOString() })
        .eq("id", row.id);
    }
  }

  return { checked: data.length, sent };
}

/** แจ้ง owner เมื่อระบบเก็บประกาศอัตโนมัติ (ครบ 30 วัน) */
async function notifyAutoArchived(
  supabase: SupabaseClient<any, any, any>,
  archivedIds: string[],
): Promise<number> {
  if (archivedIds.length === 0) return 0;

  const { data, error } = await supabase
    .from("listings")
    .select("id, owner_id, listing_code, title")
    .in("id", archivedIds);

  if (error || !data) return 0;

  let sent = 0;
  for (const row of data as ArchivedRow[]) {
    const title = "LivingBKK — เก็บประกาศแล้ว";
    const body = `${row.listing_code} · ${row.title}\n` +
      "เก็บอัตโนมัติ — ไม่ได้ยืนยันว่างครบ 30 วัน";
    const fcm = await sendFcmToUser(supabase, row.owner_id, title, body, {
      type: "listing_archived",
      listing_id: row.id,
    });
    if (fcm.sent) sent++;
  }
  return sent;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const cronSecret = Deno.env.get("CRON_SECRET");
    const auth = req.headers.get("Authorization") ?? "";
    if (!cronSecret || auth !== `Bearer ${cronSecret}`) {
      return jsonResponse({ error: "unauthorized" }, 401);
    }

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );

    const reminders = await sendBumpReminders(supabase);

    const { data: publishedRows } = await supabase
      .from("listings")
      .select("id, last_bump_at, published_at")
      .eq("status", "published")
      .is("owner_deleted_at", null);

    const now = new Date();
    const idsToArchive: string[] = [];
    for (const row of (publishedRows ?? []) as ListingRow[]) {
      if (daysBetween(activityAnchor(row), now) >= 30) {
        idsToArchive.push(row.id);
      }
    }

    const { data, error } = await supabase.rpc("apply_listing_lifecycle");
    if (error) {
      return jsonResponse({ error: error.message, reminders }, 500);
    }

    const archiveNotified = await notifyAutoArchived(supabase, idsToArchive);

    return jsonResponse({
      ok: true,
      reminders,
      lifecycle: data,
      archive_push_sent: archiveNotified,
      archive_candidates: idsToArchive.length,
    });
  } catch (e) {
    return jsonResponse({ error: String(e) }, 500);
  }
});
