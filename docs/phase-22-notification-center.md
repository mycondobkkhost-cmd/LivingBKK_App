# Phase 22: Notification Center (มุมบนขวา)

**สถานะ:** ออกแบบไว้ก่อน — ยังไม่ implement  
**อัปเดต:** 2026-06-05  
**อ้างอิง:** `InAppNotificationHub`, Phase 19 lifecycle, chat, leads, appointments

---

## 1. ปัญหาปัจจุบัน

| จุด | สถานะวันนี้ |
|-----|-------------|
| ไอคอนกระดิ่งหน้าแรก | กดแล้ว **ไปแท็บข้อความ** (`MainShell` tab 3) — ไม่ใช่ศูนย์แจ้งเตือน |
| `LiHomeHeader` | ปุ่มกระดิ่ง `onPressed: () {}` — **ยังไม่ทำงาน** |
| `InAppNotificationHub` | แบนเนอร์บน + `unreadChat` เท่านั้น |
| ประกาศ lifecycle | แยกเป็น `ListingBumpReminderBanner` บนหน้าแรก |
| Push นอกแอป | FCM แยก type ใน `NotificationService` — ยังไม่รวมศูนย์ |

**เป้าหมาย:** กระดิ่งมุมขวาบน = **ศูนย์แจ้งเตือนครบ** (อ่านแล้ว / กดไปงานได้) ไม่ปนกับรายการแชทอย่างเดียว

---

## 2. UX — เปิดจากไหน

| จุดเข้า | พฤติกรรม |
|---------|----------|
| กระดิ่ง `home_browse_layout` / `LiHomeHeader` | เปิด **Notification Center** |
| Badge บนกระดิ่ง | จำนวน **ยังไม่อ่าน** รวมทุกประเภท (cap แสดง `9+`) |
| แบนเนอร์ `InAppNotificationBanner` | แตะ → เปิด Center กรองที่ **ประเภทนั้น** หรือ deep link ตรง |
| Push (FCM) | เปิดแอป → Center + scroll ไปรายการ + mark read |

**รูปแบบ UI (แนะนำ v1):** Bottom sheet สูง ~85% หรือเต็มหน้า `/notifications`  
โทน Canva/PROPPITER — พื้น `#F9F9FB`, การ์ดขาว, pill chip กรอง

```
┌─────────────────────────────────────┐
│ ← การแจ้งเตือน          [อ่านทั้งหมด] │
│ [ทั้งหมด] [แชท] [นัด] [ประกาศ] [ระบบ] │  ← filter chips
├─────────────────────────────────────┤
│ วันนี้                               │
│ ┌─────────────────────────────────┐ │
│ │ 💬 แชทใหม่ — คอนโด xxx          │ │
│ │    ทีมงานตอบกลับแล้ว · 2 นาที    │ │
│ └─────────────────────────────────┘ │
│ ┌─────────────────────────────────┐ │
│ │ 📅 นัดชมพรุ่งนี้ 10:00           │ │
│ └─────────────────────────────────┘ │
│ เมื่อวาน                             │
│ ┌─────────────────────────────────┐ │
│ │ 📢 ยืนยันว่างประกาศ — บ้าน xxx   │ │
│ │    ครบ 7 วัน · กด bump ฟรี      │ │
│ └─────────────────────────────────┘ │
│ ...                                 │
└─────────────────────────────────────┘
```

---

## 3. ประเภทแจ้งเตือน (Taxonomy)

รหัส `type` ใช้ร่วม in-app + FCM + DB

### 3.1 แชท & การสื่อสาร

| type | ใครเห็น | ข้อความตัวอย่าง | Deep link |
|------|---------|-----------------|-----------|
| `chat_message` | ทุก role | ข้อความใหม่ในแชททรัพย์ / ลีด | `/contact/chat/:threadId` |
| `chat_admin_reply` | Seeker/Owner/Agent | ทีม PROPPITER ตอบกลับแล้ว | เหมือนบน |
| `lead_new` | Agent/Admin | มีลีดใหม่รอรับ | `/work/leads/:id` |
| `lead_status` | Owner/Seeker | สถานะลีดอัปเดต | `/work/leads/:id` |

### 3.2 นัดหมาย

| type | ใครเห็น | ข้อความตัวอย่าง | Deep link |
|------|---------|-----------------|-----------|
| `appointment_created` | ที่เกี่ยวข้อง | นัดชมทรัพย์ — วัน/เวลา | `/work/appointments/:id` หรือ admin |
| `appointment_reminder` | ที่เกี่ยวข้อง | เตือนนัดชมใน 24 ชม. | เหมือนบน |
| `appointment_cancelled` | ที่เกี่ยวข้อง | นัดชมถูกยกเลิก | เหมือนบน |
| `viewing_access_granted` | Seeker | เปิดห้องนัดดูแล้ว | `/listing/:id` + sheet |

### 3.3 ประกาศ (Owner / Agent) — **ดันประกาศ**

| type | trigger | ข้อความตัวอย่าง | CTA |
|------|---------|-----------------|-----|
| `listing_bump_due` | ครบ 7 วัน | ยืนยันว่างเพื่อดันโพสต์ขึ้น | `/listings/mine` → bump |
| `listing_stale_warning` | เหลือ 3–7 วันก่อน 30 | ประกาศใกล้ถูกเก็บ — ยืนยันว่าง | bump |
| `listing_archived_stale` | ครบ 30 วัน | เก็บประกาศอัตโนมัติแล้ว | `/listings/mine?tab=archived` |
| `listing_draft_fix` | moderation reject | แก้ประกาศเพื่อเผยแพร่ได้ | `/listing/create?edit=:id` |
| `listing_pending_review` | ส่งตรวจแล้ว | ทีมกำลังตรวจสอบ | `/listings/mine` |
| `listing_published` | อนุมัติแล้ว | ประกาศขึ้นแล้ว | `/listing/:id` |
| `listing_promo_nudge` | ทางเลือกอนาคต | ดันประกาศให้เห็นมากขึ้น (ไม่ขายเครดิต — แค่ bump/เคล็ดลับ) | `/listings/mine` |
| `listing_exclusive_bump` | auto bump exclusive | ดันประกาศ Exclusive อัตโนมัติ | `/listings/mine` |

### 3.4 การค้นหา & บอร์ด

| type | ใครเห็น | ข้อความ | Deep link |
|------|---------|---------|-----------|
| `saved_search_match` | Seeker | ทรัพย์ใหม่ตรง Saved Search | `/browse?filters=...` |
| `demand_offer_received` | Owner/Admin | มีข้อเสนอบนบอร์ด | `/board/:postId` |
| `demand_offer_status` | Agent | สถานะข้อเสนอของคุณ | `/board` |
| `co_agent_request` | Agent | คำขอ Co-Agent | `/work` |

### 3.5 ระบบ & อนาคต

| type | ใครเห็น | หมายเหตุ |
|------|---------|----------|
| `system_announcement` | ทุกคน | ประกาศนโยบาย / maintenance |
| `system_policy` | ทุกคน | อัปเดต Terms/Privacy |
| `e_contract_pending` | Agent/Owner | รอลงนาม E-Contract |
| `account_security` | ทุกคน | ล็อกอินอุปกรณ์ใหม่ (อนาคต) |
| `payment_success_fee` | ภายใน (อนาคต) | Success Fee ครบวงจร |

### 3.6 Admin (เฉพาะ role admin)

| type | Deep link |
|------|-----------|
| `admin_chat_sla` | `/admin/chats` |
| `admin_moderation_queue` | `/admin/moderation` |
| `admin_lead_unassigned` | `/admin/leads` |

---

## 4. การจัดกลุ่ม UI

**แท็บ / Chip กรอง (v1):**

| Chip | รวม type |
|------|----------|
| ทั้งหมด | * |
| แชท | `chat_*`, `lead_new` (optional) |
| นัด | `appointment_*`, `viewing_*` |
| ประกาศ | `listing_*` |
| ระบบ | `system_*`, `saved_search_*`, `demand_*`, `co_agent_*`, `e_contract_*` |

**เรียงลำดับ:** `created_at` ใหม่สุดก่อน  
**จัดกลุ่มตามวัน:** วันนี้ / เมื่อวาน / สัปดาห์นี้ / เก่ากว่า

**ความสำคัญ (visual):**

| ระดับ | สีซ้ายการ์ด | ตัวอย่าง |
|-------|-------------|----------|
| Urgent | `#DB3D76` (accent) | นัดใน 2 ชม., ประกาศจะ archive พรุ่งนี้ |
| Action | `#583AD6` (primary) | แก้ draft, bump due |
| Info | `#6B7280` | ระบบ, published |

---

## 5. Badge กระดิ่ง

```
unread_total = sum(unread ทุก type ที่ user เห็น)
แสดง: 0 = ไม่มี badge | 1–9 = ตัวเลข | 10+ = "9+"
```

**ไม่นับ:** รายการที่ user ปิดการแจ้งเตือนประเภทนั้น (settings อนาคต)

**แยกจาก:** badge แท็บล่าง「ข้อความ」— แชทยังมี unread ของ thread; กระดิ่งรวม **event** ทุกประเภท

---

## 6. การกระทำบนแต่ละรายการ

| ท่า | ผล |
|-----|-----|
| แตะการ์ด | mark read + deep link |
| ปัดซ้าย (อนาคต) | ลบจากรายการ (soft) |
| 「อ่านทั้งหมด」 | `mark_all_read` |
| ปุ่ม CTA ในการ์ด | primary action (เช่น ยืนยันว่าง) |

---

## 7. Data model (แผน Backend)

ตารางใหม่ `app_notifications` (หรือ `user_notifications`):

```sql
-- แนวทาง (ยังไม่ migrate)
id uuid PK
user_id uuid FK profiles
type text NOT NULL          -- ตาม taxonomy §3
title text NOT NULL
body text
payload jsonb               -- { listingId, threadId, appointmentId, ... }
priority text               -- urgent | action | info
read_at timestamptz
created_at timestamptz
expires_at timestamptz NULL   -- ซ่อนหลังหมดอายุ
dedupe_key text NULL          -- กันซ้ำ bump รายวัน
```

**แหล่งสร้าง event:**

| แหล่ง | วิธี |
|-------|------|
| Chat realtime | Edge / trigger → insert row |
| `listing-lifecycle-cron` | insert + FCM |
| `route-lead-notification` | insert + FCM |
| `notify-appointment` | insert + FCM |
| Moderation | trigger on status change |

**RLS:** `user_id = auth.uid()` อ่าน/อัปเดต read_at ของตัวเองเท่านั้น

---

## 8. แผน Flutter (เมื่อ implement)

| ไฟล์ใหม่ | หน้าที่ |
|----------|---------|
| `lib/models/app_notification.dart` | type enum + payload |
| `lib/services/notification_center_repository.dart` | list / mark read |
| `lib/features/notifications/notification_center_sheet.dart` | UI หลัก |
| `lib/widgets/notification_bell_button.dart` | กระดิ่ง + badge รวม |

**แก้จุดเดิม:**

- `map_home_page` `onOpenNotifications` → เปิด Center แทน `selectTab(3)`
- `LiHomeHeader` → ใช้ `NotificationBellButton`
- `InAppNotificationHub` → ขยายเป็น feed + ยังคง banner
- รวม logic `ListingBumpReminderBanner` → สร้าง notification `listing_bump_due` (banner บนหน้าแรกเป็น shortcut รายการเดียวกัน)

**Route:** `/notifications` (optional full page)

---

## 9. Role matrix (สรุป)

| ประเภท | Seeker | Owner | Agent | Admin |
|--------|--------|-------|-------|-------|
| แชท | ✓ | ✓ | ✓ | ✓ (+ admin queue) |
| นัดชม | ✓ | ✓ | ✓ | ✓ |
| listing lifecycle | — | ✓ | ✓ | — |
| draft/moderation | — | ✓ | ✓ | ✓ (คิว) |
| saved search | ✓ | — | — | — |
| demand/co-agent | — | ✓ | ✓ | ✓ |
| system | ✓ | ✓ | ✓ | ✓ |

---

## 10. ลำดับ implement แนะนำ

| รอบ | ขอบเขต |
|-----|--------|
| **22a** | UI Center + mock/local list + กระดิ่ง + deep link ที่มีอยู่ |
| **22b** | DB `app_notifications` + RLS + mark read |
| **22c** | ผูก lifecycle cron + chat + appointment → insert |
| **22d** | รวม FCM payload กับ type เดียวกัน |
| **22e** | Settings ปิดประเภท / quiet hours (อนาคต) |

---

## 11. ข้อความ i18n (ตัวอย่าง key)

```
notifCenterTitle          การแจ้งเตือน / Notifications
notifMarkAllRead          อ่านทั้งหมด / Mark all read
notifEmpty                ยังไม่มีการแจ้งเตือน / No notifications yet
notifFilterAll            ทั้งหมด / All
notifFilterChat           แชท / Chat
notifFilterAppointment    นัด / Appointments
notifFilterListing        ประกาศ / Listings
notifFilterSystem         ระบบ / System
listingBumpDueTitle       ยืนยันว่างเพื่อดันโพสต์ / Confirm available to bump
listingStaleWarnTitle     ประกาศใกล้ถูกเก็บ / Listing expiring soon
listingDraftFixTitle      แก้ประกาศเพื่อเผยแพร่ / Fix listing to publish
```

---

## 12. สิ่งที่ยังไม่ทำในรอบออกแบบ

- [ ] Migration `app_notifications`
- [ ] หน้า UI จริง
- [ ] เปลี่ยนพฤติกรรมกระดิ่งหน้าแรก
- [ ] ยุบ `ListingBumpReminderBanner` เข้า Center (หรือเก็บทั้งสองเป็น duplicate ชั่วคราว)

ดูต่อ: [phase-19-listing-lifecycle-push.md](phase-19-listing-lifecycle-push.md), [business-rules.md](business-rules.md)
