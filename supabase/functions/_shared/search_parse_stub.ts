export type SearchParseResult = {
  filters: Record<string, unknown>;
  preview: { label: string; value: string }[];
};

/** Rule-based parser (ไม่ต้องมี API key) */
export function parseSearchStub(query: string): SearchParseResult {
  const q = query.toLowerCase();
  const filters: Record<string, unknown> = {};
  const preview: { label: string; value: string }[] = [];

  if (/สุขุมวิท|sukhumvit|อโศก|asok|มศว/.test(q)) {
    filters.geo_zone_slugs = ["sukhumvit", "asok"];
    preview.push({ label: "ทำเล", value: "สุขุมวิท, อโศก" });
  }
  if (/ทองหล่อ|thonglor|ทรู/.test(q)) {
    filters.geo_zone_slugs = ["thonglor"];
    filters.project_name = "ทรู ทองหล่อ";
    preview.push({ label: "โครงการ", value: "ทรู ทองหล่อ" });
    preview.push({ label: "ทำเล", value: "BTS ทองหล่อ" });
  }
  if (/บางนา|bang na|bangna/.test(q)) {
    filters.geo_zone_slugs = ["bangna"];
    preview.push({ label: "ทำเล", value: "BTS บางนา" });
  }

  const priceMatch = q.match(/(\d+)\s*k|ไม่เกิน\s*(\d+)/);
  if (priceMatch) {
    const amount = Number(priceMatch[1] || priceMatch[2]) * (q.includes("k") ? 1000 : 1);
    filters.max_price_net = amount;
    preview.push({
      label: "งบ",
      value: `≤ ${amount.toLocaleString("th-TH")} บาท/เดือน`,
    });
  }

  if (/เลี้ยงสัตว์|pet/.test(q)) {
    filters.pet_allowed = true;
    preview.push({ label: "สัตว์เลี้ยง", value: "อนุญาต" });
  }
  if (/คอนโด|condo/.test(q)) {
    filters.property_type = "condo";
    preview.push({ label: "ประเภท", value: "คอนโด" });
  }
  if (/เช่า|rent/.test(q)) {
    filters.listing_type = "rent";
    preview.push({ label: "ธุรกรรม", value: "เช่า" });
  }
  if (/ซื้อ|sale/.test(q)) {
    filters.listing_type = "sale";
    preview.push({ label: "ธุรกรรม", value: "ซื้อ" });
  }
  if (/co-agent|โคเอเจ้นท์|co agent/.test(q)) {
    filters.co_agent_eligible = true;
    preview.push({ label: "Co-Agent", value: "เปิดรับโคเอเจ้นท์" });
  }
  if (/bmv|below market/.test(q)) {
    filters.investor_category = "bmv";
    preview.push({ label: "นักลงทุน", value: "BMV" });
  }
  if (/ผู้เช่า|พร้อมผู้เช่า|with tenant/.test(q)) {
    filters.investor_category = "with_tenant";
    preview.push({ label: "นักลงทุน", value: "พร้อมผู้เช่า" });
  }

  const yieldMatch = q.match(/yield\s*(\d+)|ผลตอบแทน\s*(\d+)/);
  if (yieldMatch) {
    const pct = Number(yieldMatch[1] || yieldMatch[2]);
    filters.min_yield = pct;
    preview.push({ label: "Yield", value: `≥ ${pct}%` });
  }

  return { filters, preview };
}
