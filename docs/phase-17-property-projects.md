# Phase 17: ทะเบียนโครงการ (LI-style + แก้จุดอ่อน)

**สถานะ:** Implemented  
**อัปเดต:** 2026-06-02

---

## ทำอะไร

| รายการ | รายละเอียด |
|--------|------------|
| ตาราง `property_projects` | 24 โครงการกทม./metro + slug มาตรฐาน |
| `listings.project_id` | FK ไม่พึ่งชื่อซ้ำแบบ LI |
| ปักหมุด | พิกัดจากโครงการ ไม่ใช้ GPS มือถือ |
| ฟอร์มลงประกาศ ~90% LI | เลือกโครงการ → เติมเขต/ประเภท/BTS อัตโนมัติ |
| แก้ LI | ชื่อ EN ใน DB, geo_zone, ห้องในโครงเดียวกันจาก slug |

---

## Deploy

```bash
cd /Users/angkarn1996/Desktop/LivingBKK_App
./scripts/deploy-all.sh
```

Migration: `20260602120028_property_projects.sql`

Regenerate seed SQL หลังแก้ `bangkok_projects.dart`:

```bash
cd mobile && dart run tool/export_projects_sql.dart
```

---

## ไฟล์หลัก

- `mobile/lib/data/bangkok_projects.dart` — bootstrap offline
- `mobile/lib/services/project_catalog.dart` — sync จาก Supabase
- `mobile/lib/widgets/project_picker_field.dart` — UI เลือกโครงการ
- `mobile/lib/features/listing/create_listing_page.dart` — ฟอร์มลงประกาศ

---

## Pantip catalog (2026-07)

ขยายสมุดโครงการจาก Pantip hub (~2k) — ดู `docs/PANTIP-PROJECT-CATALOG.md`  
ETL: `scripts/import-pantip-projects.py` → `data/pantip_import/` + migrations `20260726170*`

## อนาคต

- Admin CRUD โครงการในแอป
- Geocode โครงการที่ `coords_source=transit_approx` / null
- Import CSV / LI scrape pipeline (คนละ pipeline กับ Pantip catalog)
- หน้า Project Hub แยก (ไม่ใช่แค่ list ห้องในโครงเดียวกัน)
