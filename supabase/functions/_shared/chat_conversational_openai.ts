import type { FaqHint, ListingDetail, ListingRow } from "./chat_answer_openai.ts";
import { formatPrice, listingBlock } from "./chat_answer_openai.ts";
import { AI_VOICE_RULE, lineOaPlaybookBlock } from "./chat_ai_voice.ts";
import type { ChatBotTrainingSettings } from "./chat_bot_training_settings.ts";
import { strategyHintsBlock } from "./chat_bot_training_settings.ts";
import type { LearnedAnswer } from "./chat_learned_memory.ts";
import { learnedAnswersBlock } from "./chat_learned_memory.ts";

export type ChatTurnMessage = {
  role: "user" | "ai" | "admin_notice";
  text: string;
};

export type CustomerStrategy =
  | "build_trust"
  | "answer_question"
  | "invite_viewing"
  | "collect_requirement"
  | "close_ready"
  | "negotiate_soft";

export type ConversationalCta =
  | "none"
  | "viewing"
  | "requirement_form"
  | "owner_inquiry"
  | "map";

export type ConversationalAnalysis = {
  customer_read: string;
  inferred_intent: string;
  strategy: CustomerStrategy;
  faq_matched: string | null;
  faq_match_score: number;
  cta: ConversationalCta;
};

export type ConversationalResult = {
  should_answer: boolean;
  answer_bursts: string[];
  needs_coach: boolean;
  coach_question?: string;
  topic_key?: string;
  confidence: number;
  attach_map_link: boolean;
  learned_answer_id?: string;
  reason?: string;
  analysis?: ConversationalAnalysis;
};

export type ConversationalContext = {
  text: string;
  normalizedText: string;
  hasListing: boolean;
  isDiscoveryThread: boolean;
  listingCode: string | null;
  projectName: string | null;
  currentListing?: ListingDetail | null;
  listings: ListingRow[];
  faqHints: FaqHint[];
  learnedAnswers: LearnedAnswer[];
  recentMessages: ChatTurnMessage[];
  trainingSettings?: ChatBotTrainingSettings;
};

function buildSystemPrompt(settings?: ChatBotTrainingSettings): string {
  const hints = settings?.strategy_hints;
  const strategyBlock = hints
    ? strategyHintsBlock(hints)
    : strategyHintsBlock({});

  const extraVoice = settings?.voice_extra_rules?.trim()
    ? `\n\nADMIN VOICE / COMMUNICATION RULES (must follow):\n${settings.voice_extra_rules.trim()}`
    : "";

  return `You are RealXtate's property chat assistant (ค่ะ/คะ/นะคะ).
You are a sales-smart admin voice — NOT a FAQ copy machine.
Your reply rhythm should feel like a real Thai LINE OA property admin: short, clear, check-before-confirm.

${AI_VOICE_RULE}${extraVoice}

${lineOaPlaybookBlock()}

MANDATORY PIPELINE (run internally every turn, in order):

STEP 1 — READ THE CUSTOMER
From RECENT CHAT + USER NOW, infer:
- Who is this customer? (seeker / comparing / ready to book / agent / co-agent / unclear)
- What do they want right now? (vacancy, price, location, viewing, negotiate, other listing, general browse)
- USER NOW may merge several quick messages the customer sent in a row — treat as ONE intent
- Fix typos / autocorrect slips before answering (e.g. "ใกล้ปี" → "ใกล้ๆ", "นัดดุวันนี้" → wants viewing today)
- Never echo the typo in your reply — answer what they MEANT

STEP 2 — PICK STRATEGY for THIS user (one primary):
${strategyBlock}

STEP 3 — MATCH FAQ
From FAQ CATALOG below, pick the BEST match (or none):
- Compare user intent to patterns — fuzzy/semantic, not exact keyword
- faq_match_score 0.0–1.0 (0.7+ = strong match)
- If matched: use reply_text as POLICY IDEA only — weave into your strategy voice

STEP 4 — SYNTHESIZE REPLY
Merge: strategy + FAQ idea + listing data + learned guidance + LINE-OA PLAYBOOK
- Fresh wording every time — never repeat prior bubble phrasing
- 1–3 short bubbles in answer_bursts (one job per bubble)
- One gentle CTA when appropriate (viewing / form / next question) — not pushy
- Vacancy questions: if LISTING DATA / owner confirmation is clear → confirm; if uncertain → check-status holding (do not invent)

STEP 5 — CTA
Set cta: none | viewing | requirement_form | owner_inquiry | map
attach_map_link=true when cta=map or user asked location/BTS/map

BUSINESS RULES (never violate):
- Net price only — never disclose commission %
- Never reveal owner phone, Line, owner name, exact unit number
- Do not invent specs — use LISTING DATA only
- Negotiation: never promise a discount number
- Never invent vacant / not-vacant / deposit months / contract length if not in data

VIEWING / APPOINTMENT (critical — RealXtate ops):
- NEVER confirm a specific viewing time as booked/approved (no "นัดได้เลย", "ยืนยันนัด", "จัดการนัดให้", "ทีมจะจัดการนัดหมายให้" for a stated time)
- Before any viewing is confirmed, team must: (1) customer profile/contact via viewing form, (2) check owner availability, (3) juristic office hours (นิติ ~17:00 — evening slots need admin)
- If customer proposes date/time (e.g. today 18:00): set needs_coach=true, strategy=invite_viewing, cta=viewing
- Customer-facing holding only: thank interest + team will check owner & juristic hours + ask viewing form / contact
- invite_viewing = offer form + confirm-back later — NOT instant booking

WHEN UNSURE (confidence < 0.55 OR no FAQ/listing data for a specific claim):
- needs_coach=true
- coach_question: ask admin what angle/strategy (Thai, internal)
- answer_bursts: brief holding line for customer only
- Do NOT say "ยังไม่แน่ใจคำถาม" or ask user to type keywords

Return ONLY JSON:
{
  "analysis": {
    "customer_read": "1 sentence Thai who they are + what they want",
    "inferred_intent": "what they meant to say (corrected if typo)",
    "strategy": "build_trust|answer_question|invite_viewing|collect_requirement|close_ready|negotiate_soft",
    "faq_matched": "FAQ id from catalog or null",
    "faq_match_score": 0.0,
    "cta": "none|viewing|requirement_form|owner_inquiry|map"
  },
  "should_answer": true,
  "answer_bursts": ["bubble1"],
  "needs_coach": false,
  "coach_question": null,
  "topic_key": "short_snake_case",
  "confidence": 0.0,
  "attach_map_link": false,
  "learned_answer_id": null,
  "reason": "short internal note"
}`;
}

function faqCatalogBlock(rules: FaqHint[]): string {
  if (rules.length === 0) return "(no FAQ catalog — use listing data + strategy only)";
  return rules
    .slice(0, 12)
    .map(
      (r, i) =>
        `[FAQ-${i + 1}] scope=${r.scope} | patterns: ${r.patterns.join(", ")} | policy_idea: ${r.reply_text}`,
    )
    .join("\n");
}

function historyBlock(msgs: ChatTurnMessage[]): string {
  if (msgs.length === 0) return "(new conversation)";
  return msgs
    .slice(-10)
    .map((m) => `${m.role}: ${m.text.slice(0, 300)}`)
    .join("\n");
}

function discoveryBlock(listings: ListingRow[]): string {
  if (listings.length === 0) return "(none)";
  return listings
    .slice(0, 5)
    .map(
      (l) =>
        `${l.listing_code} · ${l.project_name ?? l.title} · ${formatPrice(l)}`,
    )
    .join("\n");
}

function buildPrompt(ctx: ConversationalContext): string {
  const parts = [
    `USER NOW: ${ctx.text}`,
    `Normalized: ${ctx.normalizedText}`,
    `Thread: ${ctx.isDiscoveryThread ? "discovery" : ctx.hasListing ? "property" : "general"}`,
  ];
  if (ctx.listingCode) parts.push(`Listing: ${ctx.listingCode}`);
  if (ctx.projectName) parts.push(`Project: ${ctx.projectName}`);
  if (ctx.currentListing) {
    parts.push("\nLISTING DATA:\n" + listingBlock(ctx.currentListing));
  }
  parts.push("\nRECENT CHAT:\n" + historyBlock(ctx.recentMessages));
  parts.push(
    "\nFAQ CATALOG (Step 3: pick best FAQ-N id, score match, merge idea into strategy — do NOT copy text):\n" +
      faqCatalogBlock(ctx.faqHints),
  );
  parts.push("\nLEARNED GUIDANCE (paraphrase):\n" + learnedAnswersBlock(ctx.learnedAnswers));
  parts.push("\nOTHER LISTINGS:\n" + discoveryBlock(ctx.listings));
  return parts.join("\n");
}

/** Primary conversational answer — LLM-first with coach fallback. */
export async function answerConversationalOpenAI(
  ctx: ConversationalContext,
): Promise<ConversationalResult | null> {
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
        temperature: 0.65,
        max_tokens: 700,
        response_format: { type: "json_object" },
        messages: [
          { role: "system", content: buildSystemPrompt(ctx.trainingSettings) },
          { role: "user", content: buildPrompt(ctx) },
        ],
      }),
    });

    if (!res.ok) {
      console.error("conversational OpenAI error", await res.text());
      return null;
    }

    const body = await res.json();
    const raw = body?.choices?.[0]?.message?.content;
    if (!raw || typeof raw !== "string") return null;

    const parsed = JSON.parse(raw);
    const bursts = Array.isArray(parsed.answer_bursts)
      ? parsed.answer_bursts
        .filter((b: unknown) => typeof b === "string" && b.trim())
        .map((b: string) => b.trim())
        .slice(0, 3)
      : [];

    const confidence = typeof parsed.confidence === "number"
      ? Math.max(0, Math.min(1, parsed.confidence))
      : 0.5;

    const coachOnLowConfidence = ctx.trainingSettings?.coach_when_low_confidence !== false;
    const needsCoach = parsed.needs_coach === true ||
      (coachOnLowConfidence && confidence < 0.55);

    const analysisRaw = parsed.analysis;
    let analysis: ConversationalAnalysis | undefined;
    if (analysisRaw && typeof analysisRaw === "object") {
      const strategies = [
        "build_trust", "answer_question", "invite_viewing",
        "collect_requirement", "close_ready", "negotiate_soft",
      ];
      const ctas = ["none", "viewing", "requirement_form", "owner_inquiry", "map"];
      const strat = String(analysisRaw.strategy ?? "");
      const cta = String(analysisRaw.cta ?? "none");
      analysis = {
        customer_read: String(analysisRaw.customer_read ?? "").slice(0, 300),
        inferred_intent: String(analysisRaw.inferred_intent ?? "").slice(0, 300),
        strategy: strategies.includes(strat)
          ? strat as CustomerStrategy
          : "answer_question",
        faq_matched: analysisRaw.faq_matched != null
          ? String(analysisRaw.faq_matched)
          : null,
        faq_match_score: typeof analysisRaw.faq_match_score === "number"
          ? Math.max(0, Math.min(1, analysisRaw.faq_match_score))
          : 0,
        cta: ctas.includes(cta) ? cta as ConversationalCta : "none",
      };
    }

    const attachMap = parsed.attach_map_link === true ||
      analysis?.cta === "map";

    return {
      should_answer: parsed.should_answer !== false && bursts.length > 0,
      answer_bursts: bursts,
      needs_coach: needsCoach,
      coach_question: typeof parsed.coach_question === "string"
        ? parsed.coach_question.trim()
        : undefined,
      topic_key: typeof parsed.topic_key === "string"
        ? parsed.topic_key.trim()
        : undefined,
      confidence,
      attach_map_link: attachMap,
      learned_answer_id: typeof parsed.learned_answer_id === "string"
        ? parsed.learned_answer_id
        : undefined,
      reason: typeof parsed.reason === "string" ? parsed.reason : undefined,
      analysis,
    };
  } catch (e) {
    console.error("answerConversationalOpenAI", e);
    return null;
  }
}

/** Polish admin coaching into natural customer-facing Thai. */
export async function phraseCoachGuidanceForUser(params: {
  userQuestion: string;
  coachQuestion?: string;
  adminGuidance: string;
  listingCode?: string | null;
  recentMessages?: ChatTurnMessage[];
}): Promise<string[] | null> {
  const key = Deno.env.get("OPENAI_API_KEY");
  if (!key || key.length < 10) {
    return [params.adminGuidance.trim()];
  }

  const model = Deno.env.get("OPENAI_MODEL") ?? "gpt-4o-mini";
  const history = (params.recentMessages ?? [])
    .slice(-8)
    .map((m) => `${m.role}: ${m.text}`)
    .join("\n");
  const coachCtx = params.coachQuestion &&
      params.coachQuestion.trim() !== params.userQuestion.trim()
    ? `\nEarlier topic (background only): ${params.coachQuestion}`
    : "";

  try {
    const res = await fetch("https://api.openai.com/v1/chat/completions", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${key}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model,
        temperature: 0.45,
        max_tokens: 400,
        response_format: { type: "json_object" },
        messages: [
          {
            role: "system",
            content:
              `RealXtate chat assistant (ค่ะ/คะ). Use "แอดมิน" or "ทีมงาน" by context — NEVER ดิฉัน or ผม. ` +
              `Answer the customer's LATEST question in Recent — not an older topic. ` +
              `Stay on the same subject as admin guidance; do not invent unrelated qualifying questions. ` +
              `NEVER confirm viewing/appointment times as final — team must check owner, juristic hours, and profile first. ` +
              `If admin corrects a prior AI mistake, acknowledge warmly and give the corrected customer-facing reply. ` +
              `Do not mention admin/coach/internal process. Paraphrase — do not copy guidance verbatim. ` +
              `Return JSON: {"bursts":["..."]}`,
          },
          {
            role: "user",
            content:
              `Latest customer question: ${params.userQuestion}${coachCtx}\n` +
              `Listing: ${params.listingCode ?? "-"}\n` +
              `Recent:\n${history}\n\nADMIN GUIDANCE:\n${params.adminGuidance}`,
          },
        ],
      }),
    });

    if (!res.ok) return [params.adminGuidance.trim()];
    const body = await res.json();
    const raw = body?.choices?.[0]?.message?.content;
    if (!raw) return [params.adminGuidance.trim()];
    const parsed = JSON.parse(raw);
    if (Array.isArray(parsed.bursts) && parsed.bursts.length > 0) {
      return parsed.bursts
        .filter((b: unknown) => typeof b === "string")
        .map((b: string) => b.trim())
        .slice(0, 2);
    }
    return [params.adminGuidance.trim()];
  } catch {
    return [params.adminGuidance.trim()];
  }
}
