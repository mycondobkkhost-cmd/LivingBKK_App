#!/usr/bin/env -S deno run --allow-read --allow-env
/**
 * POV chat routing smoke test — prints bot replies for common scenarios.
 * Usage: deno run --allow-read --allow-env scripts/run_chat_pov_test.ts
 */
import { routeChatMessage, type FaqRule } from "../supabase/functions/_shared/chat_router.ts";

const SEED = new URL(
  "../supabase/seed/chat_bot_training_gemini_v1.json",
  import.meta.url,
).pathname;

type Scenario = {
  pov: string;
  message: string;
  hasListing?: boolean;
  listingCode?: string;
};

const scenarios: Scenario[] = [
  { pov: "ลูกค้า — ถามราคา (พิมพ์ผิด)", message: "เท่าไหร่คับ", hasListing: true, listingCode: "PPTR-2026-000101" },
  { pov: "ลูกค้า — สัตว์เลี้ยง (พิมพ์ผิด)", message: "เลี้ยงสัตวได้ไหม", hasListing: true, listingCode: "PPTR-2026-000101" },
  { pov: "ลูกค้า — ขอเบอร์เจ้าของ", message: "ขอเบอร์เจ้าของหน่อยค่ะ จะคุยรายละเอียด", hasListing: true },
  { pov: "ลูกค้า — ถามชื่อเจ้าของ (PDPA)", message: "เจ้าของห้องชื่ออะไรคะ เป็นคนไทยหรือเปล่า", hasListing: true },
  { pov: "ลูกค้า — ต่อราคา สัญญา 2 ปี", message: "ราคา 15,000 ลดเหลือ 14,000 ได้ไหม ถ้าทำสัญญา 2 ปี", hasListing: true },
  { pov: "ลูกค้า — ถามชั้น/ทิศ", message: "ห้องนี้อยู่ชั้นอะไร ทิศไหนคะ", hasListing: true },
  { pov: "ลูกค้า — ทิ้งเบอร์มา", message: "0891112222 สนใจห้องนี้ครับ", hasListing: true },
  { pov: "ลูกค้า — ค่าคอมกี่เปอร์เซ็นต์", message: "ราคาเนทนี้รวมคอมมิชชั่นของเว็บไปกี่เปอร์เซ็นต์ครับ", hasListing: true },
  { pov: "ลูกค้า — นัดดูห้อง", message: "ขอดูห้องหน่อย ว่างไหม", hasListing: true },
  { pov: "ลูกค้า — ห้องว่างเมื่อไหร่", message: "ห้องนี้ว่างวันไหนคะ", hasListing: true },
  { pov: "ลูกค้า — ค้นหาทรัพย์", message: "หาคอนโดแถวอโศกงบหมื่นห้า", hasListing: false },
  { pov: "ลูกค้า — สัญญากี่ปี (ทั่วไป)", message: "สัญญาเช่ากี่เดือนคะ", hasListing: true },
  { pov: "ลูกค้า — คำถามกำกวมครั้งแรก", message: "อืม", hasListing: true },
  { pov: "ลูกค้า — คำถามกำกวมครั้งสอง", message: "ไม่รู้สิ", hasListing: true },
  { pov: "ลูกค้า — แพลตฟอร์มคืออะไร", message: "proppiter คึออะไร", hasListing: false },
  { pov: "ลูกค้า — Co-Agent", message: "co agent รับไหมค่ะ", hasListing: false },
  { pov: "ลูกค้า — cam fee", message: "cam fee เท่าไหร่", hasListing: true, listingCode: "PPTR-2026-000101" },
];

const raw = JSON.parse(await Deno.readTextFile(SEED));
const faqRules = raw.faq_rules as FaqRule[];

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

let unclearStreak = 0;

console.log("=== PROPPITER Chat POV Test ===\n");
console.log(`FAQ rules loaded: ${faqRules.length}`);
console.log(`OPENAI_API_KEY: ${Deno.env.get("OPENAI_API_KEY") ? "set (RAG may run)" : "not set (FAQ/rules only)"}\n`);

for (const s of scenarios) {
  const hasListing = s.hasListing ?? false;
  const result = await routeChatMessage({
    text: s.message,
    isStaffRoom: false,
    listingId: hasListing ? mockListing.id : null,
    listingCode: s.listingCode ?? (hasListing ? mockListing.listing_code : null),
    projectName: hasListing ? mockListing.project_name : null,
    listings: mockListings,
    faqRules,
    priorUserMessages: 1,
    unclearStreak: s.message === "ไม่รู้สิ" ? 1 : 0,
    currentListing: hasListing ? mockListing : null,
  });

  const admin = result.escalate ? "🔔 แจ้งแอดมิน" : "🤖 บอทตอบเอง";
  const preview = result.reply.text.length > 220
    ? result.reply.text.slice(0, 220) + "…"
    : result.reply.text;

  console.log(`【${s.pov}】`);
  console.log(`ลูกค้า: "${s.message}"`);
  console.log(`${admin} | source: ${result.source} | status: ${result.status}`);
  console.log(`บอท: ${preview}`);
  if (result.reply.links?.length) {
    console.log(`ลิงก์: ${result.reply.links.map((l) => l.label).join(", ")}`);
  }
  console.log("");
}
