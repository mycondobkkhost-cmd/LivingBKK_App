import type { SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";
import type { ChatBotTrainingSettings } from "./chat_bot_training_settings.ts";
import type { ChatTurnMessage } from "./chat_conversational_openai.ts";
import type { ListingDetail } from "./chat_answer_openai.ts";
import type { LearnedAnswer } from "./chat_learned_memory.ts";
import type { BotReply, ListingRow } from "./chat_logic.ts";
import { fuzzyIncludes, fuzzyMatchScore } from "./chat_text_normalize.ts";

export type FaqRule = {
  scope: string;
  patterns: string[];
  reply_text: string;
  priority: number;
  escalate?: boolean;
};

export type RouteContext = {
  text: string;
  isStaffRoom: boolean;
  listingId: string | null;
  listingCode: string | null;
  projectName: string | null;
  listings: ListingRow[];
  faqRules: FaqRule[];
  priorUserMessages: number;
  unclearStreak: number;
  currentListing?: ListingDetail | null;
  ownerInquiryCollecting?: boolean;
  ownerInquiryDraft?: string;
  recentMessages?: ChatTurnMessage[];
  learnedAnswers?: LearnedAnswer[];
  botTraining?: ChatBotTrainingSettings;
  /** สำหรับ auto viewing propose ใน chat-turn */
  db?: SupabaseClient;
  threadId?: string;
  userId?: string;
  threadCategory?: string;
  viewingSubmitted?: boolean;
  listingTitle?: string | null;
  transactionRef?: string | null;
};

export type RouteResult = {
  reply: BotReply;
  replies?: BotReply[];
  category: string;
  status: "open" | "waiting_admin";
  priority: "normal" | "high";
  escalate: boolean;
  notifyAdmin: boolean;
  escalateReason?: string;
  source: string;
  unclearStreak: number;
  ownerInquiryCollecting?: boolean;
  ownerInquiryDraft?: string;
  coachPending?: boolean;
  coachQuestion?: string;
  coachReplies?: BotReply[];
  coachTopicKey?: string;
  learnedAnswerId?: string;
  viewingSubmitted?: boolean;
};

export function matchFaqRule(
  text: string,
  rules: FaqRule[],
  scopes: string[],
): FaqRule | null {
  const eligible = rules
    .filter((r) => scopes.includes(r.scope))
    .sort((a, b) => a.priority - b.priority);

  for (const rule of eligible) {
    if (rule.patterns.some((p) => fuzzyIncludes(text, p))) {
      return rule;
    }
  }
  return null;
}

export function findRelatedFaqRules(
  text: string,
  rules: FaqRule[],
  scopes: string[],
  limit = 6,
): FaqRule[] {
  const scored: { rule: FaqRule; score: number }[] = [];

  for (const rule of rules) {
    if (!scopes.includes(rule.scope)) continue;
    let best: number | null = null;
    for (const p of rule.patterns) {
      const s = fuzzyMatchScore(text, p);
      if (s !== null && (best === null || s < best)) best = s;
    }
    if (best !== null) {
      scored.push({ rule, score: best + rule.priority * 0.01 });
    }
  }

  scored.sort((a, b) => a.score - b.score);
  return scored.slice(0, limit).map((x) => x.rule);
}
