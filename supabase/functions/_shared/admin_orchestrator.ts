import { SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";
import {
  AdminAiFeedInput,
  emitAdminAiFeed,
} from "./admin_ai_feed.ts";

/**
 * ศูนย์กลางสร้างการ์ด AI Feed — ทุก module ควรเรียกผ่านจุดนี้
 * (edge admin-orchestrator ใช้ฟังก์ชันเดียวกัน)
 */
export async function orchestrateAdminFeed(
  db: SupabaseClient,
  source: string,
  input: AdminAiFeedInput,
): Promise<string | null> {
  return emitAdminAiFeed(db, {
    ...input,
    metadata: {
      ...(input.metadata ?? {}),
      orchestrator_source: source,
    },
  });
}
