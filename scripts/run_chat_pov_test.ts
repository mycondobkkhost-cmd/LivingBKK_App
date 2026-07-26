#!/usr/bin/env -S deno run --allow-read --allow-env
/**
 * POV chat routing smoke test — loads scenarios from chat_pov_decisions.json.
 * Usage: deno run --allow-read --allow-env scripts/run_chat_pov_test.ts
 */
import { routeChatMessage, type FaqRule } from "../supabase/functions/_shared/chat_router.ts";

const SEED = new URL(
  "../supabase/seed/chat_bot_training_gemini_v1.json",
  import.meta.url,
).pathname;
const POV = new URL(
  "../supabase/seed/chat_pov_decisions.json",
  import.meta.url,
).pathname;

type PovDecision = {
  pov_id: number;
  wave: number;
  category: string;
  thread: string;
  customer_msg: string;
  source: string;
  notify_admin: boolean;
  bursts: number;
  status: string;
  final_text?: string;
};

type Scenario = {
  povId: number;
  pov: string;
  message: string;
  hasListing: boolean;
  listingCode?: string;
  expectedNotify: boolean;
  expectedSource?: string;
  unclearStreak: number;
  skip?: boolean;
};

const raw = JSON.parse(await Deno.readTextFile(SEED));
const povRaw = JSON.parse(await Deno.readTextFile(POV));
const faqRules = raw.faq_rules as FaqRule[];
const decisions = povRaw.decisions as PovDecision[];

/** Map playbook POVs to routable scenarios (skip relay placeholders). */
function toScenario(d: PovDecision): Scenario | null {
  if (d.customer_msg.startsWith("(")) return null;

  const hasListing = d.thread === "property";
  const waveLabel = `รอบ${d.wave} · ${d.category}`;

  let unclearStreak = 0;
  if (d.customer_msg === "ไม่รู้สิ") unclearStreak = 1;
  if (d.customer_msg === "???") unclearStreak = 2;

  return {
    povId: d.pov_id,
    pov: `POV #${d.pov_id} ${waveLabel}`,
    message: d.customer_msg,
    hasListing,
    listingCode: hasListing ? "PPTR-2026-000101" : undefined,
    expectedNotify: d.notify_admin,
    expectedSource: d.source,
    unclearStreak,
  };
}

const scenarios: Scenario[] = decisions
  .map(toScenario)
  .filter((s): s is Scenario => s != null);

const mockListings = [
  {
    id: "11111111-1111-1111-1111-111111111111",
    listing_code: "PPTR-2026-000101",
    title: "คอนโด 1 นอน อโศก",
    project_name: "The Address Asoke",
    listing_type: "rent",
    price_net: 15000,
    property_type: "condo",
    district: "วัฒนา",
  },
  {
    id: "22222222-2222-2222-2222-222222222222",
    listing_code: "PPTR-2026-000202",
    title: "คอนโด ทองหล่อ",
    project_name: "Rhythm Sukhumvit",
    listing_type: "rent",
    price_net: 14000,
    property_type: "condo",
    district: "วัฒนา",
  },
];

const mockListing = {
  id: "11111111-1111-1111-1111-111111111111",
  listing_code: "PPTR-2026-000101",
  title: "คอนโด 1 นอน อโศก",
  project_name: "The Address Asoke",
  listing_type: "rent",
  price_net: 15000,
  property_type: "condo",
  district: "วัฒนา",
  pet_allowed: true,
  furnished: true,
  bedrooms: 1,
  bathrooms: 1,
  area_sqm: 35,
};

let passed = 0;
let failed = 0;
let toneWarnings = 0;

console.log("=== RealXtate Chat POV Playbook Test ===\n");
console.log(`FAQ rules: ${faqRules.length} | POV scenarios: ${scenarios.length}`);
console.log(`OPENAI_API_KEY: ${Deno.env.get("OPENAI_API_KEY") ? "set" : "not set (FAQ/rules only)"}\n`);

for (const s of scenarios) {
  const result = await routeChatMessage({
    text: s.message,
    isStaffRoom: false,
    listingId: s.hasListing ? mockListing.id : null,
    listingCode: s.listingCode ?? (s.hasListing ? mockListing.listing_code : null),
    projectName: s.hasListing ? mockListing.project_name : null,
    listings: mockListings,
    faqRules,
    priorUserMessages: 1,
    unclearStreak: s.unclearStreak,
    currentListing: s.hasListing ? mockListing : null,
  });

  const actualNotify = result.notifyAdmin || result.escalate;
  const notifyOk = actualNotify === s.expectedNotify;
  const burstCount = result.replies?.length ?? 1;

  const allText = (result.replies ?? [result.reply])
    .map((r) => r.text)
    .join(" ");
  const hasMaleTone = /ครับ|นะครับ|ไหมครับ/.test(allText) && result.reply.role !== "admin_notice";

  if (!notifyOk) failed++;
  else passed++;
  if (hasMaleTone) toneWarnings++;

  const admin = actualNotify ? "🔔 แจ้งแอดมิน" : "🤖 บอทตอบเอง";
  const preview = result.reply.text.length > 180
    ? result.reply.text.slice(0, 180) + "…"
    : result.reply.text;

  const statusIcon = notifyOk ? "✓" : "✗";

  console.log(`${statusIcon} 【${s.pov}】`);
  console.log(`ลูกค้า: "${s.message}"`);
  console.log(`${admin} | source: ${result.source} | ฟอง: ${burstCount}`);
  if (!notifyOk) {
    console.log(`  ⚠ notify mismatch: expected ${s.expectedNotify}, got ${actualNotify}`);
  }
  if (hasMaleTone) console.log(`  ⚠ male tone (ครับ) in AI reply`);
  console.log(`บอท: ${preview}`);
  if (result.reply.links?.length) {
    console.log(`ลิงก์: ${result.reply.links.map((l) => l.label).join(", ")}`);
  }
  console.log("");
}

console.log("--- Summary ---");
console.log(`Notify gate: ${passed}/${scenarios.length} passed, ${failed} failed`);
console.log(`Female tone warnings: ${toneWarnings}`);
if (failed > 0) Deno.exit(1);
