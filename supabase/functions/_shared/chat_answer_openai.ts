import { AI_DISCLAIMER, ListingRow } from "./chat_logic.ts";
import { AI_VOICE_RULE } from "./chat_ai_voice.ts";

export type FaqHint = {
  scope: string;
  patterns: string[];
  reply_text: string;
  priority: number;
};

export type ListingDetail = {
  id: string;
  listing_code: string;
  title: string;
  project_name: string | null;
  listing_type: string;
  price_net: number;
  property_type: string;
  district: string | null;
  subdistrict?: string | null;
  description_public?: string | null;
  pet_allowed?: boolean | null;
  furnished?: boolean | null;
  bedrooms?: number | null;
  bathrooms?: number | null;
  area_sqm?: number | null;
  floor_range?: string | null;
  max_distance_bts_km?: number | null;
  updated_at?: string | null;
  /** พิกัดสำหรับแผนที่ — ใช้ project pin ก่อน listing public */
  map_lat?: number | null;
  map_lng?: number | null;
  project_bts?: string | null;
};

export type ChatAnswerResult = {
  intent: "discovery" | "property_faq" | "sensitive" | "unknown";
  should_answer: boolean;
  needs_admin: boolean;
  answer_text?: string;
  reason?: string;
};

export type AnswerContext = {
  text: string;
  normalizedText: string;
  hasListing: boolean;
  isDiscoveryThread: boolean;
  listingCode: string | null;
  projectName: string | null;
  currentListing?: ListingDetail | null;
  listings: ListingRow[];
  faqHints: FaqHint[];
};

const SYSTEM = `You are RealXtate (realxtateth.com) — female AI chat assistant for Bangkok+vicinity rent/buy/sell.
Answer in Thai unless the user writes English. Be concise, warm, professional.

${AI_VOICE_RULE}

BUSINESS RULES (never violate):
- Net price only — NEVER disclose commission % to seeker/buyer
- NEVER reveal: owner phone, Line ID, owner real name, exact unit number (e.g. 12/34)
- Do NOT invent floor, direction, prices, or appliances — use CONTEXT listing data only
- If CONTEXT lacks data: use "เบื้องต้นในระบบ..." / "เบื้องต้นที่มีข้อมูล..." then coordinate or collect questions for owner
- Location: when CONTEXT has map_lat/map_lng, you may mention a Google Maps link is available; never invent coordinates

SAFE ANSWERS:
- Do not confirm 100%: availability, pets, exact specs — buffer with "เบื้องต้น..."
- Vary phrasing — avoid repeating "ถามเจ้าของ" every time; use: ขอรับเรื่องประสานงาน / ตรวจสอบเชิงลึก / รวบรวมไปสอบถามเจ้าของทีเดียว
- Pivot to viewing when user asks many unknowable details: invite ขอนัดดู to see real specs

NEGOTIATION (conditional close — never promise a number):
- Never confirm a discount amount or say "ลดได้ X บาท" unless owner reply is in CONTEXT
- OK: "ในระบบข้อมูลที่ลงราคา … เป็นราคาสุทธิแล้วค่ะ แต่ถ้าหากลูกค้าดูแล้วพร้อมจอง ทางแอดมินจะช่วยคุยกับเจ้าของให้อย่างสุดความสามารถเลยค่ะ"
- Numeric counter-offers → collect questions, owner inquiry flow; needs_admin=false until form/phone

SOFT CLOSE (gentle, not pushy):
- End with one small CTA when appropriate: นัดดู / บอกงบทำเล / กรอกฟอร์ม / พร้อมส่งคำถามให้เจ้าของ
- Avoid fake urgency ("มีคิวรอคอนเฟิร์ม") unless true in CONTEXT

ESCALATE (needs_admin=true) when user:
- Leaves phone number in chat
- Explicitly asks for human/admin
- Asks commission % or split
- Unclear/nonsense 3 times in a row (??? / งง / อืม with no progress)

STANDARD REPLIES:
- Owner/contact: PDPA — cannot share owner contact; user may leave THEIR phone
- Owner identity: PDPA — cannot disclose
- Co-Agent: explain opt-in + ask for listing code (LB-…) or property details
- Internet: rent excludes internet; RealXtate offers installer concierge for both major ISPs — customer picks package only

INTENTS: discovery | property_faq | sensitive | unknown

Return ONLY JSON:
{"intent":"discovery|property_faq|sensitive|unknown","should_answer":true|false,"needs_admin":true|false,"answer_text":"Thai 1-2 sentences per bubble max","reason":"short note"}

Keep answer_text short (1-2 sentences). Female tone ค่ะ/คะ only.`;

export function formatPrice(l: ListingDetail | ListingRow): string {
  if (l.listing_type === "rent") {
    return `${Math.round(l.price_net).toLocaleString("th-TH")} บาท/เดือน (Net)`;
  }
  if (l.price_net >= 1_000_000) {
    return `${(l.price_net / 1_000_000).toFixed(2)} ล้านบาท (Net)`;
  }
  return `${Math.round(l.price_net).toLocaleString("th-TH")} บาท (Net)`;
}

export function listingBlock(l: ListingDetail): string {
  const lines = [
    `รหัส: ${l.listing_code}`,
    `ชื่อ: ${l.title}`,
    `โครงการ: ${l.project_name ?? "-"}`,
    `ประเภท: ${l.property_type} · ${l.listing_type === "rent" ? "เช่า" : "ขาย"}`,
    `ราคา Net: ${formatPrice(l)}`,
    `ทำเล: ${[l.district, l.subdistrict].filter(Boolean).join(" / ") || "-"}`,
  ];
  if (l.bedrooms != null) lines.push(`ห้องนอน: ${l.bedrooms}`);
  if (l.bathrooms != null) lines.push(`ห้องน้ำ: ${l.bathrooms}`);
  if (l.area_sqm != null) lines.push(`พื้นที่: ${l.area_sqm} ตร.ม.`);
  if (l.furnished != null) lines.push(`เฟอร์นิเจอร์: ${l.furnished ? "มี" : "ไม่ระบุ/ไม่มี"}`);
  if (l.pet_allowed != null) {
    lines.push(`สัตว์เลี้ยง: ${l.pet_allowed ? "อนุญาต (ตามประกาศ)" : "ไม่ระบุ/ไม่อนุญาต"}`);
  }
  if (l.floor_range) lines.push(`ช่วงชั้น (สาธารณะ): ${l.floor_range}`);
  if (l.max_distance_bts_km != null) {
    lines.push(`ระยะ BTS/MRT โดยประมาณ: ${l.max_distance_bts_km} กม.`);
  }
  if (l.map_lat != null && l.map_lng != null) {
    lines.push(`พิกัดโครงการ (แผนที่): ${l.map_lat}, ${l.map_lng}`);
  }
  if (l.description_public) {
    const desc = l.description_public.slice(0, 400);
    lines.push(`รายละเอียด: ${desc}${l.description_public.length > 400 ? "…" : ""}`);
  }
  return lines.join("\n");
}

function faqHintsBlock(rules: FaqHint[]): string {
  if (rules.length === 0) return "(none)";
  return rules
    .slice(0, 6)
    .map((r) => `[${r.scope}] patterns: ${r.patterns.join(", ")} → ${r.reply_text}`)
    .join("\n");
}

function discoveryListingsBlock(listings: ListingRow[]): string {
  if (listings.length === 0) return "(no matching listings in system)";
  return listings
    .slice(0, 5)
    .map(
      (l) =>
        `${l.listing_code} · ${l.project_name ?? l.title} · ${formatPrice(l)} · ${l.district ?? ""}`,
    )
    .join("\n");
}

function buildUserPrompt(ctx: AnswerContext): string {
  const parts = [
    `User message (original): ${ctx.text}`,
    `User message (normalized): ${ctx.normalizedText}`,
    `Thread: ${ctx.isDiscoveryThread ? "discovery/search" : ctx.hasListing ? "property listing" : "general"}`,
  ];
  if (ctx.listingCode) parts.push(`Listing code: ${ctx.listingCode}`);
  if (ctx.projectName) parts.push(`Project: ${ctx.projectName}`);

  if (ctx.currentListing) {
    parts.push("\nCURRENT LISTING (public data only):\n" + listingBlock(ctx.currentListing));
  }

  parts.push("\nFAQ POLICY HINTS (prefer these when relevant):\n" + faqHintsBlock(ctx.faqHints));
  parts.push("\nCANDIDATE LISTINGS (discovery):\n" + discoveryListingsBlock(ctx.listings));

  return parts.join("\n");
}

function ensureDisclaimer(text: string): string {
  const t = text.trim();
  if (t.includes("AI เป็นตัวช่วย") || t.includes(AI_DISCLAIMER.slice(0, 20))) return t;
  return `${t}\n\n${AI_DISCLAIMER}`;
}

/** Grounded RAG answer — uses listing + FAQ context; optional when OPENAI_API_KEY set. */
export async function answerChatWithOpenAI(
  ctx: AnswerContext,
): Promise<ChatAnswerResult | null> {
  const key = Deno.env.get("OPENAI_API_KEY");
  if (!key || key.length < 10) return null;

  const model = Deno.env.get("OPENAI_MODEL") ?? "gpt-4o-mini";

  try {
    const res = await fetch("https://api.openai.com/v1/chat/completions", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${key}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model,
        temperature: 0.2,
        max_tokens: 480,
        response_format: { type: "json_object" },
        messages: [
          { role: "system", content: SYSTEM },
          { role: "user", content: buildUserPrompt(ctx) },
        ],
      }),
    });

    if (!res.ok) {
      console.error("OpenAI chat answer error", await res.text());
      return null;
    }

    const body = await res.json();
    const raw = body?.choices?.[0]?.message?.content;
    if (!raw || typeof raw !== "string") return null;

    const parsed = JSON.parse(raw);
    const intent = parsed.intent as string;
    const valid = ["discovery", "property_faq", "sensitive", "unknown"];
    if (!valid.includes(intent)) return null;

    let answerText = typeof parsed.answer_text === "string"
      ? parsed.answer_text.trim()
      : undefined;

    const shouldAnswer = parsed.should_answer === true;
    const needsAdmin = parsed.needs_admin === true;

    if (shouldAnswer && answerText && intent !== "sensitive" && !needsAdmin) {
      answerText = ensureDisclaimer(answerText);
    }

    return {
      intent: intent as ChatAnswerResult["intent"],
      should_answer: shouldAnswer,
      needs_admin: needsAdmin,
      answer_text: answerText,
      reason: typeof parsed.reason === "string" ? parsed.reason : undefined,
    };
  } catch (e) {
    console.error("answerChatWithOpenAI", e);
    return null;
  }
}
