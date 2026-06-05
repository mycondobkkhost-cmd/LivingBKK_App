# Phase 20: ทะเบียนทรัพย์รวม (PPTR) — ไม่ซ้ำหน้าลูกค้า + หลายเอเจ้นท์หลังบ้าน

**สถานะ:** พร้อมใช้หลัง `db push`  
**Migration:** `supabase/migrations/20260604130000_property_inventory_dedup.sql`

---

## สิ่งที่ได้

| หัวข้อ | รายละเอียด |
|--------|------------|
| รหัสทรัพย์กลาง | `PPTR-2026-000001` ต่อหน่วยทรัพย์ (ตัวย่อแอป PROPPITER · จับคู่จากโครงการ+ห้อง+ชั้น+ตร.ม.+ประเภทธุรกรรม) |
| ลูกค้าเห็น | **ประกาศเดียว** ต่อทรัพย์ — ผ่าน `listings_public` (แถว `display_listing_id`) |
| หลังบ้าน | ทุกประกาศที่ผูก `inventory_id` เดียวกัน — แท็บแอดมิน **ทะเบียนทรัพย์** |
| เจ้าของโพสหลังเอเจ้นท์ | ลำดับติดต่อ **1** + remark `เจ้าของตรง — ลำดับความสำคัญ 1 (โพสต์หลังเอเจ้นท์)` + แจ้งเตือน admin |
| เอเจ้นท์โพสก่อน | remark `เอเจ้นท์ — โพสต์ก่อนเจ้าของ` |
| ไม่ว่าง / ปิด | เอเจ้นท์คนหนึ่งปิด/ซ่อน → ซิงค์ซ่อนประกาศ **published** อื่นในทรัพย์เดียวกัน + บันทึก `inventory_sync_remark` |

---

## Deploy

```bash
source scripts/dev-path.sh
supabase db push
# หรือ
./scripts/deploy-all.sh
```

---

## แอดมิน

แท็บ **ทะเบียนทรัพย์** ใน Admin Home:

- รายการ PPTR + จำนวนประกาศ + badge แจ้งเตือน
- รายละเอียด: สมาชิกเรียงตาม `inventory_contact_priority` (1 = ติดต่อก่อน)
- ปุ่ม **ตั้งเป็นติดต่อหลัก** → RPC `admin_set_inventory_primary_contact`
- **รับทราบ** แจ้งเตือนเจ้าของครอบสิทธิ์

---

## กฎจับคู่อัตโนมัติ

Fingerprint = `listing_type | property_type | project_id | project_name | unit_number | exact_floor | area_sqm`

เมื่อ `status` → `published` (หรืออัปเดตฟิลด์จับคู่) → `assign_listing_to_inventory`

**หมายเหตุ:** เอเจ้นต้องกรอก **เลขห้อง/ชั้น** ตรงกันถึงจะรวมกลุ่มได้ — ถ้าไม่กรอกจะแยก PPTR คนละกลุ่ม

---

## ถัดไป (ไม่รวมเฟสนี้)

- จับคู่จากรูปซ้ำ (`image-dedup-check`) → เสนอรวม PPTR
- Lead ผูก `inventory_id` แทน `listing_id` เดียว
- UI เอเจ้นท์: ปุ่ม “ทรัพย์ไม่ว่าง” เรียก sync ชัดเจน
