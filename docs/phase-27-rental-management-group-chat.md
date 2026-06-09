# Phase 27: บริหารจัดการทรัพย์ให้เช่า + แชทกลุ่ม

**Status:** Scaffold (Flutter demo + spec; DB ยังไม่ migrate)  
**Brand:** PROPPITER

---

## เป้าหมาย

เมนูหลัก **「บริหารจัดการทรัพย์ให้เช่า」** — ใช้ได้ทั้งหน้าบ้านและหลังบ้าน สำหรับสัญญาเช่าที่ active แล้ว (หลังปิดดีล / มอบหมายผู้เช่า)

| ความสามารถ | รายละเอียด |
|------------|------------|
| แชทกลุ่ม | ผู้เช่า · เอเจ้นท์ · เจ้าของ · แอดมิน อยู่ห้องเดียวกัน |
| เอกสาร | อัปโหลด/แชร์ไฟล์ · โน้ตต่อเอกสารในกลุ่ม |
| ค่าเช่า | แจ้งเตือนชำระ · ตั้งวันครบกำหนด · รอบบิล (รายเดือน/กำหนดเอง) |
| อัลบั้ม | อัลบั้มรูปในกลุ่ม (สภาพห้อง · มิเตอร์ · ซ่อม) |
| บัญชี | โน้ตเลขที่บัญชีรับโอน (ไม่เปิดเผย PII ส่วนตัว) |
| แจ้งซ่อม | เปิดเคสซ่อมในกลุ่ม · ติดตามสถานะ |
| Blind default | **ห้าม** เห็นเบอร์/Line/ข้อมูลหวงห้ามของกันและกันในแชทกลุ่ม |

อ้างอิงกฎธุรกิจ: [business-rules.md](business-rules.md) — blind intermediation ยังบังคับในกลุ่มเช่า

---

## Topology แชท (ต่อจาก Phase 24–26)

| `room_kind` | ใคร | จำนวน | Blind |
|-------------|-----|-------|-------|
| `rental_lease_group` | สมาชิกสัญญาเช่า | 1 / lease | ✅ |

สมาชิกแสดงเป็น **ชื่อแท็ก/บทบาท** เท่านั้น (`ผู้เช่า · คุณมิ้นท์`, `เอเจ้นท์ · PR-xxx`) — ไม่ดึง `profiles.phone` / Line เข้าห้อง

แอดมิน ops ดู PII ได้เฉพาะผ่าน **Vault / Participant 360°** นอกห้องกลุ่ม

---

## โมเดลข้อมูล (planned DB)

```sql
-- สัญญาเช่าที่ active
rental_leases (
  id, listing_id, listing_code, title,
  rent_amount, currency,
  payment_day_of_month,   -- 1-28
  billing_cycle,          -- monthly | custom
  lease_start, lease_end,
  status,                 -- active | ended | suspended
  thread_id,              -- FK chat_threads
  created_at
);

rental_lease_members (
  lease_id, user_id, role,  -- tenant | owner | agent | admin
  display_label,            -- snapshot ไม่มี PII
  profile_tag_id,           -- optional SP-/PR-/CL-
  joined_at
);

rental_group_attachments (
  id, lease_id, kind,       -- document | album_photo | bank_note
  storage_path, file_name, note, uploaded_by, created_at
);

rental_payment_reminders (
  id, lease_id, due_date, amount, status, sent_at, paid_at
);

rental_maintenance_tickets (
  id, lease_id, title, description, status, opened_by, created_at
);
```

`chat_messages` ขยาย `payload` สำหรับ:

- `rent_payment_reminder`
- `maintenance_ticket`
- `document_attachment`
- `bank_account_note`
- `album_photo`

---

## กฎ Blind / Vault

| ข้อมูล | ในแชทกลุ่ม | นอกกลุ่ม (Vault) |
|--------|-------------|------------------|
| เบอร์โทร | ❌ | แอดมิน tier ที่มีสิทธิ์ |
| Line ID | ❌ | แอดมิน tier ที่มีสิทธิ์ |
| เลขบัญชี | โน้ตที่แอดมิน/เจ้าของตั้งใจโพสต์ | audit log |
| ที่อยู่ละเอียด | เฉพาะที่อยู่ทรัพย์จาก listing | — |

ระบบสแกนข้อความในกลุ่ม: เบอร์/Line/ลิงก์นอก → แจ้งเตือน + บล็อกส่ง (เหมือน moderation ประกาศ)

---

## Flutter (scaffold ใน repo)

| Area | Path |
|------|------|
| Models | `mobile/lib/models/rental_lease.dart`, `rental_group_member.dart` |
| Service | `mobile/lib/services/rental_lease_service.dart`, `rental_payment_notification_service.dart` |
| Push | `notify-rental-payment` Edge · Web Notifications (demo) · FCM iOS/Android (`FCM_SERVER_KEY`) |
| หน้าบ้าน | `mobile/lib/features/rental/rental_management_home_page.dart` |
| แชทกลุ่ม | `mobile/lib/features/rental/rental_group_chat_page.dart` |
| หลังบ้าน | `mobile/lib/features/admin/admin_rental_management_tab.dart` |
| Nav | `AdminNavGroup.rentalManagement` → `/admin?nav=rentalManagement` |
| Route | `/rental-management` |

---

## Rollout

| Step | รายการ |
|------|--------|
| **27a** ✅ | Spec + scaffold UI + demo lease + เมนูหลัก |
| **27b** | DB migration + Storage bucket `rental-docs` |
| **27c** | Payment policy UI + reminders + slips + แอดมินยืนยันรับเงิน ✅ · push demo (Web Notifications + FCM Edge `notify-rental-payment`) · cron ถัดไป |
| **27d** | Maintenance workflow + admin SLA |
| **27e** | สแกน PII ในกลุ่ม + audit |

ดูเพิ่ม: [phase-24-26-chat-hub-tags.md](phase-24-26-chat-hub-tags.md), [phase-23-admin-vault.md](phase-23-admin-vault.md)
