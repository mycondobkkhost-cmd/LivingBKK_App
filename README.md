# LivingBKK

แพลตฟอร์มอสังหาริมทรัพย์สำหรับ **เช่า / ซื้อ / ขาย** — โฟกัส **กรุงเทพมหานครและปริมณฑล** เท่านั้น

แพลตฟอร์มทำหน้าที่เป็นตัวกลาง 100% (ไม่เปิดเบอร์โทรหรือ Line ID โดยตรง) — **โพสต์ประกาศฟรี** รายได้จาก Success Fee เท่านั้น

## เอกสารออกแบบ

| Phase | ไฟล์ | สถานะ |
|-------|------|--------|
| 1 | [docs/phase-1-architecture.md](docs/phase-1-architecture.md) | Architecture & Roadmap |
| 2 | [docs/phase-2-wireframes.md](docs/phase-2-wireframes.md) | Wireframes & UX Flows |
| 3 | [docs/phase-3-database.md](docs/phase-3-database.md) | Database, RLS, Edge Functions |
| 4 | [docs/phase-4-frontend.md](docs/phase-4-frontend.md) | Flutter app + FlutterFlow guide |
| 5 | [docs/phase-5-lead-econtract.md](docs/phase-5-lead-econtract.md) | Lead inbox, E-Contract, unavailable |
| 6 | [docs/phase-6-admin-appointments-maps.md](docs/phase-6-admin-appointments-maps.md) | Admin นัดชม + Maps |
| 7 | [docs/phase-7-reporting-push.md](docs/phase-7-reporting-push.md) | รายงาน, Make.com, Push |
| 8 | [docs/phase-8-seed-and-map-markers.md](docs/phase-8-seed-and-map-markers.md) | Seed ทรัพย์ + หมุดราคา |
| 9 | [docs/phase-9-discovery-smart-search.md](docs/phase-9-discovery-smart-search.md) | Smart Search + Killer filters + Cluster |
| 10 | [docs/phase-10-push-notifications.md](docs/phase-10-push-notifications.md) | FCM push + ยกเลิก PM subscription |
| 11 | [docs/phase-11-production-complete.md](docs/phase-11-production-complete.md) | Moderation + Lifecycle + Deploy ครบ |
| 12 | [docs/phase-12-ai-and-security.md](docs/phase-12-ai-and-security.md) | AI Search + กัน self-admin |
| 21 | [docs/phase-21-analytics-platform.md](docs/phase-21-analytics-platform.md) | Analytics platform — scale แสนคน |
| 13 | [docs/phase-13-เปิดใช้บนมือถือ.md](docs/phase-13-เปิดใช้บนมือถือ.md) | เว็บมือถือ + ติดจอโฮม |
| — | [docs/คู่มือ-ใช้แอปบนมือถือ.md](docs/คู่มือ-ใช้แอปบนมือถือ.md) | คู่มือภาษาไทย (ไม่ใช่โปรแกรมเมอร์) |
| — | [docs/ROADMAP-REMAINING.md](docs/ROADMAP-REMAINING.md) | **สิ่งที่เหลือทั้งหมด** |
| — | [docs/PRODUCTION-CHECKLIST.md](docs/PRODUCTION-CHECKLIST.md) | Checklist ก่อนเปิดใช้จริง |
| — | [docs/business-rules.md](docs/business-rules.md) | กฎธุรกิจรวม |
| — | [docs/flutterflow-setup.md](docs/flutterflow-setup.md) | FlutterFlow integration |
| — | [docs/SETUP.md](docs/SETUP.md) | คู่มือตั้งค่าทั้งระบบ |

## Stack (แนะนำ)

- **Frontend:** FlutterFlow
- **Backend:** Supabase (PostgreSQL + PostGIS, RLS, Storage, Edge Functions)
- **Maps:** Google Maps Platform
- **Admin sync:** Make.com → Google Sheets (สถิติเท่านั้น)

## Theme

ม่วง-ขาว (Purple & White) — Minimalist, Airbnb-inspired, Map-first

ดู design tokens: [design/tokens.json](design/tokens.json)

## Supabase (Phase 3)

```bash
brew install supabase/tap/supabase
cd LivingBKK_App
cp .env.example .env.local
supabase start
supabase db reset   # migrations + seed.sql
```

ดูรายละเอียด: [docs/phase-3-database.md](docs/phase-3-database.md)

## Mobile app (Phase 4)

```bash
# ครั้งแรก: เพิ่ม PATH (ดู docs/TROUBLESHOOTING.md)
source /Users/angkarn1996/Desktop/LivingBKK_App/scripts/dev-path.sh

cd mobile
flutter pub get
flutter run -d chrome   # macOS 12 ไม่มี Xcode → ใช้ Chrome
# แก้ค่าใน assets/env ก่อนเชื่อม Supabase จริง
```

ดู [mobile/README.md](mobile/README.md)

## รันครบชุด (Supabase + Maps)

```bash
cp .env.local.example .env.local   # ใส่ key จริง
./scripts/setup-all.sh
```

คู่มือทีละขั้น: [docs/QUICKSTART-ONE-SHOT.md](docs/QUICKSTART-ONE-SHOT.md)

## ขั้นถัดไป

1. ตั้งค่า Supabase → [docs/SETUP.md](docs/SETUP.md)  
2. แก้ `mobile/assets/env` แล้ว `flutter run`  
3. **Phase 4.3:** Maps key + `flutter create` → ดู [mobile/docs/MAPS_SETUP.md](mobile/docs/MAPS_SETUP.md)  
4. **Phase 4.4:** Admin, moderation, Realtime — [docs/phase-4-4-admin-realtime.md](docs/phase-4-4-admin-realtime.md)  
5. **Phase 5:** Lead รับเคส + E-Contract — [docs/phase-5-lead-econtract.md](docs/phase-5-lead-econtract.md)  
6. **Phase 6:** Admin นัดชม + Maps — [docs/phase-6-admin-appointments-maps.md](docs/phase-6-admin-appointments-maps.md)  
7. **Phase 7:** รายงาน + Make.com + Push — [docs/phase-7-reporting-push.md](docs/phase-7-reporting-push.md)  
8. **Phase 8:** Seed ทรัพย์ + หมุดราคา — [docs/phase-8-seed-and-map-markers.md](docs/phase-8-seed-and-map-markers.md)  
9. **Phase 9:** Smart Search + Killer filters + หมุด cluster — [docs/phase-9-discovery-smart-search.md](docs/phase-9-discovery-smart-search.md)  
10. **Phase 10:** FCM push (ทางเลือก) + โพสต์ฟรี — [docs/phase-10-push-notifications.md](docs/phase-10-push-notifications.md)  
11. **Phase 11:** Moderation + Lifecycle + Deploy ครบ — [docs/phase-11-production-complete.md](docs/phase-11-production-complete.md)  
12. **Phase 12:** AI Search + Security — [docs/phase-12-ai-and-security.md](docs/phase-12-ai-and-security.md)  
13. **Phase 13:** เปิดบนมือถือจริง — [docs/คู่มือ-ใช้แอปบนมือถือ.md](docs/คู่มือ-ใช้แอปบนมือถือ.md)  
**เหลืออะไร:** [docs/ROADMAP-REMAINING.md](docs/ROADMAP-REMAINING.md) · [PRODUCTION-CHECKLIST.md](docs/PRODUCTION-CHECKLIST.md)
