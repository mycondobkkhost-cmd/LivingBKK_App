# Phase 24–26: Hub + Threads + Profile Tags + Viewing Requests

**Status:** In progress (Flutter in-memory + demo; DB migration planned)  
**Brand:** PROPPITER (repo `LivingBKK_App`)

---

## Goals

| Goal | Detail |
|------|--------|
| Hub + Threads | ทุกคนมีแชทกลาง 1 + แชทย่อยตามบริบท |
| Tag-first | โปรไฟล์ · ทรัพย์ · คำขอนัด · แชท — อ้างอิงด้วยแท็ก |
| Immutable tags | แก้โปรไฟล์ = แท็กใหม่ (v2, v3…) |
| Blind default | snapshot ให้เจ้าของไม่มีเบอร์/Line |
| Admin 360° | มุมมองต่อ user — Hub, threads, แท็ก, ตารางนัด, moderation |

---

## Chat topology

| Room kind | Who | Count | Bot |
|-----------|-----|-------|-----|
| `seeker_hub` | ลูกค้า | 1 / user | No |
| `agent_hub` | โคเอ | 1 / user | No |
| `owner_hub` | เจ้าของ | 1 / listing | No |
| `rental_lease_group` | สมาชิกสัญญาเช่า | 1 / lease | No (blind PII) |
| `property` | ลูกค้า/โคเอ | 1 / listing | Yes (FAQ/turn) |
| `staff_support` | ลูกค้า | 1 | Yes |
| discovery (`DISCOVERY`) | ลูกค้า | 1 | Yes |

---

## Profile tags (`tag_role`)

| Role | Code prefix | ใครสร้าง |
|------|-------------|----------|
| `seeker_self` | `SP-` | ลูกค้านัดให้ตัวเอง |
| `co_agent_presenter` | `PR-` | โคเอ (ผู้พานัด) |
| `client_subject` | `CL-` | โคเอ / ลูกค้าแทนคนอื่น |

- แยกจากบัญชีแอป (`profiles` signup)
- แก้ = สร้างแท็กใหม่เท่านั้น

---

## Viewing requests

- แยกจากโปรไฟล์ — เก็บ **วัน+เวลา+ทรัพย์+สถานะ**
- `client_tag_id` บังคับ
- `presenter_tag_id` เมื่อโคเอพา (null = มานัดเอง)
- `source`: `customer` | `co_agent` | `admin_phone`

---

## Flutter (implemented / in progress)

| Area | Path |
|------|------|
| Models | `mobile/lib/models/profile_tag.dart`, `viewing_request.dart` |
| Services | `profile_tag_service.dart`, `viewing_request_service.dart`, `participant_moderation_service.dart` |
| Flow | `mobile/lib/features/contact/viewing_request_flow.dart` |
| Forms | `profile_tag_form_sheet.dart`, `profile_tag_picker_sheet.dart`, `viewing_schedule_sheet.dart` |
| Hub | `ChatService.ensureParticipantHub`, `postHubRecap` |
| Admin 360° | `admin_participant_page.dart` → `/admin?nav=participant360` |

---

## DB (planned)

```sql
-- profile_tags, viewing_requests, participant_moderation
-- chat_threads.room_kind += seeker_hub, agent_hub, owner_hub
-- chat_messages.links += profile_tag, viewing_request refs
```

---

## Rollout

1. **24a** — Tags + gate + split viewing form ✅ (this phase)
2. **24b** — Viewing requests table UI + admin phone form
3. **25** — Owner Hub + owner confirm/decline
4. **26** — Full Participant 360° search + `@tag` mentions + Listing 360°

See also: [phase-14-chat-backend.md](phase-14-chat-backend.md), [phase-23-admin-vault.md](phase-23-admin-vault.md)
