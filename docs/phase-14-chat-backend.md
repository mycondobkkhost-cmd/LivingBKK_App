# Phase 14: Chat Backend (Persisted + Admin Inbox)

**Status:** Implemented  
**Date:** 2026-06-02

---

## Delivered

| Feature | Location |
|---------|----------|
| DB `chat_threads` + `chat_messages` | migration `20260602120024_chat_backend.sql` |
| Categories / status / priority | enums + columns on `chat_threads` |
| Admin inbox view | `chat_admin_inbox` |
| Realtime sync | `chat_messages`, `chat_threads` |
| Open / ensure thread | Edge `chat-open-thread` |
| User message + auto-reply | Edge `chat-turn` |
| Admin reply | Edge `chat-admin-reply` |
| Viewing form → chat | Edge `chat-record-viewing` |
| Escalation webhook + FCM admins | Edge `notify-chat-escalation` |
| Flutter sync | `chat_repository.dart`, `ChatService` |

---

## Categories

| category | ความหมาย |
|----------|----------|
| `property_faq` | แชททรัพย์ — AI ตอบเบื้องต้น |
| `ai_support` | ห้อง AI ค้นหาทรัพย์ |
| `staff_support` | คุยกับเจ้าหน้าที่ |
| `escalation` | คำถาม sensitive — รอ admin |
| `viewing_request` | ส่งฟอร์มนัดดูแล้ว |

---

## Deploy

```bash
source scripts/dev-path.sh
./scripts/deploy-all.sh
```

Edge secrets (ทางเลือก): `MAKECOM_WEBHOOK_URL`, `FCM_SERVER_KEY`

Make.com event ใหม่: `chat_escalated`

---

## โหมดทำงาน

| โหมด | พฤติกรรม |
|------|----------|
| Supabase + ล็อกอินจริง | แชท persist, admin inbox กลาง, Realtime |
| TRIAL_MODE / ไม่ล็อกอิน | in-memory เหมือนเดิม (demo) |

---

## Lean ops (Phase 15b)

| กลไก | ผล |
|------|-----|
| **Soft clarify** | ถามไม่ชัดครั้งที่ 1 → bot ขอรายละเอียเพิ่ม (ไม่รบกวน admin) |
| **2-strike escalate** | ถามไม่ชัดครั้งที่ 2 → admin inbox |
| **Inbox กรอง** | แสดงเฉพาะ นัดดู / sensitive / staff / high priority |
| **FAQ ในแอป** | Admin → แชท → ตั้งค่า FAQ (ไม่ต้อง SQL) |
| **Notify ครั้งเดียว** | แชทเจ้าหน้าที่แจ้ง push แค่ข้อความแรก |

Deploy: `supabase db push` + `supabase functions deploy chat-turn`

## Admin console บนคอม (Phase 16)

| รายการ | รายละเอียด |
|--------|------------|
| URL | `/admin/console` (Flutter Web เต็มจอ) |
| Layout | Inbox ซ้าย + แชทขวา (≥900px) |
| รัน local | `./scripts/run-admin-console.sh` |
| Deploy | `./scripts/build-web.sh` → Netlify/host |

แชทเดียว — ลำดับตอบ (ประหยัด token):

1. **Sensitive** → admin ทันที (0 token)
2. **`chat_faq_rules`** global/property/discovery → ตอบจาก DB (0 token)
3. **Discovery** — query `listings_public` + ลิงก์ (0 token)
4. **LLM gate** (ถ้ามี `OPENAI_API_KEY`) — เฉพาะเมื่อ rule ไม่ match (~100 token)
5. **Fallback** → admin

ไม่มีแชท AI แยก — ใช้ thread `DISCOVERY` หรือแชททรัพย์เดียวกัน

### แก้ FAQ (Admin)

```sql
UPDATE chat_faq_rules SET reply_text = '...' WHERE patterns @> ARRAY['ราคา'];
INSERT INTO chat_faq_rules (scope, patterns, reply_text, priority) VALUES (...);
```
