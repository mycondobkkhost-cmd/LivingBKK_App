# Phase 11: Production Complete (Moderation + Lifecycle + Deploy)

**Status:** Implemented  
**Date:** 2026-06-02

---

## Delivered

| Feature | Location |
|---------|----------|
| Lifecycle: หมดอายุ + ซ่อนที่ไม่ bump 30 วัน | `apply_listing_lifecycle()` + Edge `listing-lifecycle-cron` |
| รูปซ้ำ (hash) | `image-dedup-check` + `StorageService` SHA256 hash |
| Admin แท็บ Moderation | `AdminModerationTab` — อนุมัติรูป, ปิด flag, ซ่อนประกาศ |
| `geo_zone_slug` บน `listings_public` | migration `20260602120021` |
| Deploy ครบชุด | `scripts/deploy-all.sh` |
| Seed cloud | `scripts/seed-cloud.sh` |
| Checklist | `docs/PRODUCTION-CHECKLIST.md` |

---

## Deploy ครั้งเดียว (ก่อนทดสอบ)

```bash
cd LivingBKK_App
source scripts/dev-path.sh
cp .env.local.example .env.local   # ใส่ Supabase + Maps
./scripts/sync-env.sh
./scripts/supabase-setup.sh        # login + link + db push (หรือ deploy-all)
./scripts/deploy-all.sh            # db push + functions ทั้งหมด
./scripts/seed-cloud.sh            # ทรัพย์ตัวอย่าง
```

ตั้ง admin:

```sql
UPDATE profiles SET role = 'admin'
WHERE id = (SELECT id FROM auth.users WHERE email = 'YOUR@EMAIL');
```

---

## Cron (รายวัน)

Supabase Dashboard → Edge Functions → `listing-lifecycle-cron` → Schedule  
หรือ Make.com HTTP:

```
POST {SUPABASE_URL}/functions/v1/listing-lifecycle-cron
Authorization: Bearer {SERVICE_ROLE_KEY}
```

ตั้ง secret `CRON_SECRET` แล้วส่ง `Authorization: Bearer {CRON_SECRET}` (ทางเลือก)

---

## โมเดลธุรกิจ

- **โพสต์ฟรี** — ไม่มี PM subscription  
- **Bump:** Owner กด「ยืนยันว่าง」ใน「ประกาศของฉัน」→ ต่ออายุ 30 วัน  
- **Auto-hide:** ไม่ bump 30 วัน → `hidden`  
- **รูปใหม่:** `pending` จน Admin อนุมัติ (หรือ auto ถ้าไม่ซ้ำ)

---

## Phase สรุป (1–11)

| Phase | หัวข้อ |
|-------|--------|
| 1–4 | Architecture, Wireframes, DB, Flutter |
| 5–6 | Lead, E-Contract, Admin นัดชม, Maps |
| 7–8 | รายงาน, Make.com, Seed, หมุดราคา |
| 9 | Smart Search, Killer filters, Cluster |
| 10 | FCM (ทางเลือก), โพสต์ฟรี |
| 11 | Moderation, Lifecycle, Deploy/Seed ครบ |

---

## Next

- ~~OpenAI ใน smart-search~~ → [phase-12-ai-and-security.md](phase-12-ai-and-security.md)  
- สรุปที่เหลือ → [ROADMAP-REMAINING.md](ROADMAP-REMAINING.md)
