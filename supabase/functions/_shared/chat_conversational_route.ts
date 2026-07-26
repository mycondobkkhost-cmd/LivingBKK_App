import type { ListingDetail } from "./chat_answer_openai.ts";
import {
  answerConversationalOpenAI,
  type ConversationalResult,
} from "./chat_conversational_openai.ts";
import { ensureFemaleAiTone } from "./chat_ai_voice.ts";
import {
  listingToMapPin,
  locationReplyLinks,
  locationReplyTexts,
} from "./chat_map_link.ts";
import type { LearnedAnswer } from "./chat_learned_memory.ts";
import {
  aiSupportReply,
  BotReply,
  classifySensitive,
  containsThaiPhone,
  isExplicitStaffRequest,
  ListingRow,
  sensitiveReply,
  type SensitiveKind,
} from "./chat_logic.ts";
import type { FaqRule, RouteContext, RouteResult } from "./chat_route_shared.ts";
import {
  findRelatedFaqRules,
  matchFaqRule,
} from "./chat_route_shared.ts";
import { normalizeChatText } from "./chat_text_normalize.ts";
import type { ChatTurnMessage } from "./chat_conversational_openai.ts";
import {
  autoProposeViewingFromSlot,
  shouldAutoProposeViewing,
} from "./chat_viewing_auto_propose.ts";
import {
  isViewingRequestIntent,
  viewingRequestBurst,
} from "./viewing_request_voice.ts";

function aiBurst(texts: string[]): BotReply[] {
  return texts.map((t) => ({ role: "ai" as const, text: ensureFemaleAiTone(t) }));
}

function autoResult(
  reply: BotReply,
  category: string,
  source: string,
  extra: Partial<RouteResult> = {},
): RouteResult {
  return {
    reply,
    category,
    status: "open",
    priority: "normal",
    escalate: false,
    notifyAdmin: false,
    source,
    unclearStreak: 0,
    ...extra,
  };
}

function coachResult(params: {
  userBursts: string[];
  coachQuestion: string;
  topicKey?: string;
  category: string;
  analysisNote?: string;
}): RouteResult {
  const userReplies = aiBurst(params.userBursts);
  const analysisLine = params.analysisNote
    ? `\n\n📊 วิเคราะห์: ${params.analysisNote}`
    : "";
  const coachText =
    `🤖 ขอคำแนะนำค่ะ — ลูกค้าถามว่า:\n「${params.coachQuestion}」${analysisLine}\n\n` +
    `พิมพ์แนวทางตอบ + กลยุทธ์ (นัดดู / ปิดการขาย / กรอกฟอร์ม) จะส่งให้ลูกค้าในแชทให้ค่ะ`;
  return {
    reply: userReplies[userReplies.length - 1],
    replies: userReplies,
    category: params.category,
    status: "waiting_admin",
    priority: "normal",
    escalate: false,
    notifyAdmin: true,
    source: "coach_request",
    unclearStreak: 0,
    coachPending: true,
    coachQuestion: params.coachQuestion,
    coachReplies: [{ role: "admin_coach", text: coachText }],
    coachTopicKey: params.topicKey,
  };
}

function sensitiveRoute(text: string, kind: SensitiveKind): RouteResult {
  const reply = sensitiveReply(kind, text);
  const notifyAdmin = kind === "commission" ||
    (kind === "contact" && containsThaiPhone(text));
  if (notifyAdmin) {
    return {
      reply,
      category: "escalation",
      status: "waiting_admin",
      priority: "high",
      escalate: true,
      notifyAdmin: true,
      escalateReason: kind,
      source: `sensitive_${kind}`,
      unclearStreak: 0,
    };
  }
  return autoResult(reply, "property_faq", `sensitive_${kind}`);
}

function applyConversationalResult(
  ctx: RouteContext,
  conv: ConversationalResult,
  category: string,
): RouteResult {
  if (conv.needs_coach) {
    const holding = conv.answer_bursts.length > 0
      ? conv.answer_bursts
      : [
        "ขอเช็กรายละเอียดให้แป๊บนึงนะคะ ทีมจะช่วยยืนยันแล้วแอดมินจะตอบกลับให้เร็วที่สุดค่ะ",
      ];
    const analysisNote = conv.analysis
      ? `${conv.analysis.customer_read} · strategy=${conv.analysis.strategy}` +
        (conv.analysis.faq_matched
          ? ` · FAQ=${conv.analysis.faq_matched}(${conv.analysis.faq_match_score})`
          : "")
      : undefined;
    return {
      ...coachResult({
        userBursts: holding,
        coachQuestion: conv.analysis?.inferred_intent?.trim() ||
          conv.coach_question?.trim() ||
          ctx.text,
        topicKey: conv.topic_key,
        category,
        analysisNote,
      }),
      unclearStreak: (ctx.unclearStreak ?? 0) + 1,
    };
  }

  if (conv.attach_map_link && ctx.currentListing) {
    const pin = listingToMapPin(ctx.currentListing);
    if (pin) {
      const links = locationReplyLinks(pin);
      const mapTexts = locationReplyTexts(pin);
      const bursts = [...conv.answer_bursts];
      if (!bursts.some((b) => b.includes("แผนที่") || b.includes("พิกัด"))) {
        bursts.push(mapTexts[0]);
      }
      const replies = aiBurst(bursts);
      const last = replies.length - 1;
      replies[last] = { ...replies[last], links };
      return {
        ...autoResult(replies[last], category, "conversational", {
          learnedAnswerId: conv.learned_answer_id,
        }),
        replies,
        unclearStreak: 0,
      };
    }
  }

  const replies = aiBurst(conv.answer_bursts);
  return {
    ...autoResult(replies[replies.length - 1], category, "conversational", {
      learnedAnswerId: conv.learned_answer_id,
    }),
    replies,
    unclearStreak: 0,
  };
}

/** LLM-first conversational routing — FAQ is inspiration only. */
export async function routeConversationalFirst(
  ctx: RouteContext,
): Promise<RouteResult | null> {
  const { text, isStaffRoom } = ctx;
  const hasListing = ctx.listingId != null && ctx.listingId.length > 0;
  const isDiscoveryThread = !hasListing;

  if (isStaffRoom) return null;
  if (isExplicitStaffRequest(text)) return null;
  if (containsThaiPhone(text)) return null;

  const sensitiveKind = classifySensitive(text);
  if (sensitiveKind) return sensitiveRoute(text, sensitiveKind);

  const training = ctx.botTraining;
  const escalateThreshold = training?.unclear_escalate_threshold ?? 2;
  if ((ctx.unclearStreak ?? 0) >= escalateThreshold) {
    return defaultCoachRequest(ctx);
  }

  const ragScopes = hasListing
    ? ["global", "property", "discovery"]
    : isDiscoveryThread
    ? ["global", "discovery"]
    : ["global"];

  const conv = await answerConversationalOpenAI({
    text,
    normalizedText: normalizeChatText(text),
    hasListing,
    isDiscoveryThread,
    listingCode: ctx.listingCode,
    projectName: ctx.projectName,
    currentListing: ctx.currentListing ?? null,
    listings: ctx.listings.slice(0, 8),
    faqHints: findRelatedFaqRules(text, ctx.faqRules, ragScopes, 12),
    learnedAnswers: ctx.learnedAnswers ?? [],
    recentMessages: ctx.recentMessages ?? [],
    trainingSettings: ctx.botTraining,
  });

  if (conv && (conv.should_answer || conv.needs_coach)) {
    const category = isDiscoveryThread ? "discovery" : "property_faq";
    return applyConversationalResult(ctx, conv, category);
  }

  return null;
}

/** นัดดู — ห้ามยืนยันเวลาชัดก่อนเช็กเจ้าของ/นิติ/โปรไฟล์ */
export async function routeViewingRequestGuard(
  ctx: RouteContext,
): Promise<RouteResult | null> {
  const hasListing = ctx.listingId != null && ctx.listingId.length > 0;
  if (!hasListing) return null;

  if (shouldAutoProposeViewing({
    text: ctx.text,
    hasListing,
    threadCategory: ctx.threadCategory,
    viewingSubmitted: ctx.viewingSubmitted,
    recentMessages: ctx.recentMessages,
  })) {
    if (ctx.db && ctx.threadId && ctx.userId) {
      const result = await autoProposeViewingFromSlot(ctx.db, {
        threadId: ctx.threadId,
        userId: ctx.userId,
        text: ctx.text,
        listingId: ctx.listingId,
        listingCode: ctx.listingCode,
        listingTitle: ctx.listingTitle,
        projectName: ctx.projectName,
        transactionRef: ctx.transactionRef,
        threadCategory: ctx.threadCategory,
        viewingSubmitted: ctx.viewingSubmitted,
        recentMessages: ctx.recentMessages,
      });
      return { ...result, viewingSubmitted: true };
    }
    return coachResult({
      userBursts: [
        "ขอบคุณที่สนใจนัดดูนะคะ แอดมินจะเช็กคิวกับเจ้าของและเวลาทำการนิติให้ก่อนค่ะ " +
          "(ช่วงเย็นมักปิด ~17:00 น.)",
        "รบกวนกรอกฟอร์มนัดดูในแชทนี้ หรือบอกชื่อกับเบอร์ติดต่อ เพื่อให้ทีมยืนยันนัดกลับให้อีกครั้งนะคะ",
      ],
      coachQuestion: ctx.text,
      topicKey: "viewing_time_proposed",
      category: "viewing_request",
      analysisNote:
        "ลูกค้าระบุเวลานัดชัด — ห้ามยืนยันก่อนโปรไฟล์/เจ้าของ/นิติ",
    });
  }

  if (!isViewingRequestIntent(ctx.text)) return null;

  const replies = aiBurst(viewingRequestBurst(ctx.text));
  return {
    ...autoResult(replies[replies.length - 1], "viewing_request", "viewing_soft"),
    replies,
    status: "open",
    notifyAdmin: true,
  };
}

/** Minimal fallback when OpenAI unavailable. */
export function routeFaqInspirationFallback(
  ctx: RouteContext,
): RouteResult | null {
  const hasListing = ctx.listingId != null && ctx.listingId.length > 0;
  const scopes = hasListing ? ["property", "global"] : ["discovery", "global"];
  const rule = matchFaqRule(ctx.text, ctx.faqRules, scopes);
  if (!rule) return null;

  const idea = rule.reply_text.slice(0, 200);
  const reply: BotReply = {
    role: "ai",
    text: ensureFemaleAiTone(
      `เรื่องนี้แอดมินขอสรุปให้แบบนี้นะคะ — ${idea} ` +
        `ถ้าอยากให้ช่วยเช็กเพิ่ม บอกรายละเอียดที่สนใจได้เลยค่ะ`,
    ),
  };
  return autoResult(reply, "property_faq", "faq_inspiration_fallback");
}

export function routeDiscoveryFallback(ctx: RouteContext): RouteResult | null {
  const discovery = aiSupportReply(ctx.text, ctx.listings);
  if (discovery.links && discovery.links.length > 0) {
    return autoResult(discovery, "discovery", "discovery_db");
  }
  return null;
}

/** Last resort — ask admin for coaching angle instead of telling user to rephrase. */
export function defaultCoachRequest(ctx: RouteContext): RouteResult {
  const hasListing = ctx.listingId != null && ctx.listingId.length > 0;
  const category = hasListing ? "property_faq" : "discovery";
  return {
    ...coachResult({
      userBursts: [
        "ขอเช็กรายละเอียดให้แป๊บนึงนะคะ ทีมจะช่วยยืนยันแล้วแอดมินจะตอบกลับให้เร็วที่สุดค่ะ",
      ],
      coachQuestion: ctx.text,
      topicKey: "general_unclear",
      category,
    }),
    unclearStreak: (ctx.unclearStreak ?? 0) + 1,
  };
}

export type { ChatTurnMessage, LearnedAnswer };
