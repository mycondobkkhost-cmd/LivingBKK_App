import {
  answerChatWithOpenAI,
  type ListingDetail,
} from "./chat_answer_openai.ts";
import {
  aiSupportReply,
  BotReply,
  classifySensitive,
  containsThaiPhone,
  escalationReply,
  isExplicitStaffRequest,
  isSmallTalk,
  ListingRow,
  phoneReceivedAckReply,
  sensitiveReply,
  type SensitiveKind,
  softClarifyReply,
  staffAckReply,
} from "./chat_logic.ts";
import {
  fuzzyIncludes,
  fuzzyMatchScore,
  normalizeChatText,
} from "./chat_text_normalize.ts";

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
  /** Full public listing row for RAG when in property thread */
  currentListing?: ListingDetail | null;
};

export type RouteResult = {
  reply: BotReply;
  category: string;
  status: "open" | "waiting_admin";
  priority: "normal" | "high";
  escalate: boolean;
  notifyAdmin: boolean;
  escalateReason?: string;
  source: string;
  unclearStreak: number;
};

const DISCOVERY_KEYS = [
  "หา",
  "แนะนำ",
  "ค้นห",
  "อยากได้",
  "อยากเช่า",
  "อยากซื้อ",
  "มีไหม",
  "โครงการ",
  "คอนโด",
  "บ้าน",
  "ทาวน์",
  "townhouse",
  "bts",
  "mrt",
  "ใกล้",
  "งบ",
  "เช่า",
  "ซื้อ",
  "sale",
  "rent",
  "ห้องอื่น",
  "ตัวอื่น",
  "ในโครงการ",
  "compare",
  "เปรียบ",
];

const PROJECT_OTHER_KEYS = ["ห้องอื่น", "ตัวอื่น", "ในโครงการ", "unit อื่น"];

function normalize(text: string): string {
  return normalizeChatText(text);
}

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

/** FAQ rules partially matching user text — context for RAG (not auto-reply). */
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

export function isDiscoveryIntent(text: string): boolean {
  const q = normalize(text);
  if (DISCOVERY_KEYS.some((k) => q.includes(k))) return true;
  return /\d[\d,]*\s*(?:บาท|k)?/i.test(q);
}

function wantsOtherUnitsInProject(text: string): boolean {
  const q = normalize(text);
  return PROJECT_OTHER_KEYS.some((k) => q.includes(k));
}

const DISCOVERY_ON_PROPERTY_KEYS = [
  "นัดดู",
  "ขอดู",
  "view",
  "ว่าง",
  "viewing",
  "เข้าชม",
  "ดูห้อง",
  "เห็นห้อง",
  "นัดชม",
  "ว่างวัน",
  "ว่างเมื่อ",
  "เข้าอยู่",
  "cam fee",
  "ค่าส่วนกลาง",
  "common fee",
];

function isDiscoveryScopedOnProperty(text: string): boolean {
  const q = normalize(text);
  return DISCOVERY_ON_PROPERTY_KEYS.some((k) => q.includes(k));
}

function discoveryPool(
  text: string,
  listings: ListingRow[],
  projectName: string | null,
  listingId: string | null,
): ListingRow[] {
  if (projectName && wantsOtherUnitsInProject(text)) {
    const inProject = listings.filter((l) => l.project_name === projectName);
    if (inProject.length > 0) return inProject;
  }
  if (listingId && wantsOtherUnitsInProject(text) && projectName) {
    return listings.filter((l) => l.project_name === projectName);
  }
  return listings;
}

function faqRouteResult(
  text: string,
  rule: FaqRule,
  listingCode: string | null,
  category: string,
  source: string,
): RouteResult {
  const reply = faqReply(text, rule, listingCode);
  if (rule.escalate) {
    reply.requires_admin = true;
    return adminResult(reply, category, source, source);
  }
  return autoResult(reply, category, source);
}

function faqReply(text: string, rule: FaqRule, listingCode: string | null): BotReply {
  let replyText = rule.reply_text;
  if (listingCode && rule.scope === "property") {
    replyText = replyText.replace("{listing_code}", listingCode);
    if (!replyText.includes(listingCode)) {
      replyText = `${replyText} (${listingCode})`;
    }
  }
  return { role: "ai", text: replyText };
}

function autoResult(
  reply: BotReply,
  category: string,
  source: string,
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
  };
}

function adminResult(
  reply: BotReply,
  category: string,
  reason: string,
  source: string,
): RouteResult {
  return {
    reply,
    category,
    status: "waiting_admin",
    priority: "high",
    escalate: true,
    notifyAdmin: true,
    escalateReason: reason,
    source,
    unclearStreak: 0,
  };
}

function sensitiveRouteResult(text: string, kind: SensitiveKind): RouteResult {
  const reply = sensitiveReply(kind, text);
  const notifyAdmin =
    kind === "negotiate" ||
    kind === "commission" ||
    (kind === "contact" && containsThaiPhone(text));

  if (notifyAdmin) {
    return adminResult(reply, "escalation", kind, `sensitive_${kind}`);
  }
  return autoResult(reply, "property_faq", `sensitive_${kind}`);
}

function softDeferResult(unclearStreak: number): RouteResult {
  return {
    reply: softClarifyReply(),
    category: "property_faq",
    status: "open",
    priority: "normal",
    escalate: false,
    notifyAdmin: false,
    source: "soft_clarify",
    unclearStreak: unclearStreak + 1,
  };
}

/** Lean cascade: auto first, admin only when necessary */
export async function routeChatMessage(ctx: RouteContext): Promise<RouteResult> {
  const {
    text,
    isStaffRoom,
    listingId,
    listingCode,
    projectName,
    listings,
    faqRules,
    unclearStreak,
  } = ctx;
  const hasListing = listingId != null && listingId.length > 0;
  const isDiscoveryThread = !hasListing;

  if (isStaffRoom) {
    const firstStaffMessage = ctx.priorUserMessages === 0;
    return {
      reply: staffAckReply(),
      category: "staff_support",
      status: "waiting_admin",
      priority: "normal",
      escalate: true,
      notifyAdmin: firstStaffMessage,
      escalateReason: firstStaffMessage ? "staff_room" : undefined,
      source: "staff_ack",
      unclearStreak: 0,
    };
  }

  if (isExplicitStaffRequest(text)) {
    return adminResult(escalationReply(), "escalation", "staff_request", "staff_request");
  }

  const sensitiveKind = classifySensitive(text);
  if (sensitiveKind) {
    return sensitiveRouteResult(text, sensitiveKind);
  }

  if (containsThaiPhone(text)) {
    return adminResult(
      phoneReceivedAckReply(),
      "escalation",
      "phone_provided",
      "phone_provided",
    );
  }

  if (isSmallTalk(text)) {
    const rule = matchFaqRule(text, faqRules, ["global"]);
    if (rule) {
      return faqRouteResult(text, rule, listingCode, "property_faq", "faq_smalltalk");
    }
  }

  const globalFaq = matchFaqRule(text, faqRules, ["global"]);
  if (globalFaq) {
    return faqRouteResult(text, globalFaq, listingCode, "property_faq", "faq_global");
  }

  if (hasListing) {
    const propFaq = matchFaqRule(text, faqRules, ["property"]);
    if (propFaq) {
      return faqRouteResult(text, propFaq, listingCode, "property_faq", "faq_property");
    }
  }

  const discoveryFaq = matchFaqRule(text, faqRules, ["discovery"]);
  const discoveryOnProperty = hasListing && isDiscoveryScopedOnProperty(text);
  if (
    discoveryFaq &&
    (isDiscoveryThread || isDiscoveryIntent(text) || discoveryOnProperty)
  ) {
    const cat = discoveryOnProperty ? "property_faq" : "discovery";
    const src = discoveryOnProperty ? "faq_discovery_on_property" : "faq_discovery";
    return faqRouteResult(text, discoveryFaq, listingCode, cat, src);
  }

  const shouldRunDiscovery =
    isDiscoveryThread ||
    isDiscoveryIntent(text) ||
    wantsOtherUnitsInProject(text);

  let discoveryFallback: BotReply | null = null;
  if (shouldRunDiscovery) {
    const pool = discoveryPool(text, listings, projectName, listingId);
    const discovery = aiSupportReply(text, pool);
    if (discovery.links && discovery.links.length > 0) {
      return autoResult(discovery, "discovery", "discovery_db");
    }
    if (isDiscoveryThread || isDiscoveryIntent(text)) {
      discoveryFallback = discovery;
    }
  }

  const ragScopes = hasListing
    ? ["global", "property", "discovery"]
    : isDiscoveryThread
    ? ["global", "discovery"]
    : ["global"];

  const ragPool = shouldRunDiscovery
    ? discoveryPool(text, listings, projectName, listingId)
    : listings;

  const rag = await answerChatWithOpenAI({
    text,
    normalizedText: normalizeChatText(text),
    hasListing,
    isDiscoveryThread,
    listingCode,
    projectName,
    currentListing: ctx.currentListing ?? null,
    listings: ragPool.slice(0, 8),
    faqHints: findRelatedFaqRules(text, faqRules, ragScopes),
  });

  if (rag) {
    if (rag.intent === "sensitive" || rag.needs_admin) {
      return adminResult(
        escalationReply(),
        "escalation",
        rag.reason ?? "llm_rag",
        "llm_rag_escalate",
      );
    }

    if (rag.should_answer && rag.answer_text) {
      const category = rag.intent === "discovery" ? "discovery" : "property_faq";
      let reply: BotReply = { role: "ai", text: rag.answer_text };

      if (rag.intent === "discovery") {
        const discovery = aiSupportReply(text, ragPool);
        if (discovery.links && discovery.links.length > 0) {
          reply = { role: "ai", text: rag.answer_text, links: discovery.links };
        }
      }

      return autoResult(reply, category, "llm_rag");
    }
  }

  if (discoveryFallback) {
    return autoResult(discoveryFallback, "discovery", "discovery_empty");
  }

  // Lean: first unclear → bot asks to clarify; second → admin
  if (unclearStreak < 1) {
    return softDeferResult(unclearStreak);
  }

  return adminResult(escalationReply(), "escalation", "repeated_unclear", "fallback_admin");
}
