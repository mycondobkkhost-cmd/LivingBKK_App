/** ประเมินและแปลงคำตอบเจ้าของก่อนส่งให้ลูกค้า */

import {
  isOwnerUncertainReply,
  VOICE,
} from "./owner_inquiry_voice.ts";

export type RelayResult = {
  policy: "auto_ok" | "blocked_pii" | "needs_admin";
  relayText: string;
  reason?: string;
};

const PHONE_RE = /(?:^|[^\d])(0[689]\d{8}|0[2-9]\d{7,8})(?:[^\d]|$)/;
const LINE_RE = /\b(line|ไลน์|line id|ไอดีไลน์)\b/i;
const EMAIL_RE = /[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,}/i;

function stripContactInfo(text: string): string {
  return text
    .replace(PHONE_RE, "[ติดต่อถูกซ่อน]")
    .replace(EMAIL_RE, "[อีเมลถูกซ่อน]")
    .replace(/\b(line|ไลน์)\s*[:@]?\s*\S+/gi, "[ไลน์ถูกซ่อน]");
}

function hasBlockedContent(text: string): boolean {
  return PHONE_RE.test(text.replace(/[\s\-().]/g, "")) ||
    LINE_RE.test(text) ||
    EMAIL_RE.test(text);
}

function polishRelay(raw: string): string {
  if (isOwnerUncertainReply(raw)) {
    return VOICE.relayUncertain + VOICE.relayOutro;
  }
  const cleaned = stripContactInfo(raw.trim());
  return `${VOICE.relayIntro}${cleaned}${VOICE.relayOutro}`;
}

/** กฎพื้นฐาน — ไม่มี OpenAI ก็ทำงานได้ */
export function relayOwnerReplyRules(
  raw: string,
  _inquiryType: string,
): RelayResult {
  const text = raw.trim();
  if (!text || text.length < 2) {
    return {
      policy: "needs_admin",
      relayText: "",
      reason: "empty_reply",
    };
  }

  if (hasBlockedContent(text)) {
    const cleaned = polishRelay(stripContactInfo(text));
    if (cleaned.includes("[ติดต่อถูกซ่อน]") || cleaned.includes("[ไลน์ถูกซ่อน]")) {
      return {
        policy: "blocked_pii",
        relayText: cleaned,
        reason: "contact_stripped",
      };
    }
  }

  const lower = text.toLowerCase();
  if (
    lower.includes("โทรมา") || lower.includes("ติดต่อตรง") ||
    lower.includes("คุยกับเจ้าของเอง")
  ) {
    return {
      policy: "needs_admin",
      relayText: "",
      reason: "bypass_attempt",
    };
  }

  return {
    policy: "auto_ok",
    relayText: polishRelay(text),
  };
}

/** แปลงคำตอบด้วย OpenAI ให้เป็นธรรมชาติขึ้น (ทางเลือก) */
export async function relayOwnerReplyWithAI(
  raw: string,
  inquiryType: string,
  seekerQuestion: string,
): Promise<RelayResult> {
  const rules = relayOwnerReplyRules(raw, inquiryType);
  if (rules.policy === "needs_admin") return rules;

  const key = Deno.env.get("OPENAI_API_KEY");
  if (!key || key.length < 10) return rules;

  try {
    const res = await fetch("https://api.openai.com/v1/chat/completions", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${key}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model: Deno.env.get("OPENAI_MODEL") ?? "gpt-4o-mini",
        temperature: 0.4,
        max_tokens: 320,
        response_format: { type: "json_object" },
        messages: [
          {
            role: "system",
            content:
              "You rewrite owner replies for a Bangkok property platform seeker chat. " +
              "Return JSON: {\"policy\":\"auto_ok|blocked_pii|needs_admin\",\"relay_text\":\"Thai 2-4 sentences\"}. " +
              "NEVER include owner phone, Line, email, or exact unit number. " +
              "Tone: female admin, warm Thai, use ค่ะ/คะ — start with 'แอดมินสอบถามเจ้าของให้แล้วนะคะ เจ้าของแจ้งมาว่า'. " +
              "If owner is uncertain or wants viewing first, use uncertain template tone. " +
              "If owner reply contains contact info, strip it and set policy=blocked_pii. " +
              "If owner asks seeker to contact directly, set policy=needs_admin. " +
              "End with gentle next step (viewing or reply in chat).",
          },
          {
            role: "user",
            content: JSON.stringify({
              inquiry_type: inquiryType,
              seeker_question: seekerQuestion,
              owner_reply_raw: raw,
            }),
          },
        ],
      }),
    });

    if (!res.ok) return rules;
    const body = await res.json();
    const content = body?.choices?.[0]?.message?.content;
    if (!content || typeof content !== "string") return rules;

    const parsed = JSON.parse(content);
    const policy = parsed.policy as RelayResult["policy"];
    const relayText = String(parsed.relay_text ?? "").trim();
    if (!relayText) return rules;

    if (!["auto_ok", "blocked_pii", "needs_admin"].includes(policy)) {
      return { ...rules, relayText };
    }
    return { policy, relayText, reason: "openai_relay" };
  } catch {
    return rules;
  }
}
