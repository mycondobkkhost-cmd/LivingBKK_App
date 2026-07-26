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

## สมุดโครงการมาสเตอร์ (2026-07)

**ชื่อยึด Property Hub · ทำเล/BTS จาก PH + LivingInsider**  
ดู `docs/PROJECT-MASTER.md` และ `./scripts/build-project-master.sh`

Pantip ไม่ใช่สมุดชื่อหลัก — ดู `docs/PANTIP-PROJECT-CATALOG.md`

## อนาคต

- Admin CRUD โครงการในแอป
- Geocode / เติมพิกัดจาก LivingInsider เมื่อ PH ว่าง
- หน้า Project Hub แยก (ไม่ใช่แค่ list ห้องในโครงเดียวกัน)
