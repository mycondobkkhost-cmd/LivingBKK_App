# Phase 14: LI-Inspired Features (โพสต์ฟรี 100%)

**Status:** Implemented  
**Date:** 2026-06-02

ฟีเจอร์จาก LivingInsider ที่ **ไม่ผูกเครดิต/ดันประกาศ** — ปรับให้เข้ากับโมเดล LivingBKK (กลาง 100%, Success Fee)

---

## Delivered

| Feature | Location |
|---------|----------|
| **Looking to Match** | `RequirementMatchService` + แสดงใน `my_requirements_page.dart` |
| **Notify Me (ฟรี)** | `SavedSearchService` + `saved_searches_page.dart` |
| **Preferred Stock (เอเจนท์)** | `PreferredStockService` + section หน้าแรก + bookmark ใน detail |
| **Compare listings** | `CompareService` + `compare_listings_page.dart` (สูงสุด 4) |
| **Recently viewed** | `ListingActivityService` + section หน้าแรก |
| **Property Near Me** | `geo_distance.dart` + section + chip หน้าแรก |
| **Listing analytics** | views/share ใน `listing_detail_page.dart` |
| **Chat quick reply + translate stub** | `property_chat_page.dart` |
| **My Stock extras** | monthly rent, video URL, template, My Note ใน `create_listing_page.dart` |
| **Agent tools** | `agent_tools_page.dart` (คำนวณค่าโอนประมาณ) |
| **Owner stock feed** | section `owner_stock_new` สำหรับเอเจนท์ |
| **Persistence (local)** | `LocalPrefsService` + `shared_preferences` |
| **DB migration** | `20260602120023_phase14_li_features.sql` |

---

## สิ่งที่ไม่ทำ (ขัดโมเดล LI / LivingBKK)

- ดันประกาศ / Boost / Automate Boost  
- แพ็กเกจเครดิต / Premium Package  
- iStock subscription  
- เปิดเบอร์/Line ในประกาศ  
- Living-One-Chat (Line OA)

---

## ทดสอบ

```bash
cd mobile && flutter pub get && flutter run -d chrome
```

1. หน้าแรก → chip **ใกล้ฉัน** / **เปรียบเทียบ** / **แจ้งเตือนค้นหา**  
2. เปิดทรัพย์ → กด compare / bookmark (เอเจนท์) → ดูสถิติเข้าชม  
3. แชททรัพย์ → quick reply / แปล EN  
4. ความต้องการของฉัน → **Looking to Match** แสดงทรัพย์ที่จับคู่ได้  
5. โปรไฟล์ → แจ้งเตือนค้นหา / เปรียบเทียบ / เครื่องมือเอเจนท์  

---

## Deploy DB (เมื่อพร้อม Cloud)

```bash
source scripts/dev-path.sh
supabase db push
```
