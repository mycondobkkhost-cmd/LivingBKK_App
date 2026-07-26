import type { SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";

export type ChatBotTrainingSettings = {
  voice_extra_rules: string;
  unclear_escalate_threshold: number;
  coach_when_low_confidence: boolean;
  strategy_hints: Record<string, string>;
};

const STRATEGY_KEYS = [
  "build_trust",
  "answer_question",
  "invite_viewing",
  "collect_requirement",
  "close_ready",
  "negotiate_soft",
] as const;

const DEFAULT_STRATEGY_HINTS: Record<string, string> = {
  build_trust:
    "ทักสั้นแบบ LINE OA จริง (สวัสดีค่ะ แอดมิน RealXtate…) ไม่เร่งขาย — ถามงบ/โซน/เช่า-ซื้อหนึ่งข้อ",
  answer_question:
    "ตอบสั้นชัดจากข้อมูลที่มี — มั่นใจ (owner/ข้อมูลยืนยันแล้ว) ยืนยันได้; ไม่มั่นใจอย่าเดา ให้เช็ค/coach ก่อน",
  invite_viewing:
    "สนใจนัดดูแล้ว — ชวนฟอร์ม/โปรไฟล์ผู้เช่า ไม่ยืนยันเวลานัดทันที; บอกว่าจะประสานเจ้าของให้นะคะ",
  collect_requirement:
    "ห้องนี้ไม่ fit หรือไม่ว่าง — ขอโทษสั้นๆ แล้วถามงบ/โซน/ห้องนอน ช่วยหาใกล้เคียง",
  close_ready:
    "ลูกค้าพร้อมปิด — สรุปขั้นตอนถัดไปชัด (มัดจำ/สัญญาตามข้อมูล) ไม่ invent เลข",
  negotiate_soft:
    "ขอลองสอบถามเจ้าของก่อน + ถามงบที่สะดวก — ห้ามสัญญาลดราคาเอง",
};

export function defaultChatBotTrainingSettings(): ChatBotTrainingSettings {
  return {
    voice_extra_rules: "",
    unclear_escalate_threshold: 2,
    coach_when_low_confidence: true,
    strategy_hints: { ...DEFAULT_STRATEGY_HINTS },
  };
}

function mergeSettings(raw: unknown): ChatBotTrainingSettings {
  const base = defaultChatBotTrainingSettings();
  if (!raw || typeof raw !== "object") return base;
  const j = raw as Record<string, unknown>;

  const hintsRaw = j.strategy_hints;
  const hints = { ...base.strategy_hints };
  if (hintsRaw && typeof hintsRaw === "object") {
    for (const key of STRATEGY_KEYS) {
      const v = (hintsRaw as Record<string, unknown>)[key];
      if (typeof v === "string" && v.trim()) hints[key] = v.trim();
    }
  }

  const threshold = typeof j.unclear_escalate_threshold === "number"
    ? Math.max(1, Math.min(5, Math.round(j.unclear_escalate_threshold)))
    : base.unclear_escalate_threshold;

  return {
    voice_extra_rules: typeof j.voice_extra_rules === "string"
      ? j.voice_extra_rules.trim()
      : base.voice_extra_rules,
    unclear_escalate_threshold: threshold,
    coach_when_low_confidence: j.coach_when_low_confidence !== false,
    strategy_hints: hints,
  };
}

/** Admin-editable bot logic — singleton row `default`. */
export async function loadChatBotTrainingSettings(
  db: SupabaseClient,
): Promise<ChatBotTrainingSettings> {
  try {
    const { data, error } = await db
      .from("chat_bot_training_settings")
      .select("settings")
      .eq("id", "default")
      .maybeSingle();
    if (error) {
      console.error("loadChatBotTrainingSettings", error.message);
      return defaultChatBotTrainingSettings();
    }
    if (data?.settings) return mergeSettings(data.settings);
  } catch (e) {
    console.error("loadChatBotTrainingSettings", e);
  }
  return defaultChatBotTrainingSettings();
}

export function strategyHintsBlock(hints: Record<string, string>): string {
  return STRATEGY_KEYS.map((k) => `- ${k}: ${hints[k] ?? DEFAULT_STRATEGY_HINTS[k] ?? ""}`)
    .join("\n");
}
