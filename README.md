# LivingBKK

แพลตฟอร์มอสังหาริมทรัพย์สำหรับ **เช่า / ซื้อ / ขาย** — โฟกัส **กรุงเทพมหานครและปริมณฑล** เท่านั้น

แพลตฟอร์มทำหน้าที่เป็นตัวกลาง 100% (ไม่เปิดเบอร์โทรหรือ Line ID โดยตรง) รายได้จาก Success Fee และแพ็กเกจ Property Management

## เอกสารออกแบบ

| Phase | ไฟล์ | สถานะ |
|-------|------|--------|
| 1 | [docs/phase-1-architecture.md](docs/phase-1-architecture.md) | Architecture & Roadmap |
| 2 | [docs/phase-2-wireframes.md](docs/phase-2-wireframes.md) | Wireframes & UX Flows |
| 3 | [docs/phase-3-database.md](docs/phase-3-database.md) | Database, RLS, Edge Functions |
| 4 | [docs/phase-4-frontend.md](docs/phase-4-frontend.md) | Flutter app + FlutterFlow guide |
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
cd mobile
flutter create . --project-name livingbkk --org com.livingbkk
flutter pub get
# แก้ค่าใน assets/env แล้ว
flutter run
```

ดู [mobile/README.md](mobile/README.md)

## ขั้นถัดไป

1. ตั้งค่า Supabase → [docs/SETUP.md](docs/SETUP.md)  
2. แก้ `mobile/assets/env` แล้ว `flutter run`  
3. **Phase 4.3:** Maps key + `flutter create` → ดู [mobile/docs/MAPS_SETUP.md](mobile/docs/MAPS_SETUP.md)  
4. **Phase 4.4:** Admin, moderation, Realtime — [docs/phase-4-4-admin-realtime.md](docs/phase-4-4-admin-realtime.md)  
5. **Phase 4.5:** FCM (optional) — [mobile/docs/FCM_SETUP.md](mobile/docs/FCM_SETUP.md)
