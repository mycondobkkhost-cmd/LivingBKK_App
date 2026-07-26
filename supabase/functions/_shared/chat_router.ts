import {
  defaultCoachRequest,
  routeConversationalFirst,
  routeDiscoveryFallback,
  routeFaqInspirationFallback,
  routeViewingRequestGuard,
} from "./chat_conversational_route.ts";
import type { FaqRule, RouteContext, RouteResult } from "./chat_route_shared.ts";
export type { FaqRule, RouteContext, RouteResult } from "./chat_route_shared.ts";
export { matchFaqRule, findRelatedFaqRules } from "./chat_route_shared.ts";
import {
  aiSupportReply,
  BotReply,
  classifySensitive,
  containsThaiPhone,
  escalationReply,
  isDiscoveryIntentOnProperty,
  isExplicitStaffRequest,
  isFindOtherRoomIntent,
  isSmallTalk,
  ListingRow,
  phoneReceivedAckReply,
  sensitiveReply,
  type SensitiveKind,
  softClarifyReply,
  staffAckReply,
  unitPrivacyReply,
  wantsOtherUnitsInProject,
} from "./chat_logic.ts";
import { FIND_OTHER, findOtherRoomBurst } from "./find_other_room_voice.ts";
import { projectOtherUnitsSingleReply } from "./project_other_units_voice.ts";
import {
  appendOwnerInquiryDraft,
  classifyOwnerInquiryIntent,
  hasSpecificNegotiateOffer,
  inferOwnerInquiryTypeFromDraft,
  isNegotiateIntent,
  isOwnerInquiryReadyToSend,
  type OwnerInquiryType,
} from "./owner_inquiry_intent.ts";
import {
  compoundListingBurst,
  floorFacingBurst,
  isCompoundListingQuestion,
  isFloorFacingQuestion,
  isUnitNumberQuestion,
  ownerInquiryOpenBurst,
  ownerInquiryProfileBurst,
  priceNegotiationSalesBurst,
  VOICE,
} from "./owner_inquiry_voice.ts";
import {
  isViewingRequestIntent,
  viewingRequestBurst,
} from "./viewing_request_voice.ts";
import { ensureFemaleAiTone, GREETING_REPLY_TEXT, isGreetingOnly, INTERNET_FAQ_REPLY_BURST, isInternetQuestion } from "./chat_ai_voice.ts";
import {
  isLocationQuestion,
  listingToMapPin,
  locationFaqReply,
} from "./chat_map_link.ts";
import {
  normalizeChatText,
} from "./chat_text_normalize.ts";

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


function normalize(text: string): string {
  return normalizeChatText(text);
}

export function isDiscoveryIntent(text: string): boolean {
  const q = normalize(text);
  if (DISCOVERY_KEYS.some((k) => q.includes(k))) return true;
  return /\d[\d,]*\s*(?:บาท|k)?/i.test(q);
}

function discoveryIntentForThread(
  text: string,
  hasListing: boolean,
  isDiscoveryThread: boolean,
): boolean {
  if (isDiscoveryThread) return isDiscoveryIntent(text);
  if (!hasListing) return isDiscoveryIntent(text);
  return isDiscoveryIntentOnProperty(text);
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
  let replyText = ensureFemaleAiTone(rule.reply_text);
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
    kind === "commission" ||
    (kind === "contact" && containsThaiPhone(text));

  if (notifyAdmin) {
    return adminResult(reply, "escalation", kind, `sensitive_${kind}`);
  }
  return autoResult(reply, "property_faq", `sensitive_${kind}`);
}

function aiBurst(texts: string[], links: BotReply["links"] = []): BotReply[] {
  return texts.map((text, i) => ({
    role: "ai" as const,
    text,
    links: i === 0 ? (links ?? []) : [],
  }));
}

function ownerInquiryFormLink(
  listingId: string,
  draft: string,
  type: OwnerInquiryType,
) {
  return {
    label: VOICE.formLabel,
    kind: "owner_inquiry_form" as const,
    listingId,
    projectName: draft,
    refCode: type,
  };
}

function ownerInquiryCollectStartReplies(
  type: OwnerInquiryType,
  listingId: string,
  draft: string,
  listing?: RouteContext["currentListing"],
): BotReply[] {
  return aiBurst(ownerInquiryOpenBurst(type, listing ?? null));
}

function ownerInquiryCollectContinueReplies(
  listingId: string,
  draft: string,
): BotReply[] {
  const type = inferOwnerInquiryTypeFromDraft(draft);
  return aiBurst(
    ownerInquiryProfileBurst(),
    [ownerInquiryFormLink(listingId, draft, type)],
  );
}

function ownerInquiryReadyReplies(
  listingId: string,
  draft: string,
): BotReply[] {
  const type = inferOwnerInquiryTypeFromDraft(draft);
  return aiBurst(
    ownerInquiryProfileBurst(),
    [ownerInquiryFormLink(listingId, draft, type)],
  );
}

function compoundListingReplies(
  listingId: string,
  draft: string,
  listing?: RouteContext["currentListing"],
): BotReply[] {
  return aiBurst(compoundListingBurst(listing ?? null));
}

function floorFacingReplies(
  listing?: RouteContext["currentListing"],
): BotReply[] {
  return aiBurst(floorFacingBurst(listing ?? null));
}

function ownerInquiryBurstResult(
  replies: BotReply[],
  collecting: boolean,
  draft: string,
  source: string,
): RouteResult {
  const last = replies[replies.length - 1];
  return {
    ...autoResult(last, "owner_inquiry", source),
    replies,
    ownerInquiryCollecting: collecting,
    ownerInquiryDraft: draft,
  };
}

function routeOwnerInquiryFlow(ctx: RouteContext): RouteResult | null {
  const listingId = ctx.listingId ?? "";
  const collecting = ctx.ownerInquiryCollecting ?? false;
  const draft = ctx.ownerInquiryDraft ?? "";
  const { text } = ctx;
  const ready = isOwnerInquiryReadyToSend(text);
  const inquiry = classifyOwnerInquiryIntent(text);

  if (collecting) {
    if (ready && draft.trim().length > 0) {
      return ownerInquiryBurstResult(
        ownerInquiryReadyReplies(listingId, draft.trim()),
        false,
        "",
        "owner_inquiry_send",
      );
    }
    const newDraft = appendOwnerInquiryDraft(draft, text);
    if (newDraft === draft && !ready) return null;
    return ownerInquiryBurstResult(
      ownerInquiryCollectContinueReplies(listingId, newDraft),
      true,
      newDraft,
      "owner_inquiry_collect",
    );
  }

  if (inquiry) {
    const newDraft = appendOwnerInquiryDraft("", text);
    return ownerInquiryBurstResult(
      ownerInquiryCollectStartReplies(
        inquiry.type,
        listingId,
        newDraft,
        ctx.currentListing,
      ),
      true,
      newDraft,
      "owner_inquiry_start",
    );
  }

  return null;
}

function findOtherRoomResult(): RouteResult {
  const replies = aiBurst(findOtherRoomBurst(), [{
    label: FIND_OTHER.formLabel,
    kind: "requirement_form",
    listingId: "",
  }]);
  return {
    ...autoResult(replies[replies.length - 1], "property_faq", "find_other_room"),
    replies,
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

  if (containsThaiPhone(text)) {
    return adminResult(
      phoneReceivedAckReply(),
      "escalation",
      "phone_provided",
      "phone_provided",
    );
  }

  if (isGreetingOnly(text)) {
    const cat = hasListing ? "property_faq" : isDiscoveryThread ? "discovery" : "property_faq";
    return autoResult(
      { role: "ai", text: GREETING_REPLY_TEXT },
      cat,
      "greeting",
    );
  }

  const ownerFlow = routeOwnerInquiryFlow(ctx);
  if (ownerFlow) return ownerFlow;

  if (isFindOtherRoomIntent(text)) {
    return findOtherRoomResult();
  }

  if (hasSpecificNegotiateOffer(text)) {
    const draft = appendOwnerInquiryDraft("", text);
    const type = classifyOwnerInquiryIntent(text)?.type ?? "price_negotiation";
    return ownerInquiryBurstResult(
      ownerInquiryCollectStartReplies(type, listingId ?? "", draft, ctx.currentListing),
      true,
      draft,
      "owner_inquiry_offer",
    );
  }

  const viewingGuard = await routeViewingRequestGuard(ctx);
  if (viewingGuard) return viewingGuard;

  const conversational = await routeConversationalFirst(ctx);
  if (conversational) return conversational;

  const discoveryFb = routeDiscoveryFallback(ctx);
  if (discoveryFb) return discoveryFb;

  const faqFb = routeFaqInspirationFallback(ctx);
  if (faqFb) return faqFb;

  return defaultCoachRequest(ctx);
}
