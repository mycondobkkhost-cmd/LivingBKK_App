import type { SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2";

/** หยุดรอเมื่อไม่มีข้อความ user ใหม่ต่อเนื่อง */
export const BURST_QUIET_MS = 800;
/** รอสูงสุดก่อนตอบ — ให้ลูกค้าพิมพ์ต่อ/แก้คำผิดได้ */
export const BURST_MAX_WAIT_MS = 2800;

export function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

export type ThreadMessageRow = {
  id: string;
  role: string;
  text: string;
  created_at: string;
};

export function mergeUserBurstTexts(texts: string[]): string {
  return texts.map((t) => t.trim()).filter(Boolean).join(" ");
}

/** ข้อความ user ติดกันท้าย thread (หลัง bubble ล่าสุดที่ไม่ใช่ user) */
export function trailingUserTexts(rows: ThreadMessageRow[]): string[] {
  const texts: string[] = [];
  for (let i = rows.length - 1; i >= 0; i--) {
    const m = rows[i];
    if (m.role === "user") {
      texts.unshift(m.text);
    } else if (texts.length > 0) {
      break;
    }
  }
  return texts;
}

export async function getLatestUserMessageId(
  db: SupabaseClient,
  threadId: string,
): Promise<string | null> {
  const { data } = await db
    .from("chat_messages")
    .select("id")
    .eq("thread_id", threadId)
    .eq("role", "user")
    .order("created_at", { ascending: false })
    .limit(1)
    .maybeSingle();
  return data?.id != null ? String(data.id) : null;
}

/**
 * รอให้ลูกค้าพิมพ์ต่อจบชุดสั้นๆ ก่อนวิเคราะห์
 * (กัน AI ตอบทีละ fragment เมื่อพิมพ์ผิดแล้วแก้ต่อ)
 */
export async function waitForUserBurstStable(
  db: SupabaseClient,
  threadId: string,
): Promise<string | null> {
  const deadline = Date.now() + BURST_MAX_WAIT_MS;
  let lastId: string | null = null;
  let stableSince = 0;

  while (Date.now() < deadline) {
    const id = await getLatestUserMessageId(db, threadId);
    if (id !== lastId) {
      lastId = id;
      stableSince = Date.now();
    } else if (id && Date.now() - stableSince >= BURST_QUIET_MS) {
      return id;
    }
    await sleep(200);
  }
  return lastId;
}

export async function loadTrailingUserBurstText(
  db: SupabaseClient,
  threadId: string,
): Promise<string> {
  const { data } = await db
    .from("chat_messages")
    .select("id, role, text, created_at")
    .eq("thread_id", threadId)
    .order("created_at", { ascending: false })
    .limit(24);
  const rows = ((data ?? []) as ThreadMessageRow[]).reverse();
  return mergeUserBurstTexts(trailingUserTexts(rows));
}
