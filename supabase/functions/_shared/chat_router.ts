import { classifyChatIntentOpenAI } from "./chat_intent_openai.ts";
import {
  aiSupportReply,
  BotReply,
  escalationReply,
  isExplicitStaffRequest,
  isSensitive,
  isSmallTalk,
  ListingRow,
  softClarifyReply,
  staffAckReply,
} from "./chat_logic.ts";

export type FaqRule = {
  scope: string;
  patterns: string[];
  reply_text: string;
  priority: number;
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
  return text.toLowerCase().trim();
}

export function matchFaqRule(
  text: string,
  rules: FaqRule[],
  scopes: string[],
): FaqRule | null {
  const q = normalize(text);
  const eligible = rules
    .filter((r) => scopes.includes(r.scope))
    .sort((a, b) => a.priority - b.priority);

  for (const rule of eligible) {
    if (rule.patterns.some((p) => q.includes(p.toLowerCase()))) {
      return rule;
    }
  }
  return null;
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

  if (isSensitive(text)) {
    return adminResult(escalationReply(), "escalation", "sensitive", "sensitive");
  }

  if (isSmallTalk(text)) {
    const rule = matchFaqRule(text, faqRules, ["global"]);
    if (rule) {
      return autoResult(faqReply(text, rule, listingCode), "property_faq", "faq_smalltalk");
    }
  }

  const globalFaq = matchFaqRule(text, faqRules, ["global"]);
  if (globalFaq) {
    return autoResult(faqReply(text, globalFaq, listingCode), "property_faq", "faq_global");
  }

  if (hasListing) {
    const propFaq = matchFaqRule(text, faqRules, ["property"]);
    if (propFaq) {
      return autoResult(
        faqReply(text, propFaq, listingCode),
        "property_faq",
        "faq_property",
      );
    }
  }

  const discoveryFaq = matchFaqRule(text, faqRules, ["discovery"]);
  if (discoveryFaq && (isDiscoveryThread || isDiscoveryIntent(text))) {
    return autoResult(faqReply(text, discoveryFaq, listingCode), "discovery", "faq_discovery");
  }

  const shouldRunDiscovery =
    isDiscoveryThread ||
    isDiscoveryIntent(text) ||
    wantsOtherUnitsInProject(text);

  if (shouldRunDiscovery) {
    const pool = discoveryPool(text, listings, projectName, listingId);
    const discovery = aiSupportReply(text, pool);
    if (discovery.links && discovery.links.length > 0) {
      return autoResult(discovery, "discovery", "discovery_db");
    }
    if (isDiscoveryThread || isDiscoveryIntent(text)) {
      return autoResult(discovery, "discovery", "discovery_empty");
    }
  }

  if (hasListing && !isDiscoveryIntent(text)) {
    const llm = await classifyChatIntentOpenAI(text, true);
    if (llm) {
      if (llm.intent === "sensitive" || llm.needs_admin) {
        return adminResult(escalationReply(), "escalation", "llm_gate", "llm_escalate");
      }
      if (llm.intent === "discovery" && llm.should_answer) {
        const discovery = aiSupportReply(text, listings);
        return autoResult(discovery, "discovery", "llm_discovery");
      }
      if (llm.intent === "property_faq" && llm.should_answer) {
        return autoResult(
          {
            role: "ai",
            text: llm.reason ??
              "รับทราบครับ หากต้องการรายละเอียดเพิ่ม แจ้งในแชทได้เลยครับ",
          },
          "property_faq",
          "llm_faq",
        );
      }
    }
  } else if (isDiscoveryThread) {
    const llm = await classifyChatIntentOpenAI(text, false);
    if (llm?.intent === "discovery" && llm.should_answer) {
      const discovery = aiSupportReply(text, listings);
      return autoResult(discovery, "discovery", "llm_discovery");
    }
  }

  // Lean: first unclear → bot asks to clarify; second → admin
  if (unclearStreak < 1) {
    return softDeferResult(unclearStreak);
  }

  return adminResult(escalationReply(), "escalation", "repeated_unclear", "fallback_admin");
}
