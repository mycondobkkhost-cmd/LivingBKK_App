# PRE-PUSH — สรุปรวมทุกงาน (อัปเดต 2026-06-04)

เอกสารนี้รวบรวมจาก **repo จริง** + งานในแชท (Q&A, รีแบรนด์ PROPPITER, PPTR inventory, Exclusive, นัดดู)

---

## สถานะโดยรวม

| มิติ | สถานะ |
|------|--------|
| โค้ดแอป + backend ใน repo | **พร้อม push** (branch ahead 2 commits + งานค้าง stage) |
| Migrations | **45 ไฟล์** — ต้อง `supabase db push` บน cloud |
| Edge Functions | **22 ตัว** — `deploy-all.sh` |
| Flutter tests | **15 ผ่าน / 0 ล้ม** (หลังแก้ widget_test) |
| รีแบรนด์ PROPPITER | ชื่อ/สีในแอปส่วนใหญ่แล้ว · asset PNG ยัง `livingbkk-*` ได้ |
| Push Git / Netlify / Store | **คุณทำ** — ดู checklist ด้านล่าง |

---

## ทำเสร็จใน repo แล้ว (Phase / ฟีเจอร์)

| Phase | หัวข้อ |
|-------|--------|
| 1–17 | ตาม `docs/phase-*.md` (architecture → projects) |
| 18–19 | LI import, lifecycle push (เอกสาร + migration) |
| **20a** | **PPTR ทะเบียนทรัพย์รวม** — dedupe ลูกค้า, หลายเอเจ้นท์, เจ้าของลำดับ 1 |
| **20b** | **Exclusive** เจ้าของ/เอเจ้นท์ + auto bump |
| **21** | **viewing_access** ตอนลงประกาศ |
| แบรนด์ | PROPPITER ใน `living_bkk_brand.dart`, `tokens.json`, wordmark |
| แอดมิน | แท็บ **ทะเบียนทรัพย์ (PPTR)** |

---

## ยังไม่เสร็จ — ไม่บล็อก push โค้ด แต่บล็อก “เปิดใช้จริง”

| ลำดับ | รายการ | ใครทำ |
|-------|--------|--------|
| 1 | Commit + push Git งานทั้งหมด | คุณ |
| 2 | `supabase db push` + `deploy-all.sh` | คุณ (มี `.env.local`) |
| 3 | `seed-cloud.sh` + ปิด Confirm email | คุณ |
| 4 | `sync-env.sh` · `TRIAL_MODE=false` เมื่อ production | คุณ |
| 5 | Cron: `listing-lifecycle-cron` รายวัน | Dashboard |
| 6 | Cron (แนะนำ): `process_exclusive_auto_bumps()` รายชม. | SQL / pg_cron |
| 7 | Google Maps / Firebase / Make.com | ทางเลือก |
| 8 | E2E ทดสอบมือตาม `PRODUCTION-CHECKLIST.md` | คุณ |
| 9 | รีแบรนด์ asset PNG ครบ + `sync-brand-assets.py` | ดีไซน์/UX project |
| 10 | E-Contract vendor จริง | ธุรกิจ/ภายนอก |
| 11 | App Store signing (release keystore) | ก่อน Store |

---

## Migrations ใหม่ที่ต้องขึ้น cloud (สำคัญ)

```
20260604120000_listing_pending_review.sql
20260604120100_listing_type_sale_installment.sql
20260604130000_property_inventory_dedup.sql
20260604130100_inventory_code_pptr.sql
20260604210000_listing_exclusive.sql
20260604220000_listing_viewing_access.sql
```

คำสั่ง:

```bash
source scripts/dev-path.sh
supabase db push
./scripts/deploy-all.sh
```

---

## คำสั่ง Push แนะนำ (ลำดับ)

```bash
# 1) ตรวจ
./scripts/verify-ready.sh
cd mobile && flutter test

# 2) Git (เมื่อพร้อม)
git add -A
git status
git commit -m "..."   # คุณกำหนดข้อความ

# 3) Remote
git push origin main

# 4) Backend
./scripts/deploy-all.sh
./scripts/seed-cloud.sh

# 5) เว็บ (ทางเลือก)
./scripts/build-web.sh
# อัปโหลด mobile/build/web → Netlify
```

---

## สิ่งที่ตั้งใจไม่ทำก่อน push (ลดความเสี่ยง)

- เปลี่ยน package name / bundle id (`livingbkk` → `proppiter`)
- Lead ผูก `inventory_id` แทน `listing_id`
- จับคู่รูปซ้ำ → รวม PPTR อัตโนมัติ
- Rewrite เอกสารทุกไฟล์ LivingBKK → PROPPITER

---

## อ้างอิง

- [PRODUCTION-CHECKLIST.md](PRODUCTION-CHECKLIST.md)
- [ROADMAP-REMAINING.md](ROADMAP-REMAINING.md)
- [phase-20-property-inventory.md](phase-20-property-inventory.md)
- [phase-20-exclusive-listings.md](phase-20-exclusive-listings.md)
- [phase-21-viewing-access.md](phase-21-viewing-access.md)
- [PROPPITER-UXUI-HANDOFF.md](PROPPITER-UXUI-HANDOFF.md)
