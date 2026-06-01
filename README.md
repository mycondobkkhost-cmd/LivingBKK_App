# LivingBKK

แพลตฟอร์มอสังหาริมทรัพย์สำหรับ **เช่า / ซื้อ / ขาย** — โฟกัส **กรุงเทพมหานครและปริมณฑล** เท่านั้น

แพลตฟอร์มทำหน้าที่เป็นตัวกลาง 100% (ไม่เปิดเบอร์โทรหรือ Line ID โดยตรง) รายได้จาก Success Fee และแพ็กเกจ Property Management

## เอกสารออกแบบ

| Phase | ไฟล์ | สถานะ |
|-------|------|--------|
| 1 | [docs/phase-1-architecture.md](docs/phase-1-architecture.md) | Architecture & Roadmap |
| 2 | [docs/phase-2-wireframes.md](docs/phase-2-wireframes.md) | Wireframes & UX Flows |
| 3 | [docs/phase-3-database.md](docs/phase-3-database.md) | Database, RLS, Edge Functions |
| — | [docs/business-rules.md](docs/business-rules.md) | กฎธุรกิจรวม |

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

## ขั้นถัดไป

- **Phase 4:** FlutterFlow — Map Home, Board, Lead Bot ตาม wireframes
