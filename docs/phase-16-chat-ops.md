# Phase 16: Chat Ops — รับงาน / มอบหมาย / SLA

**สถานะ:** Implemented  
**อัปเดต:** 2026-06-02

---

## ทำอะไร

| ฟีเจอร์ | รายละเอียด |
|---------|------------|
| **รับงาน (Claim)** | กดก่อนตอบ — ล็อกไม่ให้แอดมินคนอื่นตอบทับ |
| **มอบหมาย (Assign)** | ส่งต่อให้แอดมินคนอื่น |
| **Inbox 3 แท็บ** | รอรับงาน · งานของฉัน · ปิดแล้ว |
| **SLA Cron** | แจ้งเตือนเมื่อค้างเกินเวลา / ยังไม่มีคนรับ |
| **Realtime ในแอป** | SnackBar ภาษาไทยเมื่อแชทเข้าคิว |
| **FCM ภาษาไทย** | ข้อความมาตรฐานใน Edge Functions |

---

## ศัพท์แจ้งเตือน (ไทย)

| เหตุการณ์ | ข้อความ |
|-----------|---------|
| แชทใหม่เข้าคิว | **แชทรอรับงาน — [รหัส]** |
| รับงานแล้ว (คนอื่น) | **มีคนรับงานแล้ว — [รหัส]** |
| มอบให้คุณ | **มอบหมายแชทให้คุณ — [รหัส]** |
| ค้าง ยังไม่รับ | **⚠️ ยังไม่มีคนรับ — [รหัส] · รอ N นาที** |
| ค้าง มีผู้รับ | **⚠️ แชทค้าง — [รหัส] · N นาที · [ชื่อ]** |
| Escalate | **แชทรอรับงาน — [รหัส] · [ประเภท]** |

---

## SLA (เป้าตอบ)

| ประเภท | นาที |
|--------|------|
| นัดดู / ด่วน | 30 |
| Escalation | 60 |
| แชทเจ้าหน้าที่ | 120 |
| อื่นๆ | 240 |

Cron แจ้งซ้ำไม่ถี่กว่า **30 นาที** ต่อเคส

---

## Deploy

```bash
./scripts/deploy-all.sh
```

Functions ใหม่: `chat-claim`, `chat-assign`, `chat-sla-cron`

Migration: `20260602120027_chat_ops_assignment.sql`

### Cron (Supabase Dashboard หรือ external)

```
POST .../functions/v1/chat-sla-cron
Authorization: Bearer $CRON_SECRET
```

แนะนำ: **ทุก 30 นาที**

---

## SOP ทีม 5 คน

1. เปิด Admin → แท็บ **แชท** → **รอรับงาน**
2. กดแชท → **รับงาน** → ตอบลูกค้า
3. ไม่ว่าง → **มอบหมาย** ให้เพื่อน
4. จบ → **ปิดเคส**
5. หัวหน้าดู **⚠️** จาก push / SnackBar

---

## ไฟล์หลัก

| ส่วน | Path |
|------|------|
| Migration | `supabase/migrations/20260602120027_chat_ops_assignment.sql` |
| Claim | `supabase/functions/chat-claim/` |
| Assign | `supabase/functions/chat-assign/` |
| SLA | `supabase/functions/chat-sla-cron/` |
| UI Inbox | `mobile/lib/features/admin/admin_chats_tab.dart` |
| UI รายละเอียด | `mobile/lib/features/admin/admin_chat_detail_page.dart` |
