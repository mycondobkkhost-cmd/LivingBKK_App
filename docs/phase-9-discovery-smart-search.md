# Phase 9: Discovery + Smart Search (S2 + S3)

**Status:** Implemented  
**Date:** 2026-06-02

---

## Delivered

| Feature | Location |
|---------|----------|
| NLP preview ขณะพิมพ์ (wireframe §2.3) | `SmartSearchBar` + `SearchService.parseQuery` |
| Killer filter chips (เช่า/ซื้อ, Co-Agent, BMV, Yield) | `MapHomePage` + `SearchFilters` |
| ตัวกรองขั้นสูง: Co-Agent, นักลงทุน, Yield ขั้นต่ำ | `search_filter_sheet.dart` |
| กรอง geo zone / โครงการจาก NLP | `listing_repository.dart` + edge `smart-search-parse` |
| หมุดรวม (cluster) เมื่อซูมออก | `map_cluster_helper.dart` + `OsmListingsMap` / `ListingsMap` |

---

## Smart Search

1. พิมพ์ ≥ 3 ตัวอักษรในช่องค้นหา  
2. แสดงกล่อง **ตัวกรองที่ตรวจจับได้** (ทำเล, งบ, สัตว์เลี้ยง ฯลฯ)  
3. กด **ใช้ตัวกรอง** → โหลดทรัพย์ใหม่ · **ล้าง** → รีเซ็ต query

ใช้ Edge Function `smart-search-parse` เมื่อมี Supabase; ไม่มี → `_demoParse` ในแอป

---

## Killer Filters (หน้าแรก)

| Chip | ผลลัพธ์ |
|------|---------|
| เช่า / ซื้อ | `listing_type` |
| Co-Agent | `co_agent_eligible = true` |
| BMV | `investor_category = bmv` |
| Yield 5%+ | `yield_percent ≥ 5` |

---

## Map clustering

- ซูม **&lt; 14** และมีหมุด **≥ 8** → รวมเป็นวงกลมม่วงพร้อมตัวเลข  
- แตะ cluster → ซูมเข้าพื้นที่นั้น  
- ซูม **≥ 14** → แสดงหมุดราคาแยกรายการ (เหมือน Phase 8)

---

## Deploy

```bash
source scripts/dev-path.sh
supabase functions deploy smart-search-parse
```

---

## ทดสอบ

1. `./scripts/run-app.sh` → หน้าแรก  
2. พิมพ์ `คอนโดสุขุมวิท 15k เลี้ยงสัตว์` → ดู preview → ใช้ตัวกรอง  
3. กด chip **BMV** / **Yield 5%+**  
4. ซูมแผนที่ออก → เห็น cluster · แตะเพื่อซูมเข้า

---

## Next

- ~~FCM push~~ → [phase-10-push-notifications.md](phase-10-push-notifications.md)  
- ~~PM Package 20k~~ — ยกเลิก (โพสต์ฟรีทุกคน)
